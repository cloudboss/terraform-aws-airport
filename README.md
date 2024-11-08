# airport

A Terraform module to manage [Concourse](https://concourse-ci.org/) clusters on EC2.

It is unique in that it uses an EC2 AMI created by [easyto](https://github.com/cloudboss/easyto) that is built from the [official Concourse container image](https://hub.docker.com/r/concourse/concourse). This enables a container-like approach to managing instances, but directly on EC2 instead of a container orchestrator.

See the `example` directory for a sample root module that uses this module.

# Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| ami | Configuration of the AMI for instances. | [object](#ami-object) | `{}` | no |
| database | Configuration for the Aurora PostgreSQL database. | [object](#database-object) | N/A | yes |
| dns | Configuration of DNS. | [object](#dns-object) | N/A | yes |
| kms\_key\_ids | Configuration of KMS keys. | [object](#kms-key-ids-object) | N/A | yes |
| ssh\_key | An SSH key to assign to instances. | string | `null` | no |
| subnet\_ids | Configuration of subnets. | [object](#subnet-ids-object) | N/A | yes |
| ssm\_prefix | The prefix of SSM parameters that will be created by the module. The full prefix will be derived from this and `stack_key`. | string | `/airport` | no |
| stack\_key | A unique name from which to derive cloud resource names. | string | N/A | yes |
| tags | Tags to assign to cloud resources. | map(string) | `null` | no |
| web | Configuration of web instances. | [object](#web-object) | N/A | yes |
| workers | A list of configurations for worker instance groups. | list([object](#worker-object)) | N/A | yes |

## ami object

The ami object has the following structure.

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| filters | Filters to search for an AMI. Required if `name` is not defined. | [object](#ami-filters-object) | `[]` | conditional |
| most\_recent | Whether or not to return the most recent image found. | bool | `true` | no |
| name | Name of the AMI. Required if `filters` is not defined. | string | `concourse-7.11.0` | conditional |
| owner | AWS account where the image is located. | string | `256008164056` | no |

## ami filters object

The ami filters object has the following structure.

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| name | Name of the filter. See documentation on [ec2:DescribeImages](https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeImages.html) for available filters. | string | N/A | yes |
| values | Values of the filter. | list(string) | N/A | yes |

## database object

The database object has the following structure.

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| backups | Configuration for RDS backups. | [object](#database-backups-object) | `{}` | no |
| engine | Configuration of the database engine. | [object](#database-engine-object) | `{}` | no |
| instance\_class | Class of instances. Required unless `serverless_v2` is defined. | string | `null` | conditional |
| monitoring | Configuration of database monitoring. | [object](#database-monitoring-object) | `{}` | no |
| parameter\_group | Configuration of a cluster parameter group. | [object](#database-parameter-group-object) | `{}` | no |
| serverless\_v2 | Configuration of a cluster parameter group. | [object](#database-serverless_v2-object) | `null` | conditional |
| skip\_final\_snapshot | Whether or not to skip the final snapshot when destroying the database. | bool | `null` | no |

## database backups object

The database backups object has the following structure.

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| retention\_period | How long to retain backups. | number | `null` | no |
| preferred\_window | Preferred window of time in which to run backups. See documentation on [rds:CreateDBCluster](https://docs.aws.amazon.com/AmazonRDS/latest/APIReference/API_CreateDBCluster.html) for the format. | string | `null` | no |

## database engine object

The database engine object has the following structure.

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| type | The engine type. | string | `aurora-postgresql` | no |
| version | The engine version. | string | `16.2` | no |

## database monitoring object

The database monitoring object has the following structure.

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| interval | The monitoring interval. | number | `0` | no |
| role_arn | ARN of a role that permits RDS to send Enhanced Monitoring metrics to Amazon CloudWatch Logs. | string | `null` | no |

## database parameter group object

The database parameter group object has the following structure.

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| family | The family for the parameter group. | string | `aurora-postgresql16` | no |
| parameters | A list of parameter objects. | list([object](#database-parameter-group-parameters-object)) | N/A | yes |

## database parameter group parameters object

The database parameter group parameters object has the following structure.

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| apply\_method | When to apply the parameters. Choice of `immediate`, `pending-reboot`. | string | `null` | no |
| name | Name of the parameter. | string | N/A | yes |
| value | Value of the parameter. | string | N/A | yes |

## database serverless\_v2 object

The database serverless\_v2 object has the following structure.

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| max\_capacity | Maximum capacity of serverless instances. | number | N/A | yes |
| min\_capacity | Minimum capacity of serverless instances. | number | N/A | yes |

## dns object

The dns object has the following structure.

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| domain | The domain where records will be added. This must be the name of a Route53 zone. | string | N/A | yes |
| hostname\_web | The short hostname of the web load balancer. The default is derived from `stack_key`. | string | `null` | no |
| hostname\_tsa | The short hostname of the TSA load balancer. The default is derived from `stack_key`. | string | `null` | no |

## kms key ids object

The kms key ids object has the following structure.

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| credentials | The KMS key used for encrypting credentials. | string | N/A | yes |
| storage | The KMS key used for encrypting storage. | string | N/A | yes |

## subnet ids object

The subnet ids object has the following structure.

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| application | Subnets for application instances, database, and TSA load balancer. | list(string) | N/A | yes |
| load_balancer | Subnets for the web load balancer. | list(string) | N/A | yes |

## web object

The web object has the following structure.

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| autoscaling | Configuration of the web autoscaling group. | [object](#autoscaling-object) | N/A | yes |
| concourse | Configuration of the Concourse web process. | [object](#web-concourse-object) | N/A | yes |
| external\_url | The external URL of the web load balancer. The default is derived from `stack_key` and `dns.domain` | string | `null` | no |
| extra\_env | Extra environment variables. See the [easyto documentation](https://github.com/cloudboss/easyto?tab=readme-ov-file#name-value-object) for the structure of the name-value object. | list(object) | `[]` | no |
| extra\_env\_from | Extra environment variables from external sources. See the [easyto documentation](https://github.com/cloudboss/easyto?tab=readme-ov-file#env-from-object) for the structure of the env-from object. | list(object) | `[]` | no |
| extra\_security\_group\_ids | Extra security groups to assign to the instances. | list(string) | `[]` | no |
| iam | Configuration of the IAM role of the instances. | [object](#iam-object) | `{}` | no |
| public | Whether or not the load balancer should be internet facing. | bool | `true` | no |
| volume_root | Configuration of the root EBS volume of the instances. | [object](#volume-object) | `{}` | no |

## web concourse object

The web concourse object has the following structure.

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| credential\_manager | Configuration of a credential manager. | [object](#web-concourse-credential_manager-object) | `null` | no |
| extra\_args | Additional arguments to pass to the concourse web process. | list(string) | `[]` | no |
| features | Concourse feature flags to enable. | list(string) | `["enable-across-step", "enable-cache-streamed-volumes", "enable-global-resources", "enable-p2p-volume-streaming", "enable-pipeline-instances", "enable-redact-secrets", "enable-rerun-when-worker-disappears"]` | no |
| log\_level | The concourse log level. Choice of `debug`, `info`, `error`, `fatal`. | string | `info` | no |

## web concourse credential\_manager object

The web concourse credential\_manager object has the following structure.

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| ssm | Configuration of the SSM credential manager. | [object](#web-concourse-credential_manager-ssm-object) | `null` | no |
| secrets\_manager | Configuration of the Secrets Manager credential manager. | [object](#web-concourse-credential_manager-secrets_manager-object) | `null` | no |

## web concourse credential\_manager ssm object

The web concourse credential\_manager ssm object has the following structure.

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| path\_prefix | The prefix to use for SSM parameters. | string | N/A | yes |

## web concourse credential\_manager secrets\_manager object

The web concourse credential\_manager secrets\_manager object has the following structure.

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| path\_prefix | The prefix to use for Secrets Manager secret names. | string | N/A | yes |

## worker object

The worker object has the following structure.

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| autoscaling | Configuration of the worker autoscaling group. | [object](#autoscaling-object) | N/A | yes |
| concourse | Configuration of the Concourse worker process. | [object](#worker-concourse-object) | N/A | yes |
| extra\_security\_group\_ids | Extra security groups to assign to the instances. | list(string) | `[]` | no |
| name | Name of the worker group. | string | N/A | yes |
| iam | Configuration of the IAM role of the instances. | [object](#iam-object) | `{}` | no |
| volumes | Configuration of the EBS volumes of the instances. | [object](#worker-volume-object) | `{}` | no |

## worker concourse object

The worker concourse object has the following structure.

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| containerd\_network\_pool | IP address range to use for containers. | string | `10.80.0.0/16` | no |
| extra\_args | Additional arguments to pass to the concourse worker process. | list(string) | `[]` | no |
| log\_level | The concourse log level. Choice of `debug`, `info`, `error`, `fatal`. | string | `info` | no |

## worker volumes object

The worker volumes object has the following structure.

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| root | Configuration of the root EBS volume of the instances. | [object](#volume-object) | `{}` | no |
| work | Configuration of the work EBS volume of the instances. | [object](#volume-object) | `{}` | no |

## autoscaling object

The autoscaling object has the following structure.

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| instance\_refresh | Configuration of instance refresh. See the upstream [asg module](https://github.com/cloudboss/terraform-aws-asg/blob/v0.1.0/variables.tf#L114-L136) for the structure. | object | `{ strategy = "Rolling" }` | no |
| instance\_type | Type of the EC2 instances. Required if `mixed_instances_overrides` is not defined. | string | `null` | conditional |
| instances\_desired | The initial number of instances desired. | number | N/A | yes |
| instances\_max | The maximum number of instances desired. | number | N/A | yes |
| instances\_min | The minimum number of instances desired. | number | N/A | yes |
| max\_instance\_lifetime | The maximum lifetime of instances in seconds. | number | `null` | no |
| mixed\_instances\_distribution | The distribution of mixed instances. See the upstream [asg module](https://github.com/cloudboss/terraform-aws-asg/blob/v0.1.0/variables.tf#L169-L181) for the structure. | object | `null` | no |
| mixed\_instances\_overrides | A list of override objects for mixed instances. See the upstream [asg module](https://github.com/cloudboss/terraform-aws-asg/blob/v0.1.0/variables.tf#L183-f2441) for the structure of the object. Required if `instance_type` is not defined. | list(object) | `null` | conditional |
| suspended\_processes | A list of autoscaling processes to suspend. | list(string) | `[]` | no |
| termination\_policies | A list of policies to decide how instances should be terminated. | list(string) | `[]` | no |

## iam object

The iam object has the following structure.

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| extra\_policy\_arns | Additional policy ARNs to assign to the IAM role. | list(string) | `[]` | no |
| permissions\_boundary | An IAM policy ARN to use as a permissions boundary for the IAM role. | string | `null` | no |

## volume object

The volume object has the following structure.

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| iops | Number of IOPs given to the volume. | number | `null` | no |
| name | Name of the volume. This defaults to `/dev/xvda` for root volumes and `/dev/xvdb` for concourse work volumes. | string | conditional | no |
| size | Size of the volume in GB. This defaults to `4` for root volumes and `100` for concourse work volumes. | number | conditional | no |
| type | Type of the EBS volume. | string | `gp3` | no |

# Outputs

| Name | Description |
|------|-------------|
| database | An object representing the database. |
| lb\_tsa | An object representing the TSA load balancer. |
| lb\_web | An object representing the web load balancer. |
| web | An object representing the web instances. |
| workers | An object representing the worker instances. |
