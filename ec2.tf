
# ----------------------------------------
# Security Group
# ----------------------------------------

resource "aws_security_group" "ec2_sg" {
  name        = "ec2-security-group"
  description = "Allow inbound and outbound traffic"
  vpc_id      = aws_vpc.main.id

  # Allow all inbound traffic (lab use only)
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2-security-group"
  }
}

# ----------------------------------------
# Latest Ubuntu 22.04 AMI
# ----------------------------------------

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ----------------------------------------
# Reference Existing AWS Key Pair
# ----------------------------------------

data "aws_key_pair" "naveen" {
  key_name = "naveen"
}

# ----------------------------------------
# Create EC2 Instance
# ----------------------------------------

resource "aws_instance" "web" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.large"
  subnet_id              = aws_subnet.public_1.id

  vpc_security_group_ids = [
    aws_security_group.ec2_sg.id
  ]

  # Use existing AWS key pair
  key_name = data.aws_key_pair.naveen.key_name

  associate_public_ip_address = true

  # Root storage: 30 GB gp3
  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    delete_on_termination = true
  }

  # SSH connection using your Desktop private key
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("C:/Users/DELL/Desktop/naveen.pem")
    host        = self.public_ip
    timeout     = "5m"
  }

  # Copy install script to EC2
  provisioner "file" {
    source      = "${path.module}/install.sh"
    destination = "/tmp/install.sh"
  }

  # Execute installation script
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install.sh",
      "sudo bash /tmp/install.sh"
    ]
  }

  tags = {
    Name = "DevOps-Tool-Server"
  }
}