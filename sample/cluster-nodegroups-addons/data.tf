data "aws_kms_key" "eks_secrets" {
  provider = aws.principal
  key_id   = "alias/aws/eks"
}