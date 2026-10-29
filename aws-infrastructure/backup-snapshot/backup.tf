# IAM Role for AWS Backup service
resource "aws_iam_role" "backup_role" {
  name = "aws_backup_service_role_multi"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "backup_policy" {
  role       = aws_iam_role.backup_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "restore_policy" {
  role       = aws_iam_role.backup_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

# AWS Backup Vault
resource "aws_backup_vault" "prod_vault" {
  name = "production-backup-vault-multi"
}

# AWS Backup Plan
resource "aws_backup_plan" "prod_backup_plan" {
  name = "production-daily-backup-plan-multi"

  rule {
    rule_name         = "daily_backup_rule"
    target_vault_name = aws_backup_vault.prod_vault.name
    schedule          = "cron(0 12 * * ? *)" # Daily at 12:00 PM UTC

    lifecycle {
      delete_after = 30
    }
  }
}

# Tag-Based Selection (automatically captures all instances with BackupGroup = production-tier)
resource "aws_backup_selection" "prod_backup_selection" {
  iam_role_arn = aws_iam_role.backup_role.arn
  name         = "production-resources-selection-multi"
  plan_id      = aws_backup_plan.prod_backup_plan.id

  selection_tag {
    type  = "STRINGEQUALS"
    key   = "BackupGroup"
    value = "production-tier"
  }
}
