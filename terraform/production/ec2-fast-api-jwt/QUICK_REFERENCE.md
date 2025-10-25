# Quick Reference: Verify Secrets on EC2

## TL;DR - Quick Commands

### 1. SSH into EC2
```bash
ssh -i your-key.pem ubuntu@<EC2_IP>
```

### 2. Run Verification Script
```bash
cd /home/ubuntu/fast_api_jwt
./verify_secrets.sh
```

### 3. Check .env File Exists
```bash
cat /home/ubuntu/fast_api_jwt/.env
```

### 4. Check User Data Logs
```bash
sudo cat /var/log/cloud-init-output.log | tail -n 50
```

## What user_data.sh Does Automatically

✅ Installs: `awscli`, `jq`
✅ Retrieves: Secrets from AWS Secrets Manager
✅ Creates: `/home/ubuntu/fast_api_jwt/.env`
✅ Creates: `/home/ubuntu/fast_api_jwt/verify_secrets.sh`
✅ Sets permissions: `chmod 600` on .env

## Your .env File Will Contain

```env
SECRET=my_secret_key_fast_api_2025
ALGORITHM=HS256
USER_NAME=admin
PASSWORD=strong_password_123
URL_BASE=http://localhost:8000
AWS_REGION=us-east-1
S3_BUCKET=your-bucket-name
```

## Success Indicators

In `/var/log/cloud-init-output.log`, look for:
- ✅ "Successfully retrieved secrets from Secrets Manager"
- ✅ "Created .env file at /home/ubuntu/fast_api_jwt/.env"
- ✅ "User data script completed successfully!"

## If Something Goes Wrong

```bash
# Check IAM instance profile
curl http://169.254.169.254/latest/meta-data/iam/info

# Test Secrets Manager access
aws secretsmanager get-secret-value \
  --secret-id fast-api-jwt-credentials \
  --region us-east-1

# View full logs
sudo less /var/log/cloud-init-output.log
```

## Files & Locations

| File | Location | Purpose |
|------|----------|---------|
| `.env` | `/home/ubuntu/fast_api_jwt/.env` | Application secrets |
| `verify_secrets.sh` | `/home/ubuntu/fast_api_jwt/verify_secrets.sh` | Verification script |
| User data logs | `/var/log/cloud-init-output.log` | Boot script logs |

## Answer to Your Question

**Q: How do I know if credentials are in my EC2 machine?**

**A: Use the existing `user_data.sh` file!** No need to create a separate script. Just:

1. Deploy with Terraform
2. SSH into EC2
3. Run: `cd /home/ubuntu/fast_api_jwt && ./verify_secrets.sh`

The user_data.sh script automatically:
- Retrieves secrets from AWS Secrets Manager
- Creates the .env file
- Creates a verification script for you

**That's it! Everything is automated.** 🎉
