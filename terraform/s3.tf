# Definição do bucket S3 com force_destroy para esvaziar antes de deletar
resource "aws_s3_bucket" "crm_bucket" {
  bucket        = var.s3_bucket_name

  # Força a destruição do bucket, esvaziando-o automaticamente antes
  force_destroy = true

  lifecycle {
    prevent_destroy = false
  }

  tags = {
    Name        = "CRM Taipy Bucket"
    managed_by  = "terraform"
  }
}

# Definição da política do bucket para restringir acesso
resource "aws_s3_bucket_policy" "crm_bucket_policy" {
  bucket = aws_s3_bucket.crm_bucket.id

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::${aws_s3_bucket.crm_bucket.bucket}",
        "arn:aws:s3:::${aws_s3_bucket.crm_bucket.bucket}/*"
      ],
      "Condition": {
        "IpAddress": {
          "aws:SourceIp": [var.allowed_ip]
        }
      }
    }]
  })
}

# Configuração de controle de propriedade ACL no bucket
resource "aws_s3_bucket_ownership_controls" "crm_bucket-acl-ownership" {
  bucket = aws_s3_bucket.crm_bucket.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}
