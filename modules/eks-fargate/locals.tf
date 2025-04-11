locals {
  # Generar nombres de perfiles Fargate de forma consistente
  fargate_profile_names = {
    for k, v in var.fargate_profiles : k => {
      name = "${var.client}-${var.project}-${var.environment}-fargate-${k}"
    }
  }
}
