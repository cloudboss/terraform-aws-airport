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
  type = any
}

variable "autoscaling" {
  type = any
}

variable "cluster_name" {
  type = string
}

variable "concourse" {
  type = any
}

variable "external_url" {
  type = string
}

variable "extra_env" {
  type = list(any)
}

variable "extra_env_from" {
  type = list(any)
}

variable "iam" {
  type = any
}

variable "kms_key_id_credentials" {
  type = string
}

variable "name" {
  type = string
}

variable "postgres" {
  type = any
}

variable "prometheus" {
  type = any
}

variable "security_group_ids" {
  type = list(string)
}

variable "ssh_key" {
  type = string
}

variable "ssm" {
  type = any
}

variable "subnet_ids" {
  type = list(string)
}

variable "tags" {
  type = map(string)
}

variable "target_group_arns" {
  type = list(string)
}

variable "volume_root" {
  type = any
}

variable "vpc_id" {
  type = string
}
