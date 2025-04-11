# Módulo para crear el cluster EKS
module "eks_cluster" {
  source = "../../modules/eks-cluster"
  
  providers = {
    aws.project = aws.principal
  }
  
  client      = var.client
  project     = var.project
  environment = var.environment
  
  eks_config = {
    "main" = {
      kubernetes_version      = "1.32"
      vpc_id                  = var.vpc_id
      subnet_ids              = var.subnet_ids
      cluster_role_arn        = var.cluster_role_arn
      cluster_security_group_ids = var.security_group_ids
      
      endpoint_private_access = true
      endpoint_public_access  = var.endpoint_public_access
      public_access_cidrs     = var.public_access_cidrs

      access_config = {
        authentication_mode = "API_AND_CONFIG_MAP"
        bootstrap_cluster_creator_admin_permissions = true
      }
      
      encryption_config = [{
        provider_key_arn = data.aws_kms_key.eks_secrets.arn
        resources        = ["secrets"]
      }]
      
      create_cloudwatch_log_group            = true
      cloudwatch_log_group_retention_in_days = var.log_retention_days
      cluster_enabled_log_types              = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
      
      additional_tags = {
        "kubernetes.io/cluster-name" = "${var.client}-${var.project}-${var.environment}-eks-main"
      }
    }
  }
}

# Módulo para crear Node Groups
module "eks_nodegroups" {
  source = "../../modules/eks-nodegroups"
  
  providers = {
    aws.project = aws.principal
  }
  
  client      = var.client
  project     = var.project
  environment = var.environment
  
  nodegroups = {
    "workers" = {
      cluster_name  = module.eks_cluster.cluster_names["main"]
      node_role_arn = var.node_role_arn
      subnet_ids    = var.subnet_ids
      
      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
      disk_size      = 30
      
      desired_size = 2
      min_size     = 1
      max_size     = 4
      
      labels = {
        "role" = "worker"
      }
      
      additional_tags = {
        "kubernetes.io/cluster-name" = "${var.client}-${var.project}-${var.environment}-eks-main"
        "nodegroup-type" = "workers"
      }
    }
  }
  
  depends_on = [module.eks_cluster]
}

# Módulo para crear addons después de que los Node Groups estén disponibles
module "eks_addons" {
  source = "../../modules/eks-addons"
  
  providers = {
    aws.project = aws.principal
  }
  
  client      = var.client
  project     = var.project
  environment = var.environment
  
  addons_config = {
    "main" = {
      cluster_name = module.eks_cluster.cluster_names["main"]
      
      addons = {
        coredns = {
          addon_version     = "v1.11.4-eksbuild.2"
          resolve_conflicts_on_create = "OVERWRITE"
          resolve_conflicts_on_update = "OVERWRITE"
        }
        kube-proxy = {
          addon_version     = "v1.31.3-eksbuild.2"
          resolve_conflicts_on_create = "OVERWRITE"
          resolve_conflicts_on_update = "OVERWRITE"
        }
        vpc-cni = {
          addon_version     = "v1.19.3-eksbuild.1"
          resolve_conflicts_on_create = "OVERWRITE"
          resolve_conflicts_on_update = "OVERWRITE"
        }
      }
      
      timeouts = {
        create = 30
        update = 30
        delete = 15
      }
      
      additional_tags = {
        "kubernetes.io/cluster-name" = "${var.client}-${var.project}-${var.environment}-eks-main"
      }
    }
  }
  
  depends_on = [module.eks_nodegroups]
}
