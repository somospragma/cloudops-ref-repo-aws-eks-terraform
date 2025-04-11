# Ejemplo: Complete Cluster

## Caso de uso

Este ejemplo demuestra la implementación de un cluster EKS completo con todas las opciones avanzadas disponibles. Es ideal para:

- Entornos de producción que requieren configuraciones avanzadas de seguridad y networking
- Comprender todas las opciones de configuración disponibles para un cluster EKS
- Crear una base de referencia para implementaciones personalizadas
- Demostrar las mejores prácticas para la configuración de EKS

## Arquitectura específica

Este ejemplo crea un cluster EKS con la siguiente arquitectura:

- **Plano de control de Kubernetes** gestionado por AWS con configuración avanzada
- **Endpoint de API** configurado para acceso privado y público limitado
- **Cifrado de secretos** utilizando AWS KMS
- **Configuración de red personalizada** para servicios de Kubernetes
- **Autenticación avanzada** con modo API_AND_CONFIG_MAP
- **Logging completo** para todos los componentes del plano de control
- **Proveedor OIDC** para integración con IAM

```
Diagrama
```

## Requisitos previos

Antes de implementar este ejemplo, necesitarás:

1. **VPC configurada** con al menos dos subnets en diferentes zonas de disponibilidad
   - Las subnets deben tener las etiquetas adecuadas:
     - Para subnets públicas: `kubernetes.io/role/elb` = `1`
     - Para subnets privadas: `kubernetes.io/role/internal-elb` = `1`

2. **Rol IAM para el cluster** con la política `AmazonEKSClusterPolicy` adjunta
   ```hcl
   resource "aws_iam_role" "eks_cluster_role" {
     name = "eks-cluster-role"
     
     assume_role_policy = jsonencode({
       Version = "2012-10-17"
       Statement = [{
         Effect = "Allow"
         Principal = {
           Service = "eks.amazonaws.com"
         }
         Action = "sts:AssumeRole"
       }]
     })
   }
   
   resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
     policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
     role       = aws_iam_role.eks_cluster_role.name
   }
   ```

3. **Grupo de seguridad** para el cluster EKS
   ```hcl
   resource "aws_security_group" "eks_cluster_sg" {
     name        = "eks-cluster-sg"
     description = "Security group for EKS cluster"
     vpc_id      = var.vpc_id
     
     egress {
       from_port   = 0
       to_port     = 0
       protocol    = "-1"
       cidr_blocks = ["0.0.0.0/0"]
     }
   }
   ```

4. **Clave KMS** para cifrar los secretos de Kubernetes
   ```hcl
   resource "aws_kms_key" "eks_secrets" {
     description             = "KMS key for EKS secrets encryption"
     deletion_window_in_days = 7
     enable_key_rotation     = true
   }
   ```

5. **Credenciales AWS** configuradas con permisos suficientes para crear recursos EKS

## Instrucciones paso a paso

### 1. Preparar el directorio de trabajo

```bash
# Crear el directorio para el ejemplo
mkdir -p eks-complete-cluster
cd eks-complete-cluster

# Copiar los archivos de ejemplo
cp /ruta/al/repositorio/examples/complete-cluster/* .
```

### 2. Configurar las variables

Crea un archivo `terraform.tfvars` basado en el ejemplo:

```bash
cp terraform.tfvars.sample terraform.tfvars
```

Edita el archivo `terraform.tfvars` para ajustar los valores según tu entorno:

```hcl
# Configuración general
aws_region  = "us-east-1"
profile     = "default"
client      = "pragma"
project     = "demo"
environment = "dev"

# Configuración del cluster EKS
eks_config = {
  "main" = {
    kubernetes_version      = "1.28"
    vpc_id                  = "vpc-12345678"
    subnet_ids              = ["subnet-1", "subnet-2", "subnet-3"]
    cluster_role_arn        = "arn:aws:iam::123456789012:role/eks-cluster-role"
    cluster_security_group_ids = ["sg-12345678"]
    
    # Configuración de acceso al endpoint
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
    
    # Configuración de red de Kubernetes
    ip_family         = "ipv4"
    service_ipv4_cidr = "172.20.0.0/16"
    
    # Configuración avanzada de acceso
    access_config = {
      authentication_mode = "API_AND_CONFIG_MAP"
      bootstrap_cluster_creator_admin_permissions = true
    }
    
    # Configuración de cifrado
    encryption_config = [{
      provider_key_arn = "arn:aws:kms:us-east-1:123456789012:key/abcd1234-ab12-cd34-ef56-abcdef123456"
      resources        = ["secrets"]
    }]
    
    # Configuración de logs
    create_cloudwatch_log_group            = true
    cloudwatch_log_group_retention_in_days = 30
    cluster_enabled_log_types              = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
    
    # Timeouts personalizados
    timeouts = {
      create = 45
      update = 60
      delete = 30
    }
    
    # Etiquetas adicionales
    additional_tags = {
      "kubernetes.io/cluster-name" = "pragma-demo-dev-eks-main"
      "environment" = "dev"
      "criticality" = "high"
    }
  }
}
```

### 3. Inicializar Terraform

```bash
terraform init
```

### 4. Validar la configuración

```bash
terraform validate
terraform plan
```

### 5. Aplicar la configuración

```bash
terraform apply
```

Confirma la aplicación escribiendo `yes` cuando se te solicite.

### 6. Configurar kubectl

Una vez creado el cluster, configura kubectl para interactuar con él:

```bash
aws eks update-kubeconfig --region us-east-1 --name pragma-demo-dev-eks-main --profile default
```

## Verificación

Para verificar que el cluster se ha creado correctamente:

### 1. Verificar el estado del cluster en AWS

```bash
aws eks describe-cluster --name pragma-demo-dev-eks-main --region us-east-1 --profile default
```

### 2. Verificar la configuración de cifrado

```bash
aws eks describe-cluster --name pragma-demo-dev-eks-main --region us-east-1 --profile default --query "cluster.encryptionConfig"
```

### 3. Verificar la configuración de acceso al endpoint

```bash
aws eks describe-cluster --name pragma-demo-dev-eks-main --region us-east-1 --profile default --query "cluster.resourcesVpcConfig"
```

### 4. Verificar el proveedor OIDC

```bash
aws eks describe-cluster --name pragma-demo-dev-eks-main --region us-east-1 --profile default --query "cluster.identity.oidc"
```

### 5. Verificar los logs del cluster

Verifica que los logs se estén enviando a CloudWatch:

1. Abre la consola de AWS
2. Navega a CloudWatch > Logs > Log groups
3. Deberías ver un grupo de logs con el nombre `/aws/eks/pragma-demo-dev-eks-main/cluster`

### 6. Verificar la conexión con kubectl

```bash
kubectl get componentstatuses
```

## Limpieza

Para eliminar todos los recursos creados:

```bash
terraform destroy
```

Confirma la eliminación escribiendo `yes` cuando se te solicite.

## Personalización

Este ejemplo ya incluye todas las opciones avanzadas disponibles para un cluster EKS. Sin embargo, puedes personalizarlo según tus necesidades específicas:

### Configuración para entornos de alta seguridad

Para entornos con requisitos de seguridad más estrictos:

```hcl
# Deshabilitar el acceso público al endpoint
endpoint_private_access = true
endpoint_public_access  = false

# Configuración de cifrado más completa
encryption_config = [{
  provider_key_arn = "arn:aws:kms:us-east-1:123456789012:key/abcd1234-ab12-cd34-ef56-abcdef123456"
  resources        = ["secrets"]
}]

# Retención de logs más larga
cloudwatch_log_group_retention_in_days = 365
```

### Configuración para entornos de desarrollo

Para entornos de desarrollo donde la facilidad de acceso es más importante:

```hcl
# Permitir acceso público desde cualquier lugar
endpoint_private_access = false
endpoint_public_access  = true
public_access_cidrs     = ["0.0.0.0/0"]

# Retención de logs más corta para reducir costos
cloudwatch_log_group_retention_in_days = 7
```

### Configuración para redes personalizadas

Si necesitas evitar conflictos de CIDR con otras redes:

```hcl
# CIDR personalizado para servicios de Kubernetes
service_ipv4_cidr = "10.100.0.0/16"
```

### Siguiente paso

Una vez que tengas el cluster completo funcionando, puedes expandirlo añadiendo:

1. **Node Groups** para capacidad de cómputo basada en EC2
2. **Fargate Profiles** para capacidad de cómputo serverless
3. **Addons** para funcionalidades adicionales como balanceadores de carga, almacenamiento, etc.
