# Ejemplo: Cluster con Fargate y Addons

## Caso de uso

Este ejemplo demuestra la implementación de un cluster EKS con capacidad de cómputo serverless mediante Fargate y addons esenciales. Es ideal para:

- Entornos que requieren una solución Kubernetes sin gestión de nodos
- Cargas de trabajo que se benefician del modelo de facturación por pod de Fargate
- Aplicaciones con requisitos de aislamiento mejorado entre pods
- Implementaciones que buscan minimizar la sobrecarga operativa

## Arquitectura específica

Este ejemplo crea un cluster EKS con la siguiente arquitectura:

- **Plano de control de Kubernetes** gestionado por AWS
- **Perfiles de Fargate** para ejecutar pods sin gestionar nodos EC2
- **Addons esenciales**:
  - CoreDNS: Resolución DNS dentro del cluster
  - VPC CNI: Networking para pods
  - AWS Load Balancer Controller: Gestión de balanceadores de carga
- **Cifrado de secretos** utilizando AWS KMS
- **Proveedor OIDC** para integración con IAM

```


Diagrana
```

## Requisitos previos

Antes de implementar este ejemplo, necesitarás:

1. **VPC configurada** con al menos dos subnets privadas en diferentes zonas de disponibilidad
   - Las subnets deben tener las etiquetas adecuadas:
     - Para subnets públicas: `kubernetes.io/role/elb` = `1`
     - Para subnets privadas: `kubernetes.io/role/internal-elb` = `1`

2. **Rol IAM para el cluster** con la política `AmazonEKSClusterPolicy` adjunta

3. **Rol IAM para los pods de Fargate** con las siguientes políticas:
   - `AmazonEKSFargatePodExecutionRolePolicy`
   ```hcl
   resource "aws_iam_role" "fargate_pod_execution_role" {
     name = "eks-fargate-pod-execution-role"
     
     assume_role_policy = jsonencode({
       Version = "2012-10-17"
       Statement = [{
         Effect = "Allow"
         Principal = {
           Service = "eks-fargate-pods.amazonaws.com"
         }
         Action = "sts:AssumeRole"
       }]
     })
   }
   
   resource "aws_iam_role_policy_attachment" "fargate_pod_execution_policy" {
     policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
     role       = aws_iam_role.fargate_pod_execution_role.name
   }
   ```

4. **Roles IAM para addons** (opcional, pero recomendado para seguir el principio de privilegio mínimo)
   - Rol para AWS Load Balancer Controller
   - Rol para VPC CNI

5. **Clave KMS** para cifrar los secretos de Kubernetes

6. **Credenciales AWS** configuradas con permisos suficientes para crear recursos EKS

## Instrucciones paso a paso

### 1. Preparar el directorio de trabajo

```bash
# Crear el directorio para el ejemplo
mkdir -p eks-fargate-addons
cd eks-fargate-addons

# Copiar los archivos de ejemplo
cp /ruta/al/repositorio/examples/cluster-fargate-addons/* .
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

# Configuración de Fargate Profiles
fargate_profiles = {
  "default" = {
    cluster_name    = "pragma-demo-dev-eks-main"
    pod_execution_role_arn = "arn:aws:iam::123456789012:role/eks-fargate-pod-execution-role"
    subnet_ids      = ["subnet-1", "subnet-2", "subnet-3"]
    
    selectors = [
      {
        namespace = "default"
        labels = {}
      },
      {
        namespace = "kube-system"
        labels = {
          "k8s-app" = "kube-dns"
        }
      }
    ]
  },
  "apps" = {
    cluster_name    = "pragma-demo-dev-eks-main"
    pod_execution_role_arn = "arn:aws:iam::123456789012:role/eks-fargate-pod-execution-role"
    subnet_ids      = ["subnet-1", "subnet-2", "subnet-3"]
    
    selectors = [
      {
        namespace = "app-namespace"
        labels = {}
      }
    ]
  }
}

# Configuración de addons
addons_config = {
  "main" = {
    cluster_name = "pragma-demo-dev-eks-main"
    
    addons = {
      coredns = {
        addon_version = "v1.10.1-eksbuild.2"
        resolve_conflicts_on_create = "OVERWRITE"
        resolve_conflicts_on_update = "OVERWRITE"
      }
      vpc-cni = {
        addon_version = "v1.14.0-eksbuild.3"
        resolve_conflicts_on_create = "OVERWRITE"
        resolve_conflicts_on_update = "OVERWRITE"
      }
      aws-load-balancer-controller = {
        addon_version = "v2.7.1-eksbuild.1"
        resolve_conflicts_on_create = "OVERWRITE"
        resolve_conflicts_on_update = "OVERWRITE"
        service_account_role_arn = "arn:aws:iam::123456789012:role/aws-load-balancer-controller-role"
      }
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

Para verificar que el cluster, los perfiles de Fargate y los addons se han creado correctamente:

### 1. Verificar el estado del cluster

```bash
aws eks describe-cluster --name pragma-demo-dev-eks-main --region us-east-1 --profile default
```

### 2. Verificar los perfiles de Fargate

```bash
aws eks list-fargate-profiles --cluster-name pragma-demo-dev-eks-main --region us-east-1 --profile default
```

### 3. Verificar los addons instalados

```bash
aws eks list-addons --cluster-name pragma-demo-dev-eks-main --region us-east-1 --profile default
```

### 4. Verificar los pods en ejecución

```bash
kubectl get pods -A -o wide
```

Deberías ver los pods de CoreDNS y otros addons ejecutándose en Fargate.

### 5. Probar la funcionalidad de CoreDNS

```bash
# Crear un pod de prueba
kubectl run test-dns --image=busybox:1.28 -- sleep 3600

# Esperar a que el pod esté en ejecución
kubectl wait --for=condition=Ready pod/test-dns

# Probar la resolución DNS
kubectl exec -it test-dns -- nslookup kubernetes.default
```

### 6. Probar el AWS Load Balancer Controller

```bash
# Crear una aplicación de ejemplo
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.21
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: nginx
  namespace: default
spec:
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
  selector:
    app: nginx
  type: LoadBalancer
EOF

# Verificar que se crea el balanceador de carga
kubectl get svc nginx
```

## Limpieza

Para eliminar todos los recursos creados:

```bash
terraform destroy
```

Confirma la eliminación escribiendo `yes` cuando se te solicite.

## Personalización

Este ejemplo puede personalizarse de varias maneras:

### Configuración de Fargate Profiles adicionales

Puedes añadir más perfiles de Fargate para diferentes namespaces o aplicaciones:

```hcl
fargate_profiles = {
  # ... perfiles existentes ...
  
  "monitoring" = {
    cluster_name    = "pragma-demo-dev-eks-main"
    pod_execution_role_arn = "arn:aws:iam::123456789012:role/eks-fargate-pod-execution-role"
    subnet_ids      = ["subnet-1", "subnet-2", "subnet-3"]
    
    selectors = [
      {
        namespace = "monitoring"
        labels = {}
      }
    ]
  }
}
```

### Configuración de addons adicionales

Puedes añadir más addons según tus necesidades:

```hcl
addons = {
  # ... addons existentes ...
  
  aws-ebs-csi-driver = {
    addon_version = "v1.25.0-eksbuild.1"
    resolve_conflicts_on_create = "OVERWRITE"
    resolve_conflicts_on_update = "OVERWRITE"
    service_account_role_arn = "arn:aws:iam::123456789012:role/aws-ebs-csi-driver-role"
  }
}
```

### Configuración para aplicaciones específicas

Puedes configurar selectores de Fargate para aplicaciones específicas:

```hcl
selectors = [
  {
    namespace = "app-namespace"
    labels = {
      "environment" = "production"
      "criticality" = "high"
    }
  }
]
```

### Consideraciones para Fargate

1. **Limitaciones de Fargate**:
   - No soporta DaemonSets
   - No soporta privileged containers
   - Tiene límites en cuanto a CPU y memoria
   - No soporta volúmenes efímeros (EmptyDir) con medio de almacenamiento en memoria

2. **Optimización de costos**:
   - Fargate factura por vCPU y memoria asignada a los pods
   - Ajusta los recursos solicitados por tus pods para optimizar costos

3. **Networking**:
   - Los pods en Fargate siempre se ejecutan en subnets privadas
   - Cada pod recibe su propia ENI (Elastic Network Interface)

4. **Seguridad**:
   - Fargate proporciona aislamiento a nivel de hipervisor entre pods
   - No hay acceso al sistema operativo subyacente
