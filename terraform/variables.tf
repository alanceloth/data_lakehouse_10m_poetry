# variables.tf
variable "aws_region" {
  description = "Região da AWS onde os recursos serão criados"
  type        = string
  default     = "us-east-2"
}

variable "vpc_cidr" {
  description = "CIDR block para a VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr_a" {
  description = "CIDR block para a sub-rede pública na AZ us-east-2a"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_cidr_b" {
  description = "CIDR block para a sub-rede pública na AZ us-east-2b"
  type        = string
  default     = "10.0.2.0/24"
}

variable "private_subnet_cidr_a" {
  description = "CIDR block para a sub-rede privada na AZ us-east-2a"
  type        = string
  default     = "10.0.3.0/24"
}

variable "private_subnet_cidr_b" {
  description = "CIDR block para a sub-rede privada na AZ us-east-2b"
  type        = string
  default     = "10.0.4.0/24"
}

variable "db_username" {
  description = "Nome de usuário para o RDS PostgreSQL"
  type        = string
}

variable "db_password" {
  description = "Senha para o RDS PostgreSQL"
  type        = string
  sensitive   = true
}

variable "allowed_ip" {
  description = "Seu IP para acesso ao RDS"
  type        = string
}

variable "s3_bucket_name" {
  description = "Nome do bucket S3"
  type        = string
}
