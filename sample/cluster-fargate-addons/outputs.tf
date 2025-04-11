output "cluster_id" {
  description = "ID del cluster EKS"
  value       = module.eks_cluster.cluster_ids["main"]
}

output "cluster_name" {
  description = "Nombre del cluster EKS"
  value       = module.eks_cluster.cluster_names["main"]
}

output "cluster_endpoint" {
  description = "Endpoint del API server del cluster EKS"
  value       = module.eks_cluster.cluster_endpoints["main"]
}

output "cluster_certificate_authority_data" {
  description = "Datos del certificado de la autoridad del cluster EKS"
  value       = module.eks_cluster.cluster_certificate_authority_data["main"]
  sensitive   = true
}

output "fargate_profile_arns" {
  description = "ARNs de los perfiles de Fargate"
  value       = module.eks_fargate.fargate_profile_arns
}

output "fargate_profile_ids" {
  description = "IDs de los perfiles de Fargate"
  value       = module.eks_fargate.fargate_profile_ids
}

output "fargate_profile_statuses" {
  description = "Estados de los perfiles de Fargate"
  value       = module.eks_fargate.fargate_profile_statuses
}

output "addon_arns" {
  description = "ARNs de los addons de EKS"
  value       = module.eks_addons.addon_arns
}
