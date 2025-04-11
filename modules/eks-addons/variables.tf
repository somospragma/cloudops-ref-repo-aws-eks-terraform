variable "addons_config" {
  description = "Configuración de addons para clusters EKS"
  type = map(object({
    # Configuración básica
    cluster_name = string
    
    # Configuración de add-ons
    addons = map(object({
      addon_version            = optional(string)
      resolve_conflicts_on_create = optional(string, "OVERWRITE")
      resolve_conflicts_on_update = optional(string, "OVERWRITE")
      service_account_role_arn = optional(string)
      preserve                 = optional(bool, false)
      configuration_values     = optional(string, null)
    }))
    
    # Timeouts personalizados (en minutos)
    timeouts = optional(object({
      create = optional(number, 30)
      update = optional(number, 30)
      delete = optional(number, 15)
    }), null)
    
    # Etiquetas adicionales
    additional_tags = optional(map(string), {})
  }))
  
  validation {
    condition     = length(var.addons_config) > 0
    error_message = "Al menos una configuración de addons debe ser proporcionada."
  }
}

variable "client" {
  description = "Nombre del cliente para el que se crea el recurso"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.client))
    error_message = "El nombre del cliente debe contener solo letras minúsculas, números y guiones."
  }
}

variable "project" {
  description = "Nombre del proyecto o funcionalidad"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project))
    error_message = "El nombre del proyecto debe contener solo letras minúsculas, números y guiones."
  }
}

variable "environment" {
  description = "Entorno de despliegue (dev, qa, pdn)"
  type        = string
  validation {
    condition     = contains(["dev", "qa", "pdn"], var.environment)
    error_message = "El entorno debe ser uno de: dev, qa, pdn."
  }
}
