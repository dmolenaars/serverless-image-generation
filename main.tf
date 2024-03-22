# Configure the AliCloud Provider
terraform {
  required_providers {
    alicloud = {
      source = "aliyun/alicloud"
      version = "1.218.0"
    }
  }
}

# Provider for Europe resources
provider "alicloud" {
  alias = "europe"
  region = var.europe_region
}

module "image_generator" {
   source = "./modules/image_generator"
   providers = {
     alicloud = alicloud.europe
   }
   europe_region = var.europe_region
}