###############################################################################
# github-oidc.tf — OIDC Provider + IAM Role pentru GitHub Actions
#
# Permite pipeline-ului GitHub Actions să se autentifice la AWS
# FĂRĂ chei statice — primește credențiale temporare la fiecare rulare.
###############################################################################

# --- OIDC Identity Provider pentru GitHub ------------------------------------
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

# --- Trust policy: cine are voie să asume rolul ------------------------------
data "aws_iam_policy_document" "github_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    # Token-ul trebuie emis pentru sts.amazonaws.com
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Restricționează DOAR la repository-ul tău (orice branch)
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repo}:*"]
    }
  }
}

# --- Rolul IAM pe care GitHub Actions îl va asuma ----------------------------
resource "aws_iam_role" "github_actions" {
  name               = "${var.project_name}-github-actions"
  assume_role_policy = data.aws_iam_policy_document.github_assume.json

  tags = {
    Name = "${var.project_name}-github-actions"
  }
}

# --- Permisiunile rolului ----------------------------------------------------
# Pentru un proiect de învățare folosim PowerUserAccess (gestionează resurse,
# dar nu poate modifica IAM). Pe termen lung se poate restrânge și mai mult.
resource "aws_iam_role_policy_attachment" "github_actions" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

# Permisiuni IAM suplimentare — necesare pentru ca Terraform rulat din pipeline
# să poată gestiona rolul OIDC și provider-ul (PowerUserAccess nu acoperă IAM).
resource "aws_iam_role_policy" "github_actions_iam" {
  name = "${var.project_name}-iam-management"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "iam:GetRole",
        "iam:GetPolicy",
        "iam:GetPolicyVersion",
        "iam:ListRolePolicies",
        "iam:ListAttachedRolePolicies",
        "iam:GetOpenIDConnectProvider",
        "iam:GetRolePolicy"
      ]
      Resource = "*"
    }]
  })
}
