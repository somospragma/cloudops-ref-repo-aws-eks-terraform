output "cluster_ids" {
  description = "Map of cluster IDs"
  value       = module.eks_cluster.cluster_ids
}

output "cluster_arns" {
  description = "Map of cluster ARNs"
  value       = module.eks_cluster.cluster_arns
}

output "cluster_names" {
  description = "Map of cluster names"
  value       = module.eks_cluster.cluster_names
}

output "cluster_endpoints" {
  description = "Map of cluster endpoints"
  value       = module.eks_cluster.cluster_endpoints
}

output "cluster_certificate_authority_data" {
  description = "Map of cluster certificate authority data"
  value       = module.eks_cluster.cluster_certificate_authority_data
  sensitive   = true
}

output "cluster_security_group_ids" {
  description = "Map of cluster security group IDs"
  value       = module.eks_cluster.cluster_security_group_ids
}

output "cluster_versions" {
  description = "Map of cluster Kubernetes versions"
  value       = module.eks_cluster.cluster_versions
}

output "cluster_oidc_issuer_urls" {
  description = "Map of cluster OIDC issuer URLs"
  value       = module.eks_cluster.cluster_oidc_issuer_urls
}

output "oidc_provider_arns" {
  description = "Map of OIDC provider ARNs"
  value       = module.eks_cluster.oidc_provider_arns
}
