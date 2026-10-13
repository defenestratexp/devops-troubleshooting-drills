# This is the code that produced the state that is deployed today. It is here
# so the drill can rebuild that state. Do not edit it -- it is a record, not a
# place to fix things.
terraform {
  required_providers {
    local = { source = "hashicorp/local", version = "~> 2.5" }
  }
}

variable "services" {
  type    = set(string)
  default = ["alpha", "beta", "gamma"]
}

resource "local_file" "config" {
  for_each = var.services
  filename = "${path.root}/out/${each.key}.conf"
  content  = "service=${each.key}\n"
}
