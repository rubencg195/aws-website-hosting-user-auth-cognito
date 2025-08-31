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
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "Building React application..."
      npm ci
      npm run build
      echo "Build completed successfully!"
    EOT
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "Uploading built files to S3..."
      aws s3 sync build/ s3://${aws_s3_bucket.website.bucket}/ --delete
      echo "Upload completed successfully!"
    EOT
  }
}

# S3 objects for website files
resource "aws_s3_object" "website_files" {
  for_each = fileset("./build", "**/*")

  bucket       = aws_s3_bucket.website.id
  key          = each.value
  source       = "./build/${each.value}"
  etag         = filemd5("./build/${each.value}")
  content_type = lookup(local.mime_types, split(".", each.value)[length(split(".", each.value)) - 1], "application/octet-stream")

  depends_on = [null_resource.build_and_upload]
}


