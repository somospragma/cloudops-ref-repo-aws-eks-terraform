# Módulo EKS Addons

## Propósito

Este módulo gestiona los addons oficiales de Amazon EKS, que son componentes complementarios que extienden la funcionalidad del cluster Kubernetes. Los addons proporcionan características esenciales como DNS, networking, monitoreo, y más. El módulo permite instalar, configurar y actualizar estos addons de manera declarativa y consistente.

## Recursos creados

Este módulo crea los siguientes recursos de AWS:

| Recurso | Descripción |
|---------|-------------|
| `aws_eks_addon` | Addons oficiales de EKS |

## Inputs detallados

### Variables principales

| Nombre | Descripción | Tipo | Requerido | Default |
|--------|-------------|------|----------|---------|
| `client` | Nombre del cliente para el que se crea el recurso | `string` | Sí | - |
| `project` | Nombre del proyecto o funcionalidad | `string` | Sí | - |
| `environment` | Entorno de despliegue (dev, qa, pdn) | `string` | Sí | - |
| `addons_config` | Configuración de addons para clusters EKS | `map(object)` | Sí | - |

### Estructura de addons_config

```hcl
addons_config = {
  "cluster_key" = {
    # Configuración básica (obligatoria)
    cluster_name = string
    
    # Configuración de add-ons (obligatoria)
    addons = map(object({
      addon_version            = optional(string)
      resolve_conflicts_on_create = optional(string, "OVERWRITE")
      resolve_conflicts_on_update = optional(string, "OVERWRITE")
      service_account_role_arn = optional(string)
      preserve                 = optional(bool, false)
      configuration_values     = optional(string, null)
    }))
    
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

- `cluster_name`: Nombre del cluster EKS donde se instalarán los addons

##### Configuración de addons

- `addon_version`: Versión específica del addon (opcional, si no se especifica se usa la última versión compatible)
- `resolve_conflicts_on_create`: Estrategia para resolver conflictos durante la creación ("NONE", "OVERWRITE" o "PRESERVE")
- `resolve_conflicts_on_update`: Estrategia para resolver conflictos durante la actualización ("NONE", "OVERWRITE" o "PRESERVE")
- `service_account_role_arn`: ARN del rol IAM que asumirá la cuenta de servicio del addon
- `preserve`: Si es true, el addon no se eliminará cuando se elimine el recurso de Terraform
- `configuration_values`: Valores de configuración en formato JSON para el addon

##### Timeouts personalizados

- `create`: Timeout para la creación del addon (minutos)
- `update`: Timeout para la actualización del addon (minutos)
- `delete`: Timeout para la eliminación del addon (minutos)

##### Etiquetas adicionales

- `additional_tags`: Mapa de etiquetas adicionales para los addons

## Outputs detallados

| Nombre | Descripción | Ejemplo |
|--------|-------------|---------|
| `addon_arns` | Mapa de ARNs de los addons | `{"main:vpc-cni" = "arn:aws:eks:us-east-1:123456789012:addon/pragma-demo-dev-eks-main/vpc-cni/abcdef12-3456-7890-abcd-ef1234567890"}` |
| `addon_ids` | Mapa de IDs de los addons | `{"main:vpc-cni" = "pragma-demo-dev-eks-main:vpc-cni"}` |
| `addon_statuses` | Mapa de estados de los addons | `{"main:vpc-cni" = "ACTIVE"}` |
| `addon_created_ats` | Mapa de fechas de creación de los addons | `{"main:vpc-cni" = "2023-01-15T10:30:00Z"}` |
| `addon_modified_ats` | Mapa de fechas de modificación de los addons | `{"main:vpc-cni" = "2023-01-15T10:30:00Z"}` |
| `addon_versions` | Mapa de versiones de los addons | `{"main:vpc-cni" = "v1.14.0-eksbuild.3"}` |

## Ejemplos de uso

### Ejemplo básico con addons esenciales

```hcl
module "eks_addons" {
  source = "../../modules/eks-addons"
  
  providers = {
    aws.project = aws.principal
  }
  
  client      = "pragma"
  project     = "demo"
  environment = "dev"
  
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
      }
    }
  }
}
```

### Ejemplo con addons avanzados y roles personalizados

```hcl
# Crear un rol IAM para el AWS Load Balancer Controller
resource "aws_iam_role" "aws_load_balancer_controller" {
  name = "pragma-demo-dev-alb-controller-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/ABCDEF1234567890"
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "oidc.eks.us-east-1.amazonaws.com/id/ABCDEF1234567890:sub": "system:serviceaccount:kube-system:aws-load-balancer-controller"
        }
      }
    }]
  })
}

# Adjuntar la política necesaria
resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller" {
  role       = aws_iam_role.aws_load_balancer_controller.name
  policy_arn = "arn:aws:iam::123456789012:policy/AWSLoadBalancerControllerIAMPolicy"
}

module "eks_addons" {
  source = "../../modules/eks-addons"
  
  providers = {
    aws.project = aws.principal
  }
  
  client      = "pragma"
  project     = "demo"
  environment = "dev"
  
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
          configuration_values = jsonencode({
            env = {
              ENABLE_PREFIX_DELEGATION = "true"
              WARM_PREFIX_TARGET = "1"
            }
          })
        }
        aws-load-balancer-controller = {
          addon_version = "v2.7.1-eksbuild.1"
          resolve_conflicts_on_create = "OVERWRITE"
          resolve_conflicts_on_update = "OVERWRITE"
          service_account_role_arn = aws_iam_role.aws_load_balancer_controller.arn
        }
        aws-ebs-csi-driver = {
          addon_version = "v1.25.0-eksbuild.1"
          resolve_conflicts_on_create = "OVERWRITE"
          resolve_conflicts_on_update = "OVERWRITE"
        }
      }
      
      timeouts = {
        create = 45
        update = 45
        delete = 20
      }
      
      additional_tags = {
        "kubernetes.io/cluster-name" = "pragma-demo-dev-eks-main"
        "environment" = "dev"
      }
    }
  }
}
```

### Ejemplo con configuración personalizada para VPC CNI

```hcl
module "eks_addons" {
  source = "../../modules/eks-addons"
  
  providers = {
    aws.project = aws.principal
  }
  
  client      = "pragma"
  project     = "demo"
  environment = "dev"
  
  addons_config = {
    "main" = {
      cluster_name = "pragma-demo-dev-eks-main"
      
      addons = {
        vpc-cni = {
          addon_version = "v1.14.0-eksbuild.3"
          resolve_conflicts_on_create = "OVERWRITE"
          resolve_conflicts_on_update = "OVERWRITE"
          configuration_values = jsonencode({
            env = {
              # Habilitar delegación de prefijos para optimizar el uso de IPs
              ENABLE_PREFIX_DELEGATION = "true"
              WARM_PREFIX_TARGET = "1"
              
              # Configurar límites de pods por nodo
              WARM_IP_TARGET = "5"
              MINIMUM_IP_TARGET = "10"
              
              # Configurar MTU personalizado
              AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG = "true"
              ENI_CONFIG_LABEL_DEF = "topology.kubernetes.io/zone"
              
              # Habilitar métricas
              ENABLE_METRICS = "true"
            }
          })
        }
      }
    }
  }
}
```

## Consideraciones de rendimiento

- **Versiones de addons**: Utilizar versiones específicas de addons en lugar de permitir que EKS seleccione automáticamente la versión puede prevenir actualizaciones inesperadas que podrían afectar al rendimiento o la estabilidad.

- **CoreDNS**: El rendimiento de CoreDNS puede afectar a todas las aplicaciones del cluster. Para clusters grandes, considera aumentar el número de réplicas de CoreDNS o configurar el escalado automático.

- **VPC CNI**: La configuración del VPC CNI afecta directamente a la densidad de pods por nodo y al rendimiento de la red. Opciones como `ENABLE_PREFIX_DELEGATION` pueden aumentar significativamente el número de IPs disponibles por nodo.

- **Resolución de conflictos**: La opción `resolve_conflicts_on_update` determina cómo se manejan las configuraciones personalizadas durante las actualizaciones. "PRESERVE" mantiene las configuraciones personalizadas, mientras que "OVERWRITE" las sobrescribe con los valores predeterminados.

- **Roles IAM**: Utilizar roles IAM específicos para cada addon (a través de `service_account_role_arn`) mejora la seguridad siguiendo el principio de privilegio mínimo, pero requiere una configuración adicional.

- **Orden de instalación**: Algunos addons dependen de otros. Por ejemplo, muchos addons dependen de CoreDNS para la resolución de nombres. Es importante instalar los addons en el orden correcto o utilizar dependencias explícitas.

- **Configuración de timeouts**: Los timeouts predeterminados son adecuados para la mayoría de los casos, pero en clusters grandes o con muchos addons, puede ser necesario aumentarlos.

- **Recursos del cluster**: Cada addon consume recursos del cluster (CPU, memoria). Es importante dimensionar adecuadamente los nodos para soportar todos los addons instalados.

## Limitaciones conocidas

- **Compatibilidad de versiones**: No todas las versiones de addons son compatibles con todas las versiones de Kubernetes. Es importante verificar la compatibilidad antes de especificar una versión.

- **Configuración personalizada**: Aunque `configuration_values` permite personalizar la configuración de los addons, no todas las opciones de configuración están disponibles a través de este parámetro.

- **Addons disponibles**: No todos los addons populares de Kubernetes están disponibles como addons oficiales de EKS. Algunos requieren instalación manual o a través de Helm.

- **Actualización de addons**: La actualización de addons puede causar interrupciones temporales en los servicios que dependen de ellos.

- **Roles IAM**: Para utilizar `service_account_role_arn`, el cluster debe tener configurado un proveedor OIDC.

- **Preservación de recursos**: Si se establece `preserve = true`, el addon no se eliminará cuando se elimine el recurso de Terraform, lo que puede causar problemas de gestión de estado.

- **Conflictos de configuración**: Si un addon ya está instalado manualmente o a través de otro método, puede haber conflictos al intentar gestionarlo con este módulo.

- **Tiempo de instalación**: La instalación de addons puede tardar varios minutos, especialmente para addons complejos como el AWS Load Balancer Controller.

- **Dependencias entre addons**: Este módulo no gestiona automáticamente las dependencias entre addons. Es responsabilidad del usuario asegurar que los addons se instalen en el orden correcto.

- **Límites de recursos**: Algunos addons pueden tener requisitos específicos de recursos que deben ser satisfechos por los nodos del cluster.
