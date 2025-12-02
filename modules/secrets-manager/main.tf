# Nexus Registry Secret in AWS Secrets Manager
resource "aws_secretsmanager_secret" "nexus_registry" {
  name        = "${var.project_name}-${var.environment}-nexus-registry-credentials"
  description = "Nexus registry credentials for EKS cluster"
  kms_key_id  = var.kms_key_id

  tags = merge(
    var.tags,
    {
      Name    = "${var.project_name}-${var.environment}-nexus-registry-secret"
      Registry = "Nexus"
    }
  )
}

resource "aws_secretsmanager_secret_version" "nexus_registry" {
  secret_id = aws_secretsmanager_secret.nexus_registry.id

  secret_string = jsonencode({
    username = var.nexus_username
    password = var.nexus_password
    url      = var.nexus_registry_url
  })
}

# IAM Policy for accessing Nexus secret
resource "aws_iam_policy" "nexus_secret_access" {
  name        = "${var.project_name}-${var.environment}-nexus-secret-access"
  description = "Policy for accessing Nexus registry credentials from Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = aws_secretsmanager_secret.nexus_registry.arn
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "secretsmanager.${data.aws_region.current.name}.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-nexus-secret-access-policy"
    }
  )
}

data "aws_region" "current" {}

