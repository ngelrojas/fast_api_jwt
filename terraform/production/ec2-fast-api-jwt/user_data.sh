#!/usr/bin/env sh
echo "Starting user data script..."

# Update package lists and install necessary packages
apt-get update -y
apt-get install -y python3 python3-pip git awscli jq
echo "Installed Python, pip, git, AWS CLI, and jq."

# Set variables from Terraform template
REGION="${region}"
SECRET_NAME="${secret_name}"
APP_BUCKET="${app_data_bucket}"

echo "Region: $REGION"
echo "Secret Name: $SECRET_NAME"
echo "App Bucket: $APP_BUCKET"

# Wait for IAM instance profile to be available
echo "Waiting for IAM instance profile to be ready..."
sleep 30

# Retrieve secrets from AWS Secrets Manager
echo "Retrieving secrets from AWS Secrets Manager..."
SECRET_JSON=$(aws secretsmanager get-secret-value \
    --secret-id "$SECRET_NAME" \
    --region "$REGION" \
    --query SecretString \
    --output text)

if [ $? -eq 0 ]; then
    echo "Successfully retrieved secrets from Secrets Manager"

    # Parse secrets using jq
    SECRET=$(echo "$SECRET_JSON" | jq -r '.SECRET')
    ALGORITHM=$(echo "$SECRET_JSON" | jq -r '.ALGORITHM')
    USER_NAME=$(echo "$SECRET_JSON" | jq -r '.USER_NAME')
    PASSWORD=$(echo "$SECRET_JSON" | jq -r '.PASSWORD')
    URL_BASE=$(echo "$SECRET_JSON" | jq -r '.URL_BASE')

    # Create application directory
    APP_DIR="/home/ubuntu/fast_api_jwt"
    mkdir -p "$APP_DIR"

    # Create .env file with retrieved secrets
    cat > "$APP_DIR/.env" <<EOF
SECRET=$SECRET
ALGORITHM=$ALGORITHM
USER_NAME=$USER_NAME
PASSWORD=$PASSWORD
URL_BASE=$URL_BASE
AWS_REGION=$REGION
S3_BUCKET=$APP_BUCKET
EOF

    echo "Created .env file at $APP_DIR/.env"
    chmod 600 "$APP_DIR/.env"
    chown ubuntu:ubuntu "$APP_DIR/.env"

    # Create a verification script
    cat > "$APP_DIR/verify_secrets.sh" <<'VERIFY_EOF'
#!/bin/bash
echo "=== Verifying Secrets Configuration ==="
if [ -f .env ]; then
    echo "✓ .env file exists"
    echo ""
    echo "Environment variables (values hidden for security):"
    while IFS='=' read -r key value; do
        if [ ! -z "$key" ] && [[ ! "$key" =~ ^# ]]; then
            echo "  ✓ $key=***"
        fi
    done < .env
else
    echo "✗ .env file not found"
    exit 1
fi
VERIFY_EOF

    chmod +x "$APP_DIR/verify_secrets.sh"
    chown ubuntu:ubuntu "$APP_DIR/verify_secrets.sh"

    echo "Created verification script at $APP_DIR/verify_secrets.sh"
    echo "Run 'cd $APP_DIR && ./verify_secrets.sh' to verify the secrets"

else
    echo "ERROR: Failed to retrieve secrets from Secrets Manager"
    echo "Please check:"
    echo "  1. IAM instance profile has secretsmanager:GetSecretValue permission"
    echo "  2. Secret name '$SECRET_NAME' exists in region '$REGION'"
    echo "  3. EC2 instance has internet connectivity"
    exit 1
fi

echo "User data script completed successfully!"
