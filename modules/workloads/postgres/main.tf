resource "aws_security_group" "this" {
  name_prefix = "${var.name}-db-"
  description = "PostgreSQL, from the listed client security groups only"
  vpc_id      = var.vpc_id

  # Replace without detaching: the new group exists before the old one is deleted
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "clients" {
  for_each = var.client_security_group_ids

  security_group_id            = aws_security_group.this.id
  description                  = "PostgreSQL from ${each.key}"
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = each.value
}

# Master password generated and rotated by RDS in Secrets Manager.
# PostgreSQL 15+ defaults rds.force_ssl = 1.
resource "aws_db_instance" "this" {
  identifier     = var.name
  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage = var.allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true
  kms_key_id        = var.kms_key_arn

  db_name                       = var.db_name
  username                      = var.username
  manage_master_user_password   = true
  master_user_secret_kms_key_id = var.kms_key_arn

  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = [aws_security_group.this.id]
  publicly_accessible    = false
  multi_az               = var.multi_az

  backup_retention_period    = var.backup_retention_period
  auto_minor_version_upgrade = true
  apply_immediately          = true
  skip_final_snapshot        = var.skip_final_snapshot
  deletion_protection        = var.deletion_protection
}
