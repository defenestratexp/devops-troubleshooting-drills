terraform {
  required_providers {
    local = { source = "hashicorp/local", version = "~> 2.5" }
  }
}

variable "services" {
  type = set(string)
}

# Taken as an input rather than derived from path.module on purpose: the files
# must land in the same place they did before the refactor.
variable "out_dir" {
  type = string
}

resource "local_file" "config" {
  for_each = var.services
  filename = "${var.out_dir}/${each.key}.conf"
  content  = "service=${each.key}\n"
}
