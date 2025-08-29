# Local values for configuration
locals {
  project_name = "react-auth-demo"
  environment  = "dev"
  aws_region  = "us-east-1"
}

# Cognito User Pool
resource "aws_cognito_user_pool" "main" {
  name = "${local.project_name}-${local.environment}-user-pool"

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }

  auto_verified_attributes = ["email"]

  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
  }

  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  username_attributes = ["email"]

  tags = {
    Name        = "${local.project_name}-${local.environment}-user-pool"
    Environment = local.environment
    Project     = local.project_name
  }
}

# Cognito User Pool Client
resource "aws_cognito_user_pool_client" "main" {
  name         = "${local.project_name}-${local.environment}-client"
  user_pool_id = aws_cognito_user_pool.main.id

  generate_secret = false

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]

  callback_urls = ["https://localhost:3000", "http://localhost:3000"]
  logout_urls   = ["https://localhost:3000", "http://localhost:3000"]

  supported_identity_providers = ["COGNITO"]

  allowed_oauth_flows                  = ["code"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes                 = ["email", "openid", "profile"]

  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }

  access_token_validity  = 1
  id_token_validity      = 1
  refresh_token_validity = 30
}

# Cognito User Pool Domain
resource "aws_cognito_user_pool_domain" "main" {
  domain       = "${local.project_name}-${local.environment}"
  user_pool_id = aws_cognito_user_pool.main.id
}

# Data sources for additional information
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# Output information (using locals for display)
locals {
  # Display information after deployment
  deployment_info = {
    project_name           = local.project_name
    environment           = local.environment
    aws_region           = local.aws_region
    aws_account_id       = data.aws_caller_identity.current.account_id
    cognito_user_pool_id = aws_cognito_user_pool.main.id
    cognito_client_id    = aws_cognito_user_pool_client.main.id
    cognito_domain       = aws_cognito_user_pool_domain.main.domain
    amplify_app_id       = aws_amplify_app.main.id
    amplify_app_url      = "https://${aws_amplify_app.main.default_domain}"
    amplify_branch_url   = "https://${aws_amplify_branch.main.branch_name}.${aws_amplify_app.main.default_domain}"
  }
}
