# Secrets Manager Permission Fix

## Problem
GitHub Actions workflow was failing with the following error:
```
Error: creating Secrets Manager Secret (fast-api-jwt-credentials): operation error Secrets Manager: CreateSecret,
https response error StatusCode: 400, RequestID: d5a2e5b5-b389-44ac-999e-33d3ae797061,
api error AccessDeniedException: User: arn:aws:sts::209479292315:assumed-role/AwsAngelLLM/GitHubActions-18806446343
is not authorized to perform: secretsmanager:CreateSecret on resource: fast-api-jwt-credentials
because no identity-based policy allows the secretsmanager:CreateSecret action
```

## Root Cause
The IAM role `AwsAngelLLM` (used by GitHub Actions via OIDC) did not have permissions to create or manage AWS Secrets Manager secrets.

## Solution Applied
Added Secrets Manager permissions to the GitHub Actions OIDC role by:

1. **Updated `terraform/production/iam/variables.tf`**:
   - Added `github_actions_role_name` variable with default value "AwsAngelLLM"

2. **Updated `terraform/production/iam/main.tf`**:
   - Added data source to reference the existing GitHub Actions OIDC role
   - Created inline IAM policy `github_actions_secrets_manager` with the following permissions:
     - `secretsmanager:CreateSecret`
     - `secretsmanager:UpdateSecret`
     - `secretsmanager:DeleteSecret`
     - `secretsmanager:GetSecretValue`
     - `secretsmanager:DescribeSecret`
     - `secretsmanager:PutSecretValue`
     - `secretsmanager:TagResource`
     - `secretsmanager:UntagResource`
     - `secretsmanager:ListSecrets`
     - `secretsmanager:GetResourcePolicy` ⭐ **Critical for reading secret policies**
     - `secretsmanager:PutResourcePolicy`
     - `secretsmanager:DeleteResourcePolicy`
     - `secretsmanager:RestoreSecret`
     - `secretsmanager:RotateSecret`
     - `secretsmanager:CancelRotateSecret`
     - `secretsmanager:ValidateResourcePolicy`

3. **Updated `.github/workflows/ci-infrastructure.yaml`**:
   - The workflow already handles the IAM job which will now apply these new permissions

## How to Deploy the Fix

### Step 1: Commit and Push Changes
```bash
git add terraform/production/iam/main.tf terraform/production/iam/variables.tf .github/workflows/ci-infrastructure.yaml
git commit -m "Fix: Add Secrets Manager permissions to GitHub Actions OIDC role"
git push
```

### Step 2: Run the Workflow
1. Go to your repository on GitHub
2. Navigate to **Actions** → **2 - Provisioning Infrastructure**
3. Click **Run workflow**
4. The IAM job will run first and attach the new permissions
5. The `secreter-manager-fast-api` job will then succeed with the new permissions

## Alternative Manual Fix (If Needed)

If you need to fix this immediately without running the full workflow, you can manually apply just the IAM changes:

```bash
cd terraform/production/iam
terraform init
terraform plan
terraform apply
```

This will attach the Secrets Manager policy to the `AwsAngelLLM` role.

## What Was Changed

### Permissions Added
The GitHub Actions role now has full Secrets Manager permissions, allowing it to:
- ✅ Create secrets
- ✅ Update secrets
- ✅ Delete secrets
- ✅ Read secret values
- ✅ Describe secrets
- ✅ Tag/Untag secrets
- ✅ List secrets
- ✅ **Get/Put/Delete resource policies** (Critical!)
- ✅ Restore secrets
- ✅ Rotate secrets
- ✅ Validate policies

### Security Considerations
- The policy uses `Resource = "*"` which means it can manage all secrets in the account
- If you want to restrict this to specific secrets, you can change the Resource to:
  ```json
  "Resource": [
    "arn:aws:secretsmanager:*:*:secret:fast-api-jwt-credentials-*",
    "arn:aws:secretsmanager:*:*:secret:other-allowed-secret-*"
  ]
  ```

## Verification

After deploying, verify the fix by:

1. Check the IAM role in AWS Console:
   - Navigate to IAM → Roles → AwsAngelLLM
   - Look for the `github-actions-secrets-manager-access` policy

2. Re-run the failed workflow:
   - The `secreter-manager-fast-api` job should now succeed

3. Verify the secret was created:
   ```bash
   aws secretsmanager describe-secret --secret-id fast-api-jwt-credentials
   ```

## Troubleshooting

If the issue persists:

1. **Verify the role name**: Ensure `AwsAngelLLM` is the correct role name
   ```bash
   aws sts get-caller-identity
   ```

2. **Check if policy was attached**:
   ```bash
   aws iam get-role-policy --role-name AwsAngelLLM --policy-name github-actions-secrets-manager-access
   ```

3. **Verify Terraform state**:
   ```bash
   cd terraform/production/iam
   terraform state list | grep github_actions
   ```

## Next Steps

After the fix is deployed:
- ✅ The workflow will successfully create the `fast-api-jwt-credentials` secret
- ✅ The EC2 instances will be able to retrieve these credentials
- ✅ Future runs will maintain proper permissions

---
**Last Updated**: October 25, 2025
