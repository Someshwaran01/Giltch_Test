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
echo "5. Uncheck 'Provide user access to AWS Management Console' (we only need CLI access)"
echo "6. Click 'Next'"
echo "7. Click 'Attach policies directly'"
echo "8. In the search box, type 'Lightsail' (without quotes)"
echo "9. Select ONE of these policies (choose the first one you find):"
echo "   OPTION 1 (Best): ☑ AmazonLightsailFullAccess"
echo "   OPTION 2 (Alternative): ☑ PowerUserAccess (gives Lightsail + EC2 access)"
echo "   OPTION 3 (If above not found): ☑ AdministratorAccess (full access - use temporarily)"
echo ""
echo "   NOTE: If you can't find 'AmazonLightsailFullAccess':"
echo "   - Try typing just 'Lightsail' in search"
echo "   - Or use 'PowerUserAccess' (works for Lightsail)"
echo "   - You can change permissions later after deployment"
echo ""
echo "10. Click 'Next' → Review → 'Create user'"
echo ""
echo "Then create access keys:"
echo "11. Click on the user 'marathon-deployer' you just created"
echo "12. Go to 'Security credentials' tab"
echo "13. Scroll down to 'Access keys' section"
echo "14. Click 'Create access key' button"
echo "15. Select: 'Command Line Interface (CLI)'"
echo "16. Check the confirmation box (I understand...)"
echo "17. Click 'Next' → Add description (optional) → 'Create access key'"
echo "18. ⚠️ IMPORTANT: COPY both keys NOW (you won't see Secret Key again!):"
echo "    - Access key ID (starts with AKIA...)"
echo "    - Secret access key (long random string)"
echo "19. Click 'Download .csv file' (backup) or save them in a text file"
echo "20. Click 'Done'"
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
echo ""

# Test 1: Check if credentials are valid
echo "Test 1: Verifying AWS credentials..."
if aws sts get-caller-identity &> /dev/null; then
    echo -e "${GREEN}✓ Credentials are valid!${NC}"
    aws sts get-caller-identity
else
    echo -e "${RED}✗ Credentials are invalid!${NC}"
    echo ""
    echo "Possible issues:"
    echo "1. Access Key ID or Secret Access Key is incorrect"
    echo "2. Copy-paste error (check for extra spaces)"
    echo "3. Keys were deleted or disabled in AWS Console"
    echo ""
    echo "Solutions:"
    echo "1. Go to AWS Console → IAM → Users → marathon-deployer → Security credentials"
    echo "2. Delete the old access key"
    echo "3. Create a new access key"
    echo "4. Run this script again: ./00-setup-aws-cli.sh"
    echo ""
    echo "Or run manually: aws configure"
    exit 1
fi

echo ""
echo "Test 2: Checking Lightsail permissions..."
if aws lightsail get-regions --output table &> /dev/null; then
    echo -e "${GREEN}✓ Lightsail access is working!${NC}"
    echo ""
    echo "Available Lightsail regions:"
    aws lightsail get-regions --query 'regions[].name' --output table
else
    echo -e "${YELLOW}⚠ Lightsail permission test failed${NC}"
    echo ""
    echo "Your credentials work, but Lightsail access might be missing."
    echo ""
    echo "Possible causes:"
    echo "1. IAM user doesn't have Lightsail permissions"
    echo "2. AWS account is still being set up (can take a few minutes)"
    echo "3. Lightsail is not available in your region"
    echo ""
    echo "Solutions:"
    echo "1. Go to: https://console.aws.amazon.com/iam/"
    echo "2. Click: Users → marathon-deployer → Permissions"
    echo "3. Click: Add permissions → Attach policies directly"
    echo "4. Search for: AdministratorAccess (temporary - easiest)"
    echo "5. Click: Add permissions"
    echo "6. Wait 1-2 minutes, then run this script again"
    echo ""
    read -p "Do you want to continue anyway? (y/n): " continue_anyway
    if [[ $continue_anyway != "y" ]]; then
        exit 1
    fi
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
