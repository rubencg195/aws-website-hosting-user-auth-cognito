# Amplify App
resource "aws_amplify_app" "main" {
  name = "${local.project_name}-${local.environment}"

  # Repository configuration (optional - for documentation)
  description = "React Authentication Demo with AWS Cognito and Amplify"

  # Build specification
  build_spec = <<-EOT
    version: 1
    frontend:
      phases:
        preBuild:
          commands:
            - npm ci
        build:
          commands:
            - npm run build
      artifacts:
        baseDirectory: build
        files:
          - '**/*'
      cache:
        paths:
          - node_modules/**/*
  EOT

  # Environment variables for the build
  environment_variables = {
    REACT_APP_AWS_REGION = local.aws_region
    REACT_APP_USER_POOL_ID = aws_cognito_user_pool.main.id
    REACT_APP_USER_POOL_CLIENT_ID = aws_cognito_user_pool_client.main.id
    REACT_APP_COGNITO_DOMAIN = aws_cognito_user_pool_domain.main.domain
  }

  # Enable repository connection features
  enable_branch_auto_build = true
  enable_branch_auto_deletion = false

  tags = {
    Name        = "${local.project_name}-${local.environment}"
    Environment = local.environment
    Project     = local.project_name
  }
}

# Amplify Branch (main branch)
resource "aws_amplify_branch" "main" {
  app_id      = aws_amplify_app.main.id
  branch_name = "main"

  # Enable auto build and deploy
  enable_auto_build = true
  enable_pull_request_preview = true

  # Environment variables for the branch
  environment_variables = {
    REACT_APP_AWS_REGION = local.aws_region
    REACT_APP_USER_POOL_ID = aws_cognito_user_pool.main.id
    REACT_APP_USER_POOL_CLIENT_ID = aws_cognito_user_pool_client.main.id
    REACT_APP_COGNITO_DOMAIN = aws_cognito_user_pool_domain.main.domain
  }

  # Framework configuration
  framework = "React"

  tags = {
    Name        = "${local.project_name}-${local.environment}-main"
    Environment = local.environment
    Project     = local.project_name
  }
}

# Webhook for repository integration (optional)
resource "aws_amplify_webhook" "main" {
  app_id      = aws_amplify_app.main.id
  branch_name = aws_amplify_branch.main.branch_name
  description = "Webhook for main branch deployments"

  # This will be configured after manual repository connection
  # The webhook URL will be available in the Amplify console
}

# IAM Role for Amplify with enhanced permissions
resource "aws_iam_role" "amplify_role" {
  name = "${local.project_name}-${local.environment}-amplify-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "amplify.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${local.project_name}-${local.environment}-amplify-role"
    Environment = local.environment
    Project     = local.project_name
  }
}

# Attach Amplify policy to the role
resource "aws_iam_role_policy_attachment" "amplify_policy" {
  role       = aws_iam_role.amplify_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess-Amplify"
}