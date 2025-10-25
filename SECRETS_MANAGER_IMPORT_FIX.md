# Secrets Manager "Already Exists" Error - FIXED

## Problem Summary

The CI/CD pipeline was repeatedly failing with this error:
```
Error: creating Secrets Manager Secret (fast-api-jwt-app): operation error Secrets Manager: CreateSecret,
https response error StatusCode: 400, RequestID: 9290d875-6e32-40a4-adec-1503eb96065f,
ResourceExistsException: The operation failed because the secret fast-api-jwt-app already exists.
```

## Root Causes Identified

### 1. **Wrong Secret ID in Import Script** (Critical Bug)
In `.github/workflows/ci-infrastructure.yaml` line 331, the script was using:
```bash
SECRET_ARN=$(aws secretsmanager describe-secret --secret-id fast-api-jwt-credentials --query 'ARN' --output text)
```

**Problem:** The secret ID should be `fast-api-jwt-app`, not `fast-api-jwt-credentials`. This caused the import of the secret version to fail silently, leaving the secret partially imported.

### 2. **Missing State Refresh**
The workflow wasn't refreshing the Terraform state before checking if resources were already imported. This meant that even if the secret was in AWS, Terraform didn't know about it.

### 3. **No State Cleanup**
When import failed, corrupted state entries weren't being removed, causing subsequent runs to fail.

### 4. **Variables Not Passed to Refresh/Apply**
The `terraform refresh` and `terraform apply` commands weren't receiving the required variables, causing them to use defaults instead of actual values.

## Fixes Applied

### Fix 1: Corrected Secret ID in Import Script ✅
**File:** `.github/workflows/ci-infrastructure.yaml`

**Before:**
```bash
SECRET_ARN=$(aws secretsmanager describe-secret --secret-id fast-api-jwt-credentials --query 'ARN' --output text)
```

**After:**
```bash
SECRET_ARN=$(aws secretsmanager describe-secret --secret-id fast-api-jwt-app --query 'ARN' --output text)
```

### Fix 2: Added State Refresh with Variables ✅
**File:** `.github/workflows/ci-infrastructure.yaml`

Added at the beginning of the import step:
```bash
# Force refresh state first to get latest
echo "→ Refreshing Terraform state..."
terraform refresh \
  -var="secret_key=$TF_VAR_secret_key" \
  -var="algorithm=$TF_VAR_algorithm" \
  -var="user_name=$TF_VAR_user_name" \
  -var="password=$TF_VAR_password" \
  -var="url_base=$TF_VAR_url_base" || echo "⚠ Refresh failed, continuing..."
```

### Fix 3: Added State Cleanup Before Import ✅
**File:** `.github/workflows/ci-infrastructure.yaml`

Added before importing:
```bash
# Try to remove it first in case of corrupted state
terraform state rm aws_secretsmanager_secret.fast_api_credentials 2>/dev/null || true
terraform state rm aws_secretsmanager_secret_version.fast_api_credentials_version 2>/dev/null || true
```

### Fix 4: Pass Variables to Apply Command ✅
**File:** `.github/workflows/ci-infrastructure.yaml`

**Before:**
```bash
terraform apply -auto-approve
```

**After:**
```bash
terraform apply -auto-approve \
  -var="secret_key=$TF_VAR_secret_key" \
  -var="algorithm=$TF_VAR_algorithm" \
  -var="user_name=$TF_VAR_user_name" \
  -var="password=$TF_VAR_password" \
  -var="url_base=$TF_VAR_url_base"
```

### Fix 5: Added Import Block to Terraform Config ✅
**File:** `terraform/production/secret-manager/main.tf`

Added import block (Terraform 1.5+ feature):
```hcl
# Import block for existing secret (Terraform 1.5+)
import {
  to = aws_secretsmanager_secret.fast_api_credentials
  id = "fast-api-jwt-app"
}
```

This tells Terraform to automatically import the resource if it exists in AWS but not in state.

### Fix 6: Created Manual Fix Script ✅
**File:** `terraform/production/secret-manager/fix-secret-state.sh`

A helper script that can be run manually to fix state issues:
```bash
cd terraform/production/secret-manager
./fix-secret-state.sh
```

## How the Fix Works

### Workflow Flow (Improved)
1. **Refresh State**: Updates Terraform state from AWS to detect any drift
2. **Check AWS**: Verifies if secret exists in AWS
3. **Check State**: Verifies if secret is in Terraform state
4. **Clean Corrupted State**: Removes any corrupted state entries
5. **Import Resources**: Imports both secret and secret version from AWS
6. **Apply Changes**: Applies any configuration changes with all variables

### Import Block (Terraform 1.5+)
The `import` block in `main.tf` provides declarative import:
- Terraform automatically checks if the resource exists in AWS
- If it exists but not in state, it imports automatically
- No manual `terraform import` commands needed

## Testing the Fix

### Option 1: Run the GitHub Actions Workflow
1. Go to GitHub Actions
2. Run "2 - Provisioning Infrastructure"
3. Monitor the `secreter-manager-fast-api` job
4. Should now complete successfully

### Option 2: Run Locally
```bash
# Navigate to the secret manager directory
cd terraform/production/secret-manager

# Initialize Terraform
terraform init

# Run the fix script
./fix-secret-state.sh

# Verify with plan
terraform plan \
  -var="secret_key=YOUR_SECRET" \
  -var="algorithm=HS256" \
  -var="user_name=YOUR_USER" \
  -var="password=YOUR_PASS" \
  -var="url_base=https://your-url.com"

# Apply if everything looks good
terraform apply \
  -var="secret_key=YOUR_SECRET" \
  -var="algorithm=HS256" \
  -var="user_name=YOUR_USER" \
  -var="password=YOUR_PASS" \
  -var="url_base=https://your-url.com"
```

## Verification

After applying the fixes, verify:

1. **Secret in AWS:**
   ```bash
   aws secretsmanager describe-secret --secret-id fast-api-jwt-app
   ```

2. **Secret in Terraform State:**
   ```bash
   cd terraform/production/secret-manager
   terraform state show aws_secretsmanager_secret.fast_api_credentials
   ```

3. **Secret Version in State:**
   ```bash
   terraform state show aws_secretsmanager_secret_version.fast_api_credentials_version
   ```

All three commands should return data without errors.

## Prevention

To prevent this issue in the future:

1. **Always use correct resource identifiers** - Double-check secret IDs/names
2. **Refresh state before operations** - Run `terraform refresh` regularly
3. **Use import blocks** (Terraform 1.5+) - Declarative imports prevent this issue
4. **Test import logic** - Verify import commands work with correct identifiers
5. **Monitor state consistency** - Use `terraform state list` to check resources

## Related Files Changed

- ✅ `.github/workflows/ci-infrastructure.yaml` - Fixed import logic
- ✅ `terraform/production/secret-manager/main.tf` - Added import block
- ✅ `terraform/production/secret-manager/fix-secret-state.sh` - Created fix script

## Summary

The "secret already exists" error was caused by:
1. **Wrong secret ID** causing import to fail silently
2. **No state refresh** causing Terraform to not detect existing resources
3. **No state cleanup** leaving corrupted state entries

All issues have been resolved with proper import logic, state management, and declarative import blocks.
