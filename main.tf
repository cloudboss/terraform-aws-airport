# Copyright © 2024 Joseph Wright <joseph@cloudboss.co>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

data "aws_kms_key" "credentials" {
  key_id = var.kms_key_ids.credentials
}

data "aws_kms_key" "storage" {
  key_id = var.kms_key_ids.storage
}

resource "aws_security_group" "them" {
  for_each = local.security_group_names

  name   = each.value
  tags   = var.tags
  vpc_id = var.vpc_id
}

module "security_group_rules_database" {
  source  = "cloudboss/security-group-rules/aws"
  version = "0.1.0"

  mapping = local.security_group_mapping
  rules = [
    {
      from_port                 = local.ports.postgres
      ip_protocol               = "tcp"
      referenced_security_group = "web"
      to_port                   = local.ports.postgres
      type                      = "ingress"
    },
  ]
  security_group_id = local.security_group_mapping["database"]
  tags              = var.tags
}

module "security_group_rules_lb_tsa" {
  source  = "cloudboss/security-group-rules/aws"
  version = "0.1.0"

  mapping = local.security_group_mapping
  rules = [
    {
      from_port                 = local.ports.tsa
      ip_protocol               = "tcp"
      referenced_security_group = "worker"
      to_port                   = local.ports.tsa
      type                      = "ingress"
    },
    {
      from_port                 = local.ports.tsa
      ip_protocol               = "tcp"
      referenced_security_group = "web"
      to_port                   = local.ports.tsa
      type                      = "egress"
    },
    {
      # Use the web port for the health check to avoid
      # spamming the Concourse log with EOF errors.
      from_port                 = local.ports.web
      ip_protocol               = "tcp"
      referenced_security_group = "web"
      to_port                   = local.ports.web
      type                      = "egress"
    },
  ]
  security_group_id = local.security_group_mapping["lb-tsa"]
  tags              = var.tags
}

module "security_group_rules_lb_web" {
  source  = "cloudboss/security-group-rules/aws"
  version = "0.1.0"

  mapping = local.security_group_mapping
  rules = [
    {
      cidr_ipv4   = "0.0.0.0/0"
      from_port   = local.ports.https
      ip_protocol = "tcp"
      to_port     = local.ports.https
      type        = "ingress"
    },
    {
      from_port                 = local.ports.web
      ip_protocol               = "tcp"
      referenced_security_group = "web"
      to_port                   = local.ports.web
      type                      = "egress"
    },
  ]
  security_group_id = local.security_group_mapping["lb-web"]
  tags              = var.tags
}

module "security_group_rules_web" {
  source  = "cloudboss/security-group-rules/aws"
  version = "0.1.0"

  mapping = local.security_group_mapping
  rules = [
    {
      # TSA LB in.
      from_port                 = local.ports.tsa
      ip_protocol               = "tcp"
      referenced_security_group = "lb-tsa"
      to_port                   = local.ports.tsa
      type                      = "ingress"
    },
    {
      # TSA LB health check in.
      from_port                 = local.ports.web
      ip_protocol               = "tcp"
      referenced_security_group = "lb-tsa"
      to_port                   = local.ports.web
      type                      = "ingress"
    },
    # Web LB in.
    {
      from_port                 = local.ports.web
      ip_protocol               = "tcp"
      referenced_security_group = "lb-web"
      to_port                   = local.ports.web
      type                      = "ingress"
    },
    # Peer ephemeral ports.
    {
      from_port                 = 32768
      ip_protocol               = "tcp"
      referenced_security_group = "web"
      to_port                   = 65535
      type                      = "ingress"
    },
    {
      from_port                 = 32768
      ip_protocol               = "tcp"
      referenced_security_group = "web"
      to_port                   = 65535
      type                      = "egress"
    },
    # Database out.
    {
      from_port                 = local.ports.postgres
      ip_protocol               = "tcp"
      referenced_security_group = "database"
      to_port                   = local.ports.postgres
      type                      = "egress"
    },
    # HTTPS out.
    {
      cidr_ipv4   = "0.0.0.0/0"
      from_port   = local.ports.https
      ip_protocol = "tcp"
      to_port     = local.ports.https
      type        = "egress"
    },
  ]
  security_group_id = local.security_group_mapping["web"]
  tags              = var.tags
}

module "security_group_rules_worker" {
  source  = "cloudboss/security-group-rules/aws"
  version = "0.1.0"

  mapping = local.security_group_mapping
  rules = [
    # Peer baggageclaim ports.
    {
      ip_protocol               = "tcp"
      from_port                 = local.ports.baggageclaim
      referenced_security_group = "worker"
      to_port                   = local.ports.baggageclaim
      type                      = "ingress"
    },
    {
      ip_protocol               = "tcp"
      from_port                 = local.ports.baggageclaim
      referenced_security_group = "worker"
      to_port                   = local.ports.baggageclaim
      type                      = "egress"
    },
    # TSA LB out.
    {
      ip_protocol               = "tcp"
      from_port                 = local.ports.tsa
      referenced_security_group = "lb-tsa"
      to_port                   = local.ports.tsa
      type                      = "egress"
    },
    # HTTPS out.
    {
      cidr_ipv4   = "0.0.0.0/0"
      ip_protocol = "tcp"
      from_port   = local.ports.https
      to_port     = local.ports.https
      type        = "egress"
    },
  ]
  security_group_id = local.security_group_mapping["worker"]
  tags              = var.tags
}

module "database" {
  source  = "cloudboss/aurora/aws"
  version = "0.2.0"

  backups = var.database.backups
  database = {
    manage_password = true
    name            = "atc"
    username        = "concourse"
  }
  kms_key_ids = {
    password = var.kms_key_ids.credentials
    storage  = var.kms_key_ids.storage
  }
  engine              = var.database.engine
  instance_class      = var.database.instance_class
  monitoring          = var.database.monitoring
  name                = local.stack_prefix
  parameter_group     = var.database.parameter_group
  security_group_ids  = [local.security_group_mapping["database"]]
  serverless_v2       = var.database.serverless_v2
  skip_final_snapshot = var.database.skip_final_snapshot
  subnet_ids          = var.subnet_ids.private
  tags                = var.tags
}

module "ssh_keys" {
  source = "./modules/airport-keys"

  kms_key_id    = var.kms_key_ids.credentials
  path_prefix   = "${var.ssm_prefix}/${var.stack_key}"
  worker_groups = keys(local.workers)
  tags          = var.tags
}

module "acm_certificate_web" {
  source  = "cloudboss/acm/aws"
  version = "0.1.1"

  fqdn              = local.fqdn_web
  route53_zone_name = var.dns.domain
  tags              = var.tags
}

module "lb_tsa" {
  source  = "cloudboss/elbv2/aws"
  version = "0.1.1"

  listener = {
    port     = 2222
    protocol = "TCP"
    rules = {
      default = {
        type = "forward"
      }
    }
  }
  name               = "${local.stack_prefix}-tsa"
  security_group_ids = [local.security_group_mapping["lb-tsa"]]
  subnet_mapping = [for subnet_id in var.subnet_ids.private : {
    subnet_id = subnet_id
  }]
  tags = var.tags
  target_group = {
    connection_termination = true
    deregistration_delay   = 0
    health_check = {
      interval = 10
      # Use web port for health check to avoid EOF errors on the TCP port.
      port     = local.ports.web
      protocol = "HTTP"
    }
    port     = local.ports.tsa
    protocol = "TCP"
  }
  type   = "network"
  vpc_id = var.vpc_id
}

module "lb_web" {
  source  = "cloudboss/elbv2/aws"
  version = "0.1.1"

  internal = false
  listener = {
    default_action = {
      type = "forward"
    }
    port             = 443
    protocol         = "HTTPS"
    certificate_arns = [module.acm_certificate_web.certificate_arn]
    rules = {
      default = {
        type = "forward"
      }
    }
  }
  name               = "${local.stack_prefix}-web"
  security_group_ids = [local.security_group_mapping["lb-web"]]
  subnet_mapping = [for subnet_id in var.subnet_ids.public : {
    subnet_id = subnet_id
  }]
  tags = var.tags
  target_group = {
    deregistration_delay = 15
    health_check = {
      interval = 10
      port     = local.ports.web
      protocol = "HTTP"
    }
    port     = local.ports.web
    protocol = "HTTP"
  }
  type   = "application"
  vpc_id = var.vpc_id
}

module "dns" {
  source  = "cloudboss/route53-records/aws"
  version = "0.1.0"

  dns_records = [
    {
      alias = {
        evaluate_target_health = true
        name                   = module.lb_tsa.load_balancer.dns_name
        zone_id                = module.lb_tsa.load_balancer.zone_id
      }
      name = local.fqdn_tsa
      type = "A"
    },
    {
      alias = {
        evaluate_target_health = true
        name                   = module.lb_web.load_balancer.dns_name
        zone_id                = module.lb_web.load_balancer.zone_id
      }
      name = local.fqdn_web
      type = "A"
    },
  ]
  route53_zone_name = var.dns.domain
}

module "web" {
  source = "./modules/airport-web"

  ami                    = var.ami
  autoscaling            = var.web.autoscaling
  cluster_name           = var.stack_key
  concourse              = var.web.concourse
  external_url           = local.external_url
  extra_env              = var.web.extra_env
  extra_env_from         = var.web.extra_env_from
  iam                    = var.web.iam
  kms_key_id_credentials = data.aws_kms_key.credentials.arn
  name                   = "${local.stack_prefix}-web"
  postgres = {
    database           = "atc"
    host               = module.database.cluster.endpoint
    password_secret_id = one(module.database.cluster.master_user_secret[*].secret_arn)
    port               = local.ports.postgres
    user               = "concourse"
  }
  prometheus = {
    bind_ip = "$(IPV4_ADDRESS)"
    port    = local.ports.prometheus
  }
  security_group_ids = concat(
    [local.security_group_mapping["web"]],
    var.web.extra_security_group_ids,
  )
  ssh_key = var.ssh_key
  ssm = {
    path_local_users = local.ssm_paths.local_users
    paths_keys = [
      module.ssh_keys.path_tsa_host_key_private,
      module.ssh_keys.path_session_signing_key_private,
      module.ssh_keys.path_worker_keys_public,
    ]
  }
  subnet_ids = var.subnet_ids.private
  tags       = var.tags
  target_group_arns = [
    module.lb_tsa.target_group.arn,
    module.lb_web.target_group.arn,
  ]
  volume_root = var.web.volume_root
  vpc_id      = var.vpc_id
}

module "workers" {
  source   = "./modules/airport-worker"
  for_each = local.workers

  ami                    = var.ami
  autoscaling            = each.value.autoscaling
  concourse              = each.value.concourse
  iam                    = each.value.iam
  kms_key_id_credentials = data.aws_kms_key.credentials.arn
  name                   = "${local.stack_prefix}-worker-${each.key}"
  security_group_ids = concat(
    [local.security_group_mapping["worker"]],
    each.value.extra_security_group_ids,
  )
  ssh_key = var.ssh_key
  ssm = {
    paths_keys = [
      module.ssh_keys.path_tsa_host_key_public,
      module.ssh_keys.paths_worker_keys_private[each.key],
    ]
  }
  subnet_ids = var.subnet_ids.private
  tags       = var.tags
  tsa_host   = local.tsa_host
  volumes    = each.value.volumes
  vpc_id     = var.vpc_id
}
