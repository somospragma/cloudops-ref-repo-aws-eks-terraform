variable "nodegroups" {
  description = "Configuración de Node Groups para EKS"
  type = map(object({
    cluster_name    = string
    node_role_arn   = string
    subnet_ids      = list(string)
    
    # Configuración de capacidad
    instance_types  = optional(list(string), ["t3.medium"])
    capacity_type   = optional(string, "ON_DEMAND")  # ON_DEMAND o SPOT
    disk_size       = optional(number, 20)
    
    # Configuración de escalado
    desired_size    = optional(number, 2)
    min_size        = optional(number, 1)
    max_size        = optional(number, 3)
    
    # Configuración de AMI
    ami_type        = optional(string, "AL2_x86_64")  # AL2_x86_64, AL2_ARM_64, etc.
    release_version = optional(string, null)
    
    # Configuración de actualización
    update_config = optional(object({
      max_unavailable            = optional(number, 1)
      max_unavailable_percentage = optional(number, null)
    }), null)
    
    # Configuración de etiquetas y taints
    labels         = optional(map(string), {})
    taints         = optional(list(object({
      key    = string
      value  = string
      effect = string
    })), [])
    
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
    condition     = length(var.nodegroups) > 0
    error_message = "Al menos una configuración de Node Group debe ser proporcionada."
  }
  
  validation {
    condition = alltrue([
      for k, v in var.nodegroups : contains(["ON_DEMAND", "SPOT"], v.capacity_type)
    ])
    error_message = "El valor de capacity_type debe ser 'ON_DEMAND' o 'SPOT'."
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
