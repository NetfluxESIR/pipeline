output "private_key" {
  value     = tls_private_key.key.private_key_pem
  sensitive = true
}

output "website_url" {
  value = aws_s3_bucket.frontend_bucket.website_endpoint
}