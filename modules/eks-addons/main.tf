# Add-ons del cluster EKS
resource "aws_eks_addon" "this" {
  provider = aws.project
  for_each = local.addons_map
  
  cluster_name             = each.value.cluster_name
  addon_name               = each.value.addon_key
  addon_version            = each.value.addon.addon_version
  resolve_conflicts_on_create = each.value.addon.resolve_conflicts_on_create
  resolve_conflicts_on_update = each.value.addon.resolve_conflicts_on_update
  service_account_role_arn = each.value.addon.service_account_role_arn
  preserve                 = each.value.addon.preserve
  configuration_values     = each.value.addon.configuration_values
  
  # Configuración de timeouts más largos para los addons
  dynamic "timeouts" {
    for_each = each.value.timeouts != null ? [each.value.timeouts] : []
    
    content {
      create = "${timeouts.value.create}m"
      update = "${timeouts.value.update}m"
      delete = "${timeouts.value.delete}m"
    }
  }
  
  # Etiquetas adicionales
  tags = each.value.additional_tags
}
