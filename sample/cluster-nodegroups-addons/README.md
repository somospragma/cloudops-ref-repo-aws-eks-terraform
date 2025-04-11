# Ejemplo: Cluster con Node Groups y Addons

## Caso de uso

Este ejemplo demuestra la implementación de un cluster EKS con capacidad de cómputo basada en EC2 mediante Node Groups y addons esenciales. Es ideal para:

- Entornos de producción que requieren control total sobre los nodos de trabajo
- Cargas de trabajo que necesitan tipos específicos de instancias EC2
- Aplicaciones que requieren DaemonSets o contenedores privilegiados
- Implementaciones que se benefician de la capacidad Spot para reducir costos

## Arquitectura específica

Este ejemplo crea un cluster EKS con la siguiente arquitectura:

- **Plano de control de Kubernetes** gestionado por AWS
- **Node Groups** para proporcionar capacidad de cómputo basada en EC2:
  - Node Group "general" con instancias On-Demand para cargas de trabajo estables
  - Node Group "spot" con instancias Spot para cargas de trabajo tolerantes a interrupciones
- **Addons esenciales**:
  - CoreDNS: Resolución DNS dentro del cluster
  - kube-proxy: Networking de Kubernetes
  - VPC CNI: Integración con la red de AWS
  - AWS Load Balancer Controller: Gestión de balanceadores de carga
- **Cifrado de secretos** utilizando AWS KMS
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

3. **Rol IAM para los nodos** con las siguientes políticas:
   - `AmazonEKSWorkerNodePolicy`
   - `AmazonEC2ContainerRegistryReadOnly`
   - `AmazonEKS_CNI_Policy`
   ```hcl
   resource "aws_iam_role" "eks_node_role" {
     name = "eks-node-role"
     
     assume_role_policy = jsonencode({
       Version = "2012-10-17"
       Statement = [{
         Effect = "Allow"
         Principal = {
           Service = "ec2.amazonaws.com"
         }
         Action = "sts:AssumeRole"
       }]
     })
   }
   
   resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
     policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
     role       = aws_iam_role.eks_node_role.name
   }
   
   resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
     policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
     role       = aws_iam_role.eks_node_role.name
   }
   
   resource "aws_iam_role_policy_attachment" "ecr_read_only" {
     policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
     role       = aws_iam_role.eks_node_role.name
   }
   ```

4. **Roles IAM para addons** (opcional, pero recomendado para seguir el principio de privilegio mínimo)

5. **Clave KMS** para cifrar los secretos de Kubernetes

6. **Credenciales AWS** configuradas con permisos suficientes para crear recursos EKS

## Instrucciones paso a paso

### 1. Preparar el directorio de trabajo

```bash
# Crear el directorio para el ejemplo
mkdir -p eks-nodegroups-addons
cd eks-nodegroups-addons

# Copiar los archivos de ejemplo
cp /ruta/al/repositorio/examples/cluster-nodegroups-addons/* .
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

# Configuración de Node Groups
nodegroups = {
  "general" = {
    cluster_name    = "pragma-demo-dev-eks-main"
    node_role_arn   = "arn:aws:iam::123456789012:role/eks-node-role"
    subnet_ids      = ["subnet-1", "subnet-2", "subnet-3"]
    
    instance_types  = ["t3.large"]
    capacity_type   = "ON_DEMAND"
    disk_size       = 50
    
    desired_size    = 2
    min_size        = 1
    max_size        = 4
    
    labels = {
      "role" = "general"
      "workload-type" = "general"
    }
    
    additional_tags = {
      "kubernetes.io/cluster-name" = "pragma-demo-dev-eks-main"
      "k8s.io/cluster-autoscaler/enabled" = "true"
    }
  },
  "spot" = {
    cluster_name    = "pragma-demo-dev-eks-main"
    node_role_arn   = "arn:aws:iam::123456789012:role/eks-node-role"
    subnet_ids      = ["subnet-1", "subnet-2", "subnet-3"]
    
    instance_types  = ["t3.medium", "t3a.medium", "t2.medium"]
    capacity_type   = "SPOT"
    disk_size       = 30
    
    desired_size    = 3
    min_size        = 1
    max_size        = 10
    
    labels = {
      "role" = "spot"
      "workload-type" = "batch"
    }
    
    taints = [
      {
        key    = "spot"
        value  = "true"
        effect = "NO_SCHEDULE"
      }
    ]
    
    additional_tags = {
      "kubernetes.io/cluster-name" = "pragma-demo-dev-eks-main"
      "k8s.io/cluster-autoscaler/enabled" = "true"
    }
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
      kube-proxy = {
        addon_version = "v1.28.1-eksbuild.1"
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

Para verificar que el cluster, los Node Groups y los addons se han creado correctamente:

### 1. Verificar el estado del cluster

```bash
aws eks describe-cluster --name pragma-demo-dev-eks-main --region us-east-1 --profile default
```

### 2. Verificar los Node Groups

```bash
aws eks list-nodegroups --cluster-name pragma-demo-dev-eks-main --region us-east-1 --profile default
```

### 3. Verificar los nodos en el cluster

```bash
kubectl get nodes -o wide
```

Deberías ver los nodos de ambos Node Groups con sus respectivas etiquetas.

### 4. Verificar las etiquetas y taints de los nodos

```bash
# Verificar etiquetas
kubectl get nodes --show-labels

# Verificar taints
kubectl describe nodes | grep -i taint
```

### 5. Verificar los addons instalados

```bash
aws eks list-addons --cluster-name pragma-demo-dev-eks-main --region us-east-1 --profile default
```

### 6. Verificar los pods del sistema

```bash
kubectl get pods -n kube-system
```

Deberías ver los pods de CoreDNS, kube-proxy y aws-node (VPC CNI) ejecutándose.

### 7. Probar el AWS Load Balancer Controller

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

### 8. Probar el Node Group con taints

```bash
# Crear un pod que tolere el taint de los nodos spot
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-spot
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx-spot
  template:
    metadata:
      labels:
        app: nginx-spot
    spec:
      containers:
      - name: nginx
        image: nginx:1.21
      tolerations:
      - key: "spot"
        operator: "Equal"
        value: "true"
        effect: "NoSchedule"
      nodeSelector:
        role: spot
EOF

# Verificar que los pods se ejecutan en los nodos spot
kubectl get pods -l app=nginx-spot -o wide
```

## Limpieza

Para eliminar todos los recursos creados:

```bash
terraform destroy
```

Confirma la eliminación escribiendo `yes` cuando se te solicite.

## Personalización

Este ejemplo puede personalizarse de varias maneras:

### Configuración de Node Groups adicionales

Puedes añadir más Node Groups para diferentes tipos de cargas de trabajo:

```hcl
nodegroups = {
  # ... Node Groups existentes ...
  
  "gpu" = {
    cluster_name    = "pragma-demo-dev-eks-main"
    node_role_arn   = "arn:aws:iam::123456789012:role/eks-node-role"
    subnet_ids      = ["subnet-1", "subnet-2", "subnet-3"]
    
    instance_types  = ["g4dn.xlarge"]
    capacity_type   = "ON_DEMAND"
    disk_size       = 100
    
    desired_size    = 1
    min_size        = 0
    max_size        = 3
    
    labels = {
      "role" = "gpu"
      "workload-type" = "ml"
    }
    
    taints = [
      {
        key    = "nvidia.com/gpu"
        value  = "true"
        effect = "NO_SCHEDULE"
      }
    ]
  }
}
```

### Configuración de actualización personalizada

Puedes personalizar cómo se actualizan los Node Groups:

```hcl
"general" = {
  # ... configuración existente ...
  
  update_config = {
    max_unavailable = 1  # Solo un nodo a la vez estará no disponible durante las actualizaciones
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

### Consideraciones para Node Groups

1. **Tipos de instancias**:
   - Elige tipos de instancias adecuados para tus cargas de trabajo
   - Considera usar múltiples tipos de instancias en Node Groups Spot para mejorar la disponibilidad

2. **Capacidad Spot vs On-Demand**:
   - Usa On-Demand para cargas de trabajo críticas que requieren alta disponibilidad
   - Usa Spot para cargas de trabajo tolerantes a interrupciones para reducir costos

3. **Taints y labels**:
   - Usa taints para evitar que ciertas cargas de trabajo se ejecuten en nodos específicos
   - Usa labels para dirigir cargas de trabajo específicas a nodos específicos

4. **Escalado**:
   - Configura adecuadamente los valores de `min_size`, `max_size` y `desired_size`
   - Considera implementar el Cluster Autoscaler para escalar automáticamente los Node Groups
