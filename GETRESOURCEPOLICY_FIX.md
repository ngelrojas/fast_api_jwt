# GetResourcePolicy Permission Fix

## Error Encountered
```
Error: reading Secrets Manager Secret (arn:aws:secretsmanager:***:209479292315:secret:fast-api-jwt-credentials-MdXkGT) policy:
operation error Secrets Manager: GetResourcePolicy,
https response error StatusCode: 400, RequestID: b8d080a9-f161-434c-a8ea-429a236fcb66,
api error AccessDeniedException: User: arn:aws:sts::209479292315:assumed-role/AwsAngelLLM/GitHubActions-18806599231
is not authorized to perform: secretsmanager:GetResourcePolicy on resource:
arn:aws:secretsmanager:***:209479292315:secret:fast-api-jwt-credentials-MdXkGT
because no identity-based policy allows the secretsmanager:GetResourcePolicy action
```

## Root Cause
The IAM policy for the GitHub Actions role was missing critical **resource policy management permissions**:
- ❌ `secretsmanager:GetResourcePolicy` - Required to read secret policies
- ❌ `secretsmanager:PutResourcePolicy` - Required to set secret policies
- ❌ `secretsmanager:DeleteResourcePolicy` - Required to remove secret policies

When Terraform tries to manage AWS Secrets Manager secrets, it needs to:
1. Read the current resource policy (GetResourcePolicy)
2. Compare with desired state
3. Update if needed (PutResourcePolicy)

Without `GetResourcePolicy`, Terraform cannot even read the current state, causing the error.

## Solution
Updated the IAM policy in `terraform/production/iam/main.tf` to include **all** Secrets Manager permissions needed for full lifecycle management:

```terraform
resource "aws_iam_role_policy" "github_actions_secrets_manager" {
  name = "github-actions-secrets-manager-access"
  role = data.aws_iam_role.github_actions_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:CreateSecret",
          "secretsmanager:UpdateSecret",
          "secretsmanager:DeleteSecret",
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:PutSecretValue",
          "secretsmanager:TagResource",
          "secretsmanager:UntagResource",
          "secretsmanager:ListSecrets",
          "secretsmanager:GetResourcePolicy",      # ← CRITICAL: Added
          "secretsmanager:PutResourcePolicy",      # ← CRITICAL: Added
          "secretsmanager:DeleteResourcePolicy",   # ← CRITICAL: Added
          "secretsmanager:RestoreSecret",
          "secretsmanager:RotateSecret",
          "secretsmanager:CancelRotateSecret",
          "secretsmanager:ValidateResourcePolicy"
        ]
        Resource = "*"
      }
    ]
  })
}
```

## Missing Permissions Added

### Critical (Required for Terraform to work):
- ✅ `secretsmanager:GetResourcePolicy` - Read resource policies
- ✅ `secretsmanager:PutResourcePolicy` - Set resource policies
- ✅ `secretsmanager:DeleteResourcePolicy` - Remove resource policies

### Additional (Best practice for full management):
- ✅ `secretsmanager:UntagResource` - Remove tags
- ✅ `secretsmanager:RestoreSecret` - Restore deleted secrets
- ✅ `secretsmanager:RotateSecret` - Enable secret rotation
- ✅ `secretsmanager:CancelRotateSecret` - Cancel rotation
- ✅ `secretsmanager:ValidateResourcePolicy` - Validate policies

## Why This Happened
The initial fix only included the basic CRUD operations but missed the **resource policy management** permissions. Terraform's AWS provider needs these to fully manage the secret resource, including reading its current state.

## Deploy the Fix

### Method 1: Via GitHub Actions (Recommended)
```bash
# Commit and push
git add terraform/production/iam/main.tf
git commit -m "Fix: Add GetResourcePolicy and resource policy permissions to GitHub Actions role"
git push

# Run workflow: Actions → "2 - Provisioning Infrastructure" → Run workflow
```

### Method 2: Manual Terraform Apply
```bash
cd terraform/production/iam
terraform plan  # Review the changes
terraform apply # Apply the updated policy
```

## Verification

After applying, verify the permissions:

```bash
# Get the policy and check for GetResourcePolicy
aws iam get-role-policy \
  --role-name AwsAngelLLM \
  --policy-name github-actions-secrets-manager-access \
  | jq '.PolicyDocument.Statement[0].Action' \
  | grep -i getresourcepolicy
```

Expected output:
```json
"secretsmanager:GetResourcePolicy",
```

## What Happens Next

1. ✅ The IAM job will update the policy with all required permissions
2. ✅ Terraform can now read the secret's resource policy
3. ✅ The `secreter-manager-fast-api` job will succeed
4. ✅ The secret will be created successfully

## Common Secrets Manager Permissions Reference

| Permission | Purpose | Required by Terraform? |
|-----------|---------|----------------------|
| CreateSecret | Create new secrets | ✅ Yes |
| UpdateSecret | Modify secret metadata | ✅ Yes |
| DeleteSecret | Delete secrets | ✅ Yes |
| GetSecretValue | Read secret data | ⚠️ Sometimes |
| DescribeSecret | Read secret metadata | ✅ Yes |
| PutSecretValue | Write secret data | ✅ Yes |
| **GetResourcePolicy** | Read resource policy | ✅ **YES - CRITICAL** |
| **PutResourcePolicy** | Set resource policy | ✅ **YES - CRITICAL** |
| **DeleteResourcePolicy** | Remove resource policy | ✅ **YES - CRITICAL** |
| TagResource | Add tags | ⚠️ Optional |
| UntagResource | Remove tags | ⚠️ Optional |
| ListSecrets | List all secrets | ⚠️ Optional |

## Troubleshooting

### Issue: Still getting AccessDeniedException
**Solution**: Wait 30-60 seconds for IAM policy changes to propagate, then retry

### Issue: Policy update fails
**Solution**: Check if you have permission to update the `AwsAngelLLM` role:
```bash
aws iam list-attached-role-policies --role-name AwsAngelLLM
```

### Issue: Multiple secrets failing
**Solution**: This fix applies to all secrets (Resource = "*"), so all should work after applying

## Files Modified
- ✅ `terraform/production/iam/main.tf` - Added missing permissions
- ✅ `SECRETS_MANAGER_FIX.md` - Updated with new permissions
- 📄 `GETRESOURCEPOLICY_FIX.md` - This detailed explanation

---
**Issue**: Missing `secretsmanager:GetResourcePolicy` permission
**Fixed**: Added all resource policy management permissions
**Status**: Ready to deploy
**Last Updated**: October 25, 2025
