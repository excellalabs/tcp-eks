output "eks_deployer_access_key" {
  value = "${aws_iam_access_key.eks_deployer.id}"
}

output "eks_deployer_secret_key" {
  value = "${aws_iam_access_key.eks_deployer.secret}"
}
