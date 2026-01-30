/**
 * api.js
 * API Communication Layer with timeout and retry support
 */

const API = {
    BASE_URL: '/api',
    REQUEST_TIMEOUT: 30000, // 30 seconds
    MAX_RETRIES: 2,

    async request(endpoint, method = 'GET', data = null, retryCount = 0) {
        const headers = { 'Content-Type': 'application/json' };

        // Add auth token if available (for admin/authenticated requests)
        let token = localStorage.getItem('admin_token') || localStorage.getItem('auth_token');

        // If no token found, check for participant session (dm_session)
        if (!token) {
            try {
                const sessionStr = localStorage.getItem('dm_session');
                if (sessionStr) {
                    const session = JSON.parse(sessionStr);
                    if (session && session.token) {
                        token = session.token;
                    }
                }
            } catch (e) {
                console.warn('Failed to parse session token', e);
            }
        }

        if (token) {
            headers['Authorization'] = `Bearer ${token}`;
        }

        try {
            const config = {
                method,
                headers,
                signal: AbortSignal.timeout(this.REQUEST_TIMEOUT) // Timeout support
            };
            if (data) config.body = JSON.stringify(data);

            const response = await fetch(`${this.BASE_URL}${endpoint}`, config);

            // Handle Unauthorized (401) or Forbidden (403)
            if (response.status === 401 || response.status === 403) {
                console.warn('Unauthorized/Forbidden request, logging out...');
                localStorage.removeItem('admin_token');
                localStorage.removeItem('auth_token');
                localStorage.removeItem('dm_session');

                // Only reload if we are on a protected page
                if (window.location.pathname.includes('admin.html') ||
                    window.location.pathname.includes('leaderboard.html') ||
                    window.location.pathname.includes('leader_dashboard.html')) {
                    window.location.href = '/';
                }
                return { error: 'Session expired. Please login again.', status: response.status };
            }

            // Handle rate limiting
            if (response.status === 429) {
                const result = await response.json();
                if (typeof Toast !== 'undefined') {
                    Toast.show(result.error || 'Too many requests. Please wait.', 'warning');
                }
                return result;
            }

            const result = await response.json();
            return result;

        } catch (error) {
            // Handle timeout
            if (error.name === 'TimeoutError' || error.name === 'AbortError') {
                console.error("Request timeout:", endpoint);

                // Retry on timeout
                if (retryCount < this.MAX_RETRIES) {
                    console.log(`Retrying request (${retryCount + 1}/${this.MAX_RETRIES})...`);
                    await new Promise(resolve => setTimeout(resolve, 1000 * (retryCount + 1)));
                    return this.request(endpoint, method, data, retryCount + 1);
                }

                if (typeof Toast !== 'undefined') {
                    Toast.show('Request timeout. Please check your connection.', 'error');
                }
                return { error: 'Request timeout', timeout: true };
            }

            // Handle network errors
            console.error("Network Error:", error);

            // Retry on network error
            if (retryCount < this.MAX_RETRIES) {
                console.log(`Retrying request (${retryCount + 1}/${this.MAX_RETRIES})...`);
                await new Promise(resolve => setTimeout(resolve, 1000 * (retryCount + 1)));
                return this.request(endpoint, method, data, retryCount + 1);
            }

            if (typeof Toast !== 'undefined') {
                Toast.show('Network error. Please check your connection.', 'error');
            }
            return { error: 'Network error', network_error: true };
        }
    },

    // Specific endpoints
    async login(participantId) {
        return this.request('/auth/participant/login', 'POST', { participant_id: participantId });
    },

    async submit(code, lang, qId) {
        // Real backend submission
        return this.request('/contest/submit', 'POST', { code, language: lang, question_id: qId });
    }
};
