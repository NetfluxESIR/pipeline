resource "aws_db_instance" "backend_db" {
  allocated_storage   = 20
  engine              = "postgres"
  instance_class      = "db.t4g.micro"
  db_name             = "video_pipeline"
  username            = "video_pipeline"
  password            = "video_pipeline"
  publicly_accessible = true
  skip_final_snapshot = true
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_security_group" "video_pipeline_sg" {
  name        = "video-pipeline"
  description = "Security group for video pipeline"
  ingress {
    description      = "HTTP"
    from_port        = 0
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_instance" "backend_host" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  security_groups             = [aws_security_group.video_pipeline_sg.name]
  key_name                    = aws_key_pair.video-pipeline.key_name
  user_data = templatefile("${path.module}/templates/backend_user_data.sh", {
    admin_account_email    = var.admin_account_email
    admin_account_password = var.admin_account_password
    aws_access_key         = aws_iam_access_key.video-processing.id
    aws_secret_key         = aws_iam_access_key.video-processing.secret
    bucket_name            = aws_s3_bucket.video.bucket
    region                 = aws_s3_bucket.video.region
    db_host                = aws_db_instance.backend_db.endpoint
    db_user                = aws_db_instance.backend_db.username
    db_pass                = aws_db_instance.backend_db.password
    db_name                = aws_db_instance.backend_db.db_name
  })
  depends_on = [
    aws_db_instance.backend_db,
    aws_key_pair.video-pipeline,
    aws_iam_access_key.video-processing,
    aws_security_group.video_pipeline_sg
  ]
}

resource "aws_key_pair" "video-pipeline" {
  key_name   = "video-pipeline"
  public_key = tls_private_key.key.public_key_openssh
  depends_on = [tls_private_key.key]
}

resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "key" {
  content  = tls_private_key.key.private_key_pem
  filename = "video-pipeline.pem"
}