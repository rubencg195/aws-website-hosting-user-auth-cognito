# AWS Elastic Beanstalk Infrastructure
# This file contains the Elastic Beanstalk environment for hosting the React.js app

# Data sources
data "aws_elastic_beanstalk_solution_stack" "php" {
  most_recent = true
  name_regex  = "64bit Amazon Linux 2023.*running PHP"
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Local variables for configuration
locals {
  # Elastic Beanstalk configuration
  solution_stack_name = data.aws_elastic_beanstalk_solution_stack.php.name
  instance_type       = "t3.micro"
  min_size           = 1
  max_size           = 4
  load_balancer_type = "classic"
  service_role       = "aws-elasticbeanstalk-service-role"
  
  # Network configuration
  vpc_cidr           = "10.0.0.0/16"
  subnet_cidrs       = ["10.0.1.0/24", "10.0.2.0/24"]
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 2)
  
  # Port configuration
  http_port  = 80
  https_port = 443
  ssh_port   = 22
  app_port   = 8080
  
  # Health check configuration
  health_check_interval    = 30
  healthy_threshold_count  = 3
  unhealthy_threshold_count = 5
  
  # Environment configuration
  node_env = "production"
  system_type = "enhanced"
  
  # Application configuration
  app_name    = "react-auth-demo"
  app_version = "1.0.0"
  serve_version = "^14.2.1"
  node_version = ">=20.0.0"
  
  # IAM policy ARNs
  elasticbeanstalk_policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
  cloudwatch_policy_arn      = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  
  # Security group rules
  allowed_cidr_blocks = ["0.0.0.0/0"]
  
  # Subnet IDs (computed after subnets are created)
  subnet_ids = [aws_subnet.subnet_a.id, aws_subnet.subnet_b.id]
}

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
      
                    # Create a minimal test PHP file to verify platform works
       @'
 <?php
 phpinfo();
 ?>
 '@ | Out-File -FilePath "elasticbeanstalk-deployment/index.php" -Encoding UTF8
      
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

# IAM role for Elastic Beanstalk EC2 instances
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

# IAM role for Elastic Beanstalk service
resource "aws_iam_role" "elasticbeanstalk_service_role" {
  name = "aws-elasticbeanstalk-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "elasticbeanstalk.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "aws-elasticbeanstalk-service-role"
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
  policy_arn = local.elasticbeanstalk_policy_arn
}

# IAM policy attachment for CloudWatch
resource "aws_iam_role_policy_attachment" "elasticbeanstalk_cloudwatch_policy" {
  role       = aws_iam_role.elasticbeanstalk_role.name
  policy_arn = local.cloudwatch_policy_arn
}

# IAM policy attachments for Elastic Beanstalk service role
resource "aws_iam_role_policy_attachment" "elasticbeanstalk_service_policy" {
  role       = aws_iam_role.elasticbeanstalk_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkEnhancedHealth"
}

resource "aws_iam_role_policy_attachment" "elasticbeanstalk_service_worker_policy" {
  role       = aws_iam_role.elasticbeanstalk_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkService"
}

# Security group for Elastic Beanstalk
resource "aws_security_group" "elasticbeanstalk_sg" {
  name        = "${local.project_name}-${local.environment}-elasticbeanstalk-sg"
  description = "Security group for Elastic Beanstalk environment"
  vpc_id      = aws_vpc.default.id

  # HTTP access
  ingress {
    description = "HTTP from anywhere"
    from_port   = local.http_port
    to_port     = local.http_port
    protocol    = "tcp"
    cidr_blocks = local.allowed_cidr_blocks
  }

  # HTTPS access
  ingress {
    description = "HTTPS from anywhere"
    from_port   = local.https_port
    to_port     = local.https_port
    protocol    = "tcp"
    cidr_blocks = local.allowed_cidr_blocks
  }

  # SSH access (for debugging)
  ingress {
    description = "SSH from anywhere"
    from_port   = local.ssh_port
    to_port     = local.ssh_port
    protocol    = "tcp"
    cidr_blocks = local.allowed_cidr_blocks
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = local.allowed_cidr_blocks
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
  solution_stack_name = local.solution_stack_name
  
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
    value     = local.instance_type
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MinSize"
    value     = tostring(local.min_size)
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MaxSize"
    value     = tostring(local.max_size)
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "LoadBalancerType"
    value     = local.load_balancer_type
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "ServiceRole"
    value     = aws_iam_role.elasticbeanstalk_service_role.name
  }

  # VPC Configuration
  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = aws_vpc.default.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = join(",", local.subnet_ids)
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBScheme"
    value     = "public"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = join(",", local.subnet_ids)
  }


         


  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "NODE_ENV"
    value     = local.node_env
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
    value     = local.system_type
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
    value     = tostring(local.health_check_interval)
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "HealthyThresholdCount"
    value     = tostring(local.healthy_threshold_count)
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "UnhealthyThresholdCount"
    value     = tostring(local.unhealthy_threshold_count)
  }

  # Environment variables for React app
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "PORT"
    value     = tostring(local.app_port)
  }



  tags = {
    Name        = "${local.project_name}-${local.environment}-env"
    Environment = local.environment
    Project     = local.project_name
  }
}

# Create a default VPC for Elastic Beanstalk
resource "aws_vpc" "default" {
  cidr_block           = local.vpc_cidr
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
  cidr_block              = local.subnet_cidrs[0]
  availability_zone       = local.availability_zones[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet-a-elasticbeanstalk"
  }
}

resource "aws_subnet" "subnet_b" {
  vpc_id                  = aws_vpc.default.id
  cidr_block              = local.subnet_cidrs[1]
  availability_zone       = local.availability_zones[1]
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

