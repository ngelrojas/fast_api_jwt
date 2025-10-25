# Terragrunt Integration Guide

## 🚀 What is Terragrunt?

Terragrunt is a thin wrapper for Terraform that provides extra tools for:
- **DRY Configuration**: Keep your backend and provider configurations in one place
- **Dependency Management**: Automatically handle dependencies between modules
- **Remote State Management**: Simplified S3 backend configuration
- **Environment Management**: Easy multi-environment deployments

## 📋 Prerequisites

1. **Install Terragrunt**:
   ```bash
   # macOS
   brew install terragrunt

   # Or download directly
   # https://github.com/gruntwork-io/terragrunt/releases
   ```

2. **Verify Installation**:
   ```bash
   terragrunt --version
   terraform --version
   ```

## 🏗️ Project Structure

Your project now has this structure:

```
fast_api_jwt/
├── terragrunt.hcl              # Root configuration (shared by all modules)
├── .env.example                # Environment variables template
└── terraform/
    ├── backend-infra/          # Backend infrastructure (S3, DynamoDB)
    └── production/
        ├── env.hcl             # Environment-specific variables
        ├── s3-storage/
        │   ├── main.tf
        │   ├── variables.tf
        │   ├── outputs.tf
        │   └── terragrunt.hcl  # Module-specific configuration
        ├── sqs-notifications/
        │   └── terragrunt.hcl
        ├── iam/
        │   └── terragrunt.hcl
        ├── secret-manager/
        │   └── terragrunt.hcl
        ├── ec2-fast-api-jwt/
        │   └── terragrunt.hcl
        └── ec2-self-hosted/
            └── terragrunt.hcl
```

## 🎯 How Terragrunt Helps Your Project

### 1. **DRY Backend Configuration**
Before (in each module):
```hcl
terraform {
  backend "s3" {
    bucket         = "tf-state-locks-fast-api-jwt"
    key            = "terraform/state/production.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tf-table-locks-fast-api-jwt"
    encrypt        = true
  }
}
```

After (only in root `terragrunt.hcl`):
- Automatically generates backend configuration for each module
- No more copy-pasting backend blocks

### 2. **Automatic Dependency Management**
Terragrunt automatically handles module dependencies:
- `sqs-notifications` → `s3-storage` → `iam` → `ec2-fast-api-jwt`
- Runs modules in the correct order
- Passes outputs between modules automatically

### 3. **Environment Variables**
Instead of maintaining separate `.tfvars` files, use environment variables:
```bash
export TF_VAR_secret_key="my-secret"
```

## 📖 Step-by-Step Usage Guide

### Step 1: Set Up Your Backend Infrastructure (First Time Only)

If you haven't created the S3 bucket and DynamoDB table for state management:

```bash
cd terraform/backend-infra
terraform init
terraform plan
terraform apply
```

### Step 2: Configure Your Environment Variables

```bash
# Copy the example file
cp .env.example .env

# Edit .env with your actual values
nano .env

# Load environment variables
export $(cat .env | xargs)
```

### Step 3: Initialize All Modules

From the root directory:

```bash
cd terraform/production

# Initialize all modules at once
terragrunt run-all init
```

This will initialize all modules in the correct order.

### Step 4: Plan Your Infrastructure

```bash
# Plan all modules
terragrunt run-all plan

# Or plan a specific module
cd s3-storage
terragrunt plan
```

### Step 5: Apply Your Infrastructure

```bash
# Apply all modules (deploys everything)
cd terraform/production
terragrunt run-all apply

# Or apply specific modules in dependency order
cd s3-storage
terragrunt apply
```

### Step 6: Destroy Infrastructure (when needed)

```bash
# Destroy all modules in reverse order
cd terraform/production
terragrunt run-all destroy

# Or destroy a specific module
cd ec2-fast-api-jwt
terragrunt destroy
```

## 🔧 Common Terragrunt Commands

### Working with Individual Modules

```bash
# Navigate to any module directory
cd terraform/production/s3-storage

# Initialize
terragrunt init

# Plan
terragrunt plan

# Apply
terragrunt apply

# Destroy
terragrunt destroy

# Show current state
terragrunt show

# Get outputs
terragrunt output
```

### Working with All Modules

```bash
# From production directory
cd terraform/production

# Initialize all
terragrunt run-all init

# Plan all
terragrunt run-all plan

# Apply all (with auto-approve for CI/CD)
terragrunt run-all apply --terragrunt-non-interactive

# Destroy all
terragrunt run-all destroy

# Output from all modules
terragrunt run-all output
```

### Useful Flags

```bash
# Skip interactive approval
--terragrunt-non-interactive

# Ignore dependency errors
--terragrunt-ignore-dependency-errors

# Run in parallel (faster)
--terragrunt-parallelism 10

# Debug mode
--terragrunt-log-level debug
```

## 🔄 Deployment Workflow

### For Development/Testing:
```bash
# 1. Set environment variables
export $(cat .env | xargs)

# 2. Navigate to production folder
cd terraform/production

# 3. Plan a specific module
cd s3-storage
terragrunt plan

# 4. Apply if looks good
terragrunt apply
```

### For Production Deployment:
```bash
# 1. Set production environment variables
export $(cat .env.production | xargs)

# 2. Initialize everything
cd terraform/production
terragrunt run-all init

# 3. Plan everything
terragrunt run-all plan

# 4. Review the plan carefully

# 5. Apply everything
terragrunt run-all apply
```

### For CI/CD Pipeline:
```bash
#!/bin/bash
# Deploy script for CI/CD

# Set environment variables from secrets
export TF_VAR_secret_key="${SECRET_KEY}"
export TF_VAR_github_token="${GITHUB_TOKEN}"
# ... other vars

# Navigate to production
cd terraform/production

# Initialize
terragrunt run-all init --terragrunt-non-interactive

# Plan
terragrunt run-all plan --terragrunt-non-interactive

# Apply
terragrunt run-all apply --terragrunt-non-interactive
```

## 📊 Understanding Dependencies

Terragrunt automatically manages dependencies based on the `dependency` blocks:

```
sqs-notifications (no dependencies)
    ↓
s3-storage (depends on sqs-notifications)
    ↓
iam (depends on s3-storage)
    ↓
secret-manager (no dependencies)
    ↓
ec2-fast-api-jwt (depends on s3, iam, secrets)
    ↓
ec2-self-hosted (depends on s3, iam)
```

When you run `terragrunt run-all apply`, it:
1. Builds the dependency graph
2. Runs modules in the correct order
3. Passes outputs between modules automatically
4. Handles errors and rollbacks

## 🎨 Benefits You Get

### 1. **No More Repetitive Backend Configuration**
- Backend configured once in root `terragrunt.hcl`
- Each module gets unique state file automatically

### 2. **Easy Multi-Environment Support**
```bash
# Easy to add staging environment
terraform/
  ├── production/
  │   └── env.hcl  # environment = "production"
  └── staging/
      └── env.hcl  # environment = "staging"
```

### 3. **Dependency Management**
- No more manual coordination of `terraform apply` commands
- Automatic output passing between modules
- Correct execution order guaranteed

### 4. **Mock Outputs for Planning**
- Can plan modules independently
- Mock outputs prevent dependency errors during planning

### 5. **Better State Management**
- Each module has its own state file
- Isolated state reduces risk
- Easier to manage and debug

## 🐛 Troubleshooting

### Error: "Backend not initialized"
```bash
cd terraform/production/[module-name]
terragrunt init
```

### Error: "Dependency outputs not found"
```bash
# Apply dependencies first
cd terraform/production/sqs-notifications
terragrunt apply

cd ../s3-storage
terragrunt apply
```

### Error: "No such file or directory"
Make sure you're in the correct directory and terragrunt.hcl exists.

### Clear Terragrunt Cache
```bash
find . -type d -name ".terragrunt-cache" -exec rm -rf {} +
```

## 🚦 Best Practices

1. **Always use version control** for your `.hcl` files
2. **Never commit `.env`** files (they contain secrets)
3. **Test in a separate environment** before production
4. **Use `run-all plan`** before `run-all apply`
5. **Tag your infrastructure** (Terragrunt does this automatically)
6. **Review state files** regularly
7. **Use workspaces** for different environments if needed

## 📝 Next Steps

1. ✅ Install Terragrunt
2. ✅ Set up environment variables (`.env`)
3. ✅ Initialize backend infrastructure (if not done)
4. ✅ Run `terragrunt run-all init` in production folder
5. ✅ Run `terragrunt run-all plan` to see what will be created
6. ✅ Run `terragrunt run-all apply` to deploy everything
7. ✅ Verify your infrastructure in AWS console

## 🔗 Additional Resources

- [Terragrunt Documentation](https://terragrunt.gruntwork.io/docs/)
- [Terragrunt GitHub](https://github.com/gruntwork-io/terragrunt)
- [Best Practices Guide](https://terragrunt.gruntwork.io/docs/getting-started/quick-start/)

## 💡 Tips

- Use `--terragrunt-log-level debug` for detailed logging
- Run `terragrunt graph-dependencies` to visualize dependencies
- Use `terragrunt validate-all` to check all configurations
- Consider using `terragrunt hclfmt` to format your files

---

**Your infrastructure is now Terragrunt-ready! 🎉**

You can now deploy with confidence knowing that:
- Backend configuration is centralized
- Dependencies are managed automatically
- State files are isolated per module
- Multi-environment deployment is easy
