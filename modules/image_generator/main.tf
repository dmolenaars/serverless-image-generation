
terraform {
  required_providers {
    alicloud = {
      source  = "aliyun/alicloud"
      version = "1.219.0",
    }
  }
}
data "alicloud_account" "current" {
}

resource "alicloud_ram_role" "fc_role" {
  name     = "fc-image-generation-role"
  document = <<EOF
  {
      "Statement": [
        {
          "Action": "sts:AssumeRole",
          "Effect": "Allow",
          "Principal": {
            "Service": [
              "fc.aliyuncs.com"
            ]
          }
        }
      ],
      "Version": "1"
  }
  EOF
  force    = true
}

resource "alicloud_oos_secret_parameter" "api_key_parameter" {
  secret_parameter_name = "serverless-image-generation/dashscope-api-key"
  value                 = "placeholder_value" # After the secret parameter is created, you can use the CLI or the console to set its value to your API key.
}

resource "alicloud_ram_policy" "get_secret_parameter_policy" {
  policy_name     = "fc-image-generation-policy"
  policy_document = <<EOF
{
    "Statement": [
        {
            "Action": [
                "oos:GetSecretParameter",
                "oos:ListSecretParameters",
                "kms:GetSecretValue"
            ],
            "Effect": "Allow",
            "Resource": [
                "acs:oos:*:${data.alicloud_account.current.id}:secretparameter/serverless-image-generation/*",
                "acs:kms:*:${data.alicloud_account.current.id}:secret/oos/serverless-image-generation/*"
            ]
        }
    ],
    "Version": "1"
}
EOF
}


resource "alicloud_ram_role_policy_attachment" "get_secret_parameter_attachment" {
  policy_name = alicloud_ram_policy.get_secret_parameter_policy.policy_name
  policy_type = alicloud_ram_policy.get_secret_parameter_policy.type
  role_name   = alicloud_ram_role.fc_role.name
}

resource "alicloud_ram_role_policy_attachment" "registry_read_attachment" {
  policy_name = "AliyunContainerRegistryReadOnlyAccess"
  policy_type = "System"
  role_name   = alicloud_ram_role.fc_role.name
}

resource "alicloud_fc_service" "image_generation_service" {
  name = "fc-image-generation-service"
  role = alicloud_ram_role.fc_role.arn
}

resource "alicloud_fcv2_function" "fc_image_generation_function" {
  function_name        = "fc-image-generation"
  service_name         = alicloud_fc_service.image_generation_service.name
  memory_size          = "512"
  runtime              = "custom-container"
  handler              = "dummy_handler"
  ca_port              = 7860
  instance_concurrency = 20
  timeout              = 600
  custom_container_config {
    web_server_mode = true
    image           = "registry-intl-vpc.${var.deployment_region}.aliyuncs.com/${var.registry_id}:latest"
  }
}

resource "alicloud_fc_trigger" "http_trigger" {
  service  = alicloud_fc_service.image_generation_service.name
  function = alicloud_fcv2_function.fc_image_generation_function.function_name
  name     = "http-trigger"
  type     = "http"
  config   = <<EOF
    {
        "authType": "anonymous",
        "methods": ["GET", "POST", "HEAD", "OPTIONS"],
        "disableURLInternet": false
    }
EOF
}

resource "alicloud_fc_custom_domain" "custom_domain" {
  domain_name = var.domain_name
  protocol    = "HTTPS"
  route_config {
    path          = "/*"
    service_name  = alicloud_fc_service.image_generation_service.name
    function_name = alicloud_fcv2_function.fc_image_generation_function.function_name
  }
  # Once you have an SSL certificate for your domain, you can uncomment the cert_config property below to enable HTTPS for your custom domain. See the README on how to set the custom_domain_cert and custom_domain_key variables.
  # Note: directly referencing an Alibaba Cloud Certificate is not yet supported. See https://github.com/aliyun/terraform-provider-alicloud/issues/6935
  # cert_config {
  #   cert_name   = "serverless-image-generation-certificate"
  #   certificate = var.custom_domain_cert
  #   private_key = var.custom_domain_key
  # }
}
