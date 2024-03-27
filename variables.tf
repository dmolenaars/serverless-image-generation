variable "deployment_region" {
  type        = string
  description = "The region to which you wish to deploy your resources."
}
variable "namespace_id" {
  type        = string
  description = "The namespace in which your repositories are hosted."
}
variable "domain_name" {
  type        = string
  description = "The domain name which will be associated with the Function Compute endpoint."
}
variable "api_key" {
  type        = string
  sensitive   = true
  description = "The API key that is used to interact with DashScope."
}
variable "custom_domain_cert" {
  type        = string
  sensitive   = true
  default     = ""
  description = "The certificate or certificate chain in PEM format that is used for the Function Compute custom domain."
}
variable "custom_domain_key" {
  type        = string
  sensitive   = true
  default     = ""
  description = "The private key in PEM format that is used for the Function Compute custom domain."
}
