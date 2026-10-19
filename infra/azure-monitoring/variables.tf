variable "resource_group_name" {
  description = "Resource group containing the Azure Front Door profile."
  type        = string
  default     = "northstar-portfolio-rg"
}

variable "alert_email_address" {
  description = "Email address that receives Azure Monitor notifications."
  type        = string
  sensitive   = true
}

variable "front_door_endpoint_resource_id" {
  description = "Resource ID of the Azure Front Door endpoint to monitor."
  type        = string
}
