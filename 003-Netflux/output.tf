output "private_key" {
  value     = tls_private_key.key.private_key_pem
  sensitive = true
}

output "website_url" {
  value = "http://${aws_s3_bucket_website_configuration.frontend_bucket_website.website_endpoint}"
}