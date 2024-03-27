# Configure the AliCloud Provider
terraform {
  required_providers {
    alicloud = {
      source  = "aliyun/alicloud"
      version = "1.219.0"
    }
  }
}

provider "alicloud" {
  region = var.deployment_region
}

module "container_registry" {
  source = "./modules/container_registry"
  providers = {
    alicloud : alicloud
  }
  deployment_region = var.deployment_region
  namespace_id      = var.namespace_id
}

module "image_generator" {
  source = "./modules/image_generator"
  providers = {
    alicloud : alicloud
  }
  deployment_region  = var.deployment_region
  registry_id        = module.container_registry.registry_id
  domain_name        = var.domain_name
  api_key            = var.api_key
  custom_domain_cert = var.custom_domain_cert
  custom_domain_key  = var.custom_domain_key
}
