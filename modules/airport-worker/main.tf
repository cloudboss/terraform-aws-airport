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
    "--baggageclaim-bind-ip=0.0.0.0",
    "--baggageclaim-driver=overlay",
    "--baggageclaim-log-level=${var.concourse.log_level}",
    "--containerd-network-pool=${var.concourse.containerd_network_pool}",
    "--ephemeral",
    "--log-level=${var.concourse.log_level}",
    "--tsa-host=${var.tsa_host}",
    "--tsa-public-key=${local.concourse_key_dir}/tsa_host_key.pub",
    "--tsa-worker-private-key=${local.concourse_key_dir}/worker_key",
    "--work-dir=${local.concourse_work_dir}",
  ]
  aws_account_id = data.aws_caller_identity.me.account_id
  aws_region     = data.aws_region.here.name
  command = concat(
    # The container image entrypoint starts dumb-init,
    # but we override it since the AMI has easyto-init.
    ["/usr/local/bin/entrypoint.sh", "worker"],
    local.args_default,
    var.concourse.extra_args,
  )
  concourse_key_dir  = "/concourse-keys"
  concourse_work_dir = "/concourse-work-dir"
  fs_type            = "ext4"
  iam_policy_statements = [
    {
      Action = [
        "ssm:GetParameter",
        "ssm:GetParametersByPath",
      ]
      Effect   = "Allow"
      Resource = local.ssm_resources
    },
    {
      Action   = ["kms:Decrypt"]
      Effect   = "Allow"
      Resource = [var.kms_key_id_credentials]
    },
  ]
  ssm_arn_prefix = "arn:aws:ssm:${local.aws_region}:${local.aws_account_id}:parameter"
  ssm_resources  = tolist([for path in var.ssm.paths_keys : "${local.ssm_arn_prefix}${path}"])
  volumes_ebs = [{
    ebs = {
      device  = var.volumes.work.name
      fs-type = local.fs_type
      mount = {
        destination = local.concourse_work_dir
      }
    }
  }]
  volumes_ssm = [for ssm_path in var.ssm.paths_keys : {
    ssm = {
      path = ssm_path
      mount = {
        destination = "${local.concourse_key_dir}/${basename(ssm_path)}"
      }
    }
  }]
  volumes = concat(local.volumes_ebs, local.volumes_ssm)
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

  command = local.command
  env = [
    # Use an environment variable for this instead of an
    # argument because the entrypoint script reads it.
    {
      name  = "CONCOURSE_RUNTIME"
      value = "containerd"
    },
  ]
  init-scripts = [
    <<-EOF
    #!/bin/sh
    # Containerd needs to load kernel modules. The concourse container image
    # does not have modprobe, but we can link to the busybox added in the AMI.
    ln -s /.easyto/bin/busybox /sbin/modprobe

    # The container image entrypoint moves PID 1 to the entrypoint
    # cgroup, but we modify it to move the entrypoint PID instead.
    sed -i 's|^echo 1 >|echo $$ >|' /usr/local/bin/entrypoint.sh
    EOF
  ]
  volumes = local.volumes
}

module "asg" {
  source  = "cloudboss/asg/aws"
  version = "0.1.0"

  ami = var.ami
  block_device_mappings = [
    {
      device_name = var.volumes.root.name
      ebs = {
        iops        = var.volumes.root.iops
        volume_size = var.volumes.root.size
        volume_type = var.volumes.root.type
      }
    },
    {
      device_name = var.volumes.work.name
      ebs = {
        iops        = var.volumes.work.iops
        volume_size = var.volumes.work.size
        volume_type = var.volumes.work.type
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
  termination_policies = var.autoscaling.termination_policies
  user_data = {
    value = module.user_data.value
  }
  vpc_id = var.vpc_id
}
