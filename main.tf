provider "aws" {
  version = "~> 2.0"
  region  = var.region
}

data "aws_ami" "amazon-linux-2" {
  most_recent = true

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
  owners = ["amazon"]
}

resource "aws_security_group" "sg" {
  name        = "jenkins_sg"
  description = "Allow traffic to port 80, 22 & 8080"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Jenkins"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "jenkins" {
  key_name   = "jenkins"
  public_key = "ssh-rsa "
}

resource "aws_instance" "jenkins" {
  ami                         = data.aws_ami.amazon-linux-2.id
  associate_public_ip_address = true
  instance_type               = "t2.micro"
  key_name                    = "jenkins"
  vpc_security_group_ids      = [aws_security_group.sg.id]

  tags = {
    Name = "Jenkins"
  }
  provisioner "file" {
    source      = "ansible"
    destination = "/home/ec2-user/"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      host        = aws_instance.jenkins.public_ip
      private_key = file("ssh//key.pem")
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install python-pip -y",
      "sudo pip install ansible docker",
      "ansible-playbook ansible/playbook.yaml -vvvv -b",
    ]
    connection {
      type        = "ssh"
      user        = "ec2-user"
      host        = aws_instance.jenkins.public_ip
      private_key = file("ssh//key.pem")
    }
  }
}






