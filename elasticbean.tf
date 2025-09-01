# AWS Elastic Beanstalk Infrastructure
# This file contains the Elastic Beanstalk environment for hosting the React.js app

# Local build and deployment automation
resource "null_resource" "elasticbeanstalk_build_and_deploy" {
  triggers = {
    # Trigger rebuild when source files change
    source_hash = filemd5("${path.module}/src/App.js")
    package_hash = filemd5("${path.module}/package.json")
    timestamp   = timestamp()
  }

  provisioner "local-exec" {
    interpreter = ["powershell", "-Command"]
    command = <<-EOT
      Write-Host "🚀 Building React app for Elastic Beanstalk..."
      
      # Clean previous build
      if (Test-Path "build") {
        Remove-Item -Recurse -Force "build"
      }
      
      # Install dependencies
      npm ci
      
      # Build the React app
      npm run build
      
      # Create deployment directory
      if (Test-Path "elasticbeanstalk-deployment") {
        Remove-Item -Recurse -Force "elasticbeanstalk-deployment"
      }
      New-Item -ItemType Directory -Path "elasticbeanstalk-deployment" -Force | Out-Null
      New-Item -ItemType Directory -Path "elasticbeanstalk-deployment/.ebextensions" -Force | Out-Null
      
             # Copy build files
       Copy-Item -Recurse "build/*" -Destination "elasticbeanstalk-deployment/"
       # Only copy the nginx SPA configuration, not the build config
       Copy-Item ".ebextensions/02_nginx_spa.config" -Destination "elasticbeanstalk-deployment/.ebextensions/"
      
             # Create Elastic Beanstalk specific package.json
       @'
 {
   "name": "react-auth-demo",
   "version": "1.0.0",
   "scripts": {
     "start": "serve -s . -l 8080"
   },
   "dependencies": {
     "serve": "^14.2.1"
   },
   "engines": {
     "node": ">=18.0.0"
   }
 }
 '@ | Out-File -FilePath "elasticbeanstalk-deployment/package.json" -Encoding UTF8
       
       # Create Procfile for Amazon Linux 2023
       @'
 web: npm start
 '@ | Out-File -FilePath "elasticbeanstalk-deployment/Procfile" -Encoding UTF8
       
       # Install serve package in the deployment directory
       Set-Location "elasticbeanstalk-deployment"
       npm install --production
       Set-Location ".."
      
      # Create deployment archive using PowerShell
      Compress-Archive -Path "elasticbeanstalk-deployment/*" -DestinationPath "react-app-elasticbeanstalk.zip" -Force
      
      # Clean up deployment directory
      Remove-Item -Recurse -Force "elasticbeanstalk-deployment"
      
      Write-Host "✅ Elastic Beanstalk deployment package created: react-app-elasticbeanstalk.zip"
    EOT
  }
}

# S3 bucket for Elastic Beanstalk deployment package
resource "aws_s3_bucket" "elasticbeanstalk_deployment" {
  bucket = "${local.project_name}-${local.environment}-elasticbeanstalk-deployment"

  tags = {
    Name        = "${local.project_name}-${local.environment}-elasticbeanstalk-deployment"
    Environment = local.environment
    Project     = local.project_name
  }
}

# S3 bucket versioning
resource "aws_s3_bucket_versioning" "elasticbeanstalk_deployment" {
  bucket = aws_s3_bucket.elasticbeanstalk_deployment.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket public access block
resource "aws_s3_bucket_public_access_block" "elasticbeanstalk_deployment" {
  bucket = aws_s3_bucket.elasticbeanstalk_deployment.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 object for the deployment package
resource "aws_s3_object" "elasticbeanstalk_deployment_package" {
  bucket = aws_s3_bucket.elasticbeanstalk_deployment.id
  key    = "react-app-elasticbeanstalk.zip"
  source = "${path.module}/react-app-elasticbeanstalk.zip"
  etag   = null_resource.elasticbeanstalk_build_and_deploy.triggers.timestamp

  depends_on = [null_resource.elasticbeanstalk_build_and_deploy]

  tags = {
    Name        = "${local.project_name}-${local.environment}-deployment-package"
    Environment = local.environment
    Project     = local.project_name
  }
}

# IAM role for Elastic Beanstalk
resource "aws_iam_role" "elasticbeanstalk_role" {
  name = "${local.project_name}-${local.environment}-elasticbeanstalk-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${local.project_name}-${local.environment}-elasticbeanstalk-role"
    Environment = local.environment
    Project     = local.project_name
  }
}

# IAM instance profile for Elastic Beanstalk
resource "aws_iam_instance_profile" "elasticbeanstalk_profile" {
  name = "${local.project_name}-${local.environment}-elasticbeanstalk-profile"
  role = aws_iam_role.elasticbeanstalk_role.name
}

# IAM policy attachment for Elastic Beanstalk
resource "aws_iam_role_policy_attachment" "elasticbeanstalk_policy" {
  role       = aws_iam_role.elasticbeanstalk_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

# IAM policy attachment for CloudWatch
resource "aws_iam_role_policy_attachment" "elasticbeanstalk_cloudwatch_policy" {
  role       = aws_iam_role.elasticbeanstalk_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Security group for Elastic Beanstalk
resource "aws_security_group" "elasticbeanstalk_sg" {
  name        = "${local.project_name}-${local.environment}-elasticbeanstalk-sg"
  description = "Security group for Elastic Beanstalk environment"

  # HTTP access
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access
  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH access (for debugging)
  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${local.project_name}-${local.environment}-elasticbeanstalk-sg"
    Environment = local.environment
    Project     = local.project_name
  }
}

# Elastic Beanstalk application
resource "aws_elastic_beanstalk_application" "react_app" {
  name        = "${local.project_name}-${local.environment}"
  description = "React.js application with AWS Cognito authentication"

  tags = {
    Name        = "${local.project_name}-${local.environment}-app"
    Environment = local.environment
    Project     = local.project_name
  }
}

# Elastic Beanstalk application version
resource "aws_elastic_beanstalk_application_version" "react_app_version" {
  name        = "v${formatdate("YYYYMMDD-HHmmss", timestamp())}"
  application = aws_elastic_beanstalk_application.react_app.name
  bucket      = aws_s3_bucket.elasticbeanstalk_deployment.id
  key         = aws_s3_object.elasticbeanstalk_deployment_package.key

  depends_on = [aws_s3_object.elasticbeanstalk_deployment_package]

  tags = {
    Name        = "${local.project_name}-${local.environment}-app-version"
    Environment = local.environment
    Project     = local.project_name
  }
}

# Elastic Beanstalk environment
resource "aws_elastic_beanstalk_environment" "react_env" {
  name                = "${local.project_name}-${local.environment}-env"
  application         = aws_elastic_beanstalk_application.react_app.name
  solution_stack_name = "64bit Amazon Linux 2 v5.8.0 running Node.js 18"
  
  # Use the S3 deployment package
  version_label = aws_elastic_beanstalk_application_version.react_app_version.name

           # Environment configuration
         setting {
           namespace = "aws:autoscaling:launchconfiguration"
           name      = "IamInstanceProfile"
           value     = aws_iam_instance_profile.elasticbeanstalk_profile.name
         }
         


  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "SecurityGroups"
    value     = aws_security_group.elasticbeanstalk_sg.id
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = "t3.micro"
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MinSize"
    value     = "1"
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MaxSize"
    value     = "4"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "LoadBalancerType"
    value     = "classic"
  }

             setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "ServiceRole"
    value     = "aws-elasticbeanstalk-service-role"
  }


         


  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "NODE_ENV"
    value     = "production"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "REACT_APP_AWS_REGION"
    value     = local.aws_region
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "REACT_APP_USER_POOL_ID"
    value     = aws_cognito_user_pool.main.id
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "REACT_APP_USER_POOL_CLIENT_ID"
    value     = aws_cognito_user_pool_client.main.id
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "REACT_APP_COGNITO_DOMAIN"
    value     = aws_cognito_user_pool_domain.main.domain
  }

  # Health check configuration
  setting {
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    name      = "SystemType"
    value     = "enhanced"
  }

  # Load balancer configuration
  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "HealthCheckPath"
    value     = "/"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "HealthCheckInterval"
    value     = "30"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "HealthyThresholdCount"
    value     = "3"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "UnhealthyThresholdCount"
    value     = "5"
  }

  # Environment variables for React app
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "PORT"
    value     = "8080"
  }



  tags = {
    Name        = "${local.project_name}-${local.environment}-env"
    Environment = local.environment
    Project     = local.project_name
  }
}

# Create a default VPC for Elastic Beanstalk
resource "aws_vpc" "default" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "default-vpc-elasticbeanstalk"
  }
}

# Create internet gateway
resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.default.id

  tags = {
    Name = "default-igw-elasticbeanstalk"
  }
}

# Create route table
resource "aws_route_table" "default" {
  vpc_id = aws_vpc.default.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.default.id
  }

  tags = {
    Name = "default-rt-elasticbeanstalk"
  }
}

# Create subnets in different AZs
resource "aws_subnet" "subnet_a" {
  vpc_id                  = aws_vpc.default.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet-a-elasticbeanstalk"
  }
}

resource "aws_subnet" "subnet_b" {
  vpc_id                  = aws_vpc.default.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet-b-elasticbeanstalk"
  }
}

# Associate route table with subnets
resource "aws_route_table_association" "subnet_a" {
  subnet_id      = aws_subnet.subnet_a.id
  route_table_id = aws_route_table.default.id
}

resource "aws_route_table_association" "subnet_b" {
  subnet_id      = aws_subnet.subnet_b.id
  route_table_id = aws_route_table.default.id
}

# Local variables for subnet IDs
locals {
  subnet_ids = [aws_subnet.subnet_a.id, aws_subnet.subnet_b.id]
}
