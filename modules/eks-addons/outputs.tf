output "addon_arns" {
  description = "ARNs de los addons de EKS"
  value = {
    for k, v in aws_eks_addon.this : k => v.arn
  }
}

output "addon_ids" {
  description = "IDs de los addons de EKS"
  value = {
    for k, v in aws_eks_addon.this : k => v.id
  }
}

output "addon_created_at" {
  description = "Fechas de creación de los addons de EKS"
  value = {
    for k, v in aws_eks_addon.this : k => v.created_at
  }
}

output "addon_modified_at" {
  description = "Fechas de modificación de los addons de EKS"
  value = {
    for k, v in aws_eks_addon.this : k => v.modified_at
  }
}
