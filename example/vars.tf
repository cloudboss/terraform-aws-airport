locals {
  ami = {
    name = "concourse-7.11.0"
  }

  aws_region = "us-east-1"

  database = {
    skip_final_snapshot = true
    serverless_v2 = {
      max_capacity = 4
      min_capacity = 0.5
    }
  }

  dns = {
    domain = "cloudboss.xyz"
  }

  kms_key_ids = {
    credentials = "alias/credentials"
    storage     = "alias/storage"
  }

  stack_key = "atl"

  subnet_ids = {
    application = [
      "subnet-ce19ab6789a0f558b",
      "subnet-770acebbb9c051efa",
      "subnet-a9d33d85eef79e604",
    ]
    load_balancer = [
      "subnet-c85d9f30fa71b03eb",
      "subnet-dc4b366adfaf8c151",
      "subnet-28a3bdd5df0b595b3",
    ]
  }

  tags = {
    stack-name = local.stack_key
    org        = "cloudboss"
  }

  vpc_id = "vpc-cfaf8fae40a4beef1"

  web = {
    autoscaling = {
      instance_type     = "m5.large"
      instances_desired = 2
      instances_max     = 4
      instances_min     = 1
    }
    concourse = {
      credential_manager = {
        ssm = {
          path_prefix = "/airport/${local.stack_key}/secrets"
        }
      }
    }
  }

  workers = [
    {
      autoscaling = {
        instances_desired = 2
        instances_max     = 10
        instances_min     = 1
        mixed_instances_distribution = {
          on_demand_percentage_above_base_capacity = 10
        }
        mixed_instances_overrides = [
          {
            instance_type = "m5.xlarge"
          },
          {
            instance_type = "m5a.xlarge"
          },
          {
            instance_type = "m6a.xlarge"
          },
        ]
      }
      name = "bopha"
    },
    {
      autoscaling = {
        instances_desired = 2
        instances_max     = 10
        instances_min     = 1
        mixed_instances_distribution = {
          on_demand_percentage_above_base_capacity = 10
        }
        mixed_instances_overrides = [
          {
            instance_type = "m5.xlarge"
          },
          {
            instance_type = "m5a.xlarge"
          },
          {
            instance_type = "m6a.xlarge"
          },
        ]
      }
      concourse = {
        extra_args = [
          "--team=platform",
        ]
      }
      iam = {
        extra_policy_arns = ["arn:aws:iam::aws:policy/iac"]
      }
      name = "phoyisa"
    },
  ]
}
