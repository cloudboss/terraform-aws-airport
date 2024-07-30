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
  external_url = coalesce(var.web.external_url, "https://${local.fqdn_web}")

  fqdn_tsa = "${local.hostname_tsa}.${var.dns.domain}"

  fqdn_web = "${local.hostname_web}.${var.dns.domain}"

  hostname_tsa = coalesce(var.dns.hostname_tsa, "${var.stack_key}-tsa")

  hostname_web = coalesce(var.dns.hostname_web, var.stack_key)

  ports = {
    baggageclaim = 7788
    dns          = 53
    https        = 443
    postgres     = 5432
    prometheus   = 9090
    tsa          = 2222
    web          = 8080
  }

  security_group_mapping = { for key, sg in aws_security_group.them : key => sg.id }

  security_group_names = {
    database = "${local.stack_prefix}-database",
    lb-tsa   = "${local.stack_prefix}-lb-tsa",
    lb-web   = "${local.stack_prefix}-lb-web",
    web      = "${local.stack_prefix}-web",
    worker   = "${local.stack_prefix}-worker",
  }

  ssm_paths = {
    local_users = "${var.ssm_prefix}/${var.stack_key}/web/local-users"
    tsa_host_key = {
      private_key_path = "${var.ssm_prefix}/${var.stack_key}/web/tsa_host_key"
      public_key_path  = "${var.ssm_prefix}/${var.stack_key}/worker/tsa_host_key.pub"
    }
    worker_key = {
      private_key_path = "${var.ssm_prefix}/${var.stack_key}/worker/worker_key"
      public_key_path  = "${var.ssm_prefix}/${var.stack_key}/web/authorized_worker_keys"
    }
    session_signing_key = {
      private_key_path = "${var.ssm_prefix}/${var.stack_key}/web/session_signing_key"
    }
  }

  stack_prefix = "airport-${var.stack_key}"

  tsa_host = "${local.fqdn_tsa}:${local.ports.tsa}"

  workers = { for wg in var.workers : wg.name => wg }
}
