"""
Load Testing Script for Debug Marathon Platform
Tests 350 concurrent users performing realistic actions
"""

from locust import HttpUser, task, between
import random
import json

class ParticipantUser(HttpUser):
    """Simulates a participant user behavior"""
    wait_time = between(1, 3)  # Wait 1-3 seconds between tasks
    
    def on_start(self):
        """Called when a user starts - simulates login"""
        # Use test participants (create 350+ test users first)
        self.username = f"TEST{random.randint(1, 400):03d}"
        self.login()
    
    def login(self):
        """Simulate participant login"""
        response = self.client.post("/api/auth/participant/login", 
            json={"participant_id": self.username},
            name="Login"
        )
        
        if response.status_code == 200:
            data = response.json()
            self.token = data.get('token')
            self.participant = data.get('participant', {})
            print(f"✓ {self.username} logged in")
        else:
            print(f"✗ {self.username} login failed: {response.text}")
            self.token = None
    
    @task(3)
    def get_participant_state(self):
        """Most common action - check contest state"""
        if not self.token:
            return
        
        with self.client.post("/api/contest/participant-state",
            json={"contest_id": 1},
            headers={"Authorization": f"Bearer {self.token}"},
            name="Get Participant State",
            catch_response=True) as response:
            if response.status_code != 200:
                response.failure(f"Got {response.status_code}: {response.text[:100]}")
    
    @task(2)
    def view_leaderboard(self):
        """View leaderboard"""
        with self.client.get("/api/leaderboard/1",
            name="View Leaderboard",
            catch_response=True) as response:
            if response.status_code != 200:
                response.failure(f"Got {response.status_code}: {response.text[:100]}")
    
    @task(1)
    def get_contest_info(self):
        """Get contest information"""
        with self.client.get("/api/contest/1",
            name="Get Contest Info",
            catch_response=True) as response:
            if response.status_code != 200:
                response.failure(f"Got {response.status_code}: {response.text[:100]}")
    
    @task(1)
    def submit_code(self):
        """Simulate code submission"""
        if not self.token:
            return
        
        # Simulate submitting to a random question
        question_id = random.randint(1, 5)
        code = f"def solve():\n    return 'test solution'"
        
        with self.client.post("/api/contest/submit",
            json={
                "question_id": question_id,
                "code": code,
                "language": "python"
            },
            headers={"Authorization": f"Bearer {self.token}"},
            name="Submit Code",
            catch_response=True) as response:
            if response.status_code not in [200, 201]:
                response.failure(f"Got {response.status_code}: {response.text[:100]}")


class AdminUser(HttpUser):
    """Simulates admin user checking dashboard"""
    wait_time = between(5, 10)  # Admins check less frequently
    weight = 1  # Only 1/10 of users are admins
    
    @task
    def view_dashboard(self):
        """Admin views dashboard stats"""
        # Skip admin tasks - they need authentication
        pass
    
    @task
    def view_participants(self):
        """Admin views participants list"""
        # Skip admin tasks - they need authentication
        pass
    
    @task
    def view_proctoring(self):
        """Admin views proctoring status"""
        # Skip admin tasks - they need authentication
        pass


class LeaderboardViewerUser(HttpUser):
    """Simulates users only viewing leaderboard (public access)"""
    wait_time = between(2, 5)
    weight = 2  # Some users only watch leaderboard
    
    @task
    def view_leaderboard(self):
        """Constantly refresh leaderboard"""
        with self.client.get("/api/leaderboard/1",
            name="Public Leaderboard View",
            catch_response=True) as response:
            if response.status_code != 200:
                response.failure(f"Got {response.status_code}: {response.text[:100]}")
    
    @task
    def view_rankings(self):
        """View rankings"""
        # Rankings endpoint may not exist, use leaderboard instead
        with self.client.get("/api/leaderboard/1",
            name="View Rankings",
            catch_response=True) as response:
            if response.status_code != 200:
                response.failure(f"Got {response.status_code}: {response.text[:100]}")


# Configure user distribution
# 85% participants, 5% admins, 10% viewers
ParticipantUser.weight = 17
AdminUser.weight = 1
LeaderboardViewerUser.weight = 2
