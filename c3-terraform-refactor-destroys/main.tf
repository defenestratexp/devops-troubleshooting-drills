terraform {
  required_providers {
    local = { source = "hashicorp/local", version = "~> 2.5" }
  }
}

# Refactored: the resources used to live right here in the root. They now live
# in a module so the other two environments can reuse them.
module "service" {
  source   = "./modules/service"
  services = var.services
  out_dir  = "${path.root}/out"
}
