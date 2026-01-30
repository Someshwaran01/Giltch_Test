# 🚀 Deployment Guide - Debug Marathon Platform

## 🎯 For 350+ Concurrent Users - Production Deployment

**Your app needs production-grade hosting for 350 users with real-time proctoring.**

### ⭐ Top Recommendations (Ranked by Best Fit):

1. **DigitalOcean App Platform** - BEST CHOICE ✅
   - 💰 Cost: $12-25/month (Professional tier)
   - ⚡ Auto-scaling for traffic spikes
   - 🔌 Native WebSocket support (critical for proctoring)
   - 📊 Built-in monitoring & alerts
   - 🚀 Easy deployment from GitHub
   - ✅ Free SSL, CDN included

2. **AWS Elastic Beanstalk** - ENTERPRISE CHOICE 🏢
   - 💰 Cost: $20-40/month (t3.medium instance)
   - 🎯 Best for scaling beyond 350 users
   - 💪 Most powerful & flexible
   - 📈 Auto-scaling, load balancing
   - 🔧 More complex setup

3. **Railway Pro** - MODERN & SIMPLE 🚄
   - 💰 Cost: $20-30/month
   - ⚡ Automatic deployments
   - 🎨 Great developer experience
   - ⚠️ Less established than AWS/DO

4. **Render Plus** - SIMPLE BUT PAID 💳
   - 💰 Cost: $19+/month
   - ✅ Easy setup
   - ⚠️ Free tier NOT suitable for 350 users

---

## 🏆 OPTION 1: DigitalOcean App Platform (RECOMMENDED)

### Why DigitalOcean for Your Use Case:
- ✅ Handles 350+ concurrent WebSocket connections reliably
- ✅ Auto-scales during contest peaks
- ✅ Simple deployment (Git push → Live)
- ✅ Professional tier: $12/month (Basic) or $25/month (Professional)
- ✅ 99.99% uptime SLA
- ✅ Built-in metrics & logging

### Deployment Steps:

#### Step 1: Prepare Your Code

1. **Create a GitHub repository**
   ```bash
   git init
   git add .
   git commit -m "Production deployment"
   git remote add origin https://github.com/YOUR-USERNAME/YOUR-REPO.git
   git push -u origin main
   ```

#### Step 2: Set Up Database (Supabase)

1. Go to [https://supabase.com](https://supabase.com) (Free tier supports 500+ connections)
2. Create a new project (choose region closest to your users)
3. Go to SQL Editor → New Query → Paste and run `backend/database_setup.sql`
4. Settings → API → Copy:
   - **Project URL** (SUPABASE_URL)
   - **Anon Public Key** (SUPABASE_KEY)
5. Enable connection pooling: Settings → Database → Connection Pooling → Enable

#### Step 3: Deploy to DigitalOcean

1. **Sign up at [DigitalOcean](https://cloud.digitalocean.com)**
   - Get $200 credit for 60 days (new users)

2. **Create App**
   - Click **"Create"** → **"Apps"**
   - Connect your GitHub repository
   - Select your repo and branch (main)

3. **Configure App Settings**
   - **Name**: debug-marathon
   - **Region**: Choose closest to your users
   - **Plan**: 
     - For 350 users: **Professional Basic** ($12/month) or **Professional** ($25/month)
     - Scaling: Enable auto-scaling (1-3 instances)

4. **Build Settings**
   - **Build Command**: `pip install -r backend/requirements.txt`
   - **Run Command**: `gunicorn --worker-class eventlet -w 4 --threads 2 --chdir backend app:app --bind 0.0.0.0:8080 --timeout 120`
   - **HTTP Port**: 8080

5. **Environment Variables** (Add these in App Settings):
   ```
   SECRET_KEY=<generate-strong-random-key-32-chars>
   FLASK_ENV=production
   FLASK_DEBUG=False
   SUPABASE_URL=<your-supabase-url>
   SUPABASE_KEY=<your-supabase-key>
   FRONTEND_URL=https://your-app.ondigitalocean.app
   WORKERS=4
   ```

6. **Deploy**
   - Click **"Create Resources"**
   - Wait 5-10 minutes
   - Your app will be live at: `https://your-app.ondigitalocean.app`

7. **Enable Auto-Scaling** (Important for 350 users)
   - Go to App Settings → Resources
   - Enable horizontal scaling: Min 1, Max 3 instances
   - Set trigger: CPU > 70% or Memory > 80%

#### Step 4: Performance Optimization

1. **Enable CDN** (in DigitalOcean)
   - Settings → Domains → Enable CDN
   - Caches static files (CSS, JS, images)

2. **Database Connection Pooling** (in Supabase)
   - Already enabled in Step 2
   - Use pooled connection string if needed

3. **Monitor Performance**
   - DigitalOcean → Insights → View metrics
   - Set alerts for high CPU/memory
   - Monitor response times

---

## 🏢 OPTION 2: AWS Elastic Beanstalk (For Larger Scale)

### Best for: 500+ users, enterprise requirements, complex scaling needs

### Prerequisites
1. AWS Account (Free tier available, but use t3.medium for production)
2. AWS CLI installed: [Download](https://aws.amazon.com/cli/)
3. EB CLI installed: `pip install awsebcli`

### Deployment Steps

1. **Configure AWS Credentials**
   ```bash
   aws configure
   # Enter your AWS Access Key ID and Secret Access Key
   ```

2. **Initialize Elastic Beanstalk**
   ```bash
   cd your-project-directory
   eb init -p python-3.11 debug-marathon --region us-east-1
   ```

3. **Create Environment**
   ```bash
   eb create production-env --instance-type t3.medium --envvars SECRET_KEY=your-key,FLASK_ENV=production,SUPABASE_URL=your-url,SUPABASE_KEY=your-key
   ```
1. **Push to GitHub** (if not done)
2. **Create DigitalOcean account** → Get $200 credit
3. **Create App** → Connect GitHub
4. **Choose Professional plan** ($25/month)
5. **Add environment variables** (see above)
6. **Deploy** → Wait 10 minutes
7. **Test with 350 users** → Monitor metrics
8. **Enable auto-scaling** if needed

Your production app will be ready in 15 minutes! 🎉

---

## 💡 Load Testing Before Go-Live

Before your actual contest with 350 users, test your deployment:

### Using Locust (Load Testing Tool)

1. Install Locust:
- Poor WebSocket support
- Limited resources
- Not designed for real-time apps

### ❌ Shared Hosting (cPanel, etc.)
- Can't handle WebSockets properly
- Limited Python support
- Not scalable

## 📊 Platform Comparison for 350 Users

| Platform | Cost/Month | Setup Difficulty | WebSocket Support | Auto-Scaling | Best For |
|----------|-----------|------------------|-------------------|--------------|----------|
| **DigitalOcean App Platform** | $12-25 | ⭐ Easy | ✅ Excellent | ✅ Yes | **RECOMMENDED** |
| **AWS Elastic Beanstalk** | $50-60 | ⭐⭐⭐ Complex | ✅ Excellent | ✅ Advanced | Enterprise/Scale |
| **Railway Pro** | $20-35 | ⭐ Easy | ✅ Good | ✅ Basic | Modern/Simple |
| **Render Plus** | $19-40 | ⭐ Easy | ✅ Good | ✅ Basic | Small-Medium |
| ~~Render Free~~ | Free | Easy | ⚠️ Limited | ❌ No | NOT for 350 users |
| ~~PythonAnywhere~~ | $5-12 | Easy | ❌ Poor | ❌ No | NOT for real-time |

---

## 🎯 Final Recommendation for Your Contest

**For 350 concurrent users with real-time proctoring:**

### 🥇 Best Choice: DigitalOcean App Platform
- **Plan**: Professional ($25/month)
- **Workers**: 4 gunicorn workers
- **Instances**: 2-3 with auto-scaling
- **Database**: Supabase (free tier sufficient)
- **Total Cost**: ~$25-30/month

### Configuration Settings:
```bash
# gunicorn command (optimized for 350 users)
gunicorn --worker-class eventlet -w 4 --threads 2 --chdir backend app:app --bind 0.0.0.0:8080 --timeout 120 --max-requests 1000 --max-requests-jitter 100
```

This setup can handle:
- ✅ 350+ concurrent WebSocket connections
- ✅ Real-time proctoring for all participants
- ✅ Traffic spikes during contest start
- ✅ 99.9% uptime
- ✅ Auto-recovery from failures

---

## 🚀 Quick Start: Deploy to DigitalOcean NOW

---

## Alternative: Deploy to Railway

### Step 1: Prepare Code (same as above)

### Step 2: Deploy to Railway

1. Go to [https://railway.app](https://railway.app)
2. Click **"Start a New Project"**
3. Choose **"Deploy from GitHub repo"**
4. Select your repository
5. Railway auto-detects Python and deploys
6. Add environment variables in Settings
7. Get your deployment URL

---

## Alternative: Deploy to Heroku

### Step 1: Install Heroku CLI
```bash
# Download from: https://devcenter.heroku.com/articles/heroku-cli
```

### Step 2: Deploy
```bash
heroku login
heroku create your-app-name
git push heroku main
```

### Step 3: Set Environment Variables
```bash
heroku config:set SECRET_KEY=your-secret-key
heroku config:set SUPABASE_URL=your-supabase-url
heroku config:set SUPABASE_KEY=your-supabase-key
heroku config:set FLASK_ENV=production
heroku config:set FLASK_DEBUG=False
```

### Step 4: Open Your App
```bash
heroku open
```

---

## Alternative: Deploy to PythonAnywhere

### Step 1: Sign Up
1. Go to [https://www.pythonanywhere.com](https://www.pythonanywhere.com)
2. Create a free account

### Step 2: Upload Your Code
1. Go to **Files** tab
2. Upload your project or clone from GitHub
3. Open a Bash console

### Step 3: Install Dependencies
```bash
cd your-project
pip install --user -r backend/requirements.txt
```

### Step 4: Configure Web App
1. Go to **Web** tab
2. Click **"Add a new web app"**
3. Choose **Manual Configuration** → **Python 3.10**
4. Set:
   - **Source code**: `/home/yourusername/your-project`
   - **Working directory**: `/home/yourusername/your-project/backend`
   - **WSGI file**: Edit to point to your app

### Step 5: Edit WSGI Configuration
```python
import sys
import os

# Add your project directory
project_home = '/home/yourusername/your-project'
if project_home not in sys.path:
    sys.path = [project_home] + sys.path

# Load environment variables
os.chdir(project_home)
from dotenv import load_dotenv
load_dotenv(os.path.join(project_home, '.env'))

# Import your app
from backend.app import create_app
application = create_app()
```

### Step 6: Set Environment Variables
1. Go Summary - Quick Decision Guide

**For 350 concurrent users with real-time proctoring:**

| Your Priority | Choose | Monthly Cost |
|--------------|--------|--------------|
| **Best Balance** (Easy + Performance) | DigitalOcean App Platform | $25 |
| **Maximum Performance** (Enterprise) | AWS Elastic Beanstalk | $50-60 |
| **Simplest Setup** (Modern) | Railway Pro | $20-35 |
| **Future Scale** (500+ users) | AWS with Auto-Scaling | $60-100 |

### 🎯 Our Recommendation: Start with DigitalOcean

1. Easy to set up (15 minutes)
2. Perfect for 350 users
3. Professional features
4. Easy to scale later
5. Great monitoring tools
6. $25/month is affordable

### 📈 Scaling Path

- **Start**: DigitalOcean Professional ($25/month) - 350 users
- **Grow**: Add instances or upgrade plan - 500-1000 users
- **Scale**: Migrate to AWS/Azure - 1000+ users

You can always start with DigitalOcean and migrate to AWS later if you grow beyond 1000 users!

---

## 🎉 Ready to Deploy?

**Follow the DigitalOcean steps above** (Option 1) - your app will be live in 15 minutes!

Need help? The deployment process is straightforward, but if you get stuck:
1. Check DigitalOcean docs: https://docs.digitalocean.com/products/app-platform/
2. Check Supabase docs: https://supabase.com/docs
3. Review your logs in DigitalOcean dashboard

- [ ] Change `SECRET_KEY` to a strong random value
- [ ] Set `FLASK_DEBUG=False`
- [ ] Set `FLASK_ENV=production`
- [ ] Use environment variables for all secrets
- [ ] Enable HTTPS (automatic on Render/Railway/Heroku)
- [ ] Set up Supabase Row Level Security (RLS)
- [ ] Configure CORS properly
- [ ] Back up your database regularly

---

## 📊 Post-Deployment

### Test Your Deployment
1. Visit your deployed URL
2. Test admin login
3. Create a test contest
4. Test participant features
5. Verify proctoring works
6. Check leaderboard updates

### Monitor Your Application
- Check logs regularly
- Set up error tracking (Sentry, LogRocket)
- Monitor database performance
- Set up uptime monitoring

### Custom Domain (Optional)
Most platforms allow you to add a custom domain:
- Render: Settings → Custom Domain
- Railway: Settings → Domains
- Heroku: Settings → Domains

---

## 🆘 Troubleshooting

### App Not Starting
- Check logs for errors
- Verify all environment variables are set
- Ensure database is accessible
- Check Procfile syntax

### Database Connection Issues
- Verify Supabase credentials
- Check if IP is whitelisted
- Confirm database schema is set up

### Static Files Not Loading
- Verify static folder path in app.py
- Check CORS configuration
- Clear browser cache

### WebSocket Issues (Proctoring)
- Ensure platform supports WebSockets
- Check eventlet is installed
- Verify socketio configuration

---

## 📞 Need Help?

Choose the platform that fits your needs:
- **Render**: Best for free tier with database
- **Railway**: Best for modern apps with good DX
- **Heroku**: Best for classic, well-documented deployment
- **PythonAnywhere**: Best for Python-specific hosting

All options work great with your Flask + SocketIO app!
