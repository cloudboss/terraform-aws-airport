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

variable "ami" {
  type = object({
    filters = optional(list(object({
      name   = string
      values = list(string)
    })), [])
    most_recent = optional(bool, true)
    name        = optional(string, "concourse-7.11.0")
    owner       = optional(string, "256008164056")
  })
  description = "Configuration of the AMI for instances. One of filters or name must be set."

  default = {}
}

variable "database" {
  type = object({
    backups = optional(object({
      retention_period = optional(number, null)
      preferred_window = optional(string, null)
    }), {})
    engine = optional(object({
      type    = optional(string, "aurora-postgresql")
      version = optional(string, "16.2")
    }), {})
    instance_class = optional(string, null)
    monitoring = optional(object({
      interval = optional(number, 0)
      role_arn = optional(string, null)
    }), {})
    parameter_group = optional(object({
      family = optional(string, "aurora-postgresql16")
      parameters = list(object({
        apply_method = optional(string, null)
        name         = string
        value        = string
      }))
    }), null)
    serverless_v2 = optional(object({
      max_capacity = number
      min_capacity = number
    }), null)
    skip_final_snapshot = optional(bool, null)
  })
  description = "Configuration for the database."
}

variable "dns" {
  type = object({
    domain       = string
    hostname_web = optional(string, null)
    hostname_tsa = optional(string, null)
  })
  description = "Configuration for DNS."
}

variable "kms_key_ids" {
  type = object({
    credentials = string
    storage     = string
  })
  description = "KMS key IDs used for credentials and storage."
}

variable "ssh_key" {
  type        = string
  description = "An SSH key to assign to instances."

  default = null
}

variable "subnet_ids" {
  type = object({
    application   = list(string)
    load_balancer = list(string)
  })
  description = "Subnet IDs for application and load balancer."
}

variable "ssm_prefix" {
  type        = string
  description = "Path prefix for SSM parameters."

  default = "/airport"
}

variable "stack_key" {
  type        = string
  description = "The name from which to derive cloud resource names."
}

variable "tags" {
  type        = map(string)
  description = "Tags to assign to cloud resources."

  default = null
}

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC."
}

variable "web" {
  type = object({
    autoscaling = object({
      instance_refresh = optional(any, {
        strategy = "Rolling"
      })
      instance_type                = optional(string, null)
      instances_desired            = number
      instances_max                = number
      instances_min                = number
      max_instance_lifetime        = optional(number, null)
      mixed_instances_distribution = optional(any, null)
      mixed_instances_overrides    = optional(list(any), [])
      suspended_processes          = optional(list(string), [])
      termination_policies         = optional(list(string), [])
    })
    concourse = optional(object({
      credential_manager = optional(object({
        ssm = optional(object({
          path_prefix = string
        }), null)
        secrets_manager = optional(object({
          path_prefix = string
        }), null)
      }), {})
      extra_args = optional(list(string), [])
      features = optional(list(string), [
        "enable-across-step",
        "enable-cache-streamed-volumes",
        "enable-global-resources",
        "enable-p2p-volume-streaming",
        "enable-pipeline-instances",
        "enable-redact-secrets",
        "enable-rerun-when-worker-disappears",
      ])
      log_level = optional(string, "info")
    }), {})
    external_url = optional(string, null)
    extra_env = optional(list(object({
      name  = string
      value = string
    })), [])
    extra_env_from = optional(list(object({
      imds = optional(object({
        path     = string
        name     = optional(string, null)
        optional = optional(bool, null)
      }), null)
      s3 = optional(object({
        base64-encode = optional(bool, null)
        bucket        = string
        key           = string
        name          = optional(string, null)
        optional      = optional(bool, null)
      }), null)
      ssm = optional(object({
        base64-encode = optional(bool, null)
        name          = optional(string, null)
        path          = string
        optional      = optional(bool, null)
      }), null)
      secrets-manager = optional(object({
        base64-encode = optional(bool, null)
        name          = optional(string, null)
        optional      = optional(bool, null)
        secret-id     = string
      }), null)
    })), [])
    extra_security_group_ids = optional(list(string), [])
    iam = optional(object({
      extra_policy_arns    = optional(list(string), [])
      permissions_boundary = optional(string, null)
    }), {})
    public = optional(bool, true)
    volume_root = optional(object({
      iops = optional(number, null)
      name = optional(string, "/dev/xvda")
      size = optional(number, 4)
      type = optional(string, "gp3")
    }), {})
  })
  description = "Configuration for the web instances."
}

variable "workers" {
  type = list(object({
    autoscaling = object({
      instance_refresh = optional(any, {
        strategy = "Rolling"
      })
      instance_type                = optional(string, null)
      instances_desired            = number
      instances_max                = number
      instances_min                = number
      max_instance_lifetime        = optional(number, null)
      mixed_instances_distribution = optional(any, null)
      mixed_instances_overrides    = optional(any, [])
      suspended_processes          = optional(list(string), [])
      termination_policies         = optional(list(string), [])
    })
    concourse = optional(object({
      containerd_network_pool = optional(string, "10.80.0.0/16")
      extra_args              = optional(list(string), [])
      log_level               = optional(string, "info")
    }), {})
    extra_security_group_ids = optional(list(string), [])
    name                     = string
    iam = optional(object({
      extra_policy_arns    = optional(list(string), [])
      permissions_boundary = optional(string, null)
    }), {})
    volumes = optional(object({
      root = optional(object({
        iops = optional(number, null)
        name = optional(string, "/dev/xvda")
        size = optional(number, 4)
        type = optional(string, "gp3")
      }), {})
      work = optional(object({
        iops = optional(number, null)
        name = optional(string, "/dev/xvdb")
        size = optional(number, 100)
        type = optional(string, "gp3")
      }), {})
    }), {})
  }))
  description = "Configuration for worker groups."
}
