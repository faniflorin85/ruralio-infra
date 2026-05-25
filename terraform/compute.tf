###############################################################################
# compute.tf — Instanța EC2 + Elastic IP
###############################################################################

# --- Cel mai recent AMI Ubuntu 22.04 LTS -------------------------------------
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical (oficial Ubuntu)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# --- Cheia SSH ---------------------------------------------------------------
# Importă cheia ta publică SSH ca să te poți conecta la instanță.
# Generează o pereche local cu:  ssh-keygen -t ed25519 -f ~/.ssh/ruralio
resource "aws_key_pair" "main" {
  key_name   = "${var.project_name}-key"
  public_key = file("~/.ssh/ruralio.pub")
}

# --- Instanța EC2 ------------------------------------------------------------
resource "aws_instance" "web" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name               = aws_key_pair.main.key_name

  user_data = file("${path.module}/user-data.sh")

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name = "${var.project_name}-web-server"
  }
}

# --- Elastic IP (IP fix, nu se schimbă la repornirea instanței) --------------
resource "aws_eip" "web" {
  instance = aws_instance.web.id
  domain   = "vpc"

  tags = {
    Name = "${var.project_name}-eip"
  }
}
