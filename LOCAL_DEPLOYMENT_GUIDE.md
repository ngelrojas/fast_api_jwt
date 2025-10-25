# 💻 Local Deployment Guide - No GitHub Actions Required!

## ✅ Yes, You Can Deploy Directly from Your Machine!

Terragrunt and Terraform run **directly on your local machine** and connect to AWS using your AWS credentials. **GitHub Actions is completely optional** and only needed if you want automated CI/CD pipelines.

---

## 🎯 How Local Deployment Works

```
Your MacBook
    ↓ (AWS CLI credentials)
AWS Services (EC2, S3, IAM, etc.)
    ↓
Infrastructure Created!
```

**No GitHub Actions needed!**

---

## 📋 Prerequisites for Local Deployment

### 1. Install Required Tools

```bash
# Install Terraform
brew install terraform

# Install Terragrunt
brew install terragrunt

# Install AWS CLI
brew install awscli

# Verify installations
terraform --version
terragrunt --version
aws --version
```

### 2. Configure AWS Credentials

You have **three options** to authenticate with AWS:

#### Option A: AWS Configure (Recommended for Beginners)
```bash
aws configure

# You'll be prompted for:
# AWS Access Key ID: [your-access-key]
# AWS Secret Access Key: [your-secret-key]
# Default region: us-east-1
# Default output format: json
```

This creates `~/.aws/credentials` and `~/.aws/config` files.

#### Option B: Environment Variables
```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"
```

#### Option C: AWS SSO (For Organizations)
```bash
aws sso login --profile your-profile
export AWS_PROFILE=your-profile
```

### 3. Verify AWS Connection

```bash
# Test your AWS credentials
aws sts get-caller-identity

# Expected output:
# {
#     "UserId": "...",
#     "Account": "123456789012",
#     "Arn": "arn:aws:iam::123456789012:user/yourname"
# }
```

If this works, you're ready to deploy! ✅

---

## 🚀 Local Deployment Workflow

### Step 1: Set Up Environment Variables (One Time)

```bash
# Copy the example file
cp .env.example .env

# Edit with your values
nano .env

# Add these variables:
export TF_VAR_secret_key="your-jwt-secret-key"
export TF_VAR_user_name="your-app-username"
export TF_VAR_password="your-app-password"
export TF_VAR_url_base="http://your-app-url.com"
export TF_VAR_github_token="your-github-token"  # Only if using GitHub runner
export TF_VAR_vpc_id="vpc-xxxxxxxxx"
export TF_VAR_key_name="your-ssh-key-name"

# Load environment variables
export $(cat .env | xargs)
```

### Step 2: Deploy Backend Infrastructure (First Time Only)

```bash
# Navigate to backend infrastructure
cd terraform/backend-infra

# Initialize Terraform
terraform init

# Preview what will be created
terraform plan

# Create S3 bucket and DynamoDB table for state management
terraform apply

# Expected output:
# ✅ S3 bucket: tf-state-locks-fast-api-jwt
# ✅ DynamoDB table: tf-table-locks-fast-api-jwt
```

### Step 3: Deploy Your Application Infrastructure

```bash
# Go back to root directory
cd ../..

# Initialize all modules
./deploy.sh init

# Preview all changes
./deploy.sh plan

# Review the output carefully!
# You'll see what resources will be created

# Deploy everything
./deploy.sh apply

# Type 'yes' when prompted
```

That's it! Your infrastructure is deployed! 🎉

---

## 🔧 Common Local Commands

### Deploy Everything
```bash
# From project root
./deploy.sh apply
```

### Deploy a Single Module
```bash
# Navigate to the module
cd terraform/production/s3-storage

# Plan
terragrunt plan

# Apply
terragrunt apply
```

### Check What's Deployed
```bash
# View all outputs
./deploy.sh output

# Or check individual module
cd terraform/production/ec2-fast-api-jwt
terragrunt output
```

### Update a Module
```bash
# Make changes to your Terraform files
nano terraform/production/s3-storage/main.tf

# Plan the changes
cd terraform/production/s3-storage
terragrunt plan

# Apply the changes
terragrunt apply
```

### Destroy Everything (Careful!)
```bash
# Destroy all infrastructure
./deploy.sh destroy

# Type 'destroy' when prompted
```

---

## 🔐 AWS Credentials Best Practices

### For Development (Your Machine)
```bash
# Use AWS CLI credentials
aws configure

# Or use environment variables in .env file
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."
```

### For Production
Consider using:
1. **AWS IAM Roles** (if running from EC2)
2. **AWS SSO** (for organizations)
3. **Temporary credentials** (via AWS STS)

### Security Tips
✅ **Never commit** AWS credentials to Git
✅ **Use `.env` file** (already gitignored)
✅ **Rotate keys** regularly
✅ **Use least privilege** IAM policies
✅ **Enable MFA** on your AWS account

---

## 🎯 Typical Local Development Workflow

### Daily Development
```bash
# 1. Make changes to Terraform files
nano terraform/production/ec2-fast-api-jwt/main.tf

# 2. Test changes
cd terraform/production/ec2-fast-api-jwt
terragrunt plan

# 3. Apply if looks good
terragrunt apply

# 4. Verify in AWS Console
open https://console.aws.amazon.com
```

### Full Deployment
```bash
# 1. Update multiple modules
# ... make your changes ...

# 2. Plan everything
cd terraform/production
terragrunt run-all plan

# 3. Review the plan

# 4. Apply all changes
terragrunt run-all apply
```

---

## 🆚 Local vs GitHub Actions

### Local Deployment (What You're Doing)
```
Your Machine → AWS
```

**Pros:**
- ✅ Direct control
- ✅ Immediate feedback
- ✅ Easy debugging
- ✅ No CI/CD setup needed
- ✅ Perfect for development

**Cons:**
- ❌ Requires your machine to be running
- ❌ Manual process
- ❌ Depends on your local credentials

### GitHub Actions (Optional)
```
Git Push → GitHub Actions → AWS
```

**Pros:**
- ✅ Automated deployment
- ✅ Runs on every commit
- ✅ Team collaboration
- ✅ Audit trail

**Cons:**
- ❌ Requires GitHub setup
- ❌ More complex configuration
- ❌ Costs (GitHub Actions minutes)

---

## 💡 You Don't Need GitHub Actions If:

✅ You're the only developer
✅ You prefer manual control
✅ You want to review changes before deployment
✅ You're still learning/testing
✅ You want to save costs

**Local deployment is perfectly fine and recommended for most use cases!**

---

## 🎓 Step-by-Step Example Session

Here's a complete example of deploying from your machine:

```bash
# 1. Configure AWS credentials (one time)
$ aws configure
AWS Access Key ID: AKIAIOSFODNN7EXAMPLE
AWS Secret Access Key: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
Default region name: us-east-1
Default output format: json

# 2. Verify connection
$ aws sts get-caller-identity
{
    "UserId": "AIDAI...",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/yourname"
}

# 3. Set up environment
$ cp .env.example .env
$ nano .env  # Edit with your values
$ export $(cat .env | xargs)

# 4. Deploy backend (first time only)
$ cd terraform/backend-infra
$ terraform init
$ terraform apply
✅ S3 bucket created
✅ DynamoDB table created

# 5. Deploy application
$ cd ../..
$ ./deploy.sh init
✅ All modules initialized

$ ./deploy.sh plan
... reviewing plan ...

$ ./deploy.sh apply
Are you sure? yes
✅ Deploying...
✅ Complete!

# 6. Check outputs
$ ./deploy.sh output
ec2_public_ip = "54.123.45.67"
s3_bucket_name = "storage-files-csv-..."
...

# 7. Verify in AWS Console
$ open https://console.aws.amazon.com
✅ Resources are there!
```

---

## 🐛 Troubleshooting Local Deployment

### "Unable to locate credentials"
```bash
# Check AWS credentials
aws sts get-caller-identity

# If fails, reconfigure:
aws configure
```

### "Access Denied"
```bash
# Your IAM user needs these permissions:
# - EC2 (full or create/modify)
# - S3 (full)
# - IAM (create roles)
# - Secrets Manager
# - SQS

# Check your IAM permissions in AWS Console
```

### "State locked"
```bash
# Someone else is deploying, or previous run failed
# Wait a few minutes, or:
cd terraform/production/[module]
terragrunt force-unlock [LOCK_ID]
```

### "Module not found"
```bash
# Clear cache and reinitialize
./deploy.sh clean
./deploy.sh init
```

---

## 📊 What Gets Created When You Deploy Locally

When you run `./deploy.sh apply` from your machine:

1. **S3 Bucket** - For file storage
2. **SQS Queue** - For notifications
3. **IAM Roles** - For permissions
4. **Secrets Manager** - For app secrets
5. **EC2 Instances** - For your FastAPI app
6. **Security Groups** - For network security

All from your MacBook! 💻 → ☁️

---

## ✅ Summary

### Yes, You Can Deploy Everything Locally!

**What you need:**
1. ✅ AWS CLI configured (`aws configure`)
2. ✅ Terraform installed (`brew install terraform`)
3. ✅ Terragrunt installed (`brew install terragrunt`)
4. ✅ Environment variables set (`.env` file)

**What you run:**
```bash
./deploy.sh init
./deploy.sh plan
./deploy.sh apply
```

**Result:**
- Infrastructure deployed to AWS
- Controlled from your machine
- No GitHub Actions needed!

---

## 🎯 Quick Start Commands

```bash
# First time setup
aws configure                  # Configure AWS credentials
cp .env.example .env          # Copy environment template
nano .env                     # Add your secrets
cd terraform/backend-infra
terraform apply               # Create state backend

# Deploy everything
cd ../..
./deploy.sh init              # Initialize
./deploy.sh plan              # Preview
./deploy.sh apply             # Deploy!

# Verify
aws ec2 describe-instances    # Check EC2
aws s3 ls                     # Check S3
./deploy.sh output            # See outputs
```

---

## 🚀 You're Ready!

GitHub Actions is **optional** and only needed for:
- Automated deployments on git push
- Team collaboration workflows
- CI/CD pipelines

For local deployment, you just need:
- AWS credentials
- Terraform/Terragrunt
- This guide!

**Go ahead and deploy from your machine!** 💪

---

**Need help?**
- AWS credentials: `aws configure --help`
- Deployment: `./deploy.sh --help`
- Troubleshooting: See DEPLOYMENT_CHECKLIST.md
