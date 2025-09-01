# Infrastructure Outputs
# This file contains all outputs from the infrastructure deployment

# Amplify Hosting Outputs
output "amplify_app_url" {
  description = "Amplify app URL"
  value       = "https://${aws_amplify_branch.main.branch_name}.${aws_amplify_app.main.id}.amplifyapp.com"
}

output "amplify_webhook_url" {
  description = "Webhook URL for repository integration"
  value       = aws_amplify_webhook.main.url
}

# S3 Hosting Outputs
output "website_endpoint" {
  description = "S3 website endpoint"
  value       = aws_s3_bucket_website_configuration.website.website_endpoint
}

output "s3_bucket_name" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.website.bucket
}

# CloudFront Outputs
output "cloudfront_url" {
  description = "CloudFront distribution URL"
  value       = "https://${aws_cloudfront_distribution.website.domain_name}"
}

# Cognito Outputs
output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = aws_cognito_user_pool.main.id
}

output "cognito_user_pool_client_id" {
  description = "Cognito User Pool Client ID"
  value       = aws_cognito_user_pool_client.main.id
}

output "cognito_domain" {
  description = "Cognito User Pool Domain"
  value       = aws_cognito_user_pool_domain.main.domain
}

# Elastic Beanstalk Outputs
output "elasticbeanstalk_app_name" {
  description = "Elastic Beanstalk application name"
  value       = aws_elastic_beanstalk_application.react_app.name
}

output "elasticbeanstalk_env_name" {
  description = "Elastic Beanstalk environment name"
  value       = aws_elastic_beanstalk_environment.react_env.name
}

output "elasticbeanstalk_cname" {
  description = "Elastic Beanstalk environment CNAME"
  value       = aws_elastic_beanstalk_environment.react_env.cname
}

output "elasticbeanstalk_endpoint_url" {
  description = "Elastic Beanstalk environment endpoint URL"
  value       = "http://${aws_elastic_beanstalk_environment.react_env.cname}"
}

# AWS Account Information
output "aws_account_id" {
  description = "AWS Account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "aws_region" {
  description = "AWS Region"
  value       = data.aws_region.current.id
}
