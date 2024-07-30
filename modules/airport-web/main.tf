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

locals {
  args_default = [
    "--cluster-name=${var.cluster_name}",
    "--external-url=${var.external_url}",
    "--log-cluster-name",
    "--log-level=${var.concourse.log_level}",
    "--main-team-local-user=concourse",
    "--peer-address=$(IPV4_ADDRESS)",
    "--postgres-database=${var.postgres.database}",
    "--postgres-host=${var.postgres.host}",
    "--postgres-port=${var.postgres.port}",
    "--postgres-user=${var.postgres.user}",
    "--prometheus-bind-ip=${var.prometheus.bind_ip}",
    "--prometheus-bind-port=${var.prometheus.port}",
    "--secret-cache-enabled",
    "--streaming-artifacts-compression=raw",
    "--tsa-log-level=${var.concourse.log_level}",
    "--tsa-peer-address=$(IPV4_ADDRESS)",
  ]

  args_credential_manager = concat(local.args_credential_manager_asm, local.args_credential_manager_ssm)

  args_credential_manager_asm = (
    var.concourse.credential_manager.secrets_manager == null
    ? []
    : [
      "--aws-secretsmanager-pipeline-secret-template=${local.path_prefix_asm}/{{.Team}}/{{.Pipeline}}/{{.Secret}}",
      "--aws-secretsmanager-shared-secret-template=${local.path_prefix_asm}/{{.Secret}}",
      "--aws-secretsmanager-team-secret-template=${local.path_prefix_asm}/{{.Team}}/{{.Secret}}",
      "--aws-secretsmanager-region=$(AWS_REGION)",
    ]
  )

  args_credential_manager_ssm = (
    var.concourse.credential_manager.ssm == null
    ? []
    : [
      "--aws-ssm-pipeline-secret-template=${local.path_prefix_ssm}/{{.Team}}/{{.Pipeline}}/{{.Secret}}",
      "--aws-ssm-team-secret-template=${local.path_prefix_ssm}/{{.Team}}/{{.Secret}}",
      "--aws-ssm-region=$(AWS_REGION)",
    ]
  )

  args_features = [for feature in var.concourse.features : "--${feature}"]

  arn_prefix_asm = "arn:aws:secretsmanager:${local.aws_region}:${local.aws_account_id}:secret:"

  arn_prefix_ssm = "arn:aws:ssm:${local.aws_region}:${local.aws_account_id}:parameter"

  aws_account_id = data.aws_caller_identity.me.account_id

  aws_region = data.aws_region.here.name

  env = concat([
    {
      name = "CONCOURSE_POSTGRES_PASSWORD"
      # The `password` variable comes from the secret created by RDS.
      value = "$(password)"
    },
  ], var.extra_env)

  env_from = concat([
    {
      imds = {
        name = "AWS_REGION"
        path = "/latest/meta-data/placement/region"
      }
    },
    {
      imds = {
        name = "IPV4_ADDRESS"
        path = "/latest/meta-data/local-ipv4"
      }
    },
    {
      ssm = {
        name = "CONCOURSE_ADD_LOCAL_USER"
        path = var.ssm.path_local_users
      }
    },
    {
      secrets-manager = {
        secret-id = var.postgres.password_secret_id
      }
    },
  ], var.extra_env_from)

  command = concat(
    # The container image entrypoint starts dumb-init,
    # but we override it since the AMI has easyto-init.
    ["/usr/local/bin/entrypoint.sh", "web"],
    local.args_default,
    local.args_features,
    local.args_credential_manager,
    var.concourse.extra_args,
  )

  concourse_key_dir = "/concourse-keys"

  iam_policy_statements = concat(
    local.iam_policy_statements_base,
    local.iam_policy_statements_credential_manager_asm,
  )

  iam_policy_statements_base = [
    {
      Action = [
        "ssm:GetParameter",
        "ssm:GetParametersByPath",
      ]
      Effect   = "Allow"
      Resource = local.ssm_resources
    },
    {
      Action = [
        "secretsmanager:GetSecretValue",
      ]
      Effect   = "Allow"
      Resource = [var.postgres.password_secret_id]
    },
    {
      Action   = ["kms:Decrypt"]
      Effect   = "Allow"
      Resource = [var.kms_key_id_credentials]
    },
  ]

  iam_policy_statements_credential_manager_asm = (
    var.concourse.credential_manager.secrets_manager == null
    ? []
    : [
      {
        Action = [
          "secretsmanager:ListSecrets",
        ]
        Effect   = "Allow"
        Resource = ["*"]
      },
      {
        Action = [
          "secretsmanager:DescribeSecret",
          "secretsmanager:GetSecretValue",
        ]
        Effect   = "Allow"
        Resource = local.asm_resource_credential_manager
      },
    ]
  )

  path_prefix_asm = try(var.concourse.credential_manager.secrets_manager.path_prefix, null)

  path_prefix_ssm = try(var.concourse.credential_manager.ssm.path_prefix, null)

  ssm_resource_credential_manager = (
    var.concourse.credential_manager.ssm == null
    ? []
    : ["${local.arn_prefix_ssm}${var.concourse.credential_manager.ssm.path_prefix}/*"]
  )

  asm_resource_credential_manager = (
    var.concourse.credential_manager.secrets_manager == null
    ? []
    : ["${local.arn_prefix_asm}${var.concourse.credential_manager.secrets_manager.path_prefix}/*"]
  )

  ssm_resources = tolist(
    concat(
      local.ssm_resource_credential_manager,
      ["${local.arn_prefix_ssm}${var.ssm.path_local_users}"],
      [for path in var.ssm.paths_keys : "${local.arn_prefix_ssm}${path}"]
    )
  )

  volumes = [for ssm_path in var.ssm.paths_keys : {
    ssm = {
      path = ssm_path
      mount = {
        destination = "${local.concourse_key_dir}/${basename(ssm_path)}"
      }
    }
  }]
}

data "aws_caller_identity" "me" {}

data "aws_region" "here" {}

module "iam_role" {
  source  = "cloudboss/iam-role/aws"
  version = "0.1.0"

  trust_policy_statements = [
    {
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    },
  ]
  create_instance_profile = true
  name                    = var.name
  permissions_boundary    = var.iam.permissions_boundary
  policy_arns             = var.iam.extra_policy_arns
  policy_statements       = local.iam_policy_statements
  tags                    = var.tags
}

module "user_data" {
  source  = "cloudboss/easyto-user-data/aws"
  version = "0.1.0"

  command  = local.command
  env      = local.env
  env-from = local.env_from
  volumes  = local.volumes
}

module "asg" {
  source  = "cloudboss/asg/aws"
  version = "0.1.0"

  ami = var.ami
  block_device_mappings = [
    {
      device_name = var.volume_root.name
      ebs = {
        iops        = var.volume_root.iops
        volume_size = var.volume_root.size
        volume_type = var.volume_root.type
      }
    },
  ]
  instance_initiated_shutdown_behavior = "terminate"
  instance_refresh                     = var.autoscaling.instance_refresh
  instance_type                        = var.autoscaling.instance_type
  instances_desired                    = var.autoscaling.instances_desired
  instances_max                        = var.autoscaling.instances_max
  instances_min                        = var.autoscaling.instances_min
  iam_instance_profile                 = module.iam_role.instance_profile.arn
  max_instance_lifetime                = var.autoscaling.max_instance_lifetime
  mixed_instances_distribution         = var.autoscaling.mixed_instances_distribution
  mixed_instances_overrides            = var.autoscaling.mixed_instances_overrides
  name                                 = var.name
  security_group_ids                   = var.security_group_ids
  ssh_key                              = var.ssh_key
  subnet_ids                           = var.subnet_ids
  suspended_processes                  = var.autoscaling.suspended_processes
  tags = {
    default = var.tags
  }
  target_group_arns    = var.target_group_arns
  termination_policies = var.autoscaling.termination_policies
  user_data = {
    value = module.user_data.value
  }
  vpc_id = var.vpc_id
}
