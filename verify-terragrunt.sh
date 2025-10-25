#!/bin/bash
# Terragrunt Integration Verification Script
# This script verifies that all Terragrunt files are in place

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "======================================"
echo "Terragrunt Integration Verification"
echo "======================================"
echo ""

# Function to check file exists
check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✓${NC} $1"
        return 0
    else
        echo -e "${RED}✗${NC} $1 - MISSING"
        return 1
    fi
}

# Function to check directory exists
check_dir() {
    if [ -d "$1" ]; then
        echo -e "${GREEN}✓${NC} $1"
        return 0
    else
        echo -e "${RED}✗${NC} $1 - MISSING"
        return 1
    fi
}

errors=0

echo "Checking Root Configuration Files..."
check_file "terragrunt.hcl" || ((errors++))
check_file ".env.example" || ((errors++))
check_file "deploy.sh" || ((errors++))
check_file ".gitignore" || ((errors++))
echo ""

echo "Checking Documentation Files..."
check_file "TERRAGRUNT_README.md" || ((errors++))
check_file "TERRAGRUNT_GUIDE.md" || ((errors++))
check_file "TERRAGRUNT_CHEATSHEET.md" || ((errors++))
check_file "TERRAGRUNT_ARCHITECTURE.md" || ((errors++))
check_file "DEPLOYMENT_CHECKLIST.md" || ((errors++))
check_file "TERRAGRUNT_INDEX.md" || ((errors++))
check_file "SUMMARY.md" || ((errors++))
echo ""

echo "Checking Environment Configuration..."
check_file "terraform/production/env.hcl" || ((errors++))
echo ""

echo "Checking Module Terragrunt Files..."
modules=(
    "terraform/production/s3-storage"
    "terraform/production/sqs-notifications"
    "terraform/production/iam"
    "terraform/production/secret-manager"
    "terraform/production/ec2-fast-api-jwt"
    "terraform/production/ec2-self-hosted"
    "terraform/production/roles"
    "terraform/production/policies"
)

for module in "${modules[@]}"; do
    check_file "$module/terragrunt.hcl" || ((errors++))
done
echo ""

echo "Checking Script Permissions..."
if [ -x "deploy.sh" ]; then
    echo -e "${GREEN}✓${NC} deploy.sh is executable"
else
    echo -e "${RED}✗${NC} deploy.sh is not executable"
    ((errors++))
fi
echo ""

echo "Checking for Terragrunt Installation..."
if command -v terragrunt &> /dev/null; then
    version=$(terragrunt --version | head -1)
    echo -e "${GREEN}✓${NC} Terragrunt installed: $version"
else
    echo -e "${YELLOW}⚠${NC} Terragrunt not installed (run: brew install terragrunt)"
fi
echo ""

echo "Checking for Terraform Installation..."
if command -v terraform &> /dev/null; then
    version=$(terraform --version | head -1)
    echo -e "${GREEN}✓${NC} Terraform installed: $version"
else
    echo -e "${YELLOW}⚠${NC} Terraform not installed"
fi
echo ""

echo "======================================"
if [ $errors -eq 0 ]; then
    echo -e "${GREEN}✓ All Terragrunt files verified!${NC}"
    echo ""
    echo "Next Steps:"
    echo "1. Install Terragrunt: brew install terragrunt"
    echo "2. Copy .env file: cp .env.example .env"
    echo "3. Edit .env with your values"
    echo "4. Initialize: ./deploy.sh init"
    echo "5. Deploy: ./deploy.sh apply"
    echo ""
    echo "Documentation: Start with TERRAGRUNT_INDEX.md"
    exit 0
else
    echo -e "${RED}✗ Found $errors error(s)${NC}"
    echo "Some files are missing. Please check the output above."
    exit 1
fi
