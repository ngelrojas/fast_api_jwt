#!/bin/bash

# Script to fix Secrets Manager state issues
# This script will:
# 1. Check if secret exists in AWS
# 2. Remove it from Terraform state if it's there but corrupted
# 3. Re-import it properly
# 4. Verify the import was successful

set -e  # Exit on error

SECRET_NAME="fast-api-jwt-app"
RESOURCE_NAME="aws_secretsmanager_secret.fast_api_credentials"
VERSION_RESOURCE_NAME="aws_secretsmanager_secret_version.fast_api_credentials_version"

echo "=========================================="
echo "Secrets Manager State Fix Script"
echo "=========================================="
echo ""

# Check if we're in the right directory
if [ ! -f "main.tf" ]; then
    echo "ERROR: main.tf not found. Please run this script from terraform/production/secret-manager/"
    exit 1
fi

# Check if secret exists in AWS
echo "Step 1: Checking if secret exists in AWS..."
if aws secretsmanager describe-secret --secret-id "$SECRET_NAME" &>/dev/null; then
    echo "✓ Secret '$SECRET_NAME' exists in AWS"
    SECRET_ARN=$(aws secretsmanager describe-secret --secret-id "$SECRET_NAME" --query 'ARN' --output text)
    echo "  ARN: $SECRET_ARN"
else
    echo "✗ Secret '$SECRET_NAME' does NOT exist in AWS"
    echo "  Nothing to import. You can run 'terraform apply' to create it."
    exit 0
fi

echo ""
echo "Step 2: Checking Terraform state..."
terraform init -upgrade &>/dev/null

# Check if resource is in state
if terraform state show "$RESOURCE_NAME" &>/dev/null; then
    echo "→ Secret is in Terraform state. Checking if it's valid..."

    # Try to refresh to see if state is valid
    if terraform refresh -var="secret_key=dummy" -var="algorithm=HS256" -var="user_name=dummy" -var="password=dummy" -var="url_base=http://localhost" &>/dev/null; then
        echo "✓ State appears to be valid"
        echo "  If you're still getting errors, the issue might be elsewhere."
        exit 0
    else
        echo "✗ State refresh failed. State appears corrupted."
        echo "  Removing corrupted state..."
        terraform state rm "$RESOURCE_NAME" 2>/dev/null || true
        terraform state rm "$VERSION_RESOURCE_NAME" 2>/dev/null || true
    fi
else
    echo "→ Secret is NOT in Terraform state"
fi

echo ""
echo "Step 3: Importing secret from AWS..."
if terraform import "$RESOURCE_NAME" "$SECRET_NAME"; then
    echo "✓ Secret imported successfully"
else
    echo "✗ Failed to import secret"
    echo ""
    echo "Possible reasons:"
    echo "1. The secret is managed by another Terraform workspace"
    echo "2. You don't have permissions to import"
    echo "3. The backend state is locked"
    echo ""
    echo "Try running: terraform force-unlock <lock-id>"
    exit 1
fi

echo ""
echo "Step 4: Importing secret version..."
if terraform import "$VERSION_RESOURCE_NAME" "${SECRET_ARN}|AWSCURRENT"; then
    echo "✓ Secret version imported successfully"
else
    echo "⚠ Failed to import secret version (this is often expected)"
    echo "  The version will be managed on the next 'terraform apply'"
fi

echo ""
echo "=========================================="
echo "✓ Import completed successfully!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Run 'terraform plan' to verify the configuration"
echo "2. Run 'terraform apply' to update the secret if needed"
echo ""
