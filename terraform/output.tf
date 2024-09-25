# outputs.tf
output "rds_endpoint" {
  description = "Endpoint da instância RDS PostgreSQL"
  value       = aws_db_instance.postgres.endpoint
}

output "s3_bucket_name" {
  description = "Nome do bucket S3"
  value       = aws_s3_bucket.crm_bucket.bucket
}

output "vpc_id" {
  description = "ID da VPC"
  value       = aws_vpc.main.id
}
