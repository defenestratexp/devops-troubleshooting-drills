terraform {
  required_providers {
    local = { source = "hashicorp/local", version = "~> 2.5" }
  }
}

# Each "service" gets a config file. Pretend these are IAM roles, S3 buckets, or
# anything else where a destroy-and-recreate is a real outage.
resource "local_file" "service_config" {
  count    = length(var.services)
  filename = "${path.module}/out/${var.services[count.index]}.conf"
  content  = "service=${var.services[count.index]}\n"
}
