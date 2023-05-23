resource "aws_db_instance" "backend_db" {
  allocated_storage      = 20
  engine                 = "postgres"
  instance_class         = "db.t2.micro"
  db_name                = "video_pipeline"
  username               = "video_pipeline"
  password               = "video_pipeline"
  db_subnet_group_name   = "video-pipeline-db-subnet-group"
  vpc_security_group_ids = [aws_security_group.video_backend.id]
  skip_final_snapshot    = true
}

resource "aws_db_subnet_group" "video-pipeline-db-subnet-group" {
  name       = "video-pipeline-db-subnet-group"
  subnet_ids = [aws_subnet.video.id]
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

resource "aws_vpc" "video" {
  cidr_block = "172.16.0.0/16"
}

resource "aws_subnet" "video" {
  vpc_id     = aws_vpc.video.id
  cidr_block = "172.16.10.0/24"
}

resource "aws_network_interface" "video" {
  subnet_id   = aws_subnet.video.id
  private_ips = ["172.16.10.100"]
}

resource "aws_instance" "backend_host" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  network_interface {
    network_interface_id = aws_network_interface.video.id
    device_index         = 0
  }
  key_name = aws_key_pair.video-pipeline.key_name
  user_data = templatefile("${path.module}/templates/backend_user_data.sh", {
    github_token           = var.github_token
    github_username        = var.github_username
    admin_account_email    = var.admin_account_email
    admin_account_password = var.admin_account_password
    aws_access_key         = aws_iam_access_key.video-processing.id
    aws_secret_key         = aws_iam_access_key.video-processing.secret
    bucket_name            = aws_s3_bucket.video.bucket
    region                 = aws_s3_bucket.video.region
    db_host                = aws_db_instance.backend_db.address
    db_user                = aws_db_instance.backend_db.username
    db_pass                = aws_db_instance.backend_db.password
    db_name                = aws_db_instance.backend_db.db_name
  })
  depends_on = [aws_db_instance.backend_db, aws_key_pair.video-pipeline, aws_iam_access_key.video-processing]
}

resource "aws_security_group" "video_backend" {
  name        = "video-backend"
  description = "Allow all inbound traffic"
  vpc_id      = aws_vpc.video.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "video_backend_load_balancer" {
  name               = "video-backend-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.video_backend.id]
  subnets            = [aws_subnet.video.id]
}

resource "aws_lb_target_group" "video_backend_target_group" {
  name     = "video-backend-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.video.id
}

resource "aws_lb_listener" "video_backend_listener" {
  load_balancer_arn = aws_lb.video_backend_load_balancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.video_backend_target_group.arn
    type             = "forward"
  }
}

resource "aws_lb_target_group_attachment" "video_backend_target_group_attachment" {
  target_group_arn = aws_lb_target_group.video_backend_target_group.arn
  target_id        = aws_instance.backend_host.id
  port             = 80
}

resource "aws_key_pair" "video-pipeline" {
  key_name   = "video-pipeline"
  public_key = tls_private_key.key.private_key_openssh
  depends_on = [tls_private_key.key]
}

resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}