# How to Verify Secrets on EC2 Instance

## Overview

The `user_data.sh` script automatically:
1. ✅ Installs AWS CLI and jq
2. ✅ Retrieves secrets from AWS Secrets Manager
3. ✅ Creates a `.env` file at `/home/ubuntu/fast_api_jwt/.env`
4. ✅ Creates a verification script to check the secrets

## Methods to Verify Secrets on EC2

### Method 1: Use the Verification Script (Easiest)

After the EC2 instance is running, SSH into it and run:

```bash
# SSH into your EC2 instance
ssh -i your-key.pem ubuntu@<EC2_PUBLIC_IP>

# Navigate to the application directory
cd /home/ubuntu/fast_api_jwt

# Run the verification script
./verify_secrets.sh
```

**Expected Output:**
```
=== Verifying Secrets Configuration ===
✓ .env file exists

Environment variables (values hidden for security):
  ✓ SECRET=***
  ✓ ALGORITHM=***
  ✓ USER_NAME=***
  ✓ PASSWORD=***
  ✓ URL_BASE=***
  ✓ AWS_REGION=***
  ✓ S3_BUCKET=***
```

### Method 2: Check the .env File Directly

```bash
# SSH into your EC2 instance
ssh -i your-key.pem ubuntu@<EC2_PUBLIC_IP>

# Check if .env file exists
ls -la /home/ubuntu/fast_api_jwt/.env

# View the contents (be careful, contains sensitive data!)
cat /home/ubuntu/fast_api_jwt/.env
```

**Expected Output:**
```
SECRET=my_secret_key_fast_api_2025
ALGORITHM=HS256
USER_NAME=admin
PASSWORD=strong_password_123
URL_BASE=http://localhost:8000
AWS_REGION=us-east-1
S3_BUCKET=your-bucket-name
```

### Method 3: Check User Data Execution Log

The user_data script logs are available in cloud-init logs:

```bash
# SSH into your EC2 instance
ssh -i your-key.pem ubuntu@<EC2_PUBLIC_IP>

# View the cloud-init output log
sudo cat /var/log/cloud-init-output.log | grep -A 10 "Starting user data"

# Or view the full log
sudo less /var/log/cloud-init-output.log
```

Look for these key messages:
- ✅ "Successfully retrieved secrets from Secrets Manager"
- ✅ "Created .env file at /home/ubuntu/fast_api_jwt/.env"
- ✅ "User data script completed successfully!"

### Method 4: Use AWS Systems Manager Session Manager (No SSH Key Needed)

If your EC2 has SSM agent enabled:

```bash
# From your local machine
aws ssm start-session --target <INSTANCE_ID>

# Once connected, check the secrets
cd /home/ubuntu/fast_api_jwt
./verify_secrets.sh
```

### Method 5: Verify from AWS Secrets Manager Directly

Compare what's in AWS with what should be on the instance:

```bash
# From your local machine or EC2
aws secretsmanager get-secret-value \
  --secret-id fast-api-jwt-credentials \
  --region us-east-1 \
  --query SecretString \
  --output text | jq .
```

**Expected Output:**
```json
{
  "SECRET": "my_secret_key_fast_api_2025",
  "ALGORITHM": "HS256",
  "USER_NAME": "admin",
  "PASSWORD": "strong_password_123",
  "URL_BASE": "http://localhost:8000"
}
```

## Troubleshooting

### Problem: .env file doesn't exist

**Check 1: Was user_data executed?**
```bash
sudo cat /var/log/cloud-init-output.log
```

**Check 2: IAM permissions**
```bash
# From EC2 instance
aws secretsmanager get-secret-value \
  --secret-id fast-api-jwt-credentials \
  --region us-east-1
```

If you get an error like "AccessDeniedException", the IAM role doesn't have proper permissions.

**Check 3: Instance profile attached?**
```bash
# From EC2 instance
curl http://169.254.169.254/latest/meta-data/iam/info
```

### Problem: Script shows "ERROR: Failed to retrieve secrets"

**Solution 1:** Check the secret exists
```bash
aws secretsmanager list-secrets --region us-east-1
```

**Solution 2:** Check IAM policy
The EC2 instance role needs:
```json
{
  "Effect": "Allow",
  "Action": [
    "secretsmanager:GetSecretValue",
    "secretsmanager:DescribeSecret"
  ],
  "Resource": "arn:aws:secretsmanager:*:*:secret:fast-api-jwt-credentials-*"
}
```

**Solution 3:** Wait longer
The user_data script waits 30 seconds for IAM to propagate. If still failing, it might need more time.

### Problem: Can't SSH into EC2

**Solution:** Use AWS Systems Manager Session Manager
```bash
# Find your instance ID
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=ec2-fast-api-jwt" \
  --query "Reservations[*].Instances[*].InstanceId" \
  --output text

# Connect
aws ssm start-session --target <INSTANCE_ID>
```

## Testing Your FastAPI Application

Once secrets are verified, test your FastAPI application:

```bash
# SSH into EC2
ssh -i your-key.pem ubuntu@<EC2_PUBLIC_IP>

# Navigate to app directory
cd /home/ubuntu/fast_api_jwt

# Clone your repository (if not done yet)
git clone https://github.com/ngelrojas/fast_api_jwt.git .

# Install dependencies
pip3 install -r requirements.txt

# Load environment variables
export $(cat .env | xargs)

# Run the application
python3 main.py

# Or using uvicorn
uvicorn main:app --host 0.0.0.0 --port 8000
```

## Quick Verification Checklist

- [ ] EC2 instance is running
- [ ] IAM instance profile is attached to EC2
- [ ] Secret exists in AWS Secrets Manager
- [ ] Security group allows SSH (port 22)
- [ ] User data script completed successfully
- [ ] .env file exists at `/home/ubuntu/fast_api_jwt/.env`
- [ ] .env file has correct permissions (600)
- [ ] All environment variables are populated
- [ ] FastAPI application can read the secrets

## Security Best Practices

1. ✅ **Never commit .env files** to version control
2. ✅ **Use least privilege** IAM policies
3. ✅ **.env file has restrictive permissions** (600)
4. ✅ **Rotate secrets regularly** in Secrets Manager
5. ✅ **Use HTTPS** for production URLs
6. ✅ **Monitor access** to Secrets Manager via CloudTrail

## Next Steps

After verifying secrets work:
1. Update your FastAPI app to load from .env
2. Set up systemd service for auto-start
3. Configure nginx as reverse proxy
4. Set up SSL/TLS certificates
5. Implement log rotation
6. Set up monitoring and alerts
