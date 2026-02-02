# Load Testing Guide - Debug Marathon Platform

Test if your platform can handle **350 concurrent users**.

---

## 📋 Prerequisites

1. **Install Locust**
   ```bash
   cd load_test
   pip install -r requirements.txt
   ```

2. **Create Test Users**
   
   Run this SQL in your **Supabase SQL Editor**:
   
   ```sql
   -- Create 400 test participants for load testing
   INSERT INTO users (username, email, password_hash, full_name, role, status, college, department)
   SELECT 
       'TEST' || LPAD(generate_series::text, 3, '0'),
       'test' || generate_series || '@loadtest.com',
       'dummy_hash',
       'Load Test User ' || generate_series,
       'participant',
       'active',
       'Load Test College',
       'CSE'
   FROM generate_series(1, 400)
   ON CONFLICT (username) DO NOTHING;
   ```
   
   This creates users: `TEST001`, `TEST002`, ..., `TEST400`

---

## 🚀 Running Load Tests

### **Method 1: Web UI (Recommended for Beginners)**

1. **Start Locust**
   ```bash
   cd load_test
   locust -f locustfile.py --host=https://debug-marathon-2026.onrender.com
   ```

2. **Open Web Interface**
   - Go to: http://localhost:8089
   - Set **Number of users**: `350`
   - Set **Spawn rate**: `10` (10 users/second)
   - Click **Start Swarming**

3. **Monitor Results**
   - Watch real-time stats
   - Check response times
   - Identify failures

### **Method 2: Command Line (Headless)**

```bash
cd load_test

# Test with 350 users, spawn 10 per second, run for 5 minutes
locust -f locustfile.py \
  --host=https://debug-marathon-2026.onrender.com \
  --users 350 \
  --spawn-rate 10 \
  --run-time 5m \
  --headless \
  --html report.html
```

---

## 📊 What to Monitor

### **1. Response Times**
- ✅ **Good**: < 1 second average
- ⚠️ **Warning**: 1-3 seconds average
- ❌ **Bad**: > 3 seconds average

### **2. Failure Rate**
- ✅ **Good**: < 1% failures
- ⚠️ **Warning**: 1-5% failures
- ❌ **Bad**: > 5% failures

### **3. Requests per Second (RPS)**
- Target: Handle at least 100-200 RPS with 350 users

### **4. Server Resources (Check Render Dashboard)**
- CPU usage
- Memory usage
- Database connections

---

## 🎯 Test Scenarios

The load test simulates realistic user behavior:

### **Participant Users (85%)**
- Login with username
- Check contest state every 1-3 seconds
- View leaderboard
- Submit code solutions
- Get contest info

### **Admin Users (5%)**
- View dashboard stats
- Monitor participants
- Check proctoring status

### **Leaderboard Viewers (10%)**
- Only view public leaderboard
- Refresh rankings

---

## 📈 Expected Results

### **With Current Render Free Tier:**
- ⚠️ May struggle with 350 concurrent users
- Expect slower response times
- May need to upgrade to paid tier

### **With Render Standard Plan:**
- ✅ Should handle 350 users smoothly
- Response times < 1 second
- Stable performance

### **Database Performance:**
- ✅ Supabase should handle the load well
- Connection pooling helps (you set DB_POOL_SIZE=30)

---

## 🐛 Troubleshooting

### **Issue: "Connection refused" errors**
- **Cause**: Render service is sleeping (free tier)
- **Fix**: Make a request to wake it up first, wait 30 seconds, then start test

### **Issue: High failure rate on login**
- **Cause**: Not enough test users created
- **Fix**: Run the SQL to create 400 test users

### **Issue: Database connection errors**
- **Cause**: Connection pool exhausted
- **Fix**: Increase DB_POOL_SIZE in Render environment variables

### **Issue: Slow response times**
- **Cause**: Render free tier limitations
- **Fix**: Upgrade to paid tier or reduce concurrent users

---

## 📊 Sample Test Command

```bash
# Quick test: 50 users for 2 minutes
locust -f locustfile.py --host=https://debug-marathon-2026.onrender.com --users 50 --spawn-rate 5 --run-time 2m --headless

# Full test: 350 users for 10 minutes
locust -f locustfile.py --host=https://debug-marathon-2026.onrender.com --users 350 --spawn-rate 10 --run-time 10m --headless --html load_test_report.html

# Stress test: Ramp up to find breaking point
locust -f locustfile.py --host=https://debug-marathon-2026.onrender.com --users 500 --spawn-rate 20 --run-time 5m --headless
```

---

## ✅ Success Criteria

Your platform can handle 350 users if:

- ✅ **< 1% failure rate**
- ✅ **Average response time < 2 seconds**
- ✅ **95th percentile < 5 seconds**
- ✅ **No server crashes**
- ✅ **Stable CPU/Memory usage**

---

## 🎓 Tips for Better Performance

1. **Database Optimization**
   - Add indexes on frequently queried columns
   - Use database connection pooling (already configured)
   - Cache leaderboard data

2. **Backend Optimization**
   - Increase Render instance size if on free tier
   - Enable caching for static content
   - Optimize slow queries

3. **Frontend Optimization**
   - Use CDN for static assets
   - Minimize API calls
   - Implement client-side caching

---

## 📞 Need Help?

If you encounter issues:
1. Check Render logs for errors
2. Monitor database connection count in Supabase
3. Review the HTML report generated by Locust
4. Adjust spawn rate and user count

---

**Good luck with your load testing!** 🚀
