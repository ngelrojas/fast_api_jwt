# 🔐 AWS Credentials Quick Setup Guide

## ✅ Yes! Deploy from Your Machine Without GitHub Actions

This is a **quick reference** for setting up AWS credentials on your local machine.

---

## 🚀 5-Minute Setup

### Step 1: Get AWS Credentials

1. **Log into AWS Console**: https://console.aws.amazon.com
2. **Go to IAM** → Users → Your Username
3. **Security Credentials** tab
4. **Create Access Key**
5. **Download** or copy:
   - Access Key ID (example: `AKIAIOSFODNN7EXAMPLE`)
   - Secret Access Key (example: `wJalrXUtnFEMI/K7MDENG/...`)

### Step 2: Configure AWS CLI

```bash
# Run this command
aws configure

# Enter when prompted:
AWS Access Key ID [None]: AKIAIOSFODNN7EXAMPLE
AWS Secret Access Key [None]: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
Default region name [None]: us-east-1
Default output format [None]: json
```

### Step 3: Test Connection

```bash
# Verify it works
aws sts get-caller-identity

# Expected output:
{
    "UserId": "AIDAI...",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/yourname"
}
```

✅ **If you see this, you're ready to deploy!**

---

## 📋 IAM Permissions Required

Your IAM user needs these permissions to deploy:

```
✅ EC2 (Full or Create/Modify)
✅ S3 (Full)
✅ IAM (Create Roles/Policies)
✅ Secrets Manager (Full)
✅ SQS (Full)
✅ CloudWatch Logs (optional, for monitoring)
```

### Quick Permission Setup

In AWS Console:
1. IAM → Users → Your User
2. Permissions tab
3. Add these managed policies:
   - `AmazonEC2FullAccess`
   - `AmazonS3FullAccess`
   - `IAMFullAccess`
   - `SecretsManagerReadWrite`
   - `AmazonSQSFullAccess`

Or create a custom policy with specific permissions.

---

## 🔄 Three Ways to Authenticate

### Option 1: AWS Configure (Recommended)
```bash
aws configure
```
- ✅ Easiest method
- ✅ Credentials stored in `~/.aws/`
- ✅ Works automatically with Terraform/Terragrunt

### Option 2: Environment Variables
```bash
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"
export AWS_DEFAULT_REGION="us-east-1"
```
- ✅ Temporary (session only)
- ✅ Good for testing
- ✅ Can be in your `.env` file

### Option 3: AWS Profiles
```bash
# Configure with profile name
aws configure --profile production

# Use the profile
export AWS_PROFILE=production
```
- ✅ Multiple AWS accounts
- ✅ Switch between environments
- ✅ Organized credentials

---

## 🎯 Now Deploy!

Once AWS is configured:

```bash
# From project root
./deploy.sh init
./deploy.sh plan
./deploy.sh apply
```

That's it! Your infrastructure deploys from your machine to AWS! 🚀

---

## 🔐 Security Best Practices

### DO ✅
- ✅ Use IAM users (not root account)
- ✅ Enable MFA on your AWS account
- ✅ Rotate access keys regularly
- ✅ Use least privilege permissions
- ✅ Keep `.env` file gitignored
- ✅ Delete unused access keys

### DON'T ❌
- ❌ Never commit credentials to Git
- ❌ Don't share access keys
- ❌ Don't use root account keys
- ❌ Don't use same keys everywhere
- ❌ Don't hardcode credentials in code

---

## 🐛 Troubleshooting

### "Unable to locate credentials"
```bash
# Reconfigure AWS
aws configure

# Or check if credentials file exists
cat ~/.aws/credentials
```

### "Access Denied" errors
```bash
# Check your IAM permissions in AWS Console
# Ensure you have the required policies attached
```

### "Invalid security token"
```bash
# Your credentials may be expired or invalid
# Generate new access keys in AWS Console
aws configure  # Enter new keys
```

### "Region not found"
```bash
# Ensure region is set
aws configure set region us-east-1
```

---

## 📍 Where Credentials Are Stored

### AWS Configure Method
```
~/.aws/credentials  # Your access keys
~/.aws/config       # Region and settings
```

Example `~/.aws/credentials`:
```ini
[default]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

Example `~/.aws/config`:
```ini
[default]
region = us-east-1
output = json
```

### Environment Variables Method
```bash
# In your shell or .env file
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_DEFAULT_REGION="us-east-1"
```

---

## 🎓 Complete Example

```bash
# 1. Install AWS CLI (if needed)
$ brew install awscli

# 2. Configure credentials
$ aws configure
AWS Access Key ID: AKIA**************
AWS Secret Access Key: ****************************************
Default region name: us-east-1
Default output format: json

# 3. Test
$ aws sts get-caller-identity
{
    "Account": "123456789012",
    "UserId": "AIDAI...",
    "Arn": "arn:aws:iam::123456789012:user/ngelrojas"
}

# 4. Check S3 buckets (test permissions)
$ aws s3 ls
✅ Works!

# 5. Check EC2 instances (test permissions)
$ aws ec2 describe-instances
✅ Works!

# 6. Ready to deploy!
$ ./deploy.sh apply
```

---

## ✅ Checklist

Before deploying, verify:

- [ ] AWS CLI installed (`aws --version`)
- [ ] Credentials configured (`aws configure`)
- [ ] Connection works (`aws sts get-caller-identity`)
- [ ] Permissions are correct (can list S3, EC2, etc.)
- [ ] Region is us-east-1 (or your preferred region)
- [ ] Terraform installed (`terraform --version`)
- [ ] Terragrunt installed (`terragrunt --version`)
- [ ] Environment variables set (`.env` file)

---

## 🚀 Ready!

You're now set up to deploy infrastructure from your machine!

**Next Steps:**
1. ✅ AWS credentials configured
2. → Deploy backend: `cd terraform/backend-infra && terraform apply`
3. → Deploy app: `./deploy.sh apply`

**Full Guide:** [LOCAL_DEPLOYMENT_GUIDE.md](LOCAL_DEPLOYMENT_GUIDE.md)

---

**Remember:** GitHub Actions is optional! You can do everything from your terminal! 💪
