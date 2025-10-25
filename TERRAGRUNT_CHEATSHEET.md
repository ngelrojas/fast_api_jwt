# Terragrunt Quick Reference Cheat Sheet

## 🚀 Installation

```bash
# macOS
brew install terragrunt

# Verify
terragrunt --version
```

## 📁 File Structure

```
root/
├── terragrunt.hcl        # Root config (backend, provider)
└── terraform/
    └── production/
        ├── env.hcl       # Environment variables
        └── [module]/
            └── terragrunt.hcl  # Module config
```

## 🔧 Essential Commands

### Individual Module Commands
```bash
cd terraform/production/[module-name]

terragrunt init          # Initialize module
terragrunt plan          # Plan changes
terragrunt apply         # Apply changes
terragrunt destroy       # Destroy resources
terragrunt output        # Show outputs
terragrunt validate      # Validate configuration
```

### All Modules Commands
```bash
cd terraform/production

terragrunt run-all init      # Initialize all
terragrunt run-all plan      # Plan all
terragrunt run-all apply     # Apply all
terragrunt run-all destroy   # Destroy all (reverse order)
terragrunt run-all output    # Show all outputs
terragrunt run-all validate  # Validate all
```

## 🎯 Quick Deploy Script

Use the provided `deploy.sh` script:

```bash
# First time setup
./deploy.sh init

# Plan deployment
./deploy.sh plan

# Deploy everything
./deploy.sh apply

# Check outputs
./deploy.sh output

# Clean cache
./deploy.sh clean

# Destroy (careful!)
./deploy.sh destroy
```

## 🌍 Environment Variables

```bash
# Create .env from example
cp .env.example .env

# Edit with your values
nano .env

# Load variables
export $(cat .env | xargs)

# Or use the deploy script (loads automatically)
./deploy.sh plan
```

## 🔗 Useful Flags

```bash
--terragrunt-non-interactive       # Skip prompts (CI/CD)
--terragrunt-log-level debug       # Debug mode
--terragrunt-parallelism 10        # Parallel execution
--terragrunt-ignore-dependency-errors  # Continue on errors
--terragrunt-source [path]         # Use local module source
```

## 📊 Dependency Management

Terragrunt automatically handles dependencies:

```hcl
# In module's terragrunt.hcl
dependency "other_module" {
  config_path = "../other-module"
}

inputs = {
  value = dependency.other_module.outputs.some_value
}
```

## 🧹 Cleanup

```bash
# Remove Terragrunt cache
find . -type d -name ".terragrunt-cache" -exec rm -rf {} +

# Remove Terraform files
find . -type d -name ".terraform" -exec rm -rf {} +

# Or use deploy script
./deploy.sh clean
```

## 🐛 Troubleshooting

```bash
# Module not initialized
terragrunt init

# Clear cache and reinitialize
rm -rf .terragrunt-cache
terragrunt init

# Check dependency graph
terragrunt graph-dependencies

# Force unlock state (if locked)
terragrunt force-unlock [LOCK_ID]
```

## 📦 Common Workflows

### First Time Deployment
```bash
1. cp .env.example .env
2. # Edit .env with actual values
3. ./deploy.sh init
4. ./deploy.sh plan
5. ./deploy.sh apply
```

### Update Single Module
```bash
cd terraform/production/s3-storage
terragrunt plan
terragrunt apply
```

### Update Everything
```bash
./deploy.sh plan
./deploy.sh apply
```

### Emergency Rollback
```bash
cd terraform/production/[module]
terragrunt destroy
# Fix issue
terragrunt apply
```

## 🎨 Root terragrunt.hcl Structure

```hcl
# Backend configuration
remote_state {
  backend = "s3"
  config = {
    bucket = "state-bucket"
    key    = "${path_relative_to_include()}/terraform.tfstate"
    region = "us-east-1"
  }
}

# Provider generation
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "us-east-1"
}
EOF
}

# Shared inputs
inputs = {
  environment = "production"
}
```

## 🔐 Security Best Practices

1. ✅ Never commit `.env` files
2. ✅ Use AWS Secrets Manager for sensitive data
3. ✅ Enable state encryption
4. ✅ Use state locking (DynamoDB)
5. ✅ Review plans before applying
6. ✅ Use separate state files per module

## 📈 Benefits Summary

✅ **DRY**: Backend config in one place
✅ **Dependencies**: Automatic module ordering
✅ **State**: Isolated state per module
✅ **Multi-env**: Easy environment management
✅ **Safety**: State locking and encryption
✅ **Speed**: Parallel execution support

## 🔗 Resources

- [Terragrunt Docs](https://terragrunt.gruntwork.io/docs/)
- [GitHub](https://github.com/gruntwork-io/terragrunt)
- Full Guide: `TERRAGRUNT_GUIDE.md`

---
**Made with ❤️ for Fast API JWT Project**
