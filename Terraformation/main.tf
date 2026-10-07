provider "aws" {
  region = "us-east-1"
}

# 1. Recupero della VPC di default
data "aws_vpc" "default" {
  default = true
}

# 2. Security Group per SSH, HTTP, React, Node, and Postgres
resource "aws_security_group" "ansible_lab_sg" {
  name        = "ansible-lab-sg"
  description = "Permetti SSH e HTTP per il laboratorio Ansible"
  vpc_id      = data.aws_vpc.default.id

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
    description = "React Frontend"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Node.js Backend"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "PostgreSQL"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ansible-lab-sg"
  }
}

# 3. AMI per Amazon Linux 2023
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-kernel-6.1-x86_64"]
  }
}

# 4. AMI per Ubuntu (Noble 24.04)
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

# --- NODI GESTITI (Node 1, Node 2, Node 3) ---

resource "aws_instance" "node1" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = "t2.micro"
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.ansible_lab_sg.id]

  tags = {
    Name = "node1"
  }
}

resource "aws_instance" "node2" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = "t2.micro"
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.ansible_lab_sg.id]

  tags = {
    Name = "node2"
  }
}

resource "aws_instance" "node3" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.medium"
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.ansible_lab_sg.id]

  tags = {
    Name = "node3 (ubuntu)"
  }
}

# --- CONTROL NODE ---
resource "aws_instance" "control_node" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = "t2.micro"
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.ansible_lab_sg.id]

  # User data installa Ansible e compila l'inventory con gli IP privati dei nodi sopra
  user_data = <<-EOT
    #!/bin/bash
    sudo dnf update -y
    sudo dnf install ansible -y

    mkdir -p /home/ec2-user/.ansible

    cat <<EOF > /home/ec2-user/inventory.txt
    [webservers]
    node1 ansible_host=${aws_instance.node1.private_ip} ansible_user=ec2-user
    node2 ansible_host=${aws_instance.node2.private_ip} ansible_user=ec2-user

    [ubuntuservers]
    node3 ansible_host=${aws_instance.node3.private_ip} ansible_user=ubuntu

    [all:vars]
    ansible_ssh_private_key_file=/home/ec2-user/${var.key_name}.pem
    EOF

    cat <<EOF > /home/ec2-user/ansible.cfg
    [defaults]
    host_key_checking = False
    inventory = inventory.txt
    deprecation_warnings = False
    interpreter_python = auto_silent
    EOF

    chown -R ec2-user:ec2-user /home/ec2-user/inventory.txt /home/ec2-user/ansible.cfg
  EOT

  tags = {
    Name = "control-node"
  }
}