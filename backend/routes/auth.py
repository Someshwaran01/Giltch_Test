from flask import Blueprint, jsonify, request
from db_connection import db_manager
from auth_middleware import admin_required
import jwt
import datetime
import logging
from config import Config
from werkzeug.security import generate_password_hash
import uuid
from utils.rate_limiter import rate_limiter
from utils.password_utils import password_manager

bp = Blueprint('auth', __name__)
logger = logging.getLogger(__name__)

def create_token(user_id, role='participant'):
    """Create JWT token with configurable expiry"""
    payload = {
        'sub': user_id,
        'role': role,
        'iat': datetime.datetime.utcnow(),
        'exp': datetime.datetime.utcnow() + datetime.timedelta(hours=Config.JWT_EXPIRY_HOURS)
    }
    return jwt.encode(payload, Config.SECRET_KEY, algorithm=Config.JWT_ALGORITHM)

@bp.route('/participant/login', methods=['POST'])
def participant_login():
    data = request.get_json()
    pid = data.get('participant_id', '').strip()
    
    if not pid:
        return jsonify({'error': 'Participant ID is required'}), 400
    
    # Rate limiting check
    if not rate_limiter.is_allowed(f'participant_login:{pid}'):
        wait_time = rate_limiter.get_remaining_time(f'participant_login:{pid}')
        return jsonify({
            'error': f'Too many login attempts. Please try again in {wait_time} seconds.'
        }), 429

    try:
        # Check by user_id (int) or username (str)
        if pid.isdigit():
            query = "SELECT * FROM users WHERE role='participant' AND user_id=%s"
            user_data = db_manager.execute_query(query, (int(pid),))
        else:
            query = "SELECT * FROM users WHERE role='participant' AND username=%s"
            user_data = db_manager.execute_query(query, (pid,))
            
        if not user_data:
            logger.warning(f"Participant not found: {pid}")
            return jsonify({'error': 'Participant not found'}), 404

        user = user_data[0]
        
        if user.get('status') == 'disqualified':
            return jsonify({'error': 'You have been disqualified for violations'}), 403

        # Check Proctoring Table Disqualification
        p_query = "SELECT is_disqualified FROM participant_proctoring WHERE participant_id=%s"
        proc_status = db_manager.execute_query(p_query, (user['username'],))
        if proc_status and proc_status[0].get('is_disqualified'):
            return jsonify({'error': 'You have been permanently disqualified for proctoring violations'}), 403

        if user.get('status') == 'held':
            return jsonify({'error': 'Your status is currently on hold. You have not qualified for the next level'}), 403
        
        # Success - reset rate limit
        rate_limiter.reset(f'participant_login:{pid}')

        token = create_token(user['username'], 'participant')
        
        # --- PROCTORING INIT ---
        try:
            # Strict Qualification Check
            # 1. Get Global Active Level
            c_query = "SELECT contest_id FROM contests WHERE status='live' LIMIT 1"
            c_res = db_manager.execute_query(c_query)
            active_contest_id = c_res[0]['contest_id'] if c_res else 1
            
            gl_query = "SELECT round_number FROM rounds WHERE contest_id=%s AND status='active' ORDER BY round_number ASC LIMIT 1"
            gl_res = db_manager.execute_query(gl_query, (active_contest_id,))
            global_active_level = gl_res[0]['round_number'] if gl_res else 1
            
            # 2. If Global Level > 1, User MUST be in shortlisted_participants with is_allowed=1
            if global_active_level > 1:
                # First, check if they are already playing a previous level?
                # User Requirement: "Unselected participants are fully blocked ... Even if they know a valid Participant ID."
                # We block entry if they are NOT allowed for the ACTIVE level.
                
                # Check shortlist
                sl_query = "SELECT is_allowed FROM shortlisted_participants WHERE contest_id=%s AND level=%s AND user_id=%s AND is_allowed=1"
                sl_res = db_manager.execute_query(sl_query, (active_contest_id, global_active_level, user['user_id']))
                
                if not sl_res:
                    # Not shortlisted for the active level.
                    # Edge Case: Are they lagging behind? e.g. Active=3, User just finished 1 and needs to do 2?
                    # "Problem: ... access where unqualified participants can see active levels ..."
                    # If they are NOT selected for Level 3, but Level 3 is active, they shouldn't enter.
                    # Unless they have specific permission (custom 'held' status check handles partials, but here we need strict).
                    
                    return jsonify({'error': f'You have not been selected for Level {global_active_level}. Access Denied.'}), 403

            
            proc_check = db_manager.execute_query("SELECT * FROM participant_proctoring WHERE participant_id=%s AND contest_id=%s", (user['username'], active_contest_id))
            if not proc_check:
                 db_manager.execute_update(
                     "INSERT INTO participant_proctoring (id, participant_id, user_id, contest_id, total_violations, violation_score, risk_level, created_at) VALUES (%s, %s, %s, %s, 0, 0, 'low', NOW())",
                     (str(uuid.uuid4()), user['username'], user['user_id'], active_contest_id)
                 )
        except Exception as ex:
            print(f"Proctoring init warning: {ex}")
        
        # Emit Real-time Event
        try:
            from extensions import socketio
            socketio.emit('participant:joined', {
                'participant_id': user['username'],
                'name': user['full_name'],
                'contest_id': active_contest_id
            })
        except: pass
        
        return jsonify({
            'success': True,
            'participant': {
                'id': user['user_id'],
                'participant_id': user['username'],
                'name': user['full_name'],
                'status': user['status']
            },
            'token': token
        }), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500

@bp.route('/leader/login', methods=['POST'])
def leader_login():
    data = request.get_json()
    username = data.get('username', '').strip()
    password = data.get('password', '')

    if not username or not password:
        return jsonify({'error': 'Username and password are required'}), 400
    
    # Rate limiting check
    if not rate_limiter.is_allowed(f'leader_login:{username}'):
        wait_time = rate_limiter.get_remaining_time(f'leader_login:{username}')
        return jsonify({
            'error': f'Too many login attempts. Please try again in {wait_time} seconds.'
        }), 429

    try:
        user_query = db_manager.execute_query(
            "SELECT * FROM users WHERE username=%s AND role='leader'",
            (username,)
        )
        
        if not user_query:
            logger.warning(f"Failed leader login attempt for username: {username}")
            return jsonify({'error': 'Invalid credentials'}), 401

        user = user_query[0]
        
        # Verify password using centralized password manager
        if not password_manager.verify_password(password, user['password_hash']):
            logger.warning(f"Invalid password for leader: {username}")
            return jsonify({'error': 'Invalid credentials'}), 401
             
        if user.get('admin_status') != 'APPROVED':
            return jsonify({'error': 'Your leader account is not approved'}), 403
        
        # Success - reset rate limit
        rate_limiter.reset(f'leader_login:{username}')
        
        token = create_token(user['username'], 'leader')
        logger.info(f"Leader {username} logged in successfully")
        
        return jsonify({
            'success': True, 
            'token': token,
            'leader': {
                'name': user['full_name'],
                'username': user['username']
            }
        })
    except Exception as e:
        logger.error(f"Leader login error for {username}: {str(e)}")
        return jsonify({'error': 'Login failed. Please try again.'}), 500

@bp.route('/admin/login', methods=['POST'])
def admin_login():
    data = request.get_json()
    username = data.get('username', '').strip()
    password = data.get('password', '')

    if not username or not password:
        return jsonify({'error': 'Username and password are required'}), 400
    
    # Rate limiting check
    if not rate_limiter.is_allowed(f'admin_login:{username}'):
        wait_time = rate_limiter.get_remaining_time(f'admin_login:{username}')
        logger.warning(f"Rate limit exceeded for admin login: {username}")
        return jsonify({
            'error': f'Too many login attempts. Please try again in {wait_time} seconds.'
        }), 429

    try:
        user_query = db_manager.execute_query(
            "SELECT * FROM users WHERE username=%s AND role='admin'",
            (username,)
        )
            
        if not user_query:
            logger.warning(f"Failed admin login attempt - user not found: {username}")
            return jsonify({'error': 'Invalid credentials'}), 401
        
        user = user_query[0]
        
        # Status Check
        status = user.get('admin_status', 'PENDING')
        if status == 'PENDING':
            return jsonify({'error': '⏳ Your admin request is pending approval'}), 403
        if status == 'REJECTED':
            return jsonify({'error': '❌ Your admin request has been rejected'}), 403
        
        # Verify password using centralized password manager
        if not password_manager.verify_password(password, user['password_hash']):
            logger.warning(f"Invalid password for admin: {username}")
            return jsonify({'error': 'Invalid credentials'}), 401
        
        # Success - reset rate limit
        rate_limiter.reset(f'admin_login:{username}')
        logger.info(f"Admin {username} logged in successfully")
        
        return jsonify({
            'success': True,
            'token': create_token(user['username'], 'admin'),
            'user': {
                'username': user['username'],
                'name': user['full_name']
            }
        })
        
    except Exception as e:
        logger.error(f"Admin login error for {username}: {str(e)}", exc_info=True)
        return jsonify({'error': 'Login failed. Please try again.'}), 500

@bp.route('/admin/register', methods=['POST'])
def register_admin():
    data = request.get_json()
    username = data.get('username', '').strip()
    password = data.get('password', '')
    full_name = data.get('full_name', '').strip()
    email = data.get('email', '').strip()
    
    if not all([username, password, email]):
        return jsonify({'error': 'Username, password and email are required'}), 400
    
    # Validate password strength
    if len(password) < 8:
        return jsonify({'error': 'Password must be at least 8 characters long'}), 400
        
    # Check if exists
    chk = db_manager.execute_query("SELECT user_id FROM users WHERE username=%s", (username,))
    if chk:
        return jsonify({'error': 'Username already exists'}), 400
    
    # Use centralized password hashing
    pwd_hash = password_manager.hash_password(password, method='pbkdf2')
    
    try:
        db_manager.execute_update(
            "INSERT INTO users (username, email, password_hash, full_name, role, admin_status, created_at) VALUES (%s, %s, %s, %s, 'admin', 'PENDING', NOW())",
            (username, email, pwd_hash, full_name or username)
        )
        logger.info(f"New admin registration: {username}")
        return jsonify({'success': True, 'message': 'Admin registration submitted. Waiting for approval'}), 201
    except Exception as e:
        logger.error(f"Admin registration error: {str(e)}")
        return jsonify({'error': 'Registration failed. Please try again.'}), 500

@bp.route('/admin/pending', methods=['GET'])
@admin_required
def get_pending_admins():
    try:
        query = "SELECT user_id, username, full_name, created_at, admin_status FROM users WHERE role='admin' AND admin_status='PENDING'"
        res = db_manager.execute_query(query)
        return jsonify({'pending': res})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@bp.route('/admin/approve', methods=['POST'])
@admin_required
def approve_admin():
    data = request.get_json()
    target_id = data.get('user_id')
    action = data.get('action') # APPROVE or REJECT
    
    if not target_id or action not in ['APPROVE', 'REJECT']:
        return jsonify({'error': 'Invalid request'}), 400
        
    status_map = {'APPROVE': 'APPROVED', 'REJECT': 'REJECTED'}
    new_status = status_map[action]
    
    # Get approver ID
    auth_header = request.headers.get('Authorization')
    token = auth_header.split(" ")[1]
    token_data = jwt.decode(token, Config.SECRET_KEY, algorithms=["HS256"])
    approver_username = token_data['sub']
    
    u_res = db_manager.execute_query("SELECT user_id FROM users WHERE username=%s", (approver_username,))
    approver_id = u_res[0]['user_id'] if u_res else None
    
    query = "UPDATE users SET admin_status=%s, approved_by=%s, approval_at=NOW() WHERE user_id=%s"
    db_manager.execute_update(query, (new_status, approver_id, target_id))
    
    return jsonify({'success': True, 'status': new_status})

@bp.route('/session', methods=['GET'])
def get_session():
    auth_header = request.headers.get('Authorization')
    if not auth_header:
        return jsonify(None), 401
    
    try:
        token_parts = auth_header.split(" ")
        if len(token_parts) != 2:
            return jsonify(None), 401
        token = token_parts[1]
        
        payload = jwt.decode(token, Config.SECRET_KEY, algorithms=[Config.JWT_ALGORITHM])
        user_id = payload['sub']
        
        try:
            u_res = db_manager.execute_query("SELECT * FROM users WHERE username=%s", (user_id,))
            if u_res:
                u = u_res[0]
                return jsonify({
                    'participant_id': u['user_id'],
                    'username': u['username'],
                    'full_name': u['full_name'],
                    'role': u['role'],
                    'status': u.get('status', 'active'),
                    'admin_status': u.get('admin_status', 'APPROVED') 
                })
        except Exception as e:
            logger.error(f"Session query error: {str(e)}")
             
        return jsonify(None), 404
    except jwt.ExpiredSignatureError:
        return jsonify({'error': 'Token has expired'}), 401
    except jwt.InvalidTokenError:
        return jsonify({'error': 'Invalid token'}), 401
    except Exception as e:
        logger.error(f"Session error: {str(e)}")
        return jsonify(None), 401
@bp.route('/logout', methods=['POST'])
def logout():
    """
    Universal logout endpoint for all user types.
    Since JWT is stateless, logout is handled client-side by removing the token.
    This endpoint can be used for logging/cleanup if needed.
    """
    auth_header = request.headers.get('Authorization')
    
    try:
        if auth_header:
            token = auth_header.split(" ")[1]
            payload = jwt.decode(token, Config.SECRET_KEY, algorithms=['HS256'])
            username = payload.get('sub')
            role = payload.get('role')
            
            # Optional: Log the logout event
            print(f"User {username} ({role}) logged out")
            
            # Optional: Clear any session data in database if needed
            # For example, update last_logout timestamp
            
        return jsonify({'success': True, 'message': 'Logged out successfully'}), 200
    except Exception as e:
        # Even if token is invalid, consider logout successful
        return jsonify({'success': True, 'message': 'Logged out'}), 200

@bp.route('/participant/logout', methods=['POST'])
def participant_logout():
    """Participant-specific logout endpoint"""
    return logout()

@bp.route('/leader/logout', methods=['POST'])
def leader_logout():
    """Leader-specific logout endpoint"""
    return logout()

@bp.route('/admin/logout', methods=['POST'])
def admin_logout():
    """Admin-specific logout endpoint"""
    return logout()