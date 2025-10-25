# S3 Storage Module Argument Fix

## Problem
Terraform was failing with the following error:
```
Error: Unsupported argument
  on main.tf line 19, in module "s3-storage":
  19:   file_upload_queue = module.sqs-notifications.file_upload_queue

An argument named "file_upload_queue" is not expected here.
```

## Root Cause
The `s3-storage` module was being called with a `file_upload_queue` argument that doesn't exist in the module's variable definitions.

**Why this happened:**
- The S3 storage module uses a **data source** (`data.aws_sqs_queue.file_upload_queue`) to look up the SQS queue by name
- It doesn't accept the queue as an input variable
- The module expects the SQS queue to already exist in AWS and looks it up using the queue name "file-upload-queue"

## Solution Applied

### 1. Removed Invalid Argument
**File:** `terraform/production/main.tf`

**Before:**
```terraform
module "s3-storage" {
  source            = "./s3-storage"
  file_upload_queue = module.sqs-notifications.file_upload_queue
}
```

**After:**
```terraform
module "s3-storage" {
  source = "./s3-storage"

  # S3 module uses data source to lookup SQS queue by name
  # Explicit dependency ensures SQS queue exists before S3 module runs
  depends_on = [module.sqs-notifications]
}
```

### 2. Added Missing Algorithm Variable
**File:** `terraform/production/variables.tf`

Added the `algorithm` variable for JWT configuration:
```terraform
variable "algorithm" {
  description = "Algorithm for JWT encoding"
  type        = string
  default     = "HS256"
}
```

**File:** `terraform/production/main.tf`

Updated the secret-manager module call to include the algorithm:
```terraform
module "secret-manager" {
  source     = "./secret-manager"
  secret_key = var.secret_key
  algorithm  = var.algorithm  # <- Added
  user_name  = var.user_name
  password   = var.password
  url_base   = var.url_base
}
```

## How It Works

### Module Dependency Flow:
1. **SQS Module** creates the queue named "file-upload-queue"
2. **S3 Module** uses a data source to look up the queue:
   ```terraform
   data "aws_sqs_queue" "file_upload_queue" {
     name = var.sqs_queue_name  # defaults to "file-upload-queue"
   }
   ```
3. **depends_on** ensures proper creation order

### Data Source vs Direct Reference:
- **Data Source Approach** (current): Module looks up existing resource by name
- **Direct Reference Approach** (attempted): Would pass resource object directly

The data source approach is more flexible and allows for:
- Importing existing resources
- Decoupling module dependencies
- Easier state management

## Validation Results

✅ **Terraform Init:** Successful
```
Initializing modules...
- ec2-api in ec2-fast-api-jwt
- ec2-self-hosted in ec2-self-hosted
- iam in iam
- s3-storage in s3-storage
- secret-manager in secret-manager
- sqs-notifications in sqs-notifications

Terraform has been successfully initialized!
```

✅ **Terraform Validate:** Successful
```
Success! The configuration is valid.
```

## Key Takeaways

1. **Always check module variable definitions** before passing arguments
2. **Data sources** provide loose coupling between modules
3. **depends_on** ensures proper resource creation order when using data sources
4. **Module documentation** is critical for understanding expected inputs

## Files Modified

1. ✅ `terraform/production/main.tf`
   - Removed invalid `file_upload_queue` argument
   - Added explicit `depends_on` for resource ordering
   - Added `algorithm` parameter to secret-manager module

2. ✅ `terraform/production/variables.tf`
   - Added missing `algorithm` variable for JWT configuration

## Next Steps

You can now proceed with:
1. Running `terraform plan` to see the infrastructure changes
2. Running `terraform apply` to create/update resources
3. The modules will properly coordinate through the SQS queue name

## Testing the Fix

To test the configuration:
```bash
cd terraform/production

# Initialize (already done)
terraform init

# Validate (already done - passed)
terraform validate

# Format check
terraform fmt -check

# Plan with your variables
terraform plan \
  -var="secret_key=your-secret-key" \
  -var="algorithm=HS256" \
  -var="user_name=your-username" \
  -var="password=your-password" \
  -var="github_token=your-github-token"
```

## Related Modules

- `sqs-notifications/`: Creates the SQS queue
- `s3-storage/`: Creates S3 bucket and uses data source to find SQS queue
- `secret-manager/`: Manages JWT and application secrets
