# Local values for configuration
# This file contains all local variables used across the infrastructure

locals {
  project_name = "react-auth-demo"
  environment  = "dev"
  aws_region  = "us-east-1"
  
  # MIME types for proper content serving
  mime_types = {
    # HTML and text files
    "html" = "text/html; charset=utf-8"
    "htm"  = "text/html; charset=utf-8"
    "css"  = "text/css; charset=utf-8"
    "js"   = "application/javascript; charset=utf-8"
    "jsx"  = "application/javascript; charset=utf-8"
    "ts"   = "application/typescript; charset=utf-8"
    "tsx"  = "application/typescript; charset=utf-8"
    
    # Data files
    "json" = "application/json; charset=utf-8"
    "xml"  = "application/xml; charset=utf-8"
    "txt"  = "text/plain; charset=utf-8"
    
    # Images
    "png"  = "image/png"
    "jpg"  = "image/jpeg"
    "jpeg" = "image/jpeg"
    "gif"  = "image/gif"
    "svg"  = "image/svg+xml"
    "ico"  = "image/x-icon"
    "webp" = "image/webp"
    "bmp"  = "image/bmp"
    
    # Fonts
    "woff"  = "font/woff"
    "woff2" = "font/woff2"
    "ttf"   = "font/ttf"
    "otf"   = "font/otf"
    "eot"   = "application/vnd.ms-fontobject"
    
    # Archives and other
    "zip"  = "application/zip"
    "pdf"  = "application/pdf"
    "mp4"  = "video/mp4"
    "webm" = "video/webm"
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
  
  # URLs for Cognito configuration (updated with actual deployment URLs)
  cognito_urls = {
    localhost_https = "https://localhost:3000"
    localhost_http  = "http://localhost:3000"
    cloudfront      = "https://d1d7szxa9u3zw7.cloudfront.net"
    amplify         = "https://main.d1bk1t4l23zi6w.amplifyapp.com"
  }
}
