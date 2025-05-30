terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "parking-lot-vpc"
    Environment = "FreeTier"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name        = "parking-lot-public-subnet"
    Environment = "FreeTier"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "parking-lot-igw"
    Environment = "FreeTier"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "parking-lot-public-rt"
    Environment = "FreeTier"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "app" {
  name        = "parking-lot-sg"
  description = "Security group for parking lot application"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access from anywhere"
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Application access from anywhere"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "parking-lot-sg"
    Environment = "FreeTier"
  }
}

resource "aws_eip" "app_ip" {
  instance = aws_instance.app.id
  domain   = "vpc"

  tags = {
    Name = "parking-lot-eip"
    Environment = "FreeTier"
  }
}

resource "aws_iam_role" "ec2_role" {
  name = "parking_lot_ec2_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "parking-lot-role"
    Environment = "FreeTier"
  }
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "parking_lot_ec2_profile"
  role = aws_iam_role.ec2_role.name

  tags = {
    Name        = "parking-lot-profile"
    Environment = "FreeTier"
  }
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = "parking-lot-key"
  public_key = file("~/.ssh/parking-lot-key.pub")

  tags = {
    Name        = "parking-lot-key"
    Environment = "FreeTier"
  }
}

resource "aws_instance" "app" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.deployer.key_name

  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.app.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 8
    delete_on_termination = true
    
    tags = {
      Name        = "parking-lot-root-volume"
      Environment = "FreeTier"
    }
  }

  user_data = file("${path.module}/src/startup.sh")

  tags = {
    Name        = "parking-lot-instance"
    Environment = "FreeTier"
  }

  # Disable detailed monitoring (free tier)
  monitoring = false
}

resource "null_resource" "file_provisioner" {
  depends_on = [aws_instance.app]

  # Package the application
  provisioner "local-exec" {
    command = "./package.sh"
  }

  # Wait for instance to be ready
  provisioner "remote-exec" {
    inline = ["echo 'Instance is ready!'"]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("~/.ssh/parking-lot-key")
      host        = aws_instance.app.public_ip
      timeout     = "5m"
    }
  }

  # Copy application files
  provisioner "file" {
    source      = "app.tar.gz"
    destination = "/tmp/app.tar.gz"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("~/.ssh/parking-lot-key")
      host        = aws_instance.app.public_ip
    }
  }

  # Extract and set up the application
  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /opt/parking-app",
      "sudo chown ec2-user:ec2-user /opt/parking-app",
      "cd /opt/parking-app",
      "tar xzf /tmp/app.tar.gz",
      "rm /tmp/app.tar.gz",
      "npm install",
      "npm run build",
      "sudo env PATH=$PATH:/usr/bin pm2 start dist/app.js --name parking-app",
      "sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u ec2-user --hp /home/ec2-user",
      "sudo env PATH=$PATH:/usr/bin pm2 save"
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("~/.ssh/parking-lot-key")
      host        = aws_instance.app.public_ip
    }
  }
}

output "public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.app.public_ip
}

output "public_dns" {
  description = "Public DNS of the EC2 instance"
  value       = aws_instance.app.public_dns
} 