from flask import Blueprint, jsonify
from db_connection import db_manager
import traceback

bp = Blueprint('test', __name__)

@bp.route('/db', methods=['GET'])
def test_db():
    """Test database connectivity and admin user"""
    try:
        # Test 1: Check if users table exists
        test1 = db_manager.execute_query("SELECT COUNT(*) as count FROM users")
        total_users = test1[0]['count'] if test1 else 0
        
        # Test 2: Check for admin user
        test2 = db_manager.execute_query("SELECT user_id, username, email, role, admin_status, LENGTH(password_hash) as hash_len, SUBSTRING(password_hash, 1, 20) as hash_preview FROM users WHERE username='admin' AND role='admin'")
        admin_user = test2[0] if test2 else None
        
        # Test 3: Check all roles
        test3 = db_manager.execute_query("SELECT role, admin_status, COUNT(*) as count FROM users GROUP BY role, admin_status ORDER BY role")
        
        # Test 4: Check contests
        test4 = db_manager.execute_query("SELECT contest_id, contest_name, status FROM contests WHERE contest_id = 1")
        contest = test4[0] if test4 else None
        
        return jsonify({
            'success': True,
            'database': 'connected',
            'total_users': total_users,
            'admin_user': admin_user,
            'roles_summary': test3,
            'contest': contest,
            'message': 'Database connection successful! All tables accessible.'
        }), 200
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e),
            'traceback': traceback.format_exc(),
            'message': 'Database connection failed or data not imported yet.'
        }), 500

@bp.route('/auth-test', methods=['POST'])
def test_auth():
    """Test admin authentication manually"""
    from flask import request
    import hashlib
    
    try:
        data = request.get_json() or {}
        username = data.get('username', 'admin')
        password = data.get('password', 'admin123')
        
        # Get user
        user_query = db_manager.execute_query("SELECT * FROM users WHERE username=%s AND role='admin'", (username,))
        
        if not user_query:
            return jsonify({
                'success': False,
                'message': 'User not found in database',
                'username': username
            }), 404
        
        user = user_query[0]
        password_hash = user['password_hash']
        
        # Test SHA256
        is_sha256 = len(password_hash) == 64 and all(c in '0123456789abcdef' for c in password_hash.lower())
        input_hash = hashlib.sha256(password.encode()).hexdigest()
        sha256_match = password_hash == input_hash if is_sha256 else False
        
        return jsonify({
            'success': True,
            'user_found': True,
            'user_id': user['user_id'],
            'username': user['username'],
            'role': user['role'],
            'admin_status': user['admin_status'],
            'hash_info': {
                'hash_length': len(password_hash),
                'hash_preview': password_hash[:20] + '...',
                'is_sha256': is_sha256,
                'expected_hash': input_hash[:20] + '...',
                'sha256_match': sha256_match
            },
            'password_test': {
                'input_password': password,
                'match': sha256_match
            }
        }), 200
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e),
            'traceback': traceback.format_exc()
        }), 500
