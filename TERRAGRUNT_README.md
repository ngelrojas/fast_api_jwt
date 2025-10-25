# 🎯 Terragrunt Integration - Quick Start

This project now uses **Terragrunt** for better Infrastructure as Code management!

## 📋 What You Need

1. **Terraform** (>= 1.0)
2. **Terragrunt** (latest)
3. **AWS CLI** configured
4. **AWS Account** with appropriate permissions

## 🚀 Quick Setup (3 Steps)

### Step 1: Install Terragrunt
```bash
brew install terragrunt
```

### Step 2: Configure Environment
```bash
# Copy example file
cp .env.example .env

# Edit with your values
nano .env
```

### Step 3: Deploy!
```bash
# Initialize
./deploy.sh init

# Preview changes
./deploy.sh plan

# Deploy everything
./deploy.sh apply
```

## 📚 Documentation

- **📖 [TERRAGRUNT_GUIDE.md](TERRAGRUNT_GUIDE.md)** - Complete guide with explanations
- **⚡ [TERRAGRUNT_CHEATSHEET.md](TERRAGRUNT_CHEATSHEET.md)** - Quick reference
- **🔧 [deploy.sh](deploy.sh)** - Automated deployment script

## 🎨 What's Different?

### Before (Plain Terraform)
```bash
# Had to manage modules manually
cd terraform/production/sqs-notifications
terraform init && terraform apply

cd ../s3-storage
terraform init && terraform apply
# ... repeat for each module
```

### After (With Terragrunt)
```bash
# One command deploys everything in the right order!
./deploy.sh apply
```

## 🎁 Benefits You Get

✅ **No Repeated Backend Config** - Configure once in root
✅ **Automatic Dependencies** - Modules deploy in correct order
✅ **Isolated State Files** - Each module has its own state
✅ **Easy Environment Management** - Add staging/dev easily
✅ **Better Security** - Environment variables for secrets
✅ **Faster Deployments** - Parallel execution support

## 🔧 Common Commands

```bash
./deploy.sh init      # Initialize all modules
./deploy.sh plan      # Preview changes
./deploy.sh apply     # Deploy infrastructure
./deploy.sh output    # Show outputs
./deploy.sh clean     # Clean cache
./deploy.sh destroy   # Remove everything (careful!)
```

## 📁 New File Structure

```
fast_api_jwt/
├── terragrunt.hcl              # 🆕 Root Terragrunt config
├── .env.example                # 🆕 Environment variables template
├── deploy.sh                   # 🆕 Deployment script
├── TERRAGRUNT_GUIDE.md        # 🆕 Full documentation
├── TERRAGRUNT_CHEATSHEET.md   # 🆕 Quick reference
└── terraform/
    └── production/
        ├── env.hcl            # 🆕 Environment config
        ├── s3-storage/
        │   ├── main.tf
        │   └── terragrunt.hcl # 🆕 Module config
        ├── sqs-notifications/
        │   └── terragrunt.hcl # 🆕
        ├── iam/
        │   └── terragrunt.hcl # 🆕
        └── ... (all modules have terragrunt.hcl)
```

## 🆘 Need Help?

1. Read the **[TERRAGRUNT_GUIDE.md](TERRAGRUNT_GUIDE.md)** for detailed explanations
2. Check **[TERRAGRUNT_CHEATSHEET.md](TERRAGRUNT_CHEATSHEET.md)** for quick commands
3. Your existing Terraform files work the same - Terragrunt just wraps them!

## 🎓 Learn More

- Your existing `terraform` commands still work
- Terragrunt adds `terragrunt` commands with extra features
- Read the full guide to understand how it all fits together

---

**Ready to deploy? Start with `./deploy.sh init`** 🚀
