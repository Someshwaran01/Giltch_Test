# Login Issue Troubleshooting Guide

## Issue: Frontend can't login with any credentials

### Possible Causes:

1. **No users in the database** - Database might be empty after deployment
2. **CORS issues** - Frontend can't communicate with backend API
3. **Frontend not loading from correct URL** - Assets loading but API calls failing
4. **Database not seeded** - No test users created

---

## 🔍 **Step 1: Check if Backend is Running**

Open your browser's Developer Tools (F12) and go to Console tab.

Try accessing: `https://debug-marathon.onrender.com/api/health`

**Expected Response:**
```json
{"status": "healthy"}
```

If you get an error, the backend is not running properly.

---

## 🔍 **Step 2: Check Database Connection**

The backend logs should show:
```
✓ PostgreSQL pool initialized successfully
Using PostgreSQL database manager (psycopg3)
```

If you see connection errors, the database is not connected.

---

## 🔍 **Step 3: Check if Users Exist in Database**

You need to **seed the database** with test users.

### **Option A: Run seed_data.py on Render**

In your Render dashboard, go to **Shell** tab and run:
```bash
cd backend
python seed_data.py
```

This will create:
- Test participant: `PART001`
- Test admin users
- Sample contests and questions

### **Option B: Manually Create a Test User**

Connect to your Supabase database and run:
```sql
INSERT INTO users (username, email, password_hash, full_name, role, status)
VALUES ('TEST001', 'test@example.com', 'dummy_hash', 'Test User', 'participant', 'active');
```

---

## 🔍 **Step 4: Check Frontend Console for Errors**

1. Open `https://debug-marathon.onrender.com/participant.html`
2. Press F12 to open Developer Tools
3. Go to **Console** tab
4. Try to login with a username (e.g., `TEST001` or `PART001`)
5. Look for errors like:
   - `Failed to fetch` - CORS or network issue
   - `404 Not Found` - API route not found
   - `500 Internal Server Error` - Backend error

---

## ✅ **Solution Steps**

### **1. Seed the Database**

Create a simple script to add a test user directly via the backend API.

Add this temporary endpoint to `backend/routes/admin.py`:

```python
@bp.route('/seed-test-user', methods=['POST'])
def seed_test_user():
    """Temporary endpoint to create a test user"""
    try:
        query = """
            INSERT INTO users (username, email, password_hash, full_name, role, status)
            VALUES (%s, %s, %s, %s, %s, %s)
            ON CONFLICT (username) DO NOTHING
            RETURNING user_id
        """
        result = db_manager.execute_query(
            query,
            ('TEST001', 'test@example.com', 'dummy_hash', 'Test User', 'participant', 'active')
        )
        return jsonify({'success': True, 'message': 'Test user created', 'username': 'TEST001'}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500
```

Then call it from your browser:
```
POST https://debug-marathon.onrender.com/api/admin/seed-test-user
```

### **2. Check Browser Console**

After adding the test user, try logging in with `TEST001`.

Watch the **Network** tab in Developer Tools to see:
- Is the request going to the right URL?
- What is the response status code?
- What is the response body?

### **3. Common Issues & Fixes**

#### **Issue: "Participant not found"**
- **Cause:** No users in database
- **Fix:** Run seed_data.py or manually insert users

#### **Issue: "CORS error" or "Failed to fetch"**
- **Cause:** CORS misconfiguration
- **Fix:** Check that `ALLOWED_ORIGINS` environment variable includes your Render URL

#### **Issue: "Network error"**
- **Cause:** Backend not running or wrong URL
- **Fix:** Verify backend health endpoint works

#### **Issue: "Token expired" or "Unauthorized"**
- **Cause:** JWT secret mismatch or expired token
- **Fix:** Clear browser localStorage and try again

---

## 🎯 **Quick Test**

1. Open browser console
2. Run this command:
```javascript
fetch('/api/health')
  .then(r => r.json())
  .then(d => console.log('Backend:', d))
  .catch(e => console.error('Error:', e));
```

If this works, backend is accessible.

3. Test login API:
```javascript
fetch('/api/auth/participant/login', {
  method: 'POST',
  headers: {'Content-Type': 'application/json'},
  body: JSON.stringify({participant_id: 'TEST001'})
})
.then(r => r.json())
.then(d => console.log('Login:', d))
.catch(e => console.error('Error:', e));
```

---

## 📋 **What You Should See**

**Successful Response:**
```json
{
  "success": true,
  "token": "eyJ...",
  "participant": {
    "username": "TEST001",
    "full_name": "Test User",
    "role": "participant"
  }
}
```

**Error Response:**
```json
{
  "error": "Participant not found"
}
```

---

## 🚀 **Next Steps**

Once you identify the issue from the steps above, let me know:
1. What error you see in the browser console
2. What the Network tab shows for the login request
3. If the health check endpoint works

I'll provide the specific fix for your case!
