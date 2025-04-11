# Nombres de Node Groups
locals {
  nodegroup_names = {
    for k, v in var.nodegroups : k => {
      name = "${var.client}-${var.project}-${var.environment}-ng-${k}"
    }
  }
}
