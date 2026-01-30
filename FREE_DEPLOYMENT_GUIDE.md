# 🎉 FREE Deployment Guide - Debug Marathon Platform

## 🆓 Zero-Cost Deployment for 350+ Users

**Deploy your Debug Marathon Platform completely FREE using Render + Supabase**

---

## 🏆 Why This Setup?

| Feature | Render (Free) | Supabase (Free) |
|---------|---------------|-----------------|
| **Cost** | $0/month | $0/month |
| **Database** | - | 500MB storage, unlimited API requests |
| **Uptime** | 750 hours/month | 24/7 always-on |
| **WebSockets** | ✅ Supported | ✅ Real-time subscriptions |
| **SSL Certificate** | ✅ Free | ✅ Free |
| **Auto-Deploy** | ✅ From GitHub | ✅ Instant changes |
| **Bandwidth** | 100GB/month | Unlimited |
| **Cold Starts** | ~30 seconds after idle | N/A |

**Perfect for:** Testing, small contests (50-150 users), scheduled events

---

## 📋 Prerequisites

Before you begin, make sure you have:
- [ ] GitHub account (free)
- [ ] Render account (free) - [render.com](https://render.com)
- [ ] Supabase account (free) - [supabase.com](https://supabase.com)
- [ ] Your project code on GitHub

---

## 🚀 Step-by-Step Deployment

### PART 1: Prepare Your Code for Free Hosting

#### 1. Optimize for Cold Starts

The free tier "sleeps" after 15 minutes of inactivity. Add this to handle cold starts gracefully:

**Update `backend/app.py`** - Add a health check endpoint:
```python
@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint to wake up the service"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'service': 'Debug Marathon Platform'
    }), 200
```

#### 2. Create `render.yaml` (Optional but Recommended)

Create this file in your project root:
```yaml
services:
  - type: web
    name: debug-marathon
    env: python
    region: oregon
    plan: free
    buildCommand: "pip install -r backend/requirements.txt"
    startCommand: "gunicorn --worker-class eventlet -w 1 --threads 2 --chdir backend app:app --bind 0.0.0.0:$PORT --timeout 120"
    healthCheckPath: /health
    envVars:
      - key: PYTHON_VERSION
        value: 3.11.0
      - key: SECRET_KEY
        generateValue: true
      - key: FLASK_ENV
        value: production
      - key: FLASK_DEBUG
        value: false
```

#### 3. Update `requirements.txt`

Ensure your `backend/requirements.txt` includes these for free tier optimization:
```txt
Flask==3.0.0
Flask-SocketIO==5.3.5
Flask-CORS==4.0.0
python-socketio==5.10.0
python-engineio==4.8.0
eventlet==0.33.3
gunicorn==21.2.0
psycopg2-binary==2.9.9
python-dotenv==1.0.0
PyJWT==2.8.0
requests==2.31.0
supabase==2.3.0
postgrest==0.13.0
```

#### 4. Push to GitHub

```bash
git add .
git commit -m "Optimized for free Render deployment"
git push origin main
```

---

### PART 2: Set Up Supabase Database (FREE)

#### Step 1: Create Supabase Project

1. Go to [https://supabase.com](https://supabase.com)
2. Click **"Start your project"** or **"New Project"**
3. Fill in:
   - **Name**: `debug-marathon` (or your choice)
   - **Database Password**: Create a strong password (save it!)
   - **Region**: Choose closest to your users
   - **Pricing Plan**: **Free** (500MB database, unlimited API requests)
4. Click **"Create new project"** (takes 1-2 minutes)

#### Step 2: Set Up Database Schema

1. Once project is ready, go to **SQL Editor** (left sidebar)
2. Click **"New query"**
3. Open your local `backend/database_setup.sql` file
4. Copy all SQL content and paste into Supabase SQL Editor
5. Click **"Run"** or press `Ctrl+Enter`
6. You should see: "Success. No rows returned"

#### Step 3: Enable Connection Pooling (Important!)

1. Go to **Settings** → **Database**
2. Scroll to **"Connection Pooling"**
3. Copy the **Connection String** (Transaction mode):
   ```
   postgresql://postgres.[PROJECT-ID]:[PASSWORD]@aws-0-[region].pooler.supabase.com:6543/postgres
   ```
4. **Save this** - you'll need it for Render!

#### Step 4: Get API Credentials

1. Go to **Settings** → **API**
2. Copy these values:
   - **Project URL** (e.g., `https://xxxxx.supabase.co`)
   - **Project API keys** → **anon** **public** key
3. **Save these** - needed for environment variables!

#### Step 5: Optional - Enable Real-time (For Live Features)

1. Go to **Database** → **Replication**
2. Enable replication for these tables:
   - `participants`
   - `contest_submissions`
   - `proctoring_violations`
3. This enables live leaderboard updates!

---

### PART 3: Deploy to Render (FREE)

#### Step 1: Create Render Account & Connect GitHub

1. Go to [https://render.com](https://render.com)
2. Sign up using your **GitHub account** (easiest method)
3. Authorize Render to access your repositories

#### Step 2: Create New Web Service

1. Click **"New +"** → **"Web Service"**
2. Connect your GitHub repository:
   - If not visible, click **"Configure account"** → select repository
3. Select your `Giltch-main` repository
4. Click **"Connect"**

#### Step 3: Configure Service Settings

Fill in these settings:

**Basic Settings:**
- **Name**: `debug-marathon` (or your choice - this becomes your URL)
- **Region**: Choose closest to your users (Oregon is good default)
- **Branch**: `main` (or your default branch)
- **Root Directory**: Leave blank
- **Environment**: `Python 3`
- **Build Command**:
  ```bash
  pip install -r backend/requirements.txt
  ```
- **Start Command**:
  ```bash
  gunicorn --worker-class eventlet -w 1 --threads 2 --chdir backend app:app --bind 0.0.0.0:$PORT --timeout 120
  ```

**Instance Type:**
- Select **"Free"** plan
  - 512 MB RAM
  - Shared CPU
  - 750 hours/month
  - Sleeps after 15 min inactivity

#### Step 4: Add Environment Variables

Click **"Advanced"** → **"Add Environment Variable"**

Add these one by one:

| Key | Value | Notes |
|-----|-------|-------|
| `SECRET_KEY` | `your-secret-key-32-characters-long!` | Generate random 32-char string |
| `FLASK_ENV` | `production` | Don't change |
| `FLASK_DEBUG` | `False` | Must be False |
| `DATABASE_URL` | `postgresql://postgres.[ID]...` | From Supabase Step 3 |
| `SUPABASE_URL` | `https://xxxxx.supabase.co` | From Supabase Step 4 |
| `SUPABASE_KEY` | `eyJhbGc...` | Anon public key from Supabase |
| `PORT` | `10000` | Default Render port |

**To generate a secure SECRET_KEY:**
```bash
python -c "import secrets; print(secrets.token_hex(32))"
```

#### Step 5: Deploy!

1. Click **"Create Web Service"**
2. Render will:
   - Clone your repository
   - Install dependencies
   - Start your application
   - Assign a free URL: `https://debug-marathon.onrender.com`
3. Wait 3-5 minutes for first deployment
4. Monitor logs in real-time on Render dashboard

#### Step 6: Test Your Deployment

1. Once status shows **"Live"**, click your service URL
2. You should see your landing page!
3. Test these endpoints:
   - `/health` - Should return `{"status": "healthy"}`
   - `/` - Landing page
   - `/admin.html` - Admin login

---

## 🎯 Post-Deployment Configuration

### 1. Update Frontend URLs

Your frontend needs to know the backend URL. Update these files:

**In `frontend/js/api.js`**, find and update:
```javascript
const API_BASE_URL = 'https://debug-marathon.onrender.com';
```

**In `frontend/js/main.js`**, update WebSocket connection:
```javascript
const socket = io('https://debug-marathon.onrender.com');
```

### 2. Configure CORS

The backend should already have CORS configured, but verify in `backend/app.py`:
```python
CORS(app, resources={
    r"/*": {
        "origins": "*",  # For free tier, allow all origins
        "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        "allow_headers": ["Content-Type", "Authorization"]
    }
})
```

### 3. Seed Initial Data

After deployment, you need to add admin user and sample data:

**Option A: Using Supabase SQL Editor**
1. Go to Supabase SQL Editor
2. Run this to create admin user:
```sql
INSERT INTO leaders (username, password_hash, full_name, email, created_at)
VALUES (
  'admin',
  'scrypt:32768:8:1$...',  -- Use bcrypt/scrypt hash
  'Admin User',
  'admin@debugmarathon.com',
  NOW()
);
```

**Option B: Using Python Script** (if you have database access):
```bash
# Locally run
python backend/seed_data.py
```

---

## ⚡ Handling Free Tier Limitations

### Cold Start Prevention

The free tier sleeps after 15 minutes. Here are strategies:

#### Strategy 1: Use a Keep-Alive Service (Free!)

Use **UptimeRobot** (free):
1. Sign up at [uptimerobot.com](https://uptimerobot.com)
2. Add new monitor:
   - **Monitor Type**: HTTP(s)
   - **URL**: `https://your-app.onrender.com/health`
   - **Monitoring Interval**: 5 minutes
3. This pings your app every 5 minutes, keeping it awake!

**Caveat:** You get 750 hours/month free (31 days = 744 hours), so this keeps you online 24/7!

#### Strategy 2: Wake-Up Page

Add a "Wake Up" button on your landing page:
```javascript
// In frontend/js/main.js
async function wakeUpServer() {
    const wakeBtn = document.getElementById('wake-btn');
    wakeBtn.textContent = 'Waking up server...';
    
    try {
        await fetch('https://your-app.onrender.com/health');
        setTimeout(() => {
            wakeBtn.textContent = 'Server Ready!';
            setTimeout(() => location.reload(), 1000);
        }, 30000); // Wait 30 seconds for cold start
    } catch (error) {
        wakeBtn.textContent = 'Try again';
    }
}
```

#### Strategy 3: Schedule Contests (Best for Free Tier!)

Since you know contest times:
1. Wake up the server 5 minutes before contest
2. Server stays active during contest
3. Let it sleep between contests
4. This optimizes your 750 hour budget!

---

## 📊 Free Tier Capacity Analysis

### What You Get FREE:

| Resource | Limit | Your Needs (350 users) | Status |
|----------|-------|------------------------|--------|
| **RAM** | 512 MB | 300-400 MB needed | ⚠️ Tight but workable |
| **Database** | 500 MB | ~50 MB for 350 users | ✅ Plenty |
| **Bandwidth** | 100 GB/month | ~20-30 GB/month | ✅ Good |
| **Build Minutes** | Unlimited | - | ✅ Perfect |
| **Concurrent Connections** | ~100-150 | 350 needed | ⚠️ May need pooling |

### Realistic User Capacity on Free Tier:

- **Optimal**: 50-100 concurrent users
- **Maximum**: 150-200 users (with optimization)
- **Your Target (350)**: Will need paid tier OR split traffic

### For 350 Users - FREE Solutions:

#### Option A: Use Multiple Free Instances
- Deploy 3 free Render services
- Use a free load balancer (Cloudflare)
- Each handles ~100 users
- Total: 300+ users capacity FREE!

#### Option B: Upgrade During Contest Only
- Keep free tier for testing/development
- Upgrade to Starter ($7/month) only during contest month
- Downgrade after contest
- Cost: $7 for contest month, $0 other months

---

## 🔒 Security Checklist for Free Tier

- [ ] `FLASK_DEBUG=False` set in environment
- [ ] Strong `SECRET_KEY` (32+ characters)
- [ ] Database password is strong
- [ ] Supabase Row Level Security (RLS) enabled
- [ ] Admin credentials are secure
- [ ] HTTPS enabled (automatic on Render)
- [ ] Environment variables not committed to Git
- [ ] CORS restricted to your domain (in production)

---

## 📈 Monitoring Your Free App

### Render Dashboard
1. Go to your service in Render
2. Check:
   - **Metrics**: CPU, Memory usage
   - **Logs**: Real-time application logs
   - **Events**: Deployments, crashes
   - **Health**: Uptime status

### Supabase Dashboard
1. Go to your project in Supabase
2. Check:
   - **Database**: Storage used (500MB limit)
   - **API**: Request count
   - **Auth**: Active users
   - **Logs**: Database queries

### Set Up Alerts (Free!)
- **Render**: Email notifications for crashes
- **Supabase**: Email alerts for storage limits
- **UptimeRobot**: Down alert notifications

---

## 🐛 Common Issues & Solutions

### Issue 1: Cold Start Delays
**Symptom**: First request takes 30-60 seconds
**Solution**: Use UptimeRobot to keep alive (see above)

### Issue 2: Memory Errors
**Symptom**: App crashes with "out of memory"
**Solutions:**
- Reduce Gunicorn workers: `-w 1` (already set)
- Enable SQLite fallback for caching
- Implement database connection pooling

### Issue 3: WebSocket Disconnections
**Symptom**: Proctoring features fail
**Solutions:**
- Use `eventlet` worker class (already configured)
- Implement reconnection logic in frontend
- Add heartbeat pings every 25 seconds

### Issue 4: 500MB Database Limit
**Symptom**: Database full error
**Solutions:**
- Regular cleanup of old contests
- Archive completed contests
- Delete test data before production

### Issue 5: Build Fails
**Symptom**: Deployment fails with errors
**Solutions:**
- Check `requirements.txt` for version conflicts
- Ensure Python version compatibility
- Check logs in Render dashboard

---

## 🎯 Pre-Contest Checklist

**24 Hours Before:**
- [ ] Wake up Render service (or ensure UptimeRobot is running)
- [ ] Test admin login
- [ ] Test participant registration
- [ ] Verify database connectivity
- [ ] Check proctoring features

**1 Hour Before:**
- [ ] Monitor Render metrics (should be green)
- [ ] Test WebSocket connection
- [ ] Ensure all contest questions are loaded
- [ ] Backup database (Supabase auto-backups)

**During Contest:**
- [ ] Monitor Render dashboard for errors
- [ ] Watch memory usage (stay under 80%)
- [ ] Keep Render logs open for real-time monitoring

**After Contest:**
- [ ] Export results immediately
- [ ] Archive contest data
- [ ] Review logs for any issues

---

## 🚀 Upgrade Path (When You Need More)

### When to Upgrade:

1. **Consistent 200+ concurrent users**
2. **Need zero cold starts**
3. **Want 24/7 uptime guaranteed**
4. **Need more than 512MB RAM**

### Affordable Upgrade Options:

| Plan | Cost | Users | Features |
|------|------|-------|----------|
| **Render Starter** | $7/month | 200-400 | No cold starts, 512MB RAM |
| **Render Standard** | $25/month | 500-1000 | 2GB RAM, priority support |
| **Supabase Pro** | $25/month | Unlimited | 8GB storage, daily backups |

### Hybrid Approach (Smart & Cheap):
- Keep **Supabase Free** (500MB is enough)
- Upgrade **Render to Starter** ($7) only during contest months
- Total annual cost: ~$50-80 (instead of $300-400)

---

## 📚 Additional Resources

### Documentation:
- [Render Free Tier Docs](https://render.com/docs/free)
- [Supabase Free Tier](https://supabase.com/pricing)
- [Flask-SocketIO Deployment](https://flask-socketio.readthedocs.io/en/latest/deployment.html)

### Tutorials:
- Render + Flask: [Official Guide](https://render.com/docs/deploy-flask)
- Supabase + Python: [Quick Start](https://supabase.com/docs/guides/getting-started/quickstarts/python)

### Support:
- Render Community: [Discord](https://render.com/discord)
- Supabase Community: [Discord](https://discord.supabase.com)

---

## ✅ Summary

**You can run your Debug Marathon Platform 100% FREE with:**
- ✅ Render Free (750 hours/month, WebSocket support)
- ✅ Supabase Free (500MB database, unlimited API)
- ✅ UptimeRobot Free (keep-alive monitoring)
- ✅ GitHub Free (version control, auto-deploy)

**Best for:**
- Small contests (50-150 users)
- Testing and development
- Monthly/occasional events
- Educational use

**Limitations:**
- 15-min cold starts (solvable with keep-alive)
- 512MB RAM limit
- 100-150 concurrent user capacity

**Next Steps:**
1. Follow this guide step-by-step
2. Deploy to Render + Supabase
3. Test with 10-20 users first
4. Scale to paid tier if needed for 350 users

**Questions?** The setup takes about 30-45 minutes total. Everything is free, no credit card required initially!

---

**Happy Free Hosting! 🎉**
