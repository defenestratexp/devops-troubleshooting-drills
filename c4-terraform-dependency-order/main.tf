terraform {
  required_providers {
    local = { source = "hashicorp/local", version = "~> 2.5" }
  }
}

# The build step. Stands in for a script that computes a version string we
# cannot work out ourselves -- here, the release plus a digest of it.
resource "terraform_data" "build" {
  input = var.release

  provisioner "local-exec" {
    command = <<-CMD
      mkdir -p ${path.root}/out
      printf '%s+%s\n' '${var.release}' "$(printf '%s' '${var.release}' | md5sum | cut -c1-8)" \
        > ${path.root}/out/version.txt
    CMD
  }
}

# Read back what the build step produced.
data "local_file" "version" {
  filename = "${path.root}/out/version.txt"
}

resource "local_file" "manifest" {
  filename = "${path.root}/out/manifest.json"
  content = jsonencode({
    release = trimspace(data.local_file.version.content)
  })
}
