# security_groups.tf

resource "aws_security_group" "rds_sg" {
  name        = "rds-security-group"
  description = "Security group para RDS PostgreSQL"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Acesso do meu IP"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ip]
  }

  ingress {
    description = "Trafego interno da VPC" 
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-sg"
    managed_by = "terraform"
  }
}

resource "aws_security_group" "s3_access_sg" {
  name        = "s3-access-sg"
  description = "Security group para acesso ao S3"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Permitir trafego HTTP/HTTPS para S3"
    from_port   = 443
    to_port     = 443
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
    Name = "s3-access-sg"
    managed_by = "terraform"
  }
}
