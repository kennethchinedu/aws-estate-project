# Setting up OIDC for AWS on Github
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]
}

resource "aws_iam_role" "ci_apply" {
  name = "ci-apply"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }

        Action = "sts:AssumeRoleWithWebIdentity"

        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"

            "token.actions.githubusercontent.com:sub" = "repo:kennethchinedu/aws-estate-project:ref:refs/heads/main"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ci_apply_admin" {
  role = aws_iam_role.ci_apply.name

  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

#CI plan role
resource "aws_iam_role" "ci_plan" {
  name = "ci-plan"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }

        Action = "sts:AssumeRoleWithWebIdentity"

        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"

            "token.actions.githubusercontent.com:sub" = "repo:kennethchinedu/aws-estate-project:pull_request"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ci_plan_readonly" {
  role       = aws_iam_role.ci_plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_role_policy" "ci_plan_lock" {
  name = "ci-plan-state-lock"
  role = aws_iam_role.ci_plan.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "s3:PutObject",
          "s3:DeleteObject"
        ]

        Resource = "arn:aws:s3:::aws-estate-tfstate-763054201886/management/eu-west-2/organization/terraform.tfstate.tflock"
      }
    ]
  })
}

