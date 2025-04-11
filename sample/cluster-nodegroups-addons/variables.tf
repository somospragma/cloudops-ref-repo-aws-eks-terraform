variable "region" {
  description = "Región de AWS donde se crearán los recursos"
  type        = string
  default     = "us-east-1"
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
}

variable "vpc_id" {
  description = "ID de la VPC donde se creará el cluster EKS"
  type        = string
}

variable "subnet_ids" {
  description = "Lista de IDs de subnets donde se crearán los nodos del cluster"
  type        = list(string)
}

variable "cluster_role_arn" {
  description = "ARN del rol IAM para el cluster EKS"
  type        = string
}

variable "node_role_arn" {
  description = "ARN del rol IAM para los nodos del cluster EKS"
  type        = string
}

variable "security_group_ids" {
  description = "Lista de IDs de grupos de seguridad para el cluster EKS"
  type        = list(string)
  default     = []
}

variable "endpoint_public_access" {
  description = "Si es true, el endpoint del API server será accesible públicamente"
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "Lista de bloques CIDR que pueden acceder al endpoint público del API server"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "log_retention_days" {
  description = "Número de días para retener los logs del cluster en CloudWatch"
  type        = number
  default     = 30
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