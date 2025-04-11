# Ejemplo: Simple Cluster

## Caso de uso

Este ejemplo demuestra la implementación de un cluster EKS básico sin capacidad de cómputo ni addons adicionales. Es ideal para:

- Entender los componentes mínimos necesarios para crear un cluster EKS
- Probar la configuración básica del plano de control de Kubernetes
- Crear un entorno de desarrollo inicial que se expandirá posteriormente
- Validar la configuración de red y seguridad antes de añadir nodos

## Arquitectura específica

Este ejemplo crea un cluster EKS con la siguiente arquitectura:

- **Plano de control de Kubernetes** gestionado por AWS
- **Endpoint de API** configurado para acceso privado y público limitado
- **Cifrado de secretos** utilizando AWS KMS
- **Logging** habilitado para todos los componentes del plano de control
- **Proveedor OIDC** para integración con IAM

```
Diagranma
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

4. **Clave KMS** para cifrar los secretos de Kubernetes (opcional, puede usar la clave administrada por AWS)
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
mkdir -p eks-simple-cluster
cd eks-simple-cluster

# Copiar los archivos de ejemplo
cp /ruta/al/repositorio/examples/simple-cluster/* .
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
    
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
    
    encryption_config = [{
      provider_key_arn = "arn:aws:kms:us-east-1:123456789012:key/abcd1234-ab12-cd34-ef56-abcdef123456"
      resources        = ["secrets"]
    }]
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

### 2. Verificar la conexión con kubectl

```bash
kubectl get nodes
# No mostrará nodos ya que este ejemplo no incluye capacidad de cómputo

kubectl get svc
# Debería mostrar el servicio kubernetes
```

### 3. Verificar los componentes del plano de control

```bash
kubectl get componentstatuses
```

### 4. Verificar los logs del cluster

Verifica que los logs se estén enviando a CloudWatch:

1. Abre la consola de AWS
2. Navega a CloudWatch > Logs > Log groups
3. Deberías ver un grupo de logs con el nombre `/aws/eks/pragma-demo-dev-eks-main/cluster`

## Limpieza

Para eliminar todos los recursos creados:

```bash
terraform destroy
```

Confirma la eliminación escribiendo `yes` cuando se te solicite.

## Personalización

Este ejemplo puede personalizarse de varias maneras:

### Configuración de acceso al endpoint

Para un entorno más seguro, puedes deshabilitar el acceso público:

```hcl
endpoint_private_access = true
endpoint_public_access  = false
```

O restringir el acceso público a CIDRs específicos:

```hcl
endpoint_private_access = true
endpoint_public_access  = true
public_access_cidrs     = ["203.0.113.0/24"]  # Solo permitir acceso desde esta red
```

### Configuración de red de Kubernetes

Puedes personalizar el CIDR para los servicios de Kubernetes:

```hcl
ip_family         = "ipv4"
service_ipv4_cidr = "10.100.0.0/16"  # CIDR personalizado para servicios
```

### Configuración de logs

Puedes ajustar la retención de logs o los tipos de logs habilitados:

```hcl
create_cloudwatch_log_group            = true
cloudwatch_log_group_retention_in_days = 30  # Retención más corta
cluster_enabled_log_types              = ["api", "audit"]  # Solo habilitar algunos tipos de logs
```

### Configuración avanzada de acceso

Puedes habilitar la autenticación mediante ConfigMap:

```hcl
access_config = {
  authentication_mode = "API_AND_CONFIG_MAP"
  bootstrap_cluster_creator_admin_permissions = true
}
```

### Siguiente paso

Una vez que tengas el cluster básico funcionando, puedes expandirlo añadiendo:

1. **Node Groups** para capacidad de cómputo basada en EC2
2. **Fargate Profiles** para capacidad de cómputo serverless
3. **Addons** para funcionalidades adicionales como balanceadores de carga, almacenamiento, etc.
