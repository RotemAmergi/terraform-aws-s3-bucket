module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = var.site_name
  acl    = "private"

  versioning = {
    enabled = true
  }
  cors_rule = [
      {
      allowed_headers = ["*"]
      allowed_methods = ["GET","HEAD","PUT", "POST"]
      allowed_origins = ["*"]
      max_age_seconds = 3000
    }
  ]
  tags = {
    Environment = "Production"
    Regions = "EU"
  }
  // S3 bucket-level Public Access Block configuration
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = var.s3_origin_id
}

resource "aws_cloudfront_distribution" "s3_distribution" {

  enabled             = true
  comment             = "Production"

  origin {
    domain_name = module.s3_bucket.this_s3_bucket_bucket_regional_domain_name
    origin_id   = var.s3_origin_id
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }


  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = var.s3_origin_id
    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    forwarded_values {
      query_string = false
      
      headers = [
        "Origin",
        "Access-Control-Request-Headers",
        "Access-Control-Request-Method",
      ]
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Environment = "Staging"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${module.s3_bucket.this_s3_bucket_arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "example" {
  bucket = module.s3_bucket.this_s3_bucket_id
  policy = data.aws_iam_policy_document.s3_policy.json
}