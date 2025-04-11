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

output "nodegroup_names" {
  description = "Nombres de los Node Groups creados"
  value       = module.eks_nodegroups.nodegroup_names
}

output "nodegroup_statuses" {
  description = "Estados de los Node Groups"
  value       = module.eks_nodegroups.nodegroup_statuses
}

output "autoscaling_group_names" {
  description = "Nombres de los grupos de Auto Scaling asociados a los Node Groups"
  value       = module.eks_nodegroups.autoscaling_group_names
}
