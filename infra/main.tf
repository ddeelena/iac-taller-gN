terraform {
  required_version = ">= 1.6"
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 4.6"
    }
  }
}
provider "docker" {}
resource "docker_image" "nginx" {
  name         = "nginx:1.28-alpine"
  keep_locally = true
}
resource "docker_container" "web" {
  name  = local.nombre
  image = docker_image.nginx.image_id
  ports {
    internal = 80
    external = var.puerto
  }
  upload {
    content = local.html
    file    = "/usr/share/nginx/html/index.html"
  }
  # TODO 3 (reto): agreguen las etiquetas con un bloque dynamic "labels"
  # que recorra local.etiquetas; cada etiqueta lleva label y value.

  dynamic "labels" {
    for_each = local.etiquetas
    content {
      label = labels.key
      value = labels.value
    }
  }
}
