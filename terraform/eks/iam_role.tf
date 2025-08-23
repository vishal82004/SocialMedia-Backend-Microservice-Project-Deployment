# iam_role.tf

# Add this data source to get the OIDC provider's certificate thumbprint.
# This is required to create the OIDC provider resource.
data "tls_certificate" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

# CHANGE: Convert the data source into a resource to explicitly create
# the OIDC provider, which avoids the race condition.
resource "aws_iam_openid_connect_provider" "oidc" {
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]

  # This depends_on is an extra safeguard to ensure the cluster is fully ready.
  depends_on = [aws_eks_cluster.main]
}

# IAM role for service account (IRSA)
resource "aws_iam_role" "irsa_role" {
  name = "microservices-irsa-role"
  # This policy document now correctly depends on the oidc resource we created.
  assume_role_policy = data.aws_iam_policy_document.irsa_assume_role_policy.json
}

# Trust policy with wildcard
data "aws_iam_policy_document" "irsa_assume_role_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      # This now references our explicit OIDC provider resource.
      identifiers = [aws_iam_openid_connect_provider.oidc.arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringLike"
      variable = "${replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")}:sub"
      values   = ["system:serviceaccount:microservices-prod:*"]
    }
  }
}

