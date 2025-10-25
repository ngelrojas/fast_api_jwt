# 🗺️ Terragrunt Deployment Architecture

## 📊 Module Dependency Flow

```
┌─────────────────────────────────────────────────────────────┐
│                     Terragrunt Root                          │
│                   (terragrunt.hcl)                          │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ • Backend Configuration (S3 + DynamoDB)               │  │
│  │ • Provider Generation (AWS)                           │  │
│  │ • Common Variables (region, environment, project)     │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              Production Environment                          │
│                  (env.hcl)                                   │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ • environment = "production"                          │  │
│  │ • aws_region = "us-east-1"                            │  │
│  │ • project_name = "fast-api-jwt"                       │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼

   ┌──────────────┐   ┌──────────────┐   ┌──────────────┐
   │    Roles     │   │   Policies   │   │     SQS      │
   │              │   │              │   │ Notifications│
   │ (Optional    │   │ (Optional    │   │              │
   │  baseline)   │   │  baseline)   │   │              │
   └──────────────┘   └──────────────┘   └──────┬───────┘
                                                 │
                                                 ▼
                                         ┌──────────────┐
                                         │  S3 Storage  │
                                         │              │
                                         │ • Depends on │
                                         │   SQS queue  │
                                         └──────┬───────┘
                                                │
                                                ▼
                                         ┌──────────────┐
                                         │     IAM      │
                                         │              │
                                         │ • Depends on │
                                         │   S3 bucket  │
                                         └──────┬───────┘
                                                │
                              ┌─────────────────┼─────────────────┐
                              ▼                 ▼                 ▼
                      ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
                      │    Secret    │  │  EC2 FastAPI │  │ EC2 Self-    │
                      │   Manager    │  │     JWT      │  │   Hosted     │
                      │              │  │              │  │              │
                      │ (Parallel)   │  │ • Depends on:│  │ • Depends on:│
                      │              │  │   - S3       │  │   - S3       │
                      │              │  │   - IAM      │  │   - IAM      │
                      │              │  │   - Secrets  │  │              │
                      └──────────────┘  └──────────────┘  └──────────────┘
```

## 🔄 Execution Order

When you run `terragrunt run-all apply`, modules execute in this order:

```
Step 1: Independent Modules (Parallel)
├── roles
├── policies
├── sqs-notifications
└── secret-manager

Step 2: S3 Storage
└── Waits for: sqs-notifications

Step 3: IAM
└── Waits for: s3-storage

Step 4: EC2 Instances (Parallel)
├── ec2-fast-api-jwt
│   └── Waits for: s3-storage, iam, secret-manager
└── ec2-self-hosted
    └── Waits for: s3-storage, iam
```

## 📁 State File Organization

```
S3 Bucket: tf-state-locks-fast-api-jwt
├── production/
│   ├── roles/terraform.tfstate
│   ├── policies/terraform.tfstate
│   ├── sqs-notifications/terraform.tfstate
│   ├── s3-storage/terraform.tfstate
│   ├── iam/terraform.tfstate
│   ├── secret-manager/terraform.tfstate
│   ├── ec2-fast-api-jwt/terraform.tfstate
│   └── ec2-self-hosted/terraform.tfstate
```

**Benefits:**
- ✅ Isolated state per module
- ✅ Easier to debug issues
- ✅ Safer to make changes
- ✅ Parallel state operations

## 🔐 Configuration Hierarchy

```
Root Configuration (terragrunt.hcl)
    │
    ├── Backend Config ────────────► Applied to ALL modules
    ├── Provider Config ───────────► Applied to ALL modules
    └── Common Variables ──────────► Available to ALL modules
            │
            ▼
Environment Config (production/env.hcl)
    │
    ├── environment = "production"
    ├── aws_region = "us-east-1"
    └── project_name = "fast-api-jwt"
            │
            ▼
Module Config (module/terragrunt.hcl)
    │
    ├── Dependencies ──────────────► Links to other modules
    ├── Module Inputs ─────────────► Specific to this module
    └── Custom Configuration ──────► Module-specific overrides
```

## 🎯 Data Flow Example: S3 Storage

```
┌─────────────────────────────────────────────────────────┐
│  SQS Notifications Module                               │
│  Output: file_upload_queue (ARN)                        │
└────────────────┬────────────────────────────────────────┘
                 │
                 │ dependency.sqs.outputs.file_upload_queue
                 │
                 ▼
┌─────────────────────────────────────────────────────────┐
│  S3 Storage Module (terragrunt.hcl)                     │
│                                                          │
│  dependency "sqs" {                                      │
│    config_path = "../sqs-notifications"                 │
│  }                                                       │
│                                                          │
│  inputs = {                                              │
│    file_upload_queue = dependency.sqs.outputs...        │
│  }                                                       │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────┐
│  S3 Storage Module (main.tf)                            │
│                                                          │
│  variable "file_upload_queue" {                         │
│    type = string                                         │
│  }                                                       │
│                                                          │
│  resource "aws_s3_bucket_notification" {                │
│    queue_arn = var.file_upload_queue                    │
│  }                                                       │
└────────────────┬────────────────────────────────────────┘
                 │
                 │ Output: storage_files_csv
                 │
                 ▼
┌─────────────────────────────────────────────────────────┐
│  IAM Module                                              │
│  Uses: dependency.s3.outputs.storage_files_csv          │
└─────────────────────────────────────────────────────────┘
```

## 🚀 Deployment Workflow

```
┌──────────────┐
│ Developer    │
│ runs command │
└──────┬───────┘
       │
       ▼
┌────────────────────────────────────┐
│ ./deploy.sh apply                  │
└────────┬───────────────────────────┘
         │
         ▼
┌────────────────────────────────────┐
│ Load .env file                     │
│ Export environment variables        │
└────────┬───────────────────────────┘
         │
         ▼
┌────────────────────────────────────┐
│ Terragrunt processes root config   │
│ • Read terragrunt.hcl              │
│ • Read env.hcl                     │
│ • Generate backend.tf              │
│ • Generate provider.tf             │
└────────┬───────────────────────────┘
         │
         ▼
┌────────────────────────────────────┐
│ Terragrunt builds dependency graph │
│ • Analyze all terragrunt.hcl files │
│ • Identify dependencies            │
│ • Determine execution order        │
└────────┬───────────────────────────┘
         │
         ▼
┌────────────────────────────────────┐
│ Execute modules in order           │
│ Step 1: Independent modules        │
│ Step 2: Dependent modules          │
│ Step 3: Final modules              │
└────────┬───────────────────────────┘
         │
         ▼
┌────────────────────────────────────┐
│ Each module:                       │
│ 1. terraform init                  │
│ 2. terraform plan                  │
│ 3. terraform apply                 │
│ 4. Save outputs                    │
└────────┬───────────────────────────┘
         │
         ▼
┌────────────────────────────────────┐
│ Infrastructure deployed! ✅         │
└────────────────────────────────────┘
```

## 🔄 State Locking Flow

```
┌─────────────────┐
│ Terragrunt      │
│ starts          │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ Request lock from DynamoDB          │
│ Table: tf-table-locks-fast-api-jwt  │
└────────┬────────────────────────────┘
         │
    ┌────┴────┐
    │         │
    ▼         ▼
┌───────┐  ┌──────────────┐
│ Lock  │  │ Lock Failed  │
│ OK    │  │ (Someone     │
└───┬───┘  │  else is     │
    │      │  deploying)  │
    │      └──────────────┘
    ▼
┌─────────────────────────┐
│ Perform changes         │
│ • Read state from S3    │
│ • Make infrastructure   │
│   changes               │
│ • Write state to S3     │
└───────┬─────────────────┘
        │
        ▼
┌─────────────────────────┐
│ Release lock            │
└─────────────────────────┘
```

## 🎨 Backend Configuration Auto-Generation

```
Root: terragrunt.hcl
├── remote_state {
│     backend = "s3"
│     key = "${path_relative_to_include()}/terraform.tfstate"
│   }
│
├── For: production/s3-storage/
│   └── Generates: backend.tf
│       terraform {
│         backend "s3" {
│           key = "production/s3-storage/terraform.tfstate"
│         }
│       }
│
└── For: production/iam/
    └── Generates: backend.tf
        terraform {
          backend "s3" {
            key = "production/iam/terraform.tfstate"
          }
        }
```

## 🌐 Multi-Environment Ready

```
terraform/
├── production/
│   ├── env.hcl (environment = "production")
│   └── modules...
│
├── staging/  (Future)
│   ├── env.hcl (environment = "staging")
│   └── modules... (same structure)
│
└── development/  (Future)
    ├── env.hcl (environment = "development")
    └── modules... (same structure)
```

**To add staging:**
```bash
cp -r terraform/production terraform/staging
# Edit terraform/staging/env.hcl
# Update any environment-specific values
terragrunt run-all apply --terragrunt-working-dir terraform/staging
```

## 📊 Benefits Visualization

```
Traditional Terraform:
─────────────────────
Module 1: backend.tf (15 lines)
Module 2: backend.tf (15 lines)  ← Repetitive!
Module 3: backend.tf (15 lines)  ← Repetitive!
Module 4: backend.tf (15 lines)  ← Repetitive!
Total: 60 lines of duplicated code

With Terragrunt:
────────────────
Root: terragrunt.hcl (1 config)
Modules: inherit automatically
Total: 1 configuration, 0 duplication! ✅
```

---

**This architecture ensures:**
- ✅ Consistent configuration across all modules
- ✅ Automatic dependency management
- ✅ Isolated state files for safety
- ✅ Easy multi-environment support
- ✅ Parallel execution where possible
- ✅ Clear visualization of infrastructure
