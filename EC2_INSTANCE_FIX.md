# EC2 Instance Error Fix

## Problem
You encountered the error:
```
Error: collecting instance settings: couldn't find resource
  with aws_instance.fast_api_jwt,
  on main.tf line 34, in resource "aws_instance" "fast_api_jwt":
  34: resource "aws_instance" "fast_api_jwt" {
```

## Root Cause
The issue was in the `aws_iam_role_policy_attachment` resource (line 12-15 of main.tf). The problem was:

1. **Wrong variable reference**: The `role` attribute in `aws_iam_role_policy_attachment` was using `var.ec2_ssm_role`, which receives the **entire IAM role object** from the Terragrunt dependency.
2. **Type mismatch**: The `role` attribute expects a **string** (role name), but was receiving a **complex object**.

This caused Terraform to fail when trying to process the EC2 instance resource because it couldn't resolve the dependency chain correctly.

## Solution Applied

### 1. Updated main.tf
Changed line 13 from:
```terraform
role       = var.ec2_ssm_role
```
to:
```terraform
role       = var.ec2_ssm_role_name
```

### 2. Added new variable in variables.tf
Added a new variable to handle the role name specifically:
```terraform
variable "ec2_ssm_role_name" {
  description = "EC2 IAM Role name for policy attachment"
  type        = string
  default     = "ec2-ssm-fast-api"
}
```

### 3. Updated terragrunt.hcl
Added the role name to the inputs:
```terraform
inputs = {
  storage_files_csv    = dependency.s3.outputs.storage_files_csv.bucket
  ec2_ssm_role         = dependency.iam.outputs.ec2_ssm_role
  ec2_ssm_role_name    = dependency.iam.outputs.ec2_ssm_role.name  # NEW
  secret_name          = dependency.secrets.outputs.secret_name
  ec2_instance_profile = dependency.iam.outputs.ec2_ssm_profile.name
}
```

## Verification
The configuration has been validated with:
```bash
terraform init
terraform validate
```

Both commands completed successfully.

## Next Steps
You can now run:
```bash
terragrunt plan
terragrunt apply
```

The EC2 instance should deploy without errors now!
