data "terraform_remote_state" "service_state" {
  backend = "local"
  config = {
    path = "${path.module}/../002-Services/terraform.tfstate"
  }
}

resource "aws_s3_bucket" "video" {
  bucket        = "netflux-video"
  force_destroy = true
  tags = {
    Name        = "video"
    Environment = "production"
  }
}

resource "aws_s3_bucket_cors_configuration" "video-cors" {
  bucket = aws_s3_bucket.video.id
  cors_rule {
    allowed_methods = ["GET", "PUT", "POST", "DELETE"]
    allowed_origins = ["*"]
    allowed_headers = ["*"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket_cors_configuration" "video-processed-cors" {
  bucket = aws_s3_bucket.video-processed.id
  cors_rule {
    allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
    allowed_origins = ["*"]
    allowed_headers = ["*"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket" "video-processed" {
  bucket        = "netflux-video-processed"
  force_destroy = true
  tags = {
    Name        = "video-processed"
    Environment = "production"
  }
}

resource "aws_s3_bucket_public_access_block" "video_processed_bucket_public_access_block" {
  bucket                  = aws_s3_bucket.video-processed.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
  depends_on              = [aws_s3_bucket.video-processed, aws_s3_bucket_ownership_controls.video_processed_bucket_ownership_controls]
}

resource "aws_s3_bucket_ownership_controls" "video_processed_bucket_ownership_controls" {
  bucket = aws_s3_bucket.video-processed.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
  depends_on = [aws_s3_bucket.video-processed]
}

resource "aws_s3_bucket_acl" "video_processed_bucket_acl" {
  bucket     = aws_s3_bucket.video-processed.id
  acl        = "public-read"
  depends_on = [aws_s3_bucket_public_access_block.video_processed_bucket_public_access_block]
}

resource "aws_s3_bucket_policy" "video_processed_bucket_policy" {
  bucket = aws_s3_bucket.video-processed.id
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
          "arn:aws:s3:::${aws_s3_bucket.video-processed.id}/*"
        ]
      }
    ]
  })
  depends_on = [aws_s3_bucket_public_access_block.video_processed_bucket_public_access_block]
}

// Create a new User for the Video Processing Service
resource "aws_iam_user" "video-processing" {
  name = "video-processing"
  path = "/system/"
}

// Create a new IAM Policy for the Video Processing Service
resource "aws_iam_policy" "video-processing" {
  name        = "video-processing"
  path        = "/system/"
  description = "Policy for the Video Processing Service"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "Stmt1468949110000",
        "Effect" : "Allow",
        "Action" : [
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:ListBucketMultipartUploads",
          "s3:ListBucketVersions"
        ],
        "Resource" : [
          "arn:aws:s3:::${aws_s3_bucket.video.id}",
          "arn:aws:s3:::${aws_s3_bucket.video-processed.id}"
        ]
      },
      {
        "Sid" : "Stmt1468949110001",
        "Effect" : "Allow",
        "Action" : [
          "s3:AbortMultipartUpload",
          "s3:DeleteObject",
          "s3:DeleteObjectVersion",
          "s3:GetObject",
          "s3:GetObjectAcl",
          "s3:GetObjectVersion",
          "s3:GetObjectVersionAcl",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:PutObjectVersionAcl"
        ],
        "Resource" : [
          "arn:aws:s3:::${aws_s3_bucket.video.id}/*",
          "arn:aws:s3:::${aws_s3_bucket.video-processed.id}/*",
        ]
      }
    ]
  })
  depends_on = [aws_s3_bucket.video, aws_s3_bucket.video-processed]
}

// Attach the IAM Policy to the Video Processing Service User
resource "aws_iam_user_policy_attachment" "video-processing" {
  user       = aws_iam_user.video-processing.name
  policy_arn = aws_iam_policy.video-processing.arn
  depends_on = [aws_iam_policy.video-processing, aws_iam_user.video-processing]
}

// Create a new Access Key for the Video Processing Service User
resource "aws_iam_access_key" "video-processing" {
  user       = aws_iam_user.video-processing.name
  depends_on = [aws_iam_user_policy_attachment.video-processing]
}

resource "kubernetes_cron_job_v1" "video_bucket_replication" {
  metadata {
    name      = "bucket-replication"
    namespace = "video-pipeline-minio"
  }
  spec {
    concurrency_policy            = "Forbid"
    failed_jobs_history_limit     = 5
    schedule                      = "*/1 * * * *"
    starting_deadline_seconds     = 10
    successful_jobs_history_limit = 10
    job_template {
      metadata {}
      spec {
        backoff_limit              = 2
        ttl_seconds_after_finished = 10
        template {
          spec {
            container {
              name    = "mc"
              image   = "minio/mc"
              command = ["/bin/sh", "./scripts/replicate.sh"]
              volume_mount {
                name       = "scripts"
                mount_path = "/scripts"
              }
              env {
                name  = "MINIO_HOST"
                value = data.terraform_remote_state.service_state.outputs.minio_url
              }
              env {
                name  = "MINIO_ACCESS_KEY"
                value = data.terraform_remote_state.service_state.outputs.minio_access_key
              }
              env {
                name  = "MINIO_SECRET_KEY"
                value = data.terraform_remote_state.service_state.outputs.minio_secret_key
              }
            }
            volume {
              name = "scripts"
              config_map {
                name         = "video-bucket-replication-s3-mirror"
                default_mode = "0777"
              }
            }
          }
          metadata {}
        }
      }
    }
  }
  depends_on = [kubernetes_config_map.video_bucket_replication_s3_mirror_script]
}

// Write the replication script to the Volume
resource "kubernetes_config_map" "video_bucket_replication_s3_mirror_script" {
  metadata {
    name      = "video-bucket-replication-s3-mirror"
    namespace = "video-pipeline-minio"
  }
  data = {
    "replicate.sh" = <<EOF
#!/bin/sh
until mc alias set s3 https://s3.amazonaws.com ${aws_iam_access_key.video-processing.id} ${aws_iam_access_key.video-processing.secret}
do
  echo "Waiting for S3 to be available"
  sleep 1
done
until mc alias set video-pipeline http://${data.terraform_remote_state.service_state.outputs.minio_url} ${data.terraform_remote_state.service_state.outputs.minio_access_key} ${data.terraform_remote_state.service_state.outputs.minio_secret_key}
do
  echo "Waiting for Minio to be available"
  sleep 1
done
mc mirror --remove --overwrite s3/${aws_s3_bucket.video.bucket} video-pipeline/video-pipeline
EOF
  }
  depends_on = [aws_iam_access_key.video-processing]
}

resource "kubernetes_config_map" "video_bucket_replication_minio_mirror_script" {
  metadata {
    name      = "video-bucket-replication-minio-mirror"
    namespace = "video-pipeline-minio"
  }
  data = {
    "replicate.sh" = <<EOF
#!/bin/sh
until mc alias set s3 https://s3.${aws_s3_bucket.video-processed.region}.amazonaws.com ${aws_iam_access_key.video-processing.id} ${aws_iam_access_key.video-processing.secret}
do
  echo "Waiting for S3 to be available"
  sleep 1
done
until mc alias set video-pipeline-processed http://${data.terraform_remote_state.service_state.outputs.minio_url} ${data.terraform_remote_state.service_state.outputs.minio_access_key} ${data.terraform_remote_state.service_state.outputs.minio_secret_key}
do
  echo "Waiting for Minio to be available"
  sleep 1
done
mc mirror --watch --remove video-pipeline-processed/video-pipeline-processed s3/${aws_s3_bucket.video-processed.bucket}
EOF
  }
  depends_on = [aws_iam_access_key.video-processing]
}


resource "kubernetes_pod" "video_processed_bucket_replication" {
  metadata {
    name      = "processed-bucket-replication"
    namespace = "video-pipeline-minio"
  }
  spec {
    container {
      name    = "mc"
      image   = "minio/mc"
      command = ["/bin/sh", "./scripts/replicate.sh"]
      volume_mount {
        name       = "scripts"
        mount_path = "/scripts"
      }
      env {
        name  = "MINIO_HOST"
        value = data.terraform_remote_state.service_state.outputs.minio_url
      }
      env {
        name  = "MINIO_ACCESS_KEY"
        value = data.terraform_remote_state.service_state.outputs.minio_access_key
      }
      env {
        name  = "MINIO_SECRET_KEY"
        value = data.terraform_remote_state.service_state.outputs.minio_secret_key
      }
    }
    volume {
      name = "scripts"
      config_map {
        name         = "video-bucket-replication-minio-mirror"
        default_mode = "0777"
      }
    }
  }
  depends_on = [kubernetes_config_map.video_bucket_replication_minio_mirror_script]
}

