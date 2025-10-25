# EC2 Instance AMI Fix - GitHub Actions Error Resolution

## Problem
GitHub Actions was failing with the error:
```
Error: collecting instance settings: couldn't find resource
  with aws_instance.fast_api_jwt,
  on main.tf line 34, in resource "aws_instance" "fast_api_jwt":
  34: resource "aws_instance" "fast_api_jwt" {
```

## Root Cause
The EC2 instance was using an **outdated hardcoded AMI ID** (`ami-0c55b159cbfafe1f0`) that:
1. No longer exists in AWS (AMIs are regularly deprecated)
2. Was Amazon Linux 2, but the `user_data.sh` script uses `apt-get` which is for Ubuntu/Debian

This mismatch caused Terraform to fail when trying to create the EC2 instance because it couldn't find the specified AMI.

## Solution Applied

### Changed in `terraform/production/ec2-fast-api-jwt/main.tf`:

1. **Added dynamic AMI lookup** - Instead of using a hardcoded AMI ID, now using a data source to fetch the latest Ubuntu 22.04 LTS AMI:
   ```terraform
   data "aws_ami" "ubuntu" {
     most_recent = true
     owners      = ["099720109477"] # Canonical

     filter {
       name   = "name"
       values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
     }

     filter {
       name   = "virtualization-type"
       values = ["hvm"]
     }
   }
   ```

2. **Updated EC2 instance** - Changed from `var.ec2_ami` to `data.aws_ami.ubuntu.id`:
   ```terraform
   resource "aws_instance" "fast_api_jwt" {
     ami = data.aws_ami.ubuntu.id  # Was: var.ec2_ami
     # ...rest of configuration
   }
   ```

## Why This Fix Works

1. **Always uses latest AMI** - The data source automatically fetches the most recent Ubuntu 22.04 LTS AMI, ensuring it always exists
2. **Matches user_data.sh script** - Ubuntu uses `apt-get` which matches your existing provisioning script
3. **No manual updates needed** - When Ubuntu releases new AMIs, Terraform will automatically use them
4. **Region agnostic** - Works across all AWS regions where Ubuntu AMIs are available

## Benefits

- ✅ Eliminates "couldn't find resource" errors
- ✅ Ensures OS compatibility with provisioning scripts
- ✅ Reduces maintenance (no need to manually update AMI IDs)
- ✅ Improves reliability in CI/CD pipelines

## Testing
After this change, your GitHub Actions workflow should:
1. Successfully find the Ubuntu AMI
2. Create the EC2 instance without errors
3. Properly execute the user_data.sh script with apt-get commands

## Additional Notes
The `var.ec2_ami` variable in `variables.tf` is now unused and can be removed if desired, as we're using the dynamic AMI lookup instead.
