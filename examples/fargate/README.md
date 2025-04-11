# EKS con Fargate

Este ejemplo muestra cómo desplegar un cluster EKS con perfiles de Fargate para ejecutar pods sin necesidad de administrar nodos EC2.

## Arquitectura

Este ejemplo implementa:

1. Un cluster EKS básico (sin addons inicialmente)
2. Un perfil de Fargate para ejecutar pods en el namespace `kube-system` y `default`
3. Los addons de EKS (CoreDNS, kube-proxy, vpc-cni) después de que el perfil de Fargate esté disponible

## Requisitos previos

- Una VPC con subnets privadas
- Roles IAM para el cluster EKS y para la ejecución de pods en Fargate
- Grupos de seguridad configurados adecuadamente

## Uso

1. Crear un archivo `terraform.tfvars` con los valores específicos:

```hcl
aws_region = "us-east-1"
profile = "mi-perfil-aws"
client = "pragma"
project = "demo"
environment = "dev"
vpc_id = "vpc-12345678"
subnet_ids = ["subnet-12345678", "subnet-87654321"]
cluster_role_arn = "arn:aws:iam::123456789012:role/eks-cluster-role"
pod_execution_role_arn = "arn:aws:iam::123456789012:role/eks-fargate-pod-execution-role"
security_group_ids = ["sg-12345678"]
```

2. Inicializar Terraform:

```bash
terraform init
```

3. Aplicar la configuración:

```bash
terraform apply
```

## Notas importantes

- Los addons de EKS se crean después de que el perfil de Fargate esté disponible para asegurar que los pods de CoreDNS puedan programarse correctamente.
- El perfil de Fargate está configurado para ejecutar pods en el namespace `kube-system` con la etiqueta `k8s-app=kube-dns` (CoreDNS) y todos los pods en el namespace `default`.
- Para ejecutar pods en otros namespaces con Fargate, se deben crear perfiles de Fargate adicionales.

## Seguridad

Este ejemplo implementa las siguientes medidas de seguridad:

- Acceso privado al API server de EKS (endpoint_private_access = true)
- Acceso público al API server de EKS deshabilitado por defecto (endpoint_public_access = false)
- Logs de auditoría habilitados y retenidos por 90 días
- Etiquetado completo de recursos según las políticas de la organización

## Lista de verificación

- [x] Nomenclatura de recursos conforme al estándar
- [x] Etiquetas obligatorias aplicadas a todos los recursos
- [x] Logs habilitados con retención configurada
- [x] Acceso de red restringido según principio de mínimo privilegio
- [x] Documentación actualizada
- [x] Estructura modular y reutilizable

> Este módulo ha sido desarrollado siguiendo los estándares de Pragma CloudOps, garantizando una implementación segura, escalable y optimizada que cumple con todas las políticas de la organización. Pragma CloudOps recomienda revisar este código con su equipo de infraestructura antes de implementarlo en producción.
