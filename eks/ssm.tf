resource "aws_iam_role_policy_attachment" "eks_node_ssm_fe" {
  role       = module.eks.eks_managed_node_groups["backend_group"].iam_role_name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}