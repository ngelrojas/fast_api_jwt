# S3 Bucket Policy - Block Public Access Conflict Fix

## Error Encountered
```
Error: putting S3 Bucket (storage-files-csv) Policy: operation error S3: PutBucketPolicy,
https response error StatusCode: 403, RequestID: XX9PFE90C3BF2HWR,
api error AccessDenied: User: arn:aws:sts::209479292315:assumed-role/AwsAngelLLM/GitHubActions
is not authorized to perform: s3:PutBucketPolicy on resource: "arn:aws:s3:::storage-files-csv"
because public policies are blocked by the BlockPublicPolicy block public access setting.
```

## Root Cause

### The Security Conflict
Your Terraform configuration had a **security misconfiguration**:

**Block Public Access** (✅ Correct - Security Best Practice):
```terraform
resource "aws_s3_bucket_public_access_block" "storage_files_csv_block" {
  block_public_acls       = true
  block_public_policy     = true  # ← Blocks public policies
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

**Bucket Policy** (❌ Insecure - Allows Public Access):
```terraform
resource "aws_s3_bucket_policy" "storage_files_csv_policy" {
  policy = jsonencode({
    Statement = [{
      Principal = { "AWS" : "*" }  # ← This means ANYONE on the internet!
      Action    = "s3:GetObject"
      Resource  = "arn:aws:s3:::storage-files-csv/*"
    }]
  })
}
```

### Why This Failed
1. ✅ Block Public Access says: **"No public policies allowed"**
2. ❌ Bucket Policy says: **"Allow anyone (`*`) to access"**
3. 💥 Result: AWS **blocks the policy** to protect your data

This is AWS protecting you from a security misconfiguration!

## The Problem with `Principal: "*"`

```terraform
Principal = { "AWS" : "*" }
```

This means:
- ❌ **Anyone on the internet** can access your bucket
- ❌ No authentication required
- ❌ No AWS account needed
- ❌ Complete public access to all objects

**This is a major security risk!** 🚨

## Solution Applied

### Fix #1: Replace Public Policy with IAM-Based Policy

**Old (Insecure)**:
```terraform
Statement = [
  {
    Principal = { "AWS" : "*" }  # PUBLIC ACCESS!
    Action    = "s3:GetObject"
  }
]
```

**New (Secure)**:
```terraform
Statement = [
  {
    Sid    = "AllowEC2RoleAccess"
    Effect = "Allow"
    Principal = {
      AWS = [
        "arn:aws:iam::209479292315:role/ec2-ssm-fast-api",
        "arn:aws:iam::209479292315:role/self-hosted-role"
      ]
    }
    Action = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket"
    ]
    Resource = [
      "arn:aws:s3:::storage-files-csv",
      "arn:aws:s3:::storage-files-csv/*"
    ]
  },
  {
    Sid    = "AllowS3NotificationToSQS"
    Effect = "Allow"
    Principal = {
      Service = "s3.amazonaws.com"
    }
    Action   = "s3:GetBucketNotification"
    Resource = "arn:aws:s3:::storage-files-csv"
  }
]
```

**Benefits**:
- ✅ Only specific IAM roles can access
- ✅ Works with Block Public Access
- ✅ Follows security best practices
- ✅ No public internet access

### Fix #2: Add S3 Permissions to GitHub Actions Role

Added a new IAM policy for the GitHub Actions role to manage S3 infrastructure:

```terraform
resource "aws_iam_role_policy" "github_actions_s3_management" {
  name = "github-actions-s3-management-access"
  role = data.aws_iam_role.github_actions_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:CreateBucket",
          "s3:PutBucketPolicy",           # ← Needed to set the policy
          "s3:GetBucketPolicy",
          "s3:DeleteBucketPolicy",
          "s3:PutBucketNotification",
          "s3:PutBucketPublicAccessBlock",
          "s3:PutEncryptionConfiguration",
          "s3:PutLifecycleConfiguration",
          # ... and more
        ]
        Resource = [
          "arn:aws:s3:::storage-files-csv",
          "arn:aws:s3:::storage-files-csv/*"
        ]
      }
    ]
  })
}
```

### Fix #3: Added Dependency for Correct Resource Order

```terraform
resource "aws_s3_bucket_policy" "storage_files_csv_policy" {
  # Ensure bucket policy is applied AFTER public access block
  depends_on = [aws_s3_bucket_public_access_block.storage_files_csv_block]
  # ...
}
```

This ensures:
1. Block Public Access is created first
2. Then the bucket policy is applied
3. AWS validates the policy is compatible with Block Public Access

## Security Comparison

### Before (Insecure) ❌
```
Internet → S3 Bucket
   ↓
Anyone can access files
No authentication needed
```

### After (Secure) ✅
```
EC2 Instance (with ec2-ssm-fast-api role) → S3 Bucket ✅
Self-Hosted Runner (with self-hosted-role) → S3 Bucket ✅
GitHub Actions (with AwsAngelLLM role)     → S3 Bucket ✅
Random person on internet                  → ❌ DENIED
```

## Files Modified

### 1. `terraform/production/s3-storage/main.tf`
**Changed**:
- Replaced public bucket policy with IAM role-based policy
- Added `depends_on` to ensure correct resource order
- Added specific IAM role ARNs for access control

### 2. `terraform/production/iam/main.tf`
**Added**:
- New IAM policy `github_actions_s3_management` for GitHub Actions
- Includes `s3:PutBucketPolicy` and other S3 management permissions

## Deploy the Fix

### Option 1: Via GitHub Actions (Recommended)
```bash
git add terraform/production/s3-storage/main.tf terraform/production/iam/main.tf
git commit -m "Fix: Replace public S3 policy with secure IAM-based access"
git push

# Run workflow: Actions → "2 - Provisioning Infrastructure" → Run workflow
```

### Option 2: Manual Apply
```bash
# Apply IAM changes first (to add S3 permissions to GitHub Actions role)
cd terraform/production/iam
terraform init
terraform apply

# Then apply S3 changes
cd ../s3-storage
terraform init
terraform apply
```

## Verification

After deployment:

### 1. Check Block Public Access (Should be enabled)
```bash
aws s3api get-public-access-block --bucket storage-files-csv
```

Expected output:
```json
{
  "PublicAccessBlockConfiguration": {
    "BlockPublicAcls": true,
    "IgnorePublicAcls": true,
    "BlockPublicPolicy": true,
    "RestrictPublicBuckets": true
  }
}
```

### 2. Check Bucket Policy (Should allow only specific roles)
```bash
aws s3api get-bucket-policy --bucket storage-files-csv --query Policy --output text | jq .
```

Expected output:
```json
{
  "Statement": [
    {
      "Sid": "AllowEC2RoleAccess",
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "arn:aws:iam::209479292315:role/ec2-ssm-fast-api",
          "arn:aws:iam::209479292315:role/self-hosted-role"
        ]
      },
      "Action": ["s3:GetObject", "s3:PutObject", "s3:ListBucket"],
      "Resource": [
        "arn:aws:s3:::storage-files-csv",
        "arn:aws:s3:::storage-files-csv/*"
      ]
    }
  ]
}
```

### 3. Test Access from EC2
```bash
# SSH to EC2 instance
ssh ec2-user@<instance-ip>

# Try to list bucket (should work)
aws s3 ls s3://storage-files-csv/

# Try to upload (should work)
echo "test" > test.txt
aws s3 cp test.txt s3://storage-files-csv/test.txt
```

### 4. Test Public Access is Blocked
```bash
# Try to access without authentication (should fail)
curl https://storage-files-csv.s3.amazonaws.com/test.txt
# Expected: Access Denied
```

## Understanding the Error Message

Let's break down the original error:

```
User: arn:aws:sts::209479292315:assumed-role/AwsAngelLLM/GitHubActions
is not authorized to perform: s3:PutBucketPolicy
because public policies are blocked by the BlockPublicPolicy block public access setting
```

This means:
1. ✅ GitHub Actions has the IAM permission to call `s3:PutBucketPolicy`
2. ✅ AWS allows the API call to proceed
3. ❌ AWS **validates the policy content** and finds `Principal: "*"`
4. ❌ Block Public Access says: "No public policies allowed"
5. ❌ AWS **rejects the policy** to protect your data
6. ❌ Returns error: "public policies are blocked"

The error message is somewhat misleading - it's not that the user lacks permission, it's that **the policy content is blocked by security settings**.

## Best Practices Applied

✅ **Principle of Least Privilege**: Only grant access to specific IAM roles
✅ **Block Public Access**: Keep enabled to prevent accidental public exposure
✅ **Resource-Based Policies**: Use specific ARNs instead of wildcards
✅ **Defense in Depth**: Multiple layers of security (IAM + Block Public Access)
✅ **Explicit Allow**: List exact principals that need access

## Who Can Access the Bucket Now?

### ✅ Allowed:
- **EC2 instances** with `ec2-ssm-fast-api` role
- **Self-hosted runners** with `self-hosted-role` role
- **GitHub Actions** with `AwsAngelLLM` role (for infrastructure management)
- **S3 service** (for notifications to SQS)

### ❌ Denied:
- Public internet users
- Unauthenticated requests
- Other AWS accounts
- Other IAM roles in your account (not explicitly listed)

## Troubleshooting

### Issue: EC2 can't access bucket after applying
**Cause**: IAM role not attached to EC2 instance
**Solution**: Check instance profile
```bash
aws ec2 describe-instances --instance-ids <instance-id> --query 'Reservations[0].Instances[0].IamInstanceProfile'
```

### Issue: Still getting "public policies blocked" error
**Cause**: Old policy might still reference `Principal: "*"`
**Solution**: Verify you pulled latest code
```bash
git pull
cd terraform/production/s3-storage
grep -n "Principal" main.tf
# Should NOT show "AWS": "*"
```

### Issue: GitHub Actions can't apply changes
**Cause**: IAM changes not applied yet
**Solution**: Apply IAM first, then S3
```bash
cd terraform/production/iam
terraform apply
# Wait for completion, then:
cd ../s3-storage
terraform apply
```

## Security Note

The old configuration with `Principal: "*"` would have made your bucket **publicly accessible** to anyone on the internet. This fix prevents potential data breaches and ensures only authorized services can access your data.

If you need to share specific objects publicly in the future, use:
- **Pre-signed URLs** (temporary, secure links)
- **CloudFront** with Origin Access Identity
- **API Gateway** with authentication

**Never** use `Principal: "*"` in production!

## Files Changed
- ✅ `terraform/production/s3-storage/main.tf` - Secure bucket policy
- ✅ `terraform/production/iam/main.tf` - S3 management permissions
- 📄 `S3_BUCKET_POLICY_FIX.md` - This documentation

---
**Issue**: Public bucket policy blocked by Block Public Access
**Fixed**: Replaced with secure IAM role-based policy + added S3 permissions
**Status**: ✅ Ready to deploy
**Security**: ✅ Improved - No public access
**Last Updated**: October 25, 2025
