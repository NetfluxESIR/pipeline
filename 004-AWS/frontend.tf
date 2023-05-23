resource "terraform_data" "env" {
  provisioner "local-exec" {
    command = "export BACKEND_URL=http://${aws_lb.video_backend_load_balancer.dns_name} && export BUCKET_REGION=${aws_s3_bucket.video-processed.bucket} && export BUCKET_NAME=${aws_s3_bucket.video-processed.bucket}"
  }
  depends_on = [aws_s3_bucket.video-processed, aws_lb.video_backend_load_balancer]
}

resource "aws_s3_bucket" "frontend_bucket" {
  bucket = "frontend-bucket-netflux"
  tags = {
    Name = "frontend-bucket"
  }
  provisioner "local-exec" {
    command = "mkdir site && cd site && git clone https://github.com/NetfluxESIR/frontend.git && cd frontend && npm install && npm run build && cd .. && cd .."
  }
  depends_on = [terraform_data.env]
}

resource "aws_s3_bucket_website_configuration" "frontend_bucket_website" {
  bucket = aws_s3_bucket.frontend_bucket.id
  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "error.html"
  }
  depends_on = [aws_s3_bucket.frontend_bucket, aws_s3_object.frontend_bucket_object]
}

resource "aws_s3_object" "frontend_bucket_object" {
  for_each     = fileset("${path.module}/site/frontend/dist", "**/*.*")
  source       = "${path.module}/site/frontend/dist/${each.value}"
  content_type = "text/html"
  bucket       = aws_s3_bucket.frontend_bucket.id
  key          = each.value
  depends_on   = [aws_s3_bucket.frontend_bucket]
}

resource "aws_s3_bucket_acl" "frontend_bucket_acl" {
  bucket = aws_s3_bucket.frontend_bucket.id
  acl    = "public-read"
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
  depends_on = [aws_s3_bucket.frontend_bucket]
}