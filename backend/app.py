from flask import Flask, jsonify
from config import Config
from extensions import socketio, cors

def create_app(config_class=Config):
    app = Flask(__name__, static_folder='../frontend', static_url_path='')
    app.config.from_object(config_class)

    # Initialize extensions with secure CORS configuration
    cors.init_app(app, resources={
        r"/api/*": {
            "origins": app.config.get('ALLOWED_ORIGINS', [app.config.get('FRONTEND_URL', 'http://localhost:5000')]),
            "supports_credentials": True,
            "allow_headers": ["Content-Type", "Authorization"],
            "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
        }
    })
    socketio.init_app(app, cors_allowed_origins=app.config.get('ALLOWED_ORIGINS', '*'))
    
    # Add security headers to all responses
    @app.after_request
    def add_security_headers(response):
        for header, value in app.config.get('SECURITY_HEADERS', {}).items():
            response.headers[header] = value
        return response
    
    # Add request size limit (10MB)
    app.config['MAX_CONTENT_LENGTH'] = 10 * 1024 * 1024

    # Register Blueprints
    from routes.auth import bp as auth_bp
    from routes.contest import bp as contest_bp
    from routes.admin import bp as admin_bp
    from routes.leaderboard import bp as leaderboard_bp
    from routes.proctoring import bp as proctoring_bp
    from routes.test import bp as test_bp

    app.register_blueprint(auth_bp, url_prefix='/api/auth')
    app.register_blueprint(contest_bp, url_prefix='/api/contest')
    app.register_blueprint(admin_bp, url_prefix='/api/admin')
    app.register_blueprint(leaderboard_bp, url_prefix='/api/leaderboard')
    app.register_blueprint(proctoring_bp, url_prefix='/api/proctoring')
    app.register_blueprint(test_bp, url_prefix='/api/test')
    
    from routes.leader import bp as leader_bp
    app.register_blueprint(leader_bp, url_prefix='/api/leader')
    
    from routes.rankings import bp as rankings_bp
    app.register_blueprint(rankings_bp, url_prefix='/api/rankings')

    from routes.participant import bp as participant_bp
    app.register_blueprint(participant_bp, url_prefix='/api/participant')

    # Serve Static Files
    @app.route('/')
    def serve_index():
        return app.send_static_file('index.html')

    @app.route('/participant.html')
    def serve_participant():
        return app.send_static_file('participant.html')

    @app.route('/admin.html')
    def serve_admin():
        return app.send_static_file('admin.html')

    @app.route('/leaderboard.html')
    def serve_leaderboard():
        return app.send_static_file('leaderboard.html')

    @app.route('/results.html')
    def serve_results():
        return app.send_static_file('results.html')

    @app.route('/leader_login.html')
    def serve_leader_login():
        return app.send_static_file('leader_login.html')

    @app.route('/leader_dashboard.html')
    def serve_leader_dashboard():
        return app.send_static_file('leader_dashboard.html')
        
    @app.route('/favicon.ico')
    def favicon():
        return '', 204

    @app.errorhandler(Exception)
    def handle_global_error(e):
        from flask import request
        from werkzeug.exceptions import HTTPException
        import logging
        
        # Determine status code
        code = 500
        if isinstance(e, HTTPException):
            code = e.code

        # API Requests -> JSON
        if request.path.startswith('/api/'):
            # Only log stack trace for 500s
            if code >= 500:
                import traceback
                logging.error(f"Internal error on {request.path}: {traceback.format_exc()}")
                # Don't leak internal error details in production
                if app.config.get('DEBUG'):
                    error_msg = str(e)
                else:
                    error_msg = 'Internal server error. Please try again later.'
                return jsonify({'error': error_msg, 'success': False}), code
            return jsonify({'error': str(e), 'success': False}), code

        # Static/Page Requests -> HTML (default behavior)
        if isinstance(e, HTTPException):
            return e
            
        import traceback
        logging.error(f"Internal error: {traceback.format_exc()}")
        return jsonify({'error': 'Internal Server Error', 'message': 'An unexpected error occurred'}), 500

    @app.route('/api/health')
    def health_check():
        return jsonify({"status": "healthy"}), 200

    @app.route('/health')
    def health_check_root():
        """Health check endpoint to wake up the service"""
        from datetime import datetime
        return jsonify({
            'status': 'healthy',
            'timestamp': datetime.now().isoformat(),
            'service': 'Debug Marathon Platform'
        }), 200

    return app

# Create app instance for WSGI servers (Gunicorn, etc.)
app = create_app()

if __name__ == '__main__':
    socketio.run(app, debug=app.config['DEBUG'], host='0.0.0.0', port=5000, allow_unsafe_werkzeug=app.config['DEBUG'])
    # Database configuration updated to debug_marathon_v3 - Force Reload
