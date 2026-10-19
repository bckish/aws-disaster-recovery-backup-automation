# AWS Disaster Recovery & Backup Automation

An Infrastructure as Code reference for creating encrypted, tag-driven AWS Backup coverage for EC2 and EBS workloads. It is designed as a starting point for a recovery-ready account, not as a claim of a production deployment.

## What it provisions

- An AWS Backup vault encrypted with a customer-managed KMS key
- A daily backup plan with 35-day retention
- A selection that protects resources tagged `backup = daily`
- A scoped IAM role used by AWS Backup

## Local validation

```bash
terraform -chdir=terraform init -backend=false
terraform -chdir=terraform fmt -check
terraform -chdir=terraform validate
```

## Deployment

Set AWS credentials in your shell, then run `terraform -chdir=terraform apply`. This creates billable AWS resources; review the plan, retention policy, and recovery-point costs before applying.

## Recovery runbook

1. Select a recovery point in AWS Backup.
2. Restore to an isolated recovery environment.
3. Validate application health and data integrity.
4. Record recovery time and outcome in the incident log.

## Security

Do not commit Terraform state, credentials, or recovery-point identifiers. The provided `.gitignore` excludes local state files.
