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
  parameter_type                   = "SecureString"
  path_prefix_web                  = "${var.path_prefix}/web"
  path_prefix_worker               = "${var.path_prefix}/worker"
  path_session_signing_key_private = "${local.path_prefix_web}/session_signing_key"
  path_tsa_host_key_private        = "${local.path_prefix_web}/tsa_host_key"
  path_worker_keys_public          = "${local.path_prefix_web}/authorized_worker_keys"
  path_tsa_host_key_public         = "${local.path_prefix_worker}/tsa_host_key.pub"
  paths_worker_keys_private = { for group in var.worker_groups :
    group => "${local.path_prefix_worker}-${group}/worker_key"
  }
  worker_keys_public = join("", [
    for key in tls_private_key.worker_keys : key.public_key_openssh
  ])
}

resource "tls_private_key" "session_signing_key" {
  algorithm = "RSA"
  rsa_bits  = var.key_bits
}

resource "tls_private_key" "tsa_host_key" {
  algorithm = "RSA"
  rsa_bits  = var.key_bits
}

resource "tls_private_key" "worker_keys" {
  for_each = var.worker_groups

  algorithm = "RSA"
  rsa_bits  = var.key_bits
}

resource "aws_ssm_parameter" "session_signing_key_private" {
  key_id = var.kms_key_id
  name   = local.path_session_signing_key_private
  type   = local.parameter_type
  tags   = var.tags
  value  = tls_private_key.session_signing_key.private_key_pem
}

resource "aws_ssm_parameter" "tsa_host_key_private" {
  key_id = var.kms_key_id
  name   = local.path_tsa_host_key_private
  type   = local.parameter_type
  tags   = var.tags
  value  = tls_private_key.tsa_host_key.private_key_pem
}

resource "aws_ssm_parameter" "tsa_host_key_public" {
  key_id = var.kms_key_id
  name   = local.path_tsa_host_key_public
  type   = local.parameter_type
  tags   = var.tags
  value  = tls_private_key.tsa_host_key.public_key_openssh
}

resource "aws_ssm_parameter" "worker_keys_private" {
  for_each = tls_private_key.worker_keys

  key_id = var.kms_key_id
  name   = local.paths_worker_keys_private[each.key]
  type   = local.parameter_type
  tags   = var.tags
  value  = each.value.private_key_pem
}

resource "aws_ssm_parameter" "worker_keys_public" {
  key_id = var.kms_key_id
  name   = local.path_worker_keys_public
  type   = local.parameter_type
  tags   = var.tags
  value  = local.worker_keys_public
}
