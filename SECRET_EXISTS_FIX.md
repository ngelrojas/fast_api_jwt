# Secret Already Exists Fix

## Error Encountered
```
Error: creating Secrets Manager Secret (fast-api-jwt-credentials):
operation error Secrets Manager: CreateSecret,
https response error StatusCode: 400,
RequestID: 9d023435-fafd-46ce-b13e-894041b83f48,
ResourceExistsException: The operation failed because the secret fast-api-jwt-credentials already exists.
```

## Root Cause
The secret `fast-api-jwt-credentials` already exists in AWS, but:
1. It's **not** in the Terraform state
2. The old import logic was failing silently with `|| echo "⚠ Import failed"`
3. Terraform then tried to **create** the secret, which caused the error

## The Problem with the Old Import Logic

### Old Code (Flawed):
```yaml
if terraform state show "aws_secretsmanager_secret.fast_api_credentials" &>/dev/null; then
  echo "✓ Secret already in Terraform state"
else
  echo "→ Secret not in state, attempting import..."
  terraform import aws_secretsmanager_secret.fast_api_credentials fast-api-jwt-credentials || echo "⚠ Import failed or resource doesn't exist, will try to create"
fi
```

**Issues:**
- ❌ Doesn't check if secret **actually exists in AWS** before importing
- ❌ Uses `|| echo` which silently ignores import failures
- ❌ Doesn't import the secret **version** (only imports the secret metadata)
- ❌ Terraform proceeds to `apply` even when import fails
- ❌ Results in "ResourceExistsException" error

## Solution Applied

### New Code (Robust):
```yaml
# Check if secret exists in AWS first
SECRET_EXISTS=$(aws secretsmanager describe-secret --secret-id fast-api-jwt-credentials 2>/dev/null && echo "yes" || echo "no")

if [ "$SECRET_EXISTS" = "yes" ]; then
  echo "→ Secret exists in AWS"

  # Import secret if not in state
  if terraform state show "aws_secretsmanager_secret.fast_api_credentials" &>/dev/null; then
    echo "✓ Secret already in Terraform state"
  else
    echo "→ Secret not in Terraform state, importing..."
    terraform import aws_secretsmanager_secret.fast_api_credentials fast-api-jwt-credentials || {
      echo "⚠ Import failed. This might be a state issue."
      exit 1
    }
  fi

  # Import secret version if not in state
  if terraform state show "aws_secretsmanager_secret_version.fast_api_credentials_version" &>/dev/null; then
    echo "✓ Secret version already in Terraform state"
  else
    echo "→ Secret version not in Terraform state, importing..."
    SECRET_ARN=$(aws secretsmanager describe-secret --secret-id fast-api-jwt-credentials --query 'ARN' --output text)
    terraform import "aws_secretsmanager_secret_version.fast_api_credentials_version" "${SECRET_ARN}|AWSCURRENT" || {
      echo "⚠ Secret version import failed, will be managed on next apply"
    }
  fi
else
  echo "→ Secret doesn't exist in AWS, will be created"
fi
```

**Improvements:**
- ✅ **Checks AWS first** - Uses `aws secretsmanager describe-secret` to verify existence
- ✅ **Fails fast** - Import failures cause immediate exit with `exit 1`
- ✅ **Imports both** - Imports secret metadata AND secret version
- ✅ **Proper error handling** - Uses `{ }` block to handle failures correctly
- ✅ **Clear logging** - Shows exactly what's happening at each step

## How It Works Now

### Scenario 1: Secret Exists in AWS, Not in State (Your Case)
```
1. ✅ Check AWS → Secret found
2. ✅ Check Terraform state → Not found
3. ✅ Import secret → Success
4. ✅ Check secret version state → Not found
5. ✅ Get secret ARN from AWS
6. ✅ Import secret version → Success or graceful handling
7. ✅ Apply changes → Updates state, no creation attempt
```

### Scenario 2: Secret Exists in Both AWS and State
```
1. ✅ Check AWS → Secret found
2. ✅ Check Terraform state → Found
3. ✅ Skip import
4. ✅ Apply changes → No issues
```

### Scenario 3: Secret Doesn't Exist Anywhere (Fresh Deploy)
```
1. ✅ Check AWS → Secret not found
2. ✅ Log: "Secret doesn't exist in AWS, will be created"
3. ✅ Apply changes → Creates new secret
```

## Understanding Secret Version Import

The secret version import uses a special format:
```bash
terraform import aws_secretsmanager_secret_version.resource_name "SECRET_ARN|VERSION_STAGE"
```

Example:
```bash
terraform import aws_secretsmanager_secret_version.fast_api_credentials_version \
  "arn:aws:secretsmanager:us-east-1:123456789:secret:fast-api-jwt-credentials-AbCdEf|AWSCURRENT"
```

- `SECRET_ARN` - The full ARN of the secret
- `|` - Pipe separator (required)
- `AWSCURRENT` - The version stage (usually AWSCURRENT for active version)

## Deploy the Fix

### Option 1: Via GitHub Actions (Recommended)
```bash
git add .github/workflows/ci-infrastructure.yaml
git commit -m "Fix: Improve Secrets Manager import logic to handle existing secrets"
git push

# Run workflow: Actions → "2 - Provisioning Infrastructure" → Run workflow
```

### Option 2: Manual Import (Quick Fix)
If you need to fix this immediately without rerunning the workflow:

```bash
cd terraform/production/secret-manager
terraform init

# Import the secret
terraform import aws_secretsmanager_secret.fast_api_credentials fast-api-jwt-credentials

# Get the secret ARN
SECRET_ARN=$(aws secretsmanager describe-secret --secret-id fast-api-jwt-credentials --query 'ARN' --output text)

# Import the secret version
terraform import aws_secretsmanager_secret_version.fast_api_credentials_version "${SECRET_ARN}|AWSCURRENT"

# Now plan and apply will work
terraform plan
terraform apply
```

## Verification

After the fix is deployed, verify the import:

### Check Terraform State
```bash
cd terraform/production/secret-manager

# List all resources in state
terraform state list

# Should show:
# aws_secretsmanager_secret.fast_api_credentials
# aws_secretsmanager_secret_version.fast_api_credentials_version
```

### Verify Secret Details
```bash
# Check the secret
terraform state show aws_secretsmanager_secret.fast_api_credentials

# Check the version
terraform state show aws_secretsmanager_secret_version.fast_api_credentials_version
```

### Test Plan (Should show no changes)
```bash
terraform plan
# Expected: "No changes. Your infrastructure matches the configuration."
```

## Troubleshooting

### Issue: Import still fails with "ResourceNotFoundException"
**Cause**: Secret doesn't actually exist or name is wrong
**Solution**: Check the secret name in AWS Console or CLI:
```bash
aws secretsmanager list-secrets --query 'SecretList[?Name==`fast-api-jwt-credentials`]'
```

### Issue: Import fails with "already managed by Terraform"
**Cause**: Secret is already in state
**Solution**: Skip the import, just run apply:
```bash
terraform apply
```

### Issue: Secret version import fails
**Cause**: Secret has no current version or ARN format is wrong
**Solution**: Check the secret has a value:
```bash
aws secretsmanager get-secret-value --secret-id fast-api-jwt-credentials
```

### Issue: "MissingRegion" error
**Cause**: AWS region not configured
**Solution**: Ensure AWS credentials are configured in the workflow (already done)

## Why Both Resources Need Import

Secrets Manager has two separate resources:

1. **aws_secretsmanager_secret** - The secret container (metadata)
   - Name, description, tags, KMS key, etc.
   - Can exist without a value

2. **aws_secretsmanager_secret_version** - The actual secret value
   - The encrypted data
   - Version stages (AWSCURRENT, AWSPENDING, etc.)
   - Can have multiple versions

Both must be imported for Terraform to fully manage the secret.

## Best Practices Applied

✅ **Check before import** - Verify resource exists in AWS
✅ **Fail fast** - Don't continue on import errors
✅ **Import both resources** - Secret + Version
✅ **Clear error messages** - Help debug issues
✅ **Graceful degradation** - Secret version import can fail without blocking

## Files Modified
- ✅ `.github/workflows/ci-infrastructure.yaml` - Improved Secrets Manager import logic
- 📄 `SECRET_EXISTS_FIX.md` - This documentation

---
**Issue**: Secret already exists, import was failing silently
**Fixed**: Robust import with AWS existence check + secret version import
**Status**: ✅ Ready to deploy
**Last Updated**: October 25, 2025
