variable "GCP_PROJECT" {
  description = "GCP Project ID."
}
variable "GCP_REGION" {
  description = "GCP Default Region."
}

variable "AWS_REGION" {
  description = "AWS Default Region."
}
variable "AWS_ACCESS_KEY" {
  description = "AWS Access Key Credential."
}
variable "AWS_SECRET_KEY" {
  description = "AWS Secret Key Credential."
}
variable "AWS_VPC_ID" {
  description = "AWS Exisitng VPC ID."
}

variable "TPK_1_1" {
  description = "VPN Connection 1 :: Tunnel Pre-Shared Key 1."
}
variable "TPK_1_2" {
  description = "VPN Connection 1 :: Tunnel Pre-Shared Key 2."
}
variable "TPK_2_1" {
  description = "VPN Connection 2 :: Tunnel Pre-Shared Key 1."
}
variable "TPK_2_2" {
  description = "VPN Connection 2 :: Tunnel Pre-Shared Key 2"
}

variable "AWS_ROUTE_TABLE_ID" {
  description = "AWS Existing VPC Main Route Table ID (For Propagation)."
}