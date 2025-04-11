variable "aws_region" {
  description = "Región de AWS donde se desplegarán los recursos"
  type        = string
  default     = "us-east-1"
}

variable "profile" {
  description = "Perfil de AWS a utilizar"
  type        = string
  default     = "default"
}

variable "client" {
  description = "Nombre del cliente para el que se crea el recurso"
  type        = string
  default     = "pragma"
}

variable "project" {
  description = "Nombre del proyecto o funcionalidad"
  type        = string
  default     = "demo"
}

variable "environment" {
  description = "Entorno de despliegue (dev, qa, pdn)"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "qa", "pdn"], var.environment)
    error_message = "El entorno debe ser uno de: dev, qa, pdn."
  }
}

variable "vpc_id" {
  description = "ID de la VPC donde se desplegará el cluster EKS"
  type        = string
}

variable "subnet_ids" {
  description = "IDs de las subnets donde se desplegará el cluster EKS. Si no se especifica, se intentará detectar automáticamente."
  type        = list(string)
  default     = null
}

variable "cluster_role_arn" {
  description = "ARN del rol IAM para el cluster EKS"
  type        = string
}

variable "pod_execution_role_arn" {
  description = "ARN del rol IAM para la ejecución de pods en Fargate"
  type        = string
}

variable "security_group_ids" {
  description = "Lista de IDs de grupos de seguridad para el cluster EKS"
  type        = list(string)
}

variable "endpoint_public_access" {
  description = "Indica si el API server de EKS es accesible públicamente"
  type        = bool
  default     = false
}

variable "public_access_cidrs" {
  description = "Lista de bloques CIDR que pueden acceder al API server de EKS si el acceso público está habilitado"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "log_retention_days" {
  description = "Número de días para retener los logs en CloudWatch"
  type        = number
  default     = 90
}

variable "common_tags" {
  description = "Etiquetas comunes para todos los recursos"
  type        = map(string)
  default = {
    environment   = "dev"
    project-name  = "payments"
    cost-center   = "cloud-ops"
    owner         = "cloudops"
    area          = "infrastructure"
    provisioned   = "terraform"
    datatype      = "operational"
  }
}
