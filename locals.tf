# Local values for configuration
# This file contains all local variables used across the infrastructure

locals {
  project_name = "react-auth-demo"
  environment  = "dev"
  aws_region  = "us-east-1"
  
  # MIME types for proper content serving
  mime_types = {
    "html" = "text/html"
    "css"  = "text/css"
    "js"   = "application/javascript"
    "json" = "application/json"
    "png"  = "image/png"
    "jpg"  = "image/jpeg"
    "jpeg" = "image/jpeg"
    "gif"  = "image/gif"
    "svg"  = "image/svg+xml"
    "ico"  = "image/x-icon"
    "woff" = "font/woff"
    "woff2" = "font/woff2"
    "ttf"  = "font/ttf"
    "eot"  = "application/vnd.ms-fontobject"
  }
  
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
    amplify_app_url      = "https://main.${aws_amplify_app.main.id}.amplifyapp.com"
    amplify_branch_url   = "https://main.${aws_amplify_app.main.id}.amplifyapp.com"
  }
}
