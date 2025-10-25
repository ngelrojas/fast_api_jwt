# 📋 Terragrunt Deployment Checklist

Use this checklist to ensure a smooth deployment with Terragrunt.

## ✅ Pre-Deployment Checklist

### 1. Tools Installation
- [ ] Terraform installed (`terraform --version`)
- [ ] Terragrunt installed (`terragrunt --version`)
- [ ] AWS CLI installed and configured (`aws sts get-caller-identity`)
- [ ] Git repository up to date

### 2. AWS Prerequisites
- [ ] S3 bucket exists: `tf-state-locks-fast-api-jwt`
- [ ] DynamoDB table exists: `tf-table-locks-fast-api-jwt`
- [ ] AWS credentials configured (either via `aws configure` or env vars)
- [ ] Correct AWS permissions (S3, DynamoDB, EC2, IAM, Secrets Manager)

### 3. Environment Configuration
- [ ] `.env` file created (from `.env.example`)
- [ ] All required secrets filled in `.env`:
  - [ ] `TF_VAR_secret_key`
  - [ ] `TF_VAR_user_name`
  - [ ] `TF_VAR_password`
  - [ ] `TF_VAR_github_token`
  - [ ] `TF_VAR_vpc_id`
  - [ ] `TF_VAR_key_name`
- [ ] Environment variables loaded (`export $(cat .env | xargs)`)

### 4. Code Review
- [ ] All Terraform files reviewed
- [ ] Module dependencies verified
- [ ] Variable names consistent
- [ ] No hardcoded secrets in code
- [ ] `.gitignore` includes `.env` and cache directories

## 🚀 Deployment Steps

### Step 1: Backend Infrastructure (One-Time)
```bash
cd terraform/backend-infra
terraform init
terraform plan
terraform apply
```
- [ ] S3 bucket created successfully
- [ ] DynamoDB table created successfully
- [ ] Verify in AWS Console

### Step 2: Initialize Terragrunt
```bash
cd ../../  # Back to root
./deploy.sh init
```
- [ ] All modules initialized without errors
- [ ] `.terragrunt-cache` directories created
- [ ] `backend.tf` and `provider.tf` generated in each module

### Step 3: Validate Configuration
```bash
./deploy.sh validate
```
- [ ] All modules validated successfully
- [ ] No syntax errors
- [ ] No configuration issues

### Step 4: Plan Deployment
```bash
./deploy.sh plan
```
- [ ] Plan output reviewed carefully
- [ ] Resources to be created verified
- [ ] No unexpected changes
- [ ] Dependencies resolved correctly

### Step 5: Apply Infrastructure
```bash
./deploy.sh apply
```
- [ ] Confirmed deployment (type 'yes')
- [ ] All modules applied successfully
- [ ] No errors during deployment

### Step 6: Verify Deployment
```bash
./deploy.sh output
```
- [ ] Outputs displayed correctly
- [ ] EC2 instances running
- [ ] S3 bucket accessible
- [ ] IAM roles created
- [ ] Secrets stored in Secrets Manager

### Step 7: Manual Verification (AWS Console)
- [ ] EC2 instances are running
- [ ] Security groups configured correctly
- [ ] S3 bucket has correct policies
- [ ] IAM roles attached to EC2
- [ ] Secrets Manager has secrets
- [ ] SQS queue created

## 🧪 Post-Deployment Testing

### Application Testing
- [ ] SSH into EC2 instance
- [ ] Application is running
- [ ] API endpoints responding
- [ ] Authentication working
- [ ] File upload to S3 working

### Infrastructure Testing
- [ ] S3 notification to SQS working
- [ ] IAM permissions correct
- [ ] Logs accessible
- [ ] Monitoring configured

## 🔒 Security Checklist

- [ ] S3 bucket is not publicly accessible
- [ ] Security groups have minimal required ports
- [ ] Secrets not exposed in logs or code
- [ ] State file is encrypted
- [ ] DynamoDB table has state locking enabled
- [ ] IAM roles follow least privilege principle
- [ ] SSH keys are secure and not committed to Git

## 📝 Documentation

- [ ] Update README with deployment info
- [ ] Document any custom configurations
- [ ] Add deployment date and version
- [ ] Note any manual steps required
- [ ] Update runbook if needed

## 🐛 Troubleshooting Checklist

If deployment fails, check:

- [ ] AWS credentials valid
- [ ] Sufficient AWS permissions
- [ ] S3 bucket and DynamoDB table accessible
- [ ] No conflicting resources in AWS
- [ ] State file not locked by another process
- [ ] Environment variables loaded correctly
- [ ] Internet connectivity stable
- [ ] AWS region correct

## 🔄 Rollback Checklist

If you need to rollback:

### Option 1: Destroy and Redeploy
```bash
./deploy.sh destroy
# Fix issues
./deploy.sh apply
```
- [ ] Backup important data first
- [ ] Destroy completed successfully
- [ ] Issues resolved
- [ ] Redeployed successfully

### Option 2: Selective Rollback
```bash
cd terraform/production/[module]
terragrunt destroy
# Fix module
terragrunt apply
```
- [ ] Module destroyed
- [ ] Issues fixed
- [ ] Module reapplied

## 📊 Performance Checklist

- [ ] Deployment completed in reasonable time
- [ ] Resources created as expected
- [ ] No timeout errors
- [ ] State file updated correctly
- [ ] Locks released properly

## 🎯 Final Verification

- [ ] All resources tagged correctly
- [ ] Cost estimation acceptable
- [ ] Monitoring set up
- [ ] Alerts configured
- [ ] Team notified of deployment
- [ ] Documentation updated
- [ ] Deployment logged

## 📧 Stakeholder Communication

- [ ] Notify team of deployment window
- [ ] Share deployment results
- [ ] Document any issues encountered
- [ ] Schedule review meeting if needed

## 🎉 Success Criteria

Your deployment is successful when:

✅ All modules deployed without errors
✅ Application is accessible and functional
✅ All tests pass
✅ Security requirements met
✅ Documentation updated
✅ Team notified

---

## 📞 Need Help?

If you encounter issues:

1. Check `TERRAGRUNT_GUIDE.md` for detailed explanations
2. Review `TERRAGRUNT_ARCHITECTURE.md` for architecture understanding
3. Use `TERRAGRUNT_CHEATSHEET.md` for quick commands
4. Check AWS CloudWatch logs
5. Review Terragrunt debug logs: `terragrunt plan --terragrunt-log-level debug`

## 🔖 Useful Commands for Troubleshooting

```bash
# Check state
terragrunt state list

# Show specific resource
terragrunt state show [resource]

# Clear cache
./deploy.sh clean

# Unlock state (if stuck)
terragrunt force-unlock [LOCK_ID]

# Debug mode
terragrunt plan --terragrunt-log-level debug
```

---

**Date Completed:** _______________

**Deployed By:** _______________

**Deployment Version:** _______________

**Notes:**
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
