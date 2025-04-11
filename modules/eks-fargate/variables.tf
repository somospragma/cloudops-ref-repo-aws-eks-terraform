variable "fargate_profiles" {
  description = "Configuración de perfiles de Fargate para EKS"
  type = map(object({
    # Configuración básica
    cluster_name    = string
    pod_execution_role_arn = string
    subnet_ids      = list(string)
    
    # Selectores de Fargate
    selectors = list(object({
      namespace = string
      labels    = optional(map(string), {})
    }))
    
    # Timeouts personalizados (en minutos)
    timeouts = optional(object({
      create = optional(number, 30)
      delete = optional(number, 30)
    }), null)
    
    # Etiquetas adicionales
    additional_tags = optional(map(string), {})
  }))
  
  validation {
    condition     = length(var.fargate_profiles) > 0
    error_message = "Al menos una configuración de perfil Fargate debe ser proporcionada."
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
