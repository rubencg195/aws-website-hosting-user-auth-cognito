# AWS Elastic Beanstalk Infrastructure
# This file contains the Elastic Beanstalk environment for hosting the React.js app

# Data sources
data "aws_elastic_beanstalk_solution_stack" "nodejs" {
  most_recent = true
  name_regex  = "64bit Amazon Linux 2023.*running Node.js 20"
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Local variables for configuration
locals {
  # Elastic Beanstalk configuration
  solution_stack_name = data.aws_elastic_beanstalk_solution_stack.nodejs.name
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
      
      # Clean up previous builds
      if (Test-Path "elasticbeanstalk-deployment") {
        Remove-Item -Recurse -Force "elasticbeanstalk-deployment"
      }
      New-Item -ItemType Directory -Path "elasticbeanstalk-deployment" -Force | Out-Null
      
      # Build the React app
      npm run build
      
      # Copy build files to deployment directory
      Copy-Item -Recurse "build/*" -Destination "elasticbeanstalk-deployment/"
      
                    # Create package.json for deployment
                    $packageJson = @{
                        name = "react-auth-demo"
                        version = "1.0.0"
                        scripts = @{
                            start = "node server.js"
                        }
                        dependencies = @{}
                        engines = @{
                            node = ">=20.0.0"
                        }
                    } | ConvertTo-Json -Depth 10
                                         $packageJson | Set-Content -Path "elasticbeanstalk-deployment/package.json" -Encoding UTF8 -NoNewline
      
                    # Create server.js for Elastic Beanstalk
                    $serverJs = @'
const http = require('http');
const fs = require('fs');
const path = require('path');

const hostname = '0.0.0.0';
const port = process.env.PORT || 8080;

const server = http.createServer((req, res) => {
    let filePath = path.join(__dirname, 'build', req.url === '/' ? 'index.html' : req.url);
    const extname = path.extname(filePath);
    const contentType = getContentType(extname);

    if (fs.existsSync(filePath)) {
        try {
            const content = fs.readFileSync(filePath);
            res.writeHead(200, {'Content-Type': contentType});
            res.end(content);
        } catch (err) {
            console.error('Error reading file:', err);
            res.writeHead(500);
            res.end('Server Error');
        }
    } else {
        // For SPA routing, serve index.html for all routes
        try {
            const indexPath = path.join(__dirname, 'build', 'index.html');
            if (fs.existsSync(indexPath)) {
                const content = fs.readFileSync(indexPath);
                res.writeHead(200, {'Content-Type': 'text/html'});
                res.end(content);
            } else {
                res.writeHead(404);
                res.end('Not Found');
            }
        } catch (err) {
            console.error('Error serving index.html:', err);
            res.writeHead(500);
            res.end('Server Error');
        }
    }
});

function getContentType(extname) {
    switch (extname) {
        case '.js':
            return 'text/javascript';
        case '.css':
            return 'text/css';
        case '.json':
            return 'application/json';
        case '.png':
            return 'image/png';
        case '.jpg':
            return 'image/jpeg';
        case '.gif':
            return 'image/gif';
        case '.svg':
            return 'image/svg+xml';
        case '.ico':
            return 'image/x-icon';
        case '.woff':
            return 'font/woff';
        case '.woff2':
            return 'font/woff2';
        case '.ttf':
            return 'font/ttf';
        case '.eot':
            return 'application/vnd.ms-fontobject';
        default:
            return 'text/html';
    }
}

server.listen(port, hostname, () => {
    console.log(`Server running at http://$${hostname}:$${port}/`);
    console.log(`Serving files from: $${path.join(__dirname, 'build')}`);
}).on('error', err => {
    console.error('Server error:', err);
});
'@
                                         $serverJs | Set-Content -Path "elasticbeanstalk-deployment/server.js" -Encoding UTF8 -NoNewline
      
      # Create Procfile for Elastic Beanstalk
                           "web: node server.js" | Set-Content -Path "elasticbeanstalk-deployment/Procfile" -Encoding UTF8 -NoNewline
      
                    # Create .ebextensions for Nginx SPA routing
                    New-Item -ItemType Directory -Path "elasticbeanstalk-deployment/.ebextensions" -Force | Out-Null
                    $nginxConfig = @'
files:
  "/etc/nginx/conf.d/proxy.conf":
    mode: "000644"
    owner: root
    group: root
    content: |
      upstream nodejs {
          server 127.0.0.1:8080;
          keepalive 256;
      }
      
      server {
          listen 80;
          
          location / {
              proxy_pass  http://nodejs;
              proxy_set_header   Connection "";
              proxy_http_version 1.1;
              proxy_set_header        Host            $host;
              proxy_set_header        X-Real-IP       $remote_addr;
              proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
          }
      }
'@
                                         $nginxConfig | Set-Content -Path "elasticbeanstalk-deployment/.ebextensions/02_nginx_spa.config" -Encoding UTF8 -NoNewline
      
             # Create deployment package with proper Unix paths
       # Use 7-Zip to create cross-platform ZIP files with proper directory separators
       # Change to deployment directory and create ZIP from there
       Set-Location "elasticbeanstalk-deployment"
       
       # Try to use 7-Zip if available, fallback to PowerShell Compress-Archive
       $sevenZipPath = $null
       
               # Check common 7-Zip installation paths
        $possiblePaths = @(
          'C:\Program Files\7-Zip\7z.exe',
          'C:\Program Files (x86)\7-Zip\7z.exe',
          "$env:ProgramFiles\7-Zip\7z.exe",
          "$env:ProgramFiles(x86)\7-Zip\7z.exe"
        )
       
       foreach ($path in $possiblePaths) {
         if (Test-Path $path) {
           $sevenZipPath = $path
           break
         }
       }
       
               if ($sevenZipPath) {
          Write-Host "Using 7-Zip to create cross-platform ZIP package..."
          # Use 7-Zip with proper parameters for cross-platform compatibility
          # a = archive, tzip = zip format, -mx=0 = no compression (faster)
          # Use explicit file paths instead of wildcards to ensure proper path handling
          # Create ZIP in current directory first, then move to parent
          & $sevenZipPath a -tzip -mx=0 "react-app-elasticbeanstalk.zip" "index.html" "static" "asset-manifest.json" "manifest.json" "package.json" "server.js" "Procfile" ".ebextensions"
          
          if ($LASTEXITCODE -eq 0) {
            # Move the ZIP file to parent directory
            Move-Item "react-app-elasticbeanstalk.zip" ".." -Force
            Write-Host "7-Zip ZIP package created successfully with proper Unix paths"
            $zipCreated = $true
          } else {
            Write-Host "7-Zip failed, falling back to PowerShell Compress-Archive..."
            # Fallback to PowerShell
            try {
              Compress-Archive -Path "*" -DestinationPath "../react-app-elasticbeanstalk.zip" -Force
              $zipCreated = $true
              Write-Host "PowerShell Compress-Archive succeeded"
            } catch {
              Write-Error "PowerShell Compress-Archive also failed: $_"
              $zipCreated = $false
            }
          }
        } else {
          Write-Host "7-Zip not found, using PowerShell Compress-Archive (will have Windows path separators)..."
          # Fallback to PowerShell
          try {
            Compress-Archive -Path "*" -DestinationPath "../react-app-elasticbeanstalk.zip" -Force
            $zipCreated = $true
            Write-Host "PowerShell Compress-Archive succeeded"
          } catch {
            Write-Error "PowerShell Compress-Archive failed: $_"
            $zipCreated = $false
          }
        }
        
        if (-not $zipCreated) {
          Write-Error "Failed to create ZIP package"
          exit 1
        }
       
       # Return to parent directory
       Set-Location ".."
       
       # Wait a moment for the file to be fully written
       Start-Sleep -Seconds 2
       
       # Verify the ZIP file was created and is accessible
       if (Test-Path "react-app-elasticbeanstalk.zip") {
         $fileSize = (Get-Item "react-app-elasticbeanstalk.zip").Length
         Write-Host "✅ Elastic Beanstalk deployment package created: react-app-elasticbeanstalk.zip (Size: $fileSize bytes)"
         
         # Test the ZIP file by listing its contents
         try {
           $zipContents = Get-ChildItem "react-app-elasticbeanstalk.zip" | Select-Object Name, Length
           Write-Host "ZIP file contents: $zipContents"
         } catch {
           Write-Host "Warning: Could not verify ZIP contents, but file exists"
         }
       } else {
         Write-Error "❌ Failed to create react-app-elasticbeanstalk.zip"
         exit 1
       }
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

# S3 object for the deployment package (ZIP file - Elastic Beanstalk requirement)
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

