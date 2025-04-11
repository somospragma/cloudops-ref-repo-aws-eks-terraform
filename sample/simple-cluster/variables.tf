variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "profile" {
  description = "AWS profile to use"
  type        = string
  default     = "default"
}

variable "client" {
  description = "Client name for resource naming"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.client))
    error_message = "The client name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "project" {
  description = "Project name for resource naming"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project))
    error_message = "The project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment (dev, qa, pdn)"
  type        = string
  validation {
    condition     = contains(["dev", "qa", "pdn"], var.environment)
    error_message = "The environment must be one of: dev, qa, pdn."
  }
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    provisioned = "terraform"
    owner       = "cloudops"
  }
}

variable "eks_config" {
  description = "Configuration for EKS clusters"
  type = map(object({
    # Basic configuration
    kubernetes_version      = string
    vpc_id                  = string
    subnet_ids              = list(string)
    cluster_role_arn        = string
    cluster_security_group_ids = list(string)
    
    # Endpoint access configuration
    endpoint_private_access = optional(bool, true)
    endpoint_public_access  = optional(bool, false)
    public_access_cidrs     = optional(list(string), ["0.0.0.0/0"])
    
    # Kubernetes network configuration
    ip_family               = optional(string, "ipv4")
    service_ipv4_cidr       = optional(string, null)
    
    # Advanced access configuration
    access_config = optional(object({
      authentication_mode                         = optional(string, "API")
      bootstrap_cluster_creator_admin_permissions = optional(bool, true)
    }), null)
    
    # Encryption configuration
    encryption_config = list(object({
      provider_key_arn = string
      resources        = list(string)
    }))
    
    # Logging configuration
    create_cloudwatch_log_group            = optional(bool, true)
    cloudwatch_log_group_retention_in_days = optional(number, 90)
    cluster_enabled_log_types              = optional(list(string), ["api", "audit", "authenticator", "controllerManager", "scheduler"])
    
    # Custom timeouts (in minutes)
    timeouts = optional(object({
      create = optional(number, 30)
      update = optional(number, 60)
      delete = optional(number, 15)
    }), null)
    
    # Additional tags
    additional_tags = optional(map(string), {})
  }))
}
