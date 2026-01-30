from flask import Blueprint, jsonify, request
from db_connection import db_manager
from auth_middleware import admin_required
import jwt
import datetime
from config import Config
from werkzeug.security import check_password_hash, generate_password_hash
import uuid

bp = Blueprint('auth', __name__)

def create_token(user_id, role='participant'):
    payload = {
        'sub': user_id,
        'role': role,
        'iat': datetime.datetime.utcnow(),
        'exp': datetime.datetime.utcnow() + datetime.timedelta(hours=24)
    }
    return jwt.encode(payload, Config.SECRET_KEY, algorithm='HS256')

@bp.route('/participant/login', methods=['POST'])
def participant_login():
    data = request.get_json()
    pid = data.get('participant_id')
    
    if not pid:
        return jsonify({'error': 'Participant ID is required'}), 400

    try:
        # Check by user_id (int) or username (str)
        if pid.isdigit():
            query = "SELECT * FROM users WHERE role='participant' AND user_id=%s"
            user_data = db_manager.execute_query(query, (int(pid),))
        else:
            query = "SELECT * FROM users WHERE role='participant' AND username=%s"
            user_data = db_manager.execute_query(query, (pid,))
            
        if not user_data:
            return jsonify({'error': 'Participant not found'}), 404

        user = user_data[0]
        
        if user.get('status') == 'disqualified':
            return jsonify({'error': 'You have been disqualified for violations.'}), 403

        # Check Proctoring Table Disqualification
        p_query = "SELECT is_disqualified FROM participant_proctoring WHERE participant_id=%s"
        proc_status = db_manager.execute_query(p_query, (user['username'],))
        if proc_status and proc_status[0].get('is_disqualified'):
             return jsonify({'error': 'You have been permanently disqualified for proctoring violations.'}), 403

        if user.get('status') == 'held':
            return jsonify({'error': 'Your status is currently on hold. You have not qualified for the next level.'}), 403

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
    username = data.get('username')
    password = data.get('password')

    if not username or not password:
        return jsonify({'error': 'Username and Password are required'}), 400

    try:
        user_query = db_manager.execute_query("SELECT * FROM users WHERE username=%s AND role='leader'", (username,))
        if not user_query:
             return jsonify({'error': 'Invalid credentials or not authorized as LEADER'}), 401

        user = user_query[0]
        
        # Verify Password - Support SHA256 (64 hex chars) and Werkzeug hashes
        valid = False
        password_hash = user['password_hash']
        
        # Check if it's a SHA256 hash (64 characters, all hex)
        if len(password_hash) == 64 and all(c in '0123456789abcdef' for c in password_hash.lower()):
            import hashlib
            if password_hash == hashlib.sha256(password.encode()).hexdigest():
                valid = True
        # Check if it's a scrypt hash (starts with scrypt:)
        elif password_hash.startswith('scrypt:'):
            valid = check_password_hash(password_hash, password)
        # Otherwise try Werkzeug check (pbkdf2, etc.)
        else:
            try:
                valid = check_password_hash(password_hash, password)
            except:
                pass

        if not valid:
             return jsonify({'error': 'Invalid credentials'}), 401
             
        if user.get('admin_status') != 'APPROVED':
             return jsonify({'error': 'Your leader account is not approved.'}), 403
             
        token = create_token(user['username'], 'leader')
        
        return jsonify({
            'success': True, 
            'token': token,
            'leader': {
                'name': user['full_name'],
                'username': user['username']
            }
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@bp.route('/admin/login', methods=['POST'])
def admin_login():
    data = request.get_json()
    username = data.get('username')
    password = data.get('password')

    print(f"[DEBUG] Admin login attempt - Username: {username}, Password length: {len(password) if password else 0}")

    if not username or not password:
        return jsonify({'error': 'Username and Password are required'}), 400

    try:
        user_query = db_manager.execute_query("SELECT * FROM users WHERE username=%s AND role='admin'", (username,))
        
        print(f"[DEBUG] Query result: {len(user_query) if user_query else 0} users found")
            
        if user_query:
            user = user_query[0]
            
            print(f"[DEBUG] User found - ID: {user.get('user_id')}, Status: {user.get('admin_status')}")
            print(f"[DEBUG] Password hash length: {len(user['password_hash'])}")
            print(f"[DEBUG] Password hash (first 20): {user['password_hash'][:20]}...")
            
            # Status Check
            status = user.get('admin_status', 'PENDING')
            if status == 'PENDING':
                print(f"[DEBUG] Status check failed: PENDING")
                return jsonify({'error': '⏳ Your admin request is pending approval.'}), 403
            if status == 'REJECTED':
                print(f"[DEBUG] Status check failed: REJECTED")
                return jsonify({'error': '❌ Your admin request has been rejected.'}), 403
            
            # Verify Password - Support SHA256 (64 hex chars) and Werkzeug hashes
            valid = False
            password_hash = user['password_hash']
            
            # Check if it's a SHA256 hash (64 characters, all hex)
            if len(password_hash) == 64 and all(c in '0123456789abcdef' for c in password_hash.lower()):
                print(f"[DEBUG] Detected as SHA256 hash")
                import hashlib
                input_hash = hashlib.sha256(password.encode()).hexdigest()
                print(f"[DEBUG] Input hash: {input_hash[:20]}...")
                if password_hash == input_hash:
                    valid = True
                    print(f"[DEBUG] SHA256 verification: PASSED")
                else:
                    print(f"[DEBUG] SHA256 verification: FAILED")
            # Check if it's a scrypt hash (starts with scrypt:)
            elif password_hash.startswith('scrypt:'):
                print(f"[DEBUG] Detected as Scrypt hash")
                valid = check_password_hash(password_hash, password)
                print(f"[DEBUG] Scrypt verification: {'PASSED' if valid else 'FAILED'}")
            # Otherwise try Werkzeug check (pbkdf2, etc.)
            else:
                print(f"[DEBUG] Trying Werkzeug verification")
                try:
                    valid = check_password_hash(password_hash, password)
                    print(f"[DEBUG] Werkzeug verification: {'PASSED' if valid else 'FAILED'}")
                except Exception as e:
                    print(f"[DEBUG] Werkzeug verification error: {e}")
                    pass

            if valid:
                print(f"[DEBUG] Login successful for {username}")
                return jsonify({
                    'success': True,
                    'token': create_token(user['username'], 'admin'),
                    'user': {
                        'username': user['username'],
                        'name': user['full_name']
                    }
                })
            else:
                print(f"[DEBUG] Login failed - Invalid password")
                return jsonify({'error': 'Invalid credentials'}), 401
        else:
            print(f"[DEBUG] No user found with username: {username}")
            return jsonify({'error': 'Invalid credentials'}), 401
    except Exception as e:
        print(f"[ERROR] Admin login exception: {e}")
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500

@bp.route('/admin/register', methods=['POST'])
def register_admin():
    data = request.get_json()
    username = data.get('username')
    password = data.get('password')
    full_name = data.get('full_name')
    email = data.get('email')
    
    if not all([username, password, email]):
        return jsonify({'error': 'Username, password and email are required'}), 400
        
    # Check if exists
    chk = db_manager.execute_query("SELECT user_id FROM users WHERE username=%s", (username,))
    if chk:
        return jsonify({'error': 'Username already exists'}), 400
        
    pwd_hash = generate_password_hash(password)
    
    try:
        db_manager.execute_update(
            "INSERT INTO users (username, email, password_hash, full_name, role, admin_status, created_at) VALUES (%s, %s, %s, %s, 'admin', 'PENDING', NOW())",
            (username, email, pwd_hash, full_name or username)
        )
        return jsonify({'success': True, 'message': 'Admin registration submitted. Waiting for approval.'}), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 500

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
        if len(token_parts) != 2: return jsonify(None), 401
        token = token_parts[1]
        
        payload = jwt.decode(token, Config.SECRET_KEY, algorithms=['HS256'])
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
        except Exception as e: print(e)
             
        return jsonify(None), 404
    except Exception as e:
        print(f"Session Error: {e}")
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