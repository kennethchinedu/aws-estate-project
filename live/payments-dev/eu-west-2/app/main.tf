module "ecr" {
  source = "../../../../modules/workloads/ecr-repository"

  name         = "pygoat"
  force_delete = true
}

module "logs" {
  source = "../../../../modules/workloads/log-bucket"

  bucket_name   = "aws-waf-logs-${var.name}-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
}

module "postgres" {
  source = "../../../../modules/workloads/postgres"

  name                 = var.name
  vpc_id               = local.network.vpc_id
  db_subnet_group_name = local.network.database_subnet_group_name
  kms_key_arn          = aws_kms_key.app.arn
  db_name              = "pygoat"
  username             = "pygoat"

  client_security_group_ids = {
    tasks = module.service.security_group_id
  }

  skip_final_snapshot = true
  deletion_protection = false
}

module "alb" {
  source = "../../../../modules/workloads/alb"

  name     = var.name
  vpc_id   = local.network.vpc_id
  internal = !var.public_alb_for_operator
  subnet_ids = (var.public_alb_for_operator
    ? local.network.public_subnet_ids
    : local.network.private_subnet_ids
  )

  # Internal: CloudFront VPC origin ENIs in the private subnets. Test-only public ALB: the operator.
  ingress_cidrs = (var.public_alb_for_operator
    ? { for i, c in var.operator_ip_cidrs : "operator-${i}" => c }
    : { for id, s in data.aws_subnet.private : s.availability_zone => s.cidr_block }
  )

  target_security_group_id = module.service.security_group_id
  target_port              = 8000
  health_check_matcher     = "200-399"
  access_logs_bucket       = module.logs.id
  access_logs_prefix       = module.logs.alb_log_prefix
}

module "service" {
  source = "../../../../modules/workloads/fargate-service"

  name       = var.name
  vpc_id     = local.network.vpc_id
  subnet_ids = local.network.private_subnet_ids
  image      = "${module.ecr.repository_url}:${var.image_tag}"

  # Migrations run against RDS at start
  command        = ["sh", "-c", "python manage.py migrate --noinput && exec gunicorn --bind 0.0.0.0:8000 --workers 2 pygoat.wsgi"]
  container_port = 8000

  environment = {
    DB_HOST       = module.postgres.address
    DB_PORT       = tostring(module.postgres.port)
    DB_NAME       = module.postgres.db_name
    ALLOWED_HOSTS = module.alb.dns_name
    CSRF_TRUSTED_ORIGINS = (var.enable_cloudfront
      ? "https://${module.edge.domain_name}"
      : "http://${module.alb.dns_name}"
    )
  }

  secrets = {
    DB_USER     = "${module.postgres.master_user_secret_arn}:username::"
    DB_PASSWORD = "${module.postgres.master_user_secret_arn}:password::"
  }
  secret_arns         = [module.postgres.master_user_secret_arn]
  secret_kms_key_arns = [aws_kms_key.app.arn]

  target_group_arn                = module.alb.target_group_arn
  load_balancer_security_group_id = module.alb.security_group_id
  health_check_grace_period       = 180

  egress_security_groups = {
    "interface endpoints" = { security_group_id = local.network.endpoints_security_group_id, port = 443 }
    postgres              = { security_group_id = module.postgres.security_group_id, port = 5432 }
  }

  egress_prefix_lists = {
    "S3 (ECR image layers)" = { prefix_list_id = data.aws_ec2_managed_prefix_list.s3.id, port = 443 }
  }
}

module "edge" {
  source = "../../../../modules/workloads/edge"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  name                = var.name
  create_distribution = var.enable_cloudfront
  alb_arn             = module.alb.arn
  alb_dns_name        = module.alb.dns_name
  allowed_ip_cidrs    = var.operator_ip_cidrs
  waf_log_bucket_arn  = module.logs.arn
  force_destroy       = true
}

module "backup" {
  source = "../../../../modules/workloads/backup"

  name               = var.name
  kms_key_arn        = aws_kms_key.app.arn
  resource_arns      = [module.postgres.arn]
  delete_after_days  = 1
  max_retention_days = 7
  force_destroy      = true
}
