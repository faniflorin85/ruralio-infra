###############################################################################
# security.tf — Security Group pentru serverul web
###############################################################################

resource "aws_security_group" "web" {
  name        = "${var.project_name}-web-sg"
  description = "Permite HTTP, HTTPS si SSH restrictionat"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-web-sg"
  }
}

# --- HTTP (port 80) — necesar și pentru validarea certificatului Let's Encrypt
resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.web.id
  description       = "HTTP de oriunde"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

# --- HTTPS (port 443) --------------------------------------------------------
resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id = aws_security_group.web.id
  description       = "HTTPS de oriunde"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

# --- SSH (port 22) — deschis pentru GitHub Actions (autentificare prin cheie SSH)
resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.web.id
  description       = "SSH pentru GitHub Actions si administrator"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

# --- Egress: permite tot traficul de ieșire ----------------------------------
resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.web.id
  description       = "Permite tot traficul de iesire"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
