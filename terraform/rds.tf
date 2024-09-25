# rds.tf
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]
  tags = {
    Name = "rds-subnet-group"
  }
}

resource "aws_db_instance" "postgres" {
  identifier              = "crm-taipy-terraform"
  engine                  = "postgres"
  engine_version          = "16.3"
  instance_class          = "db.t4g.micro"
  allocated_storage       = 20
  max_allocated_storage   = 25
  storage_type            = "gp2"
  db_name                 = "crm_taipy"
  username                = var.db_username
  password                = var.db_password
  parameter_group_name    = "default.postgres16"
  db_subnet_group_name    = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  multi_az                = false
  publicly_accessible     = true
  skip_final_snapshot     = true

  tags = {
    Name = "crm-taipy-rds"
    managed_by = "terraform"
  }
}
