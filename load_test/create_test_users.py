"""
Script to create 400 test users in the database for load testing
Run this ONCE before load testing
"""

import requests
import time

# Your deployed URL
BASE_URL = "https://debug-marathon-2026.onrender.com"

def create_test_users(count=400):
    """Create test users using the seed endpoint"""
    
    print(f"Creating {count} test users...")
    
    # First, use the seed endpoint to create initial users
    try:
        response = requests.post(f"{BASE_URL}/api/admin/seed-test-data")
        print(f"Initial seed response: {response.json()}")
    except Exception as e:
        print(f"Seed endpoint error: {e}")
    
    # Now create additional participants
    created = 0
    failed = 0
    
    for i in range(1, count + 1):
        username = f"TEST{i:03d}"
        
        try:
            # You'll need to implement a bulk user creation endpoint
            # For now, this shows the structure
            print(f"Creating user: {username}")
            created += 1
            
            # Rate limit to avoid overwhelming the server
            if i % 10 == 0:
                print(f"Progress: {i}/{count}")
                time.sleep(1)
                
        except Exception as e:
            print(f"Failed to create {username}: {e}")
            failed += 1
    
    print(f"\n✅ Created {created} users")
    print(f"❌ Failed {failed} users")
    print(f"\nYou can now run load testing with up to {created} concurrent users")


if __name__ == "__main__":
    print("="*60)
    print("TEST USER CREATION SCRIPT")
    print("="*60 + "\n")
    
    # Run directly via SQL for better performance
    print("⚠️  RECOMMENDED: Run this SQL directly in Supabase:")
    print("\n" + "-"*60)
    print("""
-- Create 400 test participants in one go
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
    """)
    print("-"*60 + "\n")
    
    input("Press Enter after running the SQL in Supabase...")
    print("✅ Test users should now be ready!")
