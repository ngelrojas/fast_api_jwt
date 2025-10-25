# SQS Variable Fix - Resolving "var.file_upload_queue The operation was canceled"

## Problem
The GitHub Actions workflow was failing with the error:
```
var.file_upload_queue   The SQS queue for file uploads
Error: The operation was canceled.
```

## Root Cause
The S3 Terraform configuration required a `file_upload_queue` variable to be passed manually via command-line. The workflow was trying to:
1. Query AWS to get the SQS queue ARN
2. Pass it as a variable to terraform plan/apply

This approach had several issues:
- **Timing issues**: The AWS CLI query might time out or fail
- **Cancellation issues**: If the query took too long, GitHub Actions would cancel the operation
- **Coupling issues**: The workflow had tight coupling between SQS and S3 deployments
- **Error-prone**: Manual variable passing is fragile and hard to maintain

## Solution Applied

### Approach: Use Terraform Data Sources
Instead of manually retrieving and passing the SQS queue ARN, we now use Terraform's built-in data sources to automatically fetch it.

### Changes Made

#### 1. **Updated `terraform/production/s3-storage/main.tf`**
Added a data source to automatically fetch the SQS queue:
```terraform
data "aws_sqs_queue" "file_upload_queue" {
  name = var.sqs_queue_name
}
```

Updated the S3 notification to use the data source:
```terraform
resource "aws_s3_bucket_notification" "files_csv_notification" {
  # ...
  queue {
    queue_arn = data.aws_sqs_queue.file_upload_queue.arn  # ← Changed from var.file_upload_queue
    # ...
  }
}
```

#### 2. **Updated `terraform/production/s3-storage/variables.tf`**
Replaced the `file_upload_queue` variable with:
```terraform
variable "sqs_queue_name" {
  description = "The name of the SQS queue for file uploads"
  type        = string
  default     = "file-upload-queue"
}
```

#### 3. **Updated `terraform/production/sqs-notifications/main.tf`**
Added SQS queue policy to allow S3 to send messages:
```terraform
resource "aws_sqs_queue_policy" "file_upload_queue_policy" {
  queue_url = aws_sqs_queue.file_upload_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.file_upload_queue.arn
        Condition = {
          ArnLike = {
            "aws:SourceArn" = "arn:aws:s3:::storage-files-csv"
          }
        }
      }
    ]
  })
}
```

#### 4. **Updated `.github/workflows/ci-infrastructure.yaml`**
Removed manual SQS ARN retrieval from both the plan and apply steps:

**Before:**
```yaml
- name: Provision S3 Plan
  run: |
    SQS_QUEUE_ARN=$(aws sqs get-queue-attributes ...)
    terraform plan -var="file_upload_queue=$SQS_QUEUE_ARN"
```

**After:**
```yaml
- name: Provision S3 Plan
  run: terraform plan -out=tfplan
```

## Benefits of This Solution

✅ **Automatic**: No manual variable passing required
✅ **Reliable**: Terraform handles the lookup internally
✅ **Declarative**: Infrastructure as code, not imperative scripts
✅ **Resilient**: No timing or cancellation issues
✅ **Maintainable**: Less complex workflow logic

## How Dependencies Work Now

```
SQS Job (creates queue)
    ↓
S3 Job (looks up queue via data source)
    ↓
Creates S3 bucket notification pointing to SQS
```

The `needs: [iam, sqs]` in the workflow ensures SQS is created before S3, and Terraform's data source ensures the queue exists when S3 tries to reference it.

## Deployment Steps

### Option 1: Deploy via GitHub Actions (Recommended)
```bash
# 1. Commit and push changes
git add .
git commit -m "Fix: Use Terraform data source for SQS queue instead of manual variable passing"
git push

# 2. Run workflow
# Go to GitHub → Actions → "2 - Provisioning Infrastructure" → Run workflow
```

### Option 2: Manual Deployment
```bash
# Deploy SQS first
cd terraform/production/sqs-notifications
terraform init
terraform apply

# Then deploy S3 (will automatically find the SQS queue)
cd ../s3-storage
terraform init
terraform apply
```

## Verification

After deployment, verify the setup:

### 1. Check SQS Queue Policy
```bash
aws sqs get-queue-attributes \
  --queue-url $(aws sqs get-queue-url --queue-name file-upload-queue --query 'QueueUrl' --output text) \
  --attribute-names Policy \
  --query 'Attributes.Policy' \
  --output text | jq .
```

### 2. Check S3 Notification Configuration
```bash
aws s3api get-bucket-notification-configuration \
  --bucket storage-files-csv
```

### 3. Test the Integration
Upload a CSV file and check if SQS receives a message:
```bash
# Upload test file
echo "test,data" > test.csv
aws s3 cp test.csv s3://storage-files-csv/test.csv

# Check SQS for messages
aws sqs receive-message \
  --queue-url $(aws sqs get-queue-url --queue-name file-upload-queue --query 'QueueUrl' --output text)
```

## Troubleshooting

### Issue: "No data source found"
**Cause**: SQS queue doesn't exist yet
**Solution**: Ensure the SQS job runs before the S3 job (already configured with `needs: [iam, sqs]`)

### Issue: "Access denied"
**Cause**: SQS queue policy not allowing S3 to send messages
**Solution**: Already fixed with the `aws_sqs_queue_policy` resource

### Issue: Import conflicts
If you have existing resources, the workflow handles imports automatically. If there are issues:
```bash
cd terraform/production/sqs-notifications
terraform import aws_sqs_queue_policy.file_upload_queue_policy file-upload-queue
```

## Files Modified

- ✅ `terraform/production/s3-storage/main.tf` - Added data source, updated notification
- ✅ `terraform/production/s3-storage/variables.tf` - Changed variable to sqs_queue_name
- ✅ `terraform/production/sqs-notifications/main.tf` - Added SQS queue policy
- ✅ `.github/workflows/ci-infrastructure.yaml` - Removed manual ARN retrieval
- 📄 `SQS_VARIABLE_FIX.md` - This documentation

## Next Steps

The workflow will now:
1. ✅ Create SQS queue with proper policy
2. ✅ S3 job will automatically discover the queue ARN
3. ✅ Create S3 notification configuration
4. ✅ S3 events will trigger SQS messages

---
**Last Updated**: October 25, 2025
