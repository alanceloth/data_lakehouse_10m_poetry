data "aws_caller_identity" "current" {}

output "current_identity" {
  description = "Informações sobre a identidade atual utilizada pelo Terraform"
  value       = data.aws_caller_identity.current
}
