resource "aws_s3_bucket" "frontend_bucket" {
  bucket        = "netflux"
  force_destroy = true
  provisioner "local-exec" {
    command = "rm -rf site && mkdir site && cd site && git clone https://github.com/NetfluxESIR/frontend.git && cd frontend && npm install && BACKEND_URL=http://${aws_instance.backend_host.public_ip}/api/v1 BUCKET_NAME=${aws_s3_bucket.video-processed.bucket} BUCKET_REGION=${aws_s3_bucket.video-processed.region} npm run generate && cd .. && cd .. && sleep 1"
  }
}

resource "aws_s3_bucket_website_configuration" "frontend_bucket_website" {
  bucket = aws_s3_bucket.frontend_bucket.id
  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "index.html"
  }
  depends_on = [aws_s3_object.frontend_bucket_object]
}

resource "aws_s3_object" "frontend_bucket_object" {
  for_each     = fileset("${path.module}/site/frontend/dist/", "**/*")
  source       = "${path.module}/site/frontend/dist/${each.value}"
  bucket       = aws_s3_bucket.frontend_bucket.id
  key          = each.value
  content_type = endswith(each.value, ".html") ? "text/html" : endswith(each.value, ".js") ? "application/javascript" : endswith(each.value, ".css") ? "text/css" : "binary/octet-stream"
  depends_on   = [aws_s3_bucket_acl.frontend_bucket_acl, aws_s3_bucket.frontend_bucket]
}

resource "aws_s3_bucket_public_access_block" "frontend_bucket_public_access_block" {
  bucket                  = aws_s3_bucket.frontend_bucket.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
  depends_on              = [aws_s3_bucket.frontend_bucket, aws_s3_bucket_ownership_controls.frontend_bucket_ownership_controls]
}

resource "aws_s3_bucket_ownership_controls" "frontend_bucket_ownership_controls" {
  bucket = aws_s3_bucket.frontend_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
  depends_on = [aws_s3_bucket.frontend_bucket]
}

resource "aws_s3_bucket_acl" "frontend_bucket_acl" {
  bucket     = aws_s3_bucket.frontend_bucket.id
  acl        = "public-read"
  depends_on = [aws_s3_bucket_public_access_block.frontend_bucket_public_access_block]
}

resource "aws_s3_bucket_policy" "frontend_bucket_policy" {
  bucket = aws_s3_bucket.frontend_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action = [
          "s3:GetObject"
        ]
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.frontend_bucket.id}/*"
        ]
      }
    ]
  })
  depends_on = [aws_s3_bucket_public_access_block.frontend_bucket_public_access_block]
}