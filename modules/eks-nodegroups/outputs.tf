output "nodegroup_arns" {
  description = "ARNs de los Node Groups de EKS"
  value = {
    for k, v in aws_eks_node_group.this : k => v.arn
  }
}

output "nodegroup_ids" {
  description = "IDs de los Node Groups de EKS"
  value = {
    for k, v in aws_eks_node_group.this : k => v.id
  }
}

output "nodegroup_statuses" {
  description = "Estados de los Node Groups de EKS"
  value = {
    for k, v in aws_eks_node_group.this : k => v.status
  }
}

output "autoscaling_group_names" {
  description = "Nombres de los grupos de Auto Scaling asociados a los Node Groups"
  value = flatten([
    for ng in aws_eks_node_group.this : [
      for asg in ng.resources[0].autoscaling_groups : asg.name
    ]
  ])
}

output "nodegroup_names" {
  description = "Nombres de los Node Groups de EKS"
  value = {
    for k, v in var.nodegroups : k => local.nodegroup_names[k].name
  }
}
