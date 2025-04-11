# Módulo Terraform para Amazon EKS

Este módulo de Terraform permite crear y gestionar clusters de Amazon Elastic Kubernetes Service (EKS) con todas las mejores prácticas de seguridad, nomenclatura y configuración según los estándares.

## Características

- Creación y gestión completa de clusters EKS
- Soporte para Node Groups y Fargate Profiles
- Gestión de addons oficiales de EKS
- Configuración avanzada de seguridad y networking
- Cifrado de secretos con AWS KMS
- Integración con IAM a través de OIDC
- Logging completo con CloudWatch
- Nomenclatura y etiquetado estandarizado

## Requerimientos

| Nombre | Versión |
|--------|---------|
| terraform | >= 1.0.0 |
| aws | >= 4.31.0 |
| kubernetes | >= 2.10.0 |
| tls | >= 3.0.0 |

Para utilizar este módulo, necesitarás:

- Credenciales AWS configuradas correctamente
- Permisos IAM para crear y gestionar recursos EKS
- Una VPC existente con subnets públicas y privadas
- Roles IAM para el cluster y los nodos

## Arquitectura

El módulo implementa una arquitectura modular para EKS que consta de tres componentes principales:

1. **Cluster EKS** - Plano de control de Kubernetes gestionado por AWS
   - API Server
   - etcd
   - Controladores
   - Scheduler

2. **Capacidad de cómputo** - Dos opciones disponibles:
   - **Node Groups**: Grupos de instancias EC2 gestionadas por AWS
   - **Fargate Profiles**: Capacidad serverless para pods específicos

3. **Addons** - Componentes adicionales para extender la funcionalidad:
   - CoreDNS: Resolución DNS dentro del cluster
   - kube-proxy: Networking de Kubernetes
   - VPC CNI: Integración con la red de AWS
   - Otros addons opcionales (AWS Load Balancer Controller, etc.)

La arquitectura sigue el modelo de responsabilidad compartida de AWS:
- AWS gestiona el plano de control de Kubernetes
- El cliente gestiona los nodos de trabajo y las aplicaciones

![Arquitectura EKS](docs/images/eks-architecture.png)

## Estructura del repositorio

```
eks/
├── README.md                      # Documentación principal
├── modules/
│   ├── eks-cluster/               # Módulo para crear clusters EKS
│   │   ├── README.md              # Documentación del módulo
│   │   ├── main.tf                
│   │   ├── variables.tf           
│   │   ├── outputs.tf             
│   │   ├── locals.tf              
│   │   └── providers.tf           
│   ├── eks-nodegroups/            # Módulo para crear Node Groups
│   │   ├── README.md              # Documentación del módulo
│   │   ├── main.tf                
│   │   ├── variables.tf           
│   │   ├── outputs.tf             
│   │   ├── locals.tf              
│   │   └── providers.tf           
│   └── eks-addons/                # Módulo para gestionar addons
│       ├── README.md              # Documentación del módulo
│       ├── main.tf                
│       ├── variables.tf           
│       ├── outputs.tf             
│       ├── locals.tf              
│       └── providers.tf           
└── examples/                      # Ejemplos de implementación
    ├── simple-cluster/            # Cluster EKS básico
    │   ├── README.md              # Documentación del ejemplo
    │   ├── main.tf                
    │   ├── variables.tf           
    │   ├── outputs.tf             
    │   ├── providers.tf           
    │   └── terraform.tfvars.sample
    ├── complete-cluster/          # Cluster EKS con opciones avanzadas
    │   ├── README.md              # Documentación del ejemplo
    │   ├── main.tf                
    │   ├── variables.tf           
    │   ├── outputs.tf             
    │   ├── providers.tf           
    │   └── terraform.tfvars.sample
    ├── cluster-fargate-addons/    # Cluster con Fargate y addons
    │   ├── README.md              # Documentación del ejemplo
    │   ├── main.tf                
    │   ├── variables.tf           
    │   ├── outputs.tf             
    │   ├── providers.tf           
    │   └── terraform.tfvars.sample
    └── cluster-nodegroups-addons/ # Cluster con Node Groups y addons
        ├── README.md              # Documentación del ejemplo
        ├── main.tf                
        ├── variables.tf           
        ├── outputs.tf             
        ├── providers.tf           
        └── terraform.tfvars.sample
```

## Notas importantes

### Permisos IAM

- **Rol del cluster**: Necesita `AmazonEKSClusterPolicy` para funcionar correctamente.
- **Rol de los nodos**: Requiere las siguientes políticas:
  - `AmazonEKSWorkerNodePolicy`
  - `AmazonEC2ContainerRegistryReadOnly`
  - `AmazonEKS_CNI_Policy`

### Configuración de red

- Las subnets deben estar en al menos dos zonas de disponibilidad diferentes.
- Las subnets deben tener las etiquetas correctas:
  - Para subnets públicas: `kubernetes.io/role/elb` = `1`
  - Para subnets privadas: `kubernetes.io/role/internal-elb` = `1`
  - Para todas las subnets: `kubernetes.io/cluster/<cluster-name>` = `shared` o `owned`

### Versiones de Kubernetes

- Verifica la compatibilidad entre la versión de Kubernetes y las versiones de los addons.
- Planifica cuidadosamente las actualizaciones de versión y pruébalas en entornos no productivos primero.

### Costos

- EKS tiene un costo por hora por cada cluster ($0.10/hora).
- Los nodos EC2 y otros recursos AWS se facturan por separado.
- Fargate se factura por vCPU y memoria asignada a los pods.

### Limitaciones

- El número máximo de clusters por cuenta es 100 (puede aumentarse mediante solicitud).
- El número máximo de nodos por cluster es 450 (puede aumentarse mediante solicitud).
- Algunas características de Kubernetes pueden no estar disponibles en EKS.

## Mejores prácticas

### Arquitectura

- **Separación de responsabilidades**: Utiliza diferentes Node Groups o Fargate Profiles para diferentes tipos de cargas de trabajo.
- **Alta disponibilidad**: Distribuye los nodos en múltiples zonas de disponibilidad.
- **Escalabilidad**: Configura el Cluster Autoscaler para escalar automáticamente los Node Groups.

### Seguridad

- **Acceso privado**: Configura el endpoint del API server como privado cuando sea posible.
- **Cifrado**: Habilita el cifrado de secretos con AWS KMS.
- **RBAC**: Utiliza roles y permisos de Kubernetes para controlar el acceso.
- **Roles IAM para cuentas de servicio**: Utiliza IRSA para asignar permisos específicos a pods.

### Operaciones

- **Logging**: Habilita todos los tipos de logs para facilitar la solución de problemas.
- **Monitoreo**: Implementa soluciones de monitoreo como CloudWatch Container Insights o Prometheus.
- **Backup**: Utiliza soluciones para hacer copias de seguridad de los recursos de Kubernetes.

### Networking

- **VPC CNI**: Configura correctamente el plugin CNI para optimizar la asignación de IPs.
- **Políticas de red**: Implementa políticas de red para controlar el tráfico entre pods.
- **Ingress**: Utiliza el AWS Load Balancer Controller para gestionar el tráfico entrante.

## Seguridad

Este módulo implementa las siguientes medidas de seguridad:

### Cifrado

- **Secretos de Kubernetes**: Cifrados en reposo con AWS KMS.
- **Comunicación API**: TLS para todas las comunicaciones con el API server.

### Control de acceso

- **API server**: Opciones para acceso privado y/o público con restricción de CIDRs.
- **Autenticación**: Soporte para autenticación mediante IAM y ConfigMap.
- **Autorización**: Integración con RBAC de Kubernetes.

### Aislamiento de red

- **Grupos de seguridad**: Configuración de grupos de seguridad para controlar el tráfico.
- **Subnets privadas**: Opción para desplegar nodos en subnets privadas.

### Auditoría y cumplimiento

- **Logging**: Habilitación de todos los tipos de logs para auditoría.
- **Integración con CloudTrail**: Registro de todas las llamadas a la API de EKS.

### Actualizaciones y parches

- **Actualizaciones de versión**: Proceso controlado para actualizar la versión de Kubernetes.
- **Parches de seguridad**: AWS aplica automáticamente parches de seguridad al plano de control.

## Lista de verificación de cumplimiento

- [x] Nomenclatura de recursos conforme al estándar
- [x] Etiquetas obligatorias aplicadas a todos los recursos
- [x] Cifrado en tránsito y en reposo implementado
- [x] Acceso de red restringido según principio de mínimo privilegio
- [x] Documentación actualizada y completa
- [x] Logging y auditoría habilitados
- [x] Roles IAM con privilegios mínimos
- [x] Configuración de seguridad de red adecuada
- [x] Alta disponibilidad configurada
- [x] Estrategia de backup recomendada
- [x] Monitoreo y alertas recomendados
