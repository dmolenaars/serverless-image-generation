terraform {
  required_providers {
    alicloud = {
      source = "aliyun/alicloud"
      version = "1.219.0"
    }
  }
}

resource "alicloud_cr_namespace" "custom_namespace" {
  name               = var.namespace_id
  auto_create        = false
  default_visibility = "PRIVATE"
}

resource "alicloud_cr_repo" "image_generator_repository" {
  namespace = alicloud_cr_namespace.custom_namespace.name
  name      = "serverless-image-generation"
  summary   = "An Alibaba Cloud serverless image generation service using Function Compute and Model Studio."
  repo_type = "PRIVATE"
}

output "registry_id" {
  value = alicloud_cr_repo.image_generator_repository.id
}