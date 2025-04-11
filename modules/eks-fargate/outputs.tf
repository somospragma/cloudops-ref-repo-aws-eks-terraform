output "fargate_profile_arns" {
  description = "ARNs de los perfiles de Fargate"
  value = {
    for k, v in aws_eks_fargate_profile.this : k => v.arn
  }
}

output "fargate_profile_ids" {
  description = "IDs de los perfiles de Fargate"
  value = {
    for k, v in aws_eks_fargate_profile.this : k => v.id
  }
}

output "fargate_profile_names" {
  description = "Nombres de los perfiles de Fargate"
  value = {
    for k, v in aws_eks_fargate_profile.this : k => v.fargate_profile_name
  }
}

output "fargate_profile_statuses" {
  description = "Estados de los perfiles de Fargate"
  value = {
    for k, v in aws_eks_fargate_profile.this : k => v.status
  }
}

output "fargate_profile_selectors" {
  description = "Selectores de los perfiles de Fargate"
  value = {
    for k, v in aws_eks_fargate_profile.this : k => v.selector
  }
}
