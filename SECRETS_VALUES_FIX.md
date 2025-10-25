# Secrets Manager Values Not Created - Missing Environment Variables

## Issue Reported

The secret `fast-api-jwt-credentials` is created in AWS Secrets Manager, but when you view it in the AWS Console dashboard, the values are **empty** or **not populated**:

Expected:
```json
{
  "SECRET": "your-jwt-secret-key",
  "ALGORITHM": "HS256",
  "USER_NAME": "admin",
  "PASSWORD": "secure-password",
  "URL_BASE": "https://your-api.com"
}
```

Actual:
```json
{
  "SECRET": "",
  "ALGORITHM": "",
  "USER_NAME": "",
  "PASSWORD": "",
  "URL_BASE": ""
}
```

## Root Cause

The Terragrunt configuration in `terraform/production/secret-manager/terragrunt.hcl` expects the secret values to come from **environment variables**:

```hcl
inputs = {
  secret_key = get_env("TF_VAR_secret_key", "")  # ← Returns "" if not set!
  user_name  = get_env("TF_VAR_user_name", "")
  password   = get_env("TF_VAR_password", "")
  url_base   = get_env("TF_VAR_url_base", "http://localhost:8000")
}
```

However, the GitHub Actions workflow was **NOT setting these environment variables**, so Terragrunt used the default empty strings `""`.

## Solution Applied

### Updated GitHub Actions Workflow

Added environment variables to both the `plan` and `apply` steps in the Secrets Manager job:

```yaml
- name: Provision Secret manager Plan
  working-directory: terraform/production/secret-manager
  env:
    TF_VAR_secret_key: ${{ secrets.JWT_SECRET_KEY }}
    TF_VAR_algorithm: ${{ secrets.JWT_ALGORITHM }}
    TF_VAR_user_name: ${{ secrets.APP_USER_NAME }}
    TF_VAR_password: ${{ secrets.APP_PASSWORD }}
    TF_VAR_url_base: ${{ secrets.APP_URL_BASE }}
  run: terraform plan

- name: Import existing Secrets Manager resources if needed and apply
  working-directory: terraform/production/secret-manager
  env:
    TF_VAR_secret_key: ${{ secrets.JWT_SECRET_KEY }}
    TF_VAR_algorithm: ${{ secrets.JWT_ALGORITHM }}
    TF_VAR_user_name: ${{ secrets.APP_USER_NAME }}
    TF_VAR_password: ${{ secrets.APP_PASSWORD }}
    TF_VAR_url_base: ${{ secrets.APP_URL_BASE }}
  run: |
    # ... import and apply logic
```

## Required GitHub Secrets

You need to create the following secrets in your GitHub repository:

### How to Add GitHub Secrets

1. Go to your GitHub repository
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret** or **New environment secret** (for `prd` environment)
4. Add each of the following secrets:

| Secret Name | Description | Example Value |
|-------------|-------------|---------------|
| `JWT_SECRET_KEY` | Secret key for JWT token signing | `your-super-secret-key-here-min-32-chars` |
| `JWT_ALGORITHM` | JWT algorithm | `HS256` |
| `APP_USER_NAME` | Application username | `admin` or your desired username |
| `APP_PASSWORD` | Application password | `YourSecurePassword123!` |
| `APP_URL_BASE` | Base URL for the API | `https://your-api.example.com` |

### Security Best Practices

✅ **JWT_SECRET_KEY**: Should be at least 32 characters, random, and complex
✅ **APP_PASSWORD**: Use a strong password with letters, numbers, and symbols
✅ **Never commit these values** to git or hardcode them in files

### Example Values for Testing (DO NOT USE IN PRODUCTION!)

```
JWT_SECRET_KEY: "test-secret-key-for-development-only-change-in-production-12345678"
JWT_ALGORITHM: "HS256"
APP_USER_NAME: "admin"
APP_PASSWORD: "Change_Me_In_Production_123!"
APP_URL_BASE: "http://localhost:8000"
```

## Step-by-Step Setup

### 1. Create GitHub Secrets

#### Option A: Repository Secrets (Simpler)
```
Repository → Settings → Secrets and variables → Actions → New repository secret
```

Create all 5 secrets listed above.

#### Option B: Environment Secrets (More Secure - Recommended)
```
Repository → Settings → Environments → prd → Add secret
```

Create all 5 secrets in the `prd` environment (which the workflow already uses).

### 2. Generate Secure Values

#### For JWT_SECRET_KEY (Recommended)
```bash
# Generate a secure random secret key
python3 -c "import secrets; print(secrets.token_urlsafe(32))"

# Or using openssl
openssl rand -base64 32

# Example output: "kj4h5k23jh4k5jh34k5jh34k5jh34kjh5k34jh5k"
```

#### For APP_PASSWORD (Recommended)
```bash
# Generate a secure password
python3 -c "import secrets, string; chars = string.ascii_letters + string.digits + string.punctuation; print(''.join(secrets.choice(chars) for _ in range(16)))"

# Example output: "xY7!mK9$pL3@nQ5#"
```

### 3. Verify Secrets Are Set

After adding secrets, they should appear in the list (values are hidden for security):

```
✅ JWT_SECRET_KEY (set 2 minutes ago)
✅ JWT_ALGORITHM (set 2 minutes ago)
✅ APP_USER_NAME (set 2 minutes ago)
✅ APP_PASSWORD (set 2 minutes ago)
✅ APP_URL_BASE (set 2 minutes ago)
```

### 4. Deploy the Updated Workflow

```bash
# Commit the workflow changes
git add .github/workflows/ci-infrastructure.yaml
git commit -m "Fix: Add environment variables for secret values"
git push

# Run the workflow
# GitHub → Actions → "2 - Provisioning Infrastructure" → Run workflow
```

### 5. Verify in AWS Console

After the workflow completes:

1. Go to **AWS Console** → **Secrets Manager**
2. Click on `fast-api-jwt-credentials`
3. Click **Retrieve secret value**
4. You should now see:

```json
{
  "SECRET": "your-actual-jwt-secret-key",
  "ALGORITHM": "HS256",
  "USER_NAME": "admin",
  "PASSWORD": "your-actual-password",
  "URL_BASE": "https://your-api.example.com"
}
```

## Testing the Fix Locally

If you want to test this locally before pushing:

```bash
cd terraform/production/secret-manager

# Set environment variables
export TF_VAR_secret_key="test-secret-key-for-jwt"
export TF_VAR_algorithm="HS256"
export TF_VAR_user_name="admin"
export TF_VAR_password="test-password"
export TF_VAR_url_base="http://localhost:8000"

# Initialize and plan
terraform init
terraform plan

# You should see the values in the plan (they'll be marked as sensitive)
```

## Alternative: Update Terragrunt Defaults

If you don't want to use GitHub secrets and prefer to use default values, you can update the Terragrunt configuration:

```hcl
# terraform/production/secret-manager/terragrunt.hcl
inputs = {
  secret_key = get_env("TF_VAR_secret_key", "default-secret-key-change-me")
  algorithm  = get_env("TF_VAR_algorithm", "HS256")
  user_name  = get_env("TF_VAR_user_name", "admin")
  password   = get_env("TF_VAR_password", "default-password-change-me")
  url_base   = get_env("TF_VAR_url_base", "http://localhost:8000")
}
```

**⚠️ WARNING**: This is **NOT recommended** for production as it hardcodes sensitive values!

## Troubleshooting

### Issue: Values still empty after workflow runs

**Cause**: GitHub secrets not set or wrong environment
**Solution**:
1. Verify secrets exist: `Settings → Secrets and variables → Actions`
2. Check if using environment secrets - ensure they're in the `prd` environment
3. Re-run the workflow

### Issue: Terraform says "sensitive value"

**Cause**: Normal behavior for sensitive variables
**Solution**: This is correct! Terraform hides sensitive values in logs. Check AWS Console to see actual values.

### Issue: "Error: variable not set"

**Cause**: GitHub secret names don't match workflow
**Solution**: Ensure secret names match exactly:
- `JWT_SECRET_KEY` (not `SECRET_KEY` or `jwt_secret_key`)
- `JWT_ALGORITHM` (not `ALGORITHM`)
- etc.

### Issue: Secret version not updating

**Cause**: Terraform sees no changes if values are the same
**Solution**: If you want to force update:
```bash
# Taint the resource to force recreation
cd terraform/production/secret-manager
terraform taint aws_secretsmanager_secret_version.fast_api_credentials_version
terraform apply
```

## How It Works

### Workflow Execution Flow

```
1. GitHub Actions reads secrets from repository/environment
   ↓
2. Sets environment variables (TF_VAR_*)
   ↓
3. Terragrunt reads environment variables
   ↓
4. Passes values to Terraform variables
   ↓
5. Terraform creates secret version with actual values
   ↓
6. Values stored encrypted in AWS Secrets Manager
```

### Variable Precedence

Terraform/Terragrunt uses this order (highest to lowest priority):

1. Command-line `-var` flags
2. **Environment variables `TF_VAR_*`** ← We use this
3. `terraform.tfvars` file
4. `*.auto.tfvars` files
5. Variable defaults in `.tf` files

## Security Notes

### ✅ Good Practices Applied

- Secrets stored in GitHub Secrets (encrypted at rest)
- Secrets marked as `sensitive = true` in Terraform
- Secrets not logged in GitHub Actions output
- Secrets encrypted in AWS Secrets Manager
- Environment isolation (prd environment)

### ⚠️ Important Reminders

- Never commit secrets to git
- Rotate secrets regularly
- Use different secrets for different environments
- Review who has access to GitHub secrets
- Enable branch protection for production

## Files Modified

- ✅ `.github/workflows/ci-infrastructure.yaml` - Added environment variables
- 📄 `SECRETS_VALUES_FIX.md` - This documentation

## Summary

**Problem**: Secret created but values are empty
**Root Cause**: Terragrunt expected environment variables that weren't set
**Solution**: Added `TF_VAR_*` environment variables to workflow using GitHub secrets
**Action Required**: Create 5 GitHub secrets before running workflow
**Status**: ✅ Code fixed, requires GitHub secrets setup

---
**Last Updated**: October 25, 2025
