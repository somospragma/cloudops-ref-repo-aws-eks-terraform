
resource "aws_eks_node_group" "this" {
  provider = aws.project
  for_each = var.nodegroups
  
  cluster_name    = each.value.cluster_name
  node_group_name = local.nodegroup_names[each.key].name
  node_role_arn   = each.value.node_role_arn
  subnet_ids      = each.value.subnet_ids
  
  instance_types  = each.value.instance_types
  capacity_type   = each.value.capacity_type
  disk_size       = each.value.disk_size
  ami_type        = each.value.ami_type
  release_version = each.value.release_version
  
  scaling_config {
    desired_size = each.value.desired_size
    min_size     = each.value.min_size
    max_size     = each.value.max_size
  }
  
  dynamic "update_config" {
    for_each = each.value.update_config != null ? [each.value.update_config] : []
    
    content {
      max_unavailable            = update_config.value.max_unavailable
      max_unavailable_percentage = update_config.value.max_unavailable_percentage
    }
  }
  
  dynamic "taint" {
    for_each = each.value.taints
    
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }
  
  labels = each.value.labels
  
  # Timeouts personalizados
  dynamic "timeouts" {
    for_each = each.value.timeouts != null ? [each.value.timeouts] : []
    
    content {
      create = "${timeouts.value.create}m"
      update = "${timeouts.value.update}m"
      delete = "${timeouts.value.delete}m"
    }
  }
  
  # Tags adicionales
  tags = each.value.additional_tags
}
