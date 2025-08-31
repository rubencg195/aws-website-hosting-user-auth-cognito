# AWS S3 Infrastructure
# This file contains the S3 bucket and related resources for hosting the React app

# S3 Bucket for website hosting
resource "aws_s3_bucket" "website" {
  bucket = "${local.project_name}-${local.environment}-website"
  tags = {
    Name        = "${local.project_name}-${local.environment}-website"
    Environment = local.environment
    Project     = local.project_name
  }
}

# S3 Bucket versioning
resource "aws_s3_bucket_versioning" "website" {
  bucket = aws_s3_bucket.website.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket lifecycle configuration
resource "aws_s3_bucket_lifecycle_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  rule {
    id     = "website_lifecycle"
    status = "Enabled"
    
    # Filter for all objects
    filter {
      prefix = ""
    }

    # Clean up old versions after 30 days
    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    # Clean up incomplete multipart uploads after 7 days
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# S3 Bucket public access block
resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# S3 Bucket policy for public read access
resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.website.arn}/*"
      },
      {
        Sid       = "PublicReadListBucket"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:ListBucket"
        Resource  = aws_s3_bucket.website.arn
      }
    ]
  })
}

# S3 Bucket website configuration
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

# Local build and upload to S3
resource "null_resource" "build_and_upload" {
  triggers = {
    source_hash = filemd5("./src/App.js")
    package_hash = filemd5("./package.json")
    manifest_hash = filemd5("./public/manifest.json")
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "Building React application..."
      npm ci
      npm run build
      echo "Build completed successfully!"
    EOT
  }
}

# S3 objects for website files with proper content types
resource "aws_s3_object" "website_files" {
  for_each = fileset("./build", "**/*")

  bucket       = aws_s3_bucket.website.id
  key          = each.value
  source       = "./build/${each.value}"
  etag         = filemd5("./build/${each.value}")
  
  # Enhanced content type detection with fallbacks
  content_type = lookup(local.mime_types, split(".", each.value)[length(split(".", each.value)) - 1], "application/octet-stream")
  
  # Ensure proper metadata for critical files
  metadata = {
    "cache-control" = contains(["html", "js", "css"], split(".", each.value)[length(split(".", each.value)) - 1]) ? "public, max-age=31536000" : "public, max-age=86400"
  }

  depends_on = [null_resource.build_and_upload]
}

# Ensure manifest.json is always properly uploaded with correct content type
resource "aws_s3_object" "manifest_json" {
  bucket       = aws_s3_bucket.website.id
  key          = "manifest.json"
  source       = "./public/manifest.json"
  etag         = filemd5("./public/manifest.json")
  content_type = "application/json; charset=utf-8"
  
  # Ensure this is uploaded after the build
  depends_on = [null_resource.build_and_upload]
  
  # Add cache control for manifest
  metadata = {
    "cache-control" = "public, max-age=3600"
  }
  
  # Validate JSON format before upload
  provisioner "local-exec" {
    command = <<-EOT
      echo "Validating manifest.json..."
      node -e "JSON.parse(require('fs').readFileSync('./public/manifest.json', 'utf8')); console.log('manifest.json is valid JSON');"
    EOT
  }
}

# Note: CloudFront invalidation is handled manually or via AWS CLI
# Run this command after deployment to clear cache:
# aws cloudfront create-invalidation --distribution-id ${aws_cloudfront_distribution.website.id} --paths "/*"


