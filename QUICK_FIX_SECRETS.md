# Quick Fix for "Secret Already Exists" Error

## If you see this error again:

```
Error: creating Secrets Manager Secret (fast-api-jwt-app): operation error Secrets Manager: CreateSecret,
https response error StatusCode: 400, RequestID: ...,
ResourceExistsException: The operation failed because the secret fast-api-jwt-app already exists.
```

## Quick Manual Fix

Run this from your terminal:

```bash
cd terraform/production/secret-manager
./fix-secret-state.sh
```

That's it! The script will automatically fix the state.

## What the fix does:

1. ✅ Checks if secret exists in AWS
2. ✅ Removes corrupted Terraform state
3. ✅ Re-imports the secret properly
4. ✅ Verifies everything is working

## Or Fix via GitHub Actions:

The CI/CD workflow has been updated and will now automatically:
- Refresh state before checking
- Clean up corrupted state
- Import with correct secret ID (`fast-api-jwt-app`)
- Pass all variables to apply

Just re-run the failed workflow and it should work now!

## Root Cause (Fixed):

The workflow was using wrong secret ID `fast-api-jwt-credentials` instead of `fast-api-jwt-app` when importing the secret version. This is now fixed in:
- `.github/workflows/ci-infrastructure.yaml` (line 331)

## Files Fixed:

1. ✅ `.github/workflows/ci-infrastructure.yaml` - Corrected secret ID and added proper state management
2. ✅ `terraform/production/secret-manager/main.tf` - Added import block
3. ✅ `terraform/production/secret-manager/fix-secret-state.sh` - Manual fix script

See `SECRETS_MANAGER_IMPORT_FIX.md` for detailed explanation.
