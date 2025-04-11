# Módulo EKS Node Groups

## Propósito

Este módulo crea y gestiona grupos de nodos (Node Groups) para Amazon Elastic Kubernetes Service (EKS). Los Node Groups proporcionan la capacidad de cómputo para ejecutar las aplicaciones en contenedores dentro del cluster EKS. El módulo permite configurar múltiples grupos de nodos con diferentes tipos de instancias, capacidades y configuraciones de escalado.

## Recursos creados

Este módulo crea los siguientes recursos de AWS:

| Recurso | Descripción |
|---------|-------------|
| `aws_eks_node_group` | Grupos de nodos gestionados por EKS |

## Inputs detallados

### Variables principales

| Nombre | Descripción | Tipo | Requerido | Default |
|--------|-------------|------|----------|---------|
| `client` | Nombre del cliente para el que se crea el recurso | `string` | Sí | - |
| `project` | Nombre del proyecto o funcionalidad | `string` | Sí | - |
| `environment` | Entorno de despliegue (dev, qa, pdn) | `string` | Sí | - |
| `nodegroups` | Configuración de Node Groups para EKS | `map(object)` | Sí | - |

### Estructura de nodegroups

```hcl
nodegroups = {
  "nodegroup_key" = {
    # Configuración básica (obligatoria)
    cluster_name    = string
    node_role_arn   = string
    subnet_ids      = list(string)
    
    # Configuración de capacidad (opcional)
    instance_types  = optional(list(string), ["t3.medium"])
    capacity_type   = optional(string, "ON_DEMAND")  # ON_DEMAND o SPOT
    disk_size       = optional(number, 20)
    
    # Configuración de escalado (opcional)
    desired_size    = optional(number, 2)
    min_size        = optional(number, 1)
    max_size        = optional(number, 3)
    
    # Configuración de AMI (opcional)
    ami_type        = optional(string, "AL2_x86_64")  # AL2_x86_64, AL2_ARM_64, etc.
    release_version = optional(string, null)
    
    # Configuración de actualización (opcional)
    update_config = optional(object({
      max_unavailable            = optional(number, 1)
      max_unavailable_percentage = optional(number, null)
    }), null)
    
    # Configuración de etiquetas y taints (opcional)
    labels         = optional(map(string), {})
    taints         = optional(list(object({
      key    = string
      value  = string
      effect = string
    })), [])
    
    # Timeouts personalizados en minutos (opcional)
    timeouts = optional(object({
      create = optional(number, 30)
      update = optional(number, 30)
      delete = optional(number, 15)
    }), null)
    
    # Etiquetas adicionales (opcional)
    additional_tags = optional(map(string), {})
  }
}
```

#### Detalles de los parámetros

##### Configuración básica

- `cluster_name`: Nombre del cluster EKS al que pertenecerá el Node Group
- `node_role_arn`: ARN del rol IAM que asumirán los nodos
- `subnet_ids`: Lista de IDs de subnets donde se desplegarán los nodos

##### Configuración de capacidad

- `instance_types`: Lista de tipos de instancias EC2 para los nodos
- `capacity_type`: Tipo de capacidad ("ON_DEMAND" o "SPOT")
- `disk_size`: Tamaño del disco raíz en GB

##### Configuración de escalado

- `desired_size`: Número deseado de nodos
- `min_size`: Número mínimo de nodos
- `max_size`: Número máximo de nodos

##### Configuración de AMI

- `ami_type`: Tipo de AMI para los nodos (AL2_x86_64, AL2_ARM_64, etc.)
- `release_version`: Versión específica de la AMI

##### Configuración de actualización

- `max_unavailable`: Número máximo de nodos que pueden estar no disponibles durante una actualización
- `max_unavailable_percentage`: Porcentaje máximo de nodos que pueden estar no disponibles durante una actualización

##### Configuración de etiquetas y taints

- `labels`: Mapa de etiquetas de Kubernetes para los nodos
- `taints`: Lista de taints de Kubernetes para los nodos

##### Timeouts personalizados

- `create`: Timeout para la creación del Node Group (minutos)
- `update`: Timeout para la actualización del Node Group (minutos)
- `delete`: Timeout para la eliminación del Node Group (minutos)

##### Etiquetas adicionales

- `additional_tags`: Mapa de etiquetas adicionales para el Node Group

## Outputs detallados

| Nombre | Descripción | Ejemplo |
|--------|-------------|---------|
| `nodegroup_arns` | Mapa de ARNs de los Node Groups | `{"general" = "arn:aws:eks:us-east-1:123456789012:nodegroup/pragma-demo-dev-eks-main/pragma-demo-dev-ng-general/abcdef12-3456-7890-abcd-ef1234567890"}` |
| `nodegroup_ids` | Mapa de IDs de los Node Groups | `{"general" = "pragma-demo-dev-ng-general"}` |
| `nodegroup_statuses` | Mapa de estados de los Node Groups | `{"general" = "ACTIVE"}` |
| `nodegroup_versions` | Mapa de versiones de Kubernetes de los Node Groups | `{"general" = "1.28"}` |

## Ejemplos de uso

### Ejemplo básico

```hcl
module "eks_nodegroups" {
  source = "../../modules/eks-nodegroups"
  
  providers = {
    aws.project = aws.principal
  }
  
  client      = "pragma"
  project     = "demo"
  environment = "dev"
  
  nodegroups = {
    "general" = {
      cluster_name    = "pragma-demo-dev-eks-main"
      node_role_arn   = "arn:aws:iam::123456789012:role/EksNodeRole"
      subnet_ids      = ["subnet-1", "subnet-2", "subnet-3"]
    }
  }
}
```

### Ejemplo con múltiples Node Groups

```hcl
module "eks_nodegroups" {
  source = "../../modules/eks-nodegroups"
  
  providers = {
    aws.project = aws.principal
  }
  
  client      = "pragma"
  project     = "demo"
  environment = "dev"
  
  nodegroups = {
    "general" = {
      cluster_name    = "pragma-demo-dev-eks-main"
      node_role_arn   = "arn:aws:iam::123456789012:role/EksNodeRole"
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
      node_role_arn   = "arn:aws:iam::123456789012:role/EksNodeRole"
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
}
```

### Ejemplo con configuración de actualización

```hcl
module "eks_nodegroups" {
  source = "../../modules/eks-nodegroups"
  
  providers = {
    aws.project = aws.principal
  }
  
  client      = "pragma"
  project     = "demo"
  environment = "dev"
  
  nodegroups = {
    "general" = {
      cluster_name    = "pragma-demo-dev-eks-main"
      node_role_arn   = "arn:aws:iam::123456789012:role/EksNodeRole"
      subnet_ids      = ["subnet-1", "subnet-2", "subnet-3"]
      
      instance_types  = ["t3.large"]
      capacity_type   = "ON_DEMAND"
      
      desired_size    = 3
      min_size        = 2
      max_size        = 5
      
      # Configuración de actualización
      update_config = {
        max_unavailable = 1
      }
      
      # Timeouts personalizados
      timeouts = {
        create = 45
        update = 45
        delete = 20
      }
    }
  }
}
```

## Consideraciones de rendimiento

- **Tipos de instancias**: La elección del tipo de instancia afecta directamente al rendimiento y costo del cluster. Considera el uso de instancias optimizadas para cómputo (c5, c6g) para cargas de trabajo intensivas en CPU, o instancias optimizadas para memoria (r5, r6g) para aplicaciones que requieren mucha memoria.

- **Capacidad Spot vs On-Demand**: Las instancias Spot pueden reducir significativamente los costos (hasta un 70-90%), pero pueden ser terminadas con poca antelación. Son ideales para cargas de trabajo tolerantes a fallos, como procesamiento por lotes o trabajos de CI/CD.

- **Tamaño del disco**: Un tamaño de disco demasiado pequeño puede causar problemas si los nodos acumulan muchas imágenes de contenedores o logs. Se recomienda un mínimo de 20GB, pero considerar 50GB+ para entornos de producción.

- **Escalado**: Configurar adecuadamente los valores de `min_size`, `max_size` y `desired_size` es crucial para la eficiencia de costos y rendimiento. Considera usar el Cluster Autoscaler para ajustar automáticamente el número de nodos según la demanda.

- **Distribución de zonas**: Distribuir los nodos en múltiples zonas de disponibilidad mejora la resiliencia, pero puede aumentar los costos de transferencia de datos entre zonas.

- **Taints y labels**: El uso estratégico de taints y labels permite dirigir cargas de trabajo específicas a nodos específicos, optimizando el uso de recursos.

- **Actualizaciones**: La configuración `max_unavailable` afecta la velocidad y el impacto de las actualizaciones. Un valor más alto acelera las actualizaciones pero puede reducir la capacidad disponible durante el proceso.

- **AMI optimizadas**: Las AMI optimizadas para EKS incluyen configuraciones y optimizaciones específicas para Kubernetes, mejorando el rendimiento y la seguridad.

## Limitaciones conocidas

- **Cambios inmutables**: Algunos parámetros como `capacity_type`, `subnet_ids` y `disk_size` no pueden cambiarse después de la creación del Node Group. Requieren recrear el Node Group.

- **Actualización de versión**: La actualización de la versión de Kubernetes en un Node Group existente no es posible. Se debe crear un nuevo Node Group con la versión deseada y migrar las cargas de trabajo.

- **Tipos de instancias**: Una vez creado el Node Group, no se puede modificar la lista de tipos de instancias.

- **Capacidad mínima**: Durante las actualizaciones, el número de nodos puede caer temporalmente por debajo del `min_size` configurado.

- **Taints**: Los taints aplicados a través de este módulo se aplican a nivel de Node Group. No es posible aplicar taints a nodos individuales.

- **Escalado automático**: Este módulo configura los parámetros de escalado, pero no implementa el Cluster Autoscaler. Se requiere una instalación separada del Cluster Autoscaler para el escalado automático basado en la demanda.

- **Tiempo de creación**: La creación de un Node Group puede tardar entre 3-10 minutos, dependiendo del número de nodos y el tipo de instancia.

- **Límites de servicio**: EKS tiene límites en el número de Node Groups por cluster (30 por defecto) y nodos por cluster (450 por defecto).

- **Rol IAM**: El rol IAM debe existir antes de crear el Node Group y debe tener las políticas necesarias adjuntas (`AmazonEKSWorkerNodePolicy`, `AmazonEC2ContainerRegistryReadOnly`, `AmazonEKS_CNI_Policy`).

- **Compatibilidad de AMI**: No todas las AMI son compatibles con todas las versiones de Kubernetes. Es importante verificar la compatibilidad antes de especificar una `release_version` personalizada.
