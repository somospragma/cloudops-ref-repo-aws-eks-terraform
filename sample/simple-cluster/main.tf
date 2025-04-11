module "eks_cluster" {
  source = "../../modules/eks-cluster"
  
  providers = {
    aws.project = aws.principal
  }
  
  client      = var.client
  project     = var.project
  environment = var.environment
  
  eks_config = var.eks_config
}
