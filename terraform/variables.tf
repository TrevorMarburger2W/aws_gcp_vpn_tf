# ===================================================================================
# General GCP Parameters
# ===================================================================================
variable "GCP_PROJECT" {
  description = "GCP Project ID."
}
variable "GCP_REGION" {
  description = "GCP Default Region."
}
# ===================================================================================


# ===================================================================================
# General AWS Parameters
# ===================================================================================
variable "AWS_REGION" {
  description = "AWS Default Region."
}
variable "AWS_ACCESS_KEY" {
  description = "AWS Access Key Credential."
}
variable "AWS_SECRET_KEY" {
  description = "AWS Secret Key Credential."
}


# ===================================================================================
# Required Network Details
# ===================================================================================
variable "AWS_VPC_ID" {
  description = "AWS Exisitng VPC ID."
}

variable "AWS_ROUTE_TABLE_ID" {
  description = "AWS Existing VPC Main Route Table ID (For Propagation)."
}

variable "TUNNEL1_INSIDE_CIDR" {
  description = "AWS Inside Tunnel 1 CIDR Range."
  default     = "169.254.40.24/30"
}

variable "TUNNEL2_INSIDE_CIDR" {
  description = "AWS Inside Tunnel 2 CIDR Range."
  default     = "169.254.41.24/30"
}

variable "TUNNEL3_INSIDE_CIDR" {
  description = "AWS Inside Tunnel 3 CIDR Range."
  default     = "169.254.42.24/30"
}

variable "TUNNEL4_INSIDE_CIDR" {
  description = "AWS Inside Tunnel 4 CIDR Range."
  default     = "169.254.43.24/30"
}


# Four (4) Tunnel Preshared Keys
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

# GCP & Peer Tunnel Internal IP Addresses - see TUNNEL1_INSIDE_CIDR - TUNNEL4_INSIDE_CIDR
variable "GCP_ROUTER_IP_ADDR_1" {
  description = "GCP Cloud Router Connection IP Address (1/4)."
  default     = "169.254.40.26"
}
variable "GCP_ROUTER_PEER_IP_ADDR_1" {
  description = "GCP Cloud Router Connection PEER IP Address (1/4)."
  default     = "169.254.40.25"
}

variable "GCP_ROUTER_IP_ADDR_2" {
  description = "GCP Cloud Router Connection IP Address (2/4)."
  default     = "169.254.41.26"
}
variable "GCP_ROUTER_PEER_IP_ADDR_2" {
  description = "GCP Cloud Router Connection PEER IP Address (2/4)."
  default     = "169.254.41.25"
}

variable "GCP_ROUTER_IP_ADDR_3" {
  description = "GCP Cloud Router Connection IP Address (3/4)."
  default     = "169.254.42.26"
}
variable "GCP_ROUTER_PEER_IP_ADDR_3" {
  description = "GCP Cloud Router Connection PEER IP Address (3/4)."
  default     = "169.254.42.25"
}

variable "GCP_ROUTER_IP_ADDR_4" {
  description = "GCP Cloud Router Connection IP Address (3/4)."
  default     = "169.254.43.26"
}
variable "GCP_ROUTER_PEER_IP_ADDR_4" {
  description = "GCP Cloud Router Connection PEER IP Address (4/4)."
  default     = "169.254.43.25"
}
# ===================================================================================

