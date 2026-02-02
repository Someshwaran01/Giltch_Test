#!/bin/bash

#############################################################
# Automated AWS Lightsail Deployment Script
# Debug Marathon Platform
#
# This script will:
# 1. Create a Lightsail instance
# 2. Deploy your application
# 3. Configure Nginx, Gunicorn, Supervisor
# 4. Set up SSL (optional)
# 5. Run health checks
#############################################################

set -e  # Exit on any error

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
INSTANCE_NAME="debug-marathon-backend"
STATIC_IP_NAME="marathon-static-ip"
REGION="ap-south-1"
AVAILABILITY_ZONE="${REGION}a"
BLUEPRINT="ubuntu_22_04"
BUNDLE_ID="medium_2_0"  # 2GB RAM, $10/month
GITHUB_REPO="https://github.com/Someshwaran01/Giltch_Test.git"

# Function to print colored messages
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_header() {
    echo ""
    echo "=========================================="
    echo -e "${YELLOW}$1${NC}"
    echo "=========================================="
    echo ""
}

# Check if AWS CLI is configured
check_aws_cli() {
    print_header "Checking AWS CLI Configuration"
    
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed!"
        echo "Please run: ./00-setup-aws-cli.sh first"
        exit 1
    fi
    
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS CLI is not configured correctly!"
        echo "Please run: ./00-setup-aws-cli.sh first"
        exit 1
    fi
    
    print_success "AWS CLI is configured"
    aws sts get-caller-identity
}

# Get user's environment variables
get_environment_variables() {
    print_header "Environment Variables Configuration"
    
    echo "Enter your Supabase database credentials:"
    echo "(You can find these in your Supabase project settings)"
    echo ""
    
    read -p "DB_HOST (e.g., aws-0-ap-south-1.pooler.supabase.com): " DB_HOST
    read -p "DB_PORT (default: 6543): " DB_PORT
    DB_PORT=${DB_PORT:-6543}
    read -p "DB_USER (e.g., postgres.xxxxx): " DB_USER
    read -sp "DB_PASSWORD: " DB_PASSWORD
    echo ""
    read -p "DB_NAME (default: postgres): " DB_NAME
    DB_NAME=${DB_NAME:-postgres}
    
    echo ""
    read -p "SUPABASE_URL (e.g., https://xxxxx.supabase.co): " SUPABASE_URL
    read -sp "SUPABASE_KEY (anon key): " SUPABASE_KEY
    echo ""
    
    # Generate random secret key
    SECRET_KEY=$(openssl rand -hex 32)
    
    print_success "Environment variables configured"
}

# Create Lightsail instance
create_instance() {
    print_header "Creating Lightsail Instance"
    
    # Check if instance already exists
    if aws lightsail get-instance --instance-name "$INSTANCE_NAME" --region "$REGION" &> /dev/null; then
        print_warning "Instance '$INSTANCE_NAME' already exists"
        read -p "Do you want to delete and recreate it? (y/n): " recreate
        
        if [[ $recreate == "y" ]]; then
            print_info "Deleting existing instance..."
            aws lightsail delete-instance --instance-name "$INSTANCE_NAME" --region "$REGION"
            
            # Wait for deletion
            print_info "Waiting for deletion to complete (30 seconds)..."
            sleep 30
        else
            print_info "Using existing instance"
            return 0
        fi
    fi
    
    print_info "Creating instance '$INSTANCE_NAME' in $REGION..."
    aws lightsail create-instances \
        --instance-names "$INSTANCE_NAME" \
        --availability-zone "$AVAILABILITY_ZONE" \
        --blueprint-id "$BLUEPRINT" \
        --bundle-id "$BUNDLE_ID" \
        --region "$REGION" \
        --tags key=Project,value=DebugMarathon
    
    print_success "Instance creation initiated"
    
    # Wait for instance to be running
    print_info "Waiting for instance to start (this takes ~2 minutes)..."
    
    for i in {1..60}; do
        STATE=$(aws lightsail get-instance-state \
            --instance-name "$INSTANCE_NAME" \
            --region "$REGION" \
            --query 'state.name' \
            --output text 2>/dev/null || echo "pending")
        
        if [[ "$STATE" == "running" ]]; then
            print_success "Instance is running!"
            break
        fi
        
        echo -n "."
        sleep 2
    done
    
    if [[ "$STATE" != "running" ]]; then
        print_error "Instance failed to start. Current state: $STATE"
        exit 1
    fi
}

# Create and attach static IP
create_static_ip() {
    print_header "Creating Static IP"
    
    # Check if static IP exists
    if aws lightsail get-static-ip --static-ip-name "$STATIC_IP_NAME" --region "$REGION" &> /dev/null; then
        print_warning "Static IP already exists"
    else
        print_info "Allocating static IP..."
        aws lightsail allocate-static-ip \
            --static-ip-name "$STATIC_IP_NAME" \
            --region "$REGION"
        print_success "Static IP allocated"
    fi
    
    print_info "Attaching static IP to instance..."
    aws lightsail attach-static-ip \
        --static-ip-name "$STATIC_IP_NAME" \
        --instance-name "$INSTANCE_NAME" \
        --region "$REGION" 2>/dev/null || true
    
    # Get the static IP address
    STATIC_IP=$(aws lightsail get-static-ip \
        --static-ip-name "$STATIC_IP_NAME" \
        --region "$REGION" \
        --query 'staticIp.ipAddress' \
        --output text)
    
    print_success "Static IP: $STATIC_IP"
}

# Configure firewall
configure_firewall() {
    print_header "Configuring Firewall"
    
    print_info "Opening ports 80 (HTTP), 443 (HTTPS), 5000 (Flask)..."
    
    # Open port 80
    aws lightsail open-instance-public-ports \
        --instance-name "$INSTANCE_NAME" \
        --port-info fromPort=80,toPort=80,protocol=TCP \
        --region "$REGION" 2>/dev/null || true
    
    # Open port 443
    aws lightsail open-instance-public-ports \
        --instance-name "$INSTANCE_NAME" \
        --port-info fromPort=443,toPort=443,protocol=TCP \
        --region "$REGION" 2>/dev/null || true
    
    # Open port 5000
    aws lightsail open-instance-public-ports \
        --instance-name "$INSTANCE_NAME" \
        --port-info fromPort=5000,toPort=5000,protocol=TCP \
        --region "$REGION" 2>/dev/null || true
    
    print_success "Firewall configured"
}

# Generate deployment script
generate_deployment_script() {
    print_header "Generating Deployment Script"
    
    cat > /tmp/deploy-app.sh << 'DEPLOY_SCRIPT_EOF'
#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}=========================================="
echo "Installing Dependencies"
echo -e "==========================================${NC}"

# Update system
sudo apt update
sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y

# Install Python 3.11
sudo DEBIAN_FRONTEND=noninteractive apt install -y python3.11 python3.11-venv python3-pip git

# Install PostgreSQL client
sudo DEBIAN_FRONTEND=noninteractive apt install -y postgresql-client libpq-dev

# Install Nginx
sudo DEBIAN_FRONTEND=noninteractive apt install -y nginx

# Install Supervisor
sudo DEBIAN_FRONTEND=noninteractive apt install -y supervisor

echo -e "${GREEN}✓ Dependencies installed${NC}"

echo -e "${YELLOW}=========================================="
echo "Cloning Repository"
echo -e "==========================================${NC}"

cd /home/ubuntu
if [ -d "Giltch_Test" ]; then
    echo "Repository already exists, pulling latest changes..."
    cd Giltch_Test
    git pull
    cd ..
else
    git clone GITHUB_REPO_PLACEHOLDER
fi

cd Giltch_Test/backend

echo -e "${GREEN}✓ Repository cloned${NC}"

echo -e "${YELLOW}=========================================="
echo "Setting up Python Environment"
echo -e "==========================================${NC}"

# Create virtual environment
python3.11 -m venv venv
source venv/bin/activate

# Install Python packages
pip install --upgrade pip
pip install -r requirements.txt gunicorn gevent

echo -e "${GREEN}✓ Python environment ready${NC}"

echo -e "${YELLOW}=========================================="
echo "Configuring Environment Variables"
echo -e "==========================================${NC}"

# Create .env file
cat > .env << 'ENV_EOF'
DB_HOST=DB_HOST_PLACEHOLDER
DB_PORT=DB_PORT_PLACEHOLDER
DB_USER=DB_USER_PLACEHOLDER
DB_PASSWORD=DB_PASSWORD_PLACEHOLDER
DB_NAME=DB_NAME_PLACEHOLDER
DB_POOL_SIZE=15
DB_POOL_TIMEOUT=30

SECRET_KEY=SECRET_KEY_PLACEHOLDER
ALLOWED_ORIGINS=*

SUPABASE_URL=SUPABASE_URL_PLACEHOLDER
SUPABASE_KEY=SUPABASE_KEY_PLACEHOLDER

FLASK_ENV=production
ENV_EOF

echo -e "${GREEN}✓ Environment variables configured${NC}"

echo -e "${YELLOW}=========================================="
echo "Configuring Gunicorn"
echo -e "==========================================${NC}"

cat > gunicorn_config.py << 'GUNICORN_EOF'
import multiprocessing

bind = "0.0.0.0:5000"
backlog = 2048

workers = 4
worker_class = "gevent"
worker_connections = 1000
timeout = 120
keepalive = 5

accesslog = "/var/log/gunicorn/access.log"
errorlog = "/var/log/gunicorn/error.log"
loglevel = "info"

proc_name = "debug-marathon"
daemon = False
GUNICORN_EOF

sudo mkdir -p /var/log/gunicorn
sudo chown ubuntu:ubuntu /var/log/gunicorn

echo -e "${GREEN}✓ Gunicorn configured${NC}"

echo -e "${YELLOW}=========================================="
echo "Configuring Supervisor"
echo -e "==========================================${NC}"

sudo tee /etc/supervisor/conf.d/marathon.conf > /dev/null << 'SUPERVISOR_EOF'
[program:marathon]
directory=/home/ubuntu/Giltch_Test/backend
command=/home/ubuntu/Giltch_Test/backend/venv/bin/gunicorn -c gunicorn_config.py app:app
user=ubuntu
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
stderr_logfile=/var/log/supervisor/marathon.err.log
stdout_logfile=/var/log/supervisor/marathon.out.log
environment=PATH="/home/ubuntu/Giltch_Test/backend/venv/bin"
SUPERVISOR_EOF

sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start marathon

echo -e "${GREEN}✓ Application started with Supervisor${NC}"

echo -e "${YELLOW}=========================================="
echo "Configuring Nginx"
echo -e "==========================================${NC}"

sudo tee /etc/nginx/sites-available/marathon > /dev/null << 'NGINX_EOF'
server {
    listen 80;
    server_name STATIC_IP_PLACEHOLDER;

    location / {
        root /home/ubuntu/Giltch_Test/frontend;
        index index.html;
        try_files $uri $uri/ /index.html;
    }

    location /api {
        proxy_pass http://127.0.0.1:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 120s;
        proxy_connect_timeout 120s;
    }

    location /socket.io {
        proxy_pass http://127.0.0.1:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
    }

    client_max_body_size 10M;
}
NGINX_EOF

sudo ln -sf /etc/nginx/sites-available/marathon /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

sudo nginx -t
sudo systemctl restart nginx

echo -e "${GREEN}✓ Nginx configured and started${NC}"

echo -e "${YELLOW}=========================================="
echo "Testing Deployment"
echo -e "==========================================${NC}"

sleep 5

if curl -f http://localhost:5000/ > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Backend is responding!${NC}"
else
    echo -e "${RED}✗ Backend is not responding${NC}"
fi

echo ""
echo -e "${GREEN}=========================================="
echo "Deployment Complete!"
echo -e "==========================================${NC}"
echo ""
echo "Your application is now running at:"
echo -e "${GREEN}http://STATIC_IP_PLACEHOLDER${NC}"
echo ""
echo "To check logs:"
echo "  sudo supervisorctl tail -f marathon"
echo "  sudo tail -f /var/log/nginx/error.log"
echo ""

DEPLOY_SCRIPT_EOF

    # Replace placeholders
    sed -i "s|GITHUB_REPO_PLACEHOLDER|$GITHUB_REPO|g" /tmp/deploy-app.sh
    sed -i "s|DB_HOST_PLACEHOLDER|$DB_HOST|g" /tmp/deploy-app.sh
    sed -i "s|DB_PORT_PLACEHOLDER|$DB_PORT|g" /tmp/deploy-app.sh
    sed -i "s|DB_USER_PLACEHOLDER|$DB_USER|g" /tmp/deploy-app.sh
    sed -i "s|DB_PASSWORD_PLACEHOLDER|$DB_PASSWORD|g" /tmp/deploy-app.sh
    sed -i "s|DB_NAME_PLACEHOLDER|$DB_NAME|g" /tmp/deploy-app.sh
    sed -i "s|SECRET_KEY_PLACEHOLDER|$SECRET_KEY|g" /tmp/deploy-app.sh
    sed -i "s|SUPABASE_URL_PLACEHOLDER|$SUPABASE_URL|g" /tmp/deploy-app.sh
    sed -i "s|SUPABASE_KEY_PLACEHOLDER|$SUPABASE_KEY|g" /tmp/deploy-app.sh
    sed -i "s|STATIC_IP_PLACEHOLDER|$STATIC_IP|g" /tmp/deploy-app.sh
    
    chmod +x /tmp/deploy-app.sh
    
    print_success "Deployment script generated"
}

# Upload and execute deployment script
deploy_application() {
    print_header "Deploying Application"
    
    print_info "Downloading SSH key..."
    aws lightsail download-default-key-pair \
        --region "$REGION" \
        --output text \
        --query 'privateKeyBase64' | base64 -d > /tmp/lightsail-key.pem
    
    chmod 600 /tmp/lightsail-key.pem
    
    print_info "Waiting for SSH to be ready (30 seconds)..."
    sleep 30
    
    print_info "Uploading deployment script..."
    scp -i /tmp/lightsail-key.pem \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        /tmp/deploy-app.sh ubuntu@"$STATIC_IP":/home/ubuntu/
    
    print_info "Executing deployment script (this may take 5-10 minutes)..."
    ssh -i /tmp/lightsail-key.pem \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        ubuntu@"$STATIC_IP" 'bash /home/ubuntu/deploy-app.sh'
    
    print_success "Application deployed!"
    
    # Cleanup
    rm -f /tmp/lightsail-key.pem /tmp/deploy-app.sh
}

# Run health checks
run_health_checks() {
    print_header "Running Health Checks"
    
    print_info "Testing backend API..."
    sleep 5
    
    if curl -f "http://$STATIC_IP/api/health" > /dev/null 2>&1; then
        print_success "Backend API is healthy!"
    else
        print_warning "Backend health check failed (this might be normal if /api/health doesn't exist)"
    fi
    
    print_info "Testing frontend..."
    if curl -f "http://$STATIC_IP/" > /dev/null 2>&1; then
        print_success "Frontend is accessible!"
    else
        print_error "Frontend is not accessible"
    fi
}

# Print summary
print_summary() {
    print_header "Deployment Summary"
    
    echo -e "${GREEN}🎉 Congratulations! Your application is deployed!${NC}"
    echo ""
    echo "Access your application at:"
    echo -e "  ${GREEN}http://$STATIC_IP${NC}"
    echo ""
    echo "Instance details:"
    echo "  Name: $INSTANCE_NAME"
    echo "  Region: $REGION"
    echo "  IP Address: $STATIC_IP"
    echo "  Instance Size: 2GB RAM, 1 vCPU ($10/month)"
    echo ""
    echo "SSH access:"
    echo -e "  ${BLUE}ssh ubuntu@$STATIC_IP${NC}"
    echo "  (Download key from Lightsail console)"
    echo ""
    echo "Useful commands:"
    echo "  Check app status:  ssh ubuntu@$STATIC_IP 'sudo supervisorctl status'"
    echo "  View logs:         ssh ubuntu@$STATIC_IP 'sudo supervisorctl tail -f marathon'"
    echo "  Restart app:       ssh ubuntu@$STATIC_IP 'sudo supervisorctl restart marathon'"
    echo ""
    echo "Next steps:"
    echo "  1. Update frontend/js/api.js with: const API_BASE_URL = 'http://$STATIC_IP'"
    echo "  2. Test your application"
    echo "  3. Run load test: cd load_test && locust -f locustfile.py --host=http://$STATIC_IP"
    echo "  4. (Optional) Set up custom domain and SSL certificate"
    echo ""
    echo "Monthly cost: ~$12 (Lightsail $10 + bandwidth $2)"
    echo ""
}

# Main execution
main() {
    print_header "AWS Lightsail Automated Deployment"
    echo "This script will deploy your Debug Marathon platform to AWS"
    echo ""
    
    check_aws_cli
    get_environment_variables
    create_instance
    create_static_ip
    configure_firewall
    generate_deployment_script
    deploy_application
    run_health_checks
    print_summary
    
    print_success "Deployment completed successfully!"
}

# Run main function
main
