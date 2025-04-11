resource "aws_eks_fargate_profile" "this" {
  provider = aws.project
  for_each = var.fargate_profiles
  
  fargate_profile_name   = local.fargate_profile_names[each.key].name
  cluster_name           = each.value.cluster_name
  pod_execution_role_arn = each.value.pod_execution_role_arn
  subnet_ids             = each.value.subnet_ids
  

  dynamic "selector" {
    for_each = each.value.selectors
    
    content {
      namespace = selector.value.namespace
      labels    = selector.value.labels
    }
  }
  
 
  dynamic "timeouts" {
    for_each = each.value.timeouts != null ? [each.value.timeouts] : []
    
    content {
      create = "${timeouts.value.create}m"
      delete = "${timeouts.value.delete}m"
    }
  }
  
  # Etiquetas adicionales
  tags = each.value.additional_tags
}
