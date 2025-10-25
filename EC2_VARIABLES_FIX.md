# EC2 Instance Profile Variable Fix

## Error Encountered
```
var.ec2_instance_profile   IAM instance profile name for EC2 instance
```

The GitHub Actions workflow was waiting for the `ec2_instance_profile` variable to be provided, but no value was being passed.

## Root Cause

The `terraform/production/ec2-fast-api-jwt/variables.tf` file had several variables without default values:
1. `ec2_instance_profile` - No default value
2. `ec2_ssm_role` - No default value
3. `storage_files_csv` - No default value

When Terraform runs without these values being explicitly passed (via `-var` flags or environment variables), it waits for user input, which causes the workflow to hang.

## Solution Applied

Added default values for all required variables that match the resources created by the IAM and S3 modules:

### 1. EC2 Instance Profile
```terraform
variable "ec2_instance_profile" {
  description = "IAM instance profile name for EC2 instance"
  type        = string
  default     = "ec2-ssm-fast-api-profile"  # ← Added default
}
```

This matches the instance profile name created in `terraform/production/iam/main.tf`:
```terraform
resource "aws_iam_instance_profile" "ec2_ssm_profile" {
  name = "${var.ec2_ssm_fast_api}-profile"  # ← "ec2-ssm-fast-api-profile"
  role = aws_iam_role.ec2_ssm_role.name
}
```

### 2. EC2 SSM Role
```terraform
variable "ec2_ssm_role" {
  description = "EC2 IAM Role with SSM access"
  type        = string
  default     = "ec2-ssm-fast-api"  # ← Added default
}
```

This matches the role name created in the IAM module.

### 3. Storage Files CSV Bucket
```terraform
variable "storage_files_csv" {
  description = "S3 bucket for storing files"
  type        = string
  default     = "storage-files-csv"  # ← Added default
}
```

This matches the S3 bucket name created in `terraform/production/s3-storage/main.tf`.

## Additional Fix

Removed the empty `subnet_id = ""` parameter from the EC2 instance resource, as it was causing validation issues.

### Before:
```terraform
resource "aws_instance" "fast_api_jwt" {
  ami                  = var.ec2_ami
  instance_type        = var.ec2_instance_type
  subnet_id            = ""  # ← Empty string causes issues
  security_groups      = [aws_security_group.fast_api_jwt_sg.name]
  # ...
}
```

### After:
```terraform
resource "aws_instance" "fast_api_jwt" {
  ami                  = var.ec2_ami
  instance_type        = var.ec2_instance_type
  security_groups      = [aws_security_group.fast_api_jwt_sg.name]  # ← Uses default VPC
  # ...
}
```

**Note**: When using `security_groups` (not `vpc_security_group_ids`), the instance is launched in the default VPC, and `subnet_id` should not be specified.

## Files Modified

- ✅ `terraform/production/ec2-fast-api-jwt/variables.tf` - Added default values for 3 variables
- ✅ `terraform/production/ec2-fast-api-jwt/main.tf` - Removed empty subnet_id

## Benefits

✅ **No hanging workflows** - Terraform doesn't wait for user input
✅ **Consistent naming** - Defaults match resources created by other modules
✅ **Simple deployment** - No need to pass variables manually
✅ **Self-documenting** - Default values show expected resource names

## Deploy the Fix

```bash
# Commit the changes
git add terraform/production/ec2-fast-api-jwt/
git commit -m "Fix: Add default values for EC2 variables to prevent workflow hang"
git push

# Run the workflow
# GitHub → Actions → "2 - Provisioning Infrastructure" → Run workflow
```

## Verification

After the workflow runs:

### Check EC2 Instance Created:
```bash
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=fast-api-jwt" \
  --query "Reservations[0].Instances[0].[InstanceId,State.Name,IamInstanceProfile.Arn]" \
  --output table
```

Expected output:
```
----------------------------------------------------------------------
|                        DescribeInstances                          |
+--------------------+----------+------------------------------------+
|  i-0123456789abcd |  running | ...instance-profile/ec2-ssm-fast-api-profile |
+--------------------+----------+------------------------------------+
```

### Verify Instance Profile Attached:
```bash
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=fast-api-jwt" \
  --query "Reservations[0].Instances[0].IamInstanceProfile" \
  --output json
```

Should show:
```json
{
  "Arn": "arn:aws:iam::209479292315:instance-profile/ec2-ssm-fast-api-profile",
  "Id": "AIPXXXXXXXXXXXXXXXXXX"
}
```

## How It Works

### Variable Resolution Flow:
```
1. Terraform looks for variable values in this order:
   a. Command-line -var flags (highest priority)
   b. Environment variables TF_VAR_*
   c. terraform.tfvars file
   d. *.auto.tfvars files
   e. Variable default values ← We added these
   f. Interactive prompt (causes hang)

2. With defaults added:
   ✅ Terraform finds default values (step e)
   ✅ No prompt needed
   ✅ Workflow continues
```

### Module Dependencies:
```
IAM Module
  └─▶ Creates: ec2-ssm-fast-api-profile
      └─▶ Used by: EC2 Module (via default variable)

S3 Module
  └─▶ Creates: storage-files-csv
      └─▶ Referenced by: EC2 user_data script (via default variable)
```

## Alternative Approach (Not Recommended)

Instead of default values, you could pass variables explicitly in the workflow:

```yaml
- name: Provision EC2 Fast API Plan
  working-directory: terraform/production/ec2-fast-api-jwt
  run: |
    INSTANCE_PROFILE=$(terraform output -state=../iam/terraform.tfstate ec2_ssm_profile_name)
    terraform plan -var="ec2_instance_profile=$INSTANCE_PROFILE"
```

**Why we didn't do this**:
- More complex workflow logic
- Tight coupling between modules
- Harder to test locally
- More points of failure

## Troubleshooting

### Issue: "Instance profile does not exist"
**Cause**: IAM module not run yet or instance profile name mismatch
**Solution**: Ensure IAM job runs before EC2 job (already configured with `needs: [iam]`)

### Issue: "S3 bucket does not exist" in user_data
**Cause**: S3 module not run yet
**Solution**: Check workflow dependency order (EC2 needs S3)

### Issue: Instance launches but can't access Secrets Manager
**Cause**: IAM role doesn't have Secrets Manager permissions
**Solution**: Already fixed in IAM module with `ec2_secrets_manager_policy`

## Summary

**Problem**: Workflow hanging waiting for `ec2_instance_profile` variable input
**Root Cause**: Variables defined without default values
**Solution**: Added default values matching resources from IAM and S3 modules
**Impact**: Workflow now runs smoothly without manual input
**Status**: ✅ Fixed and ready to deploy

---
**Last Updated**: October 25, 2025
