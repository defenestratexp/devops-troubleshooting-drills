terraform {
  required_providers {
    local = { source = "hashicorp/local", version = "~> 2.5" }
  }
}

# Stamped so we can tell one deployment from another in support tickets.
resource "local_file" "build_stamp" {
  filename = "${path.module}/out/build.json"
  content = jsonencode({
    service  = var.service
    built_at = timestamp()
  })
}

# Terraform renders the base config. The node-local section is appended
# afterwards, because only the node itself knows the address to put there.
resource "local_file" "app_config" {
  filename = "${path.module}/out/app.conf"
  content  = "[app]\nservice=${var.service}\n"

  provisioner "local-exec" {
    command = "printf '[node]\\naddress=127.0.0.1\\n' >> ${self.filename}"
  }
}
