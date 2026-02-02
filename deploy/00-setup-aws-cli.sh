#!/bin/bash

#############################################################
# AWS CLI Setup Script for First-Time Users
# This script helps you install and configure AWS CLI
#############################################################

set -e  # Exit on any error

echo "=========================================="
echo "AWS CLI Setup - First Time User Guide"
echo "=========================================="
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if AWS CLI is installed
echo -e "${YELLOW}Step 1: Checking AWS CLI installation...${NC}"
if command -v aws &> /dev/null; then
    echo -e "${GREEN}✓ AWS CLI is already installed!${NC}"
    aws --version
else
    echo -e "${YELLOW}AWS CLI not found. Installing...${NC}"
    
    # Install AWS CLI v2
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        echo "Installing AWS CLI for Linux..."
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
        unzip -q /tmp/awscliv2.zip -d /tmp
        sudo /tmp/aws/install
        rm -rf /tmp/aws /tmp/awscliv2.zip
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        echo "Installing AWS CLI for macOS..."
        curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "/tmp/AWSCLIV2.pkg"
        sudo installer -pkg /tmp/AWSCLIV2.pkg -target /
        rm /tmp/AWSCLIV2.pkg
    else
        echo -e "${RED}Unsupported OS. Please install AWS CLI manually from:${NC}"
        echo "https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
        exit 1
    fi
    
    echo -e "${GREEN}✓ AWS CLI installed successfully!${NC}"
    aws --version
fi

echo ""
echo "=========================================="
echo -e "${YELLOW}Step 2: Create AWS Account (if you haven't)${NC}"
echo "=========================================="
echo ""
echo "1. Go to: https://aws.amazon.com"
echo "2. Click 'Create an AWS Account'"
echo "3. Follow the signup process (requires credit card)"
echo "4. Free tier includes: 750 hours/month of Lightsail for first 3 months"
echo ""
read -p "Have you created an AWS account? (y/n): " account_created

if [[ $account_created != "y" ]]; then
    echo -e "${RED}Please create an AWS account first, then run this script again.${NC}"
    exit 1
fi

echo ""
echo "=========================================="
echo -e "${YELLOW}Step 3: Create IAM User with Access Keys${NC}"
echo "=========================================="
echo ""
echo "Follow these steps in AWS Console:"
echo ""
echo "1. Go to: https://console.aws.amazon.com/iam/"
echo "2. Click 'Users' in the left sidebar"
echo "3. Click 'Create user'"
echo "4. Username: marathon-deployer"
echo "5. Check: 'Provide user access to AWS Management Console' (optional)"
echo "6. Click 'Next'"
echo "7. Click 'Attach policies directly'"
echo "8. Search and select these policies:"
echo "   - AmazonLightsailFullAccess"
echo "   - AmazonEC2ReadOnlyAccess (optional, for viewing)"
echo "9. Click 'Next' → 'Create user'"
echo ""
echo "Then create access keys:"
echo "10. Click on the user you just created"
echo "11. Go to 'Security credentials' tab"
echo "12. Scroll to 'Access keys' section"
echo "13. Click 'Create access key'"
echo "14. Select: 'Command Line Interface (CLI)'"
echo "15. Check the confirmation box"
echo "16. Click 'Next' → 'Create access key'"
echo "17. COPY the 'Access key ID' and 'Secret access key'"
echo "    (You'll need these in the next step!)"
echo ""
read -p "Have you created the IAM user and access keys? (y/n): " iam_created

if [[ $iam_created != "y" ]]; then
    echo -e "${RED}Please create IAM user and access keys first, then run this script again.${NC}"
    exit 1
fi

echo ""
echo "=========================================="
echo -e "${YELLOW}Step 4: Configure AWS CLI${NC}"
echo "=========================================="
echo ""
echo "You'll now be asked to enter your AWS credentials."
echo "These will be stored securely on your computer at: ~/.aws/credentials"
echo ""

# Run AWS configure
aws configure

echo ""
echo "=========================================="
echo -e "${GREEN}✓ AWS CLI Configuration Complete!${NC}"
echo "=========================================="
echo ""

# Test the configuration
echo -e "${YELLOW}Testing AWS CLI configuration...${NC}"
if aws lightsail get-regions --output table &> /dev/null; then
    echo -e "${GREEN}✓ AWS CLI is working correctly!${NC}"
    echo ""
    echo "Available Lightsail regions:"
    aws lightsail get-regions --query 'regions[].name' --output table
else
    echo -e "${RED}✗ AWS CLI test failed. Please check your credentials.${NC}"
    exit 1
fi

echo ""
echo "=========================================="
echo -e "${GREEN}Setup Complete! You're ready to deploy.${NC}"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Run: ./01-deploy-lightsail.sh"
echo "2. Wait 5-10 minutes for deployment to complete"
echo "3. Test your application!"
echo ""
