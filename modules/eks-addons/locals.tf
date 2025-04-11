locals {
  # Aplanar la configuración de addons para facilitar su uso con for_each
  flattened_addons = flatten([
    for cluster_key, cluster in var.addons_config : [
      for addon_key, addon in cluster.addons : {
        cluster_key = cluster_key
        addon_key   = addon_key
        addon       = addon
        cluster_name = cluster.cluster_name
        additional_tags = cluster.additional_tags
        timeouts = cluster.timeouts
      }
    ]
  ])
  
  # Crear un mapa con claves únicas para usar con for_each
  addons_map = {
    for addon in local.flattened_addons : "${addon.cluster_key}-${addon.addon_key}" => addon
  }
}
