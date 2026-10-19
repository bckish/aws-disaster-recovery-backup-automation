terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_kms_key" "backup" {
  description             = "KMS key for AWS Backup recovery points"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

resource "aws_backup_vault" "primary" {
  name        = "${var.name_prefix}-backup-vault"
  kms_key_arn = aws_kms_key.backup.arn
}

resource "aws_backup_plan" "daily" {
  name = "${var.name_prefix}-daily"

  rule {
    rule_name         = "daily-recovery-point"
    target_vault_name = aws_backup_vault.primary.name
    schedule          = "cron(0 2 ? * * *)"

    lifecycle {
      delete_after = 35
    }
  }
}

data "aws_iam_policy_document" "backup_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "backup" {
  name               = "${var.name_prefix}-backup-service-role"
  assume_role_policy = data.aws_iam_policy_document.backup_assume_role.json
}

resource "aws_iam_role_policy_attachment" "backup" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_backup_selection" "daily" {
  name         = "${var.name_prefix}-daily-tag-selection"
  plan_id      = aws_backup_plan.daily.id
  iam_role_arn = aws_iam_role.backup.arn

  selection_tag {
    type  = "STRINGEQUALS"
    key   = "backup"
    value = "daily"
  }
}
