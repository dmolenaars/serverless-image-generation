variable deployment_region {
    type = string
    description = "The region to which you wish to deploy your resources."
}
variable namespace_id {
    type = string
    description = "The namespace in which your repositories are hosted."
}
variable domain_name {
    type = string
    description = "The domain name which will be associated with the Function Compute endpoint."
}