
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

resource "alicloud_ram_policy" "policy" {
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


resource "alicloud_ram_role_policy_attachment" "attach" {
  policy_name = alicloud_ram_policy.policy.policy_name
  policy_type = alicloud_ram_policy.policy.type
  role_name   = alicloud_ram_role.fc_role.name
}

resource "alicloud_ram_role_policy_attachment" "attach2" {
  policy_name = "AliyunContainerRegistryReadOnlyAccess"
  policy_type = "System"
  role_name   = alicloud_ram_role.fc_role.name
}

resource "alicloud_fc_service" "default" {
  name = "fc-image-generation-service"
  role = alicloud_ram_role.fc_role.arn
}

resource "alicloud_fcv2_function" "fc_image_generation_function" {
  function_name = "fc-image-generation"
  service_name  = alicloud_fc_service.default.name
  memory_size   = "512"
  runtime       = "custom-container"
  handler       = "dummy_handler"
  custom_container_config {
    web_server_mode   = true
    image             = ""
  }
  ca_port = 7860
  instance_concurrency = 20
  timeout = 600
}

resource "alicloud_fc_trigger" "http_trigger" {
  service  = alicloud_fc_service.default.name
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
  domain_name = "genaiwithali.cloud" # Change this to your own custom domain.
  protocol    = "HTTP" # Change this to HTTPS if you have an SSL certificate for your domain.
  route_config {
    path          = "/*"
    service_name  = alicloud_fc_service.default.name
    function_name = alicloud_fcv2_function.fc_image_generation_function.function_name
  }
}
# Once you have an SSL certificate for your domain, you can use the cert_config property below to enable HTTPS for your custom domain.
#   cert_config {
#     cert_name   = "serverless-image-generation-certificate"
#     certificate = <<EOF
# -----BEGIN CERTIFICATE-----
# ....
# -----END CERTIFICATE-----
#     EOF
#     private_key = <<EOF
# -----BEGIN RSA PRIVATE KEY-----
# ....
# -----END RSA PRIVATE KEY-----
#     EOF
#   }
