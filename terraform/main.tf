# Creates a brand new Google Virtual Private Cloud
resource "google_compute_network" "gcp_vpc" {
  project                 = var.GCP_PROJECT
  name                    = "custom-vpc"
  auto_create_subnetworks = false
  mtu                     = 1460
  routing_mode            = "GLOBAL"
}

# Creates a brand new Google private subnet
resource "google_compute_subnetwork" "gcp_priv_subnet" {
  project       = var.GCP_PROJECT
  name          = "test-subnetwork"
  ip_cidr_range = "10.2.0.0/24"
  region        = "us-east1"
  network       = google_compute_network.gcp_vpc.id
}

# Creates the Google High-Availability VPN Gateway
resource "google_compute_ha_vpn_gateway" "gcp_ha_gateway" {
  project = var.GCP_PROJECT
  region  = "us-east1"
  name    = "ha-vpn-1"
  network = google_compute_network.gcp_vpc.id

  vpn_interfaces {
    id = 0
  }
  vpn_interfaces {
    id = 1
  }
}

# Creates a Google Cloud Router
resource "google_compute_router" "gcp_router" {
  project = var.GCP_PROJECT
  name    = "my-router"
  network = google_compute_network.gcp_vpc.name
  region  = "us-east1"

  bgp {
    asn            = 65001
    advertise_mode = "CUSTOM"
    advertised_groups = [
      "ALL_SUBNETS"
    ]
  }

}

# Creates first of two (1/2) Amazon Customer Gateways for redundancy
resource "aws_customer_gateway" "aws_customer_gw_1" {
  bgp_asn    = 65001
  ip_address = google_compute_ha_vpn_gateway.gcp_ha_gateway.vpn_interfaces.0.ip_address
  type       = "ipsec.1"

  tags = {
    Name = "cgw_1"
  }
}

# Creates second of two (2/2) Amazon Customer Gateways for redundancy
resource "aws_customer_gateway" "aws_customer_gw_2" {
  bgp_asn    = 65001
  ip_address = google_compute_ha_vpn_gateway.gcp_ha_gateway.vpn_interfaces.1.ip_address
  type       = "ipsec.1"

  tags = {
    Name = "cgw_2"
  }
}

# Creates Amazon VPN Gateway
resource "aws_vpn_gateway" "aws_vpn_gw" {
  vpc_id          = var.AWS_VPC_ID
  amazon_side_asn = 65002

  tags = {
    Name = "vpngw_1"
  }

}

# Attaches Amazon VPN Gateway to existing Amazon VPC
resource "aws_vpn_gateway_attachment" "vpn_attachment" {
  vpc_id         = var.AWS_VPC_ID
  vpn_gateway_id = aws_vpn_gateway.aws_vpn_gw.id
}

# Creates first of two (1/2) EC2 VPN Connections for redundancy,
# attaches to Amazon Customer Gateway which allows creation
# of tunnels (two created here) to connect to GCP Network
resource "aws_vpn_connection" "aws_vpn_conn_1" {
  vpn_gateway_id      = aws_vpn_gateway.aws_vpn_gw.id
  customer_gateway_id = aws_customer_gateway.aws_customer_gw_1.id
  type                = "ipsec.1"
  static_routes_only  = false

  tunnel1_inside_cidr   = var.TUNNEL1_INSIDE_CIDR
  tunnel1_preshared_key = var.TPK_1_1
  tunnel1_ike_versions = [
    "ikev1"
  ]

  tunnel2_inside_cidr   = var.TUNNEL2_INSIDE_CIDR
  tunnel2_preshared_key = var.TPK_1_2
  tunnel2_ike_versions = [
    "ikev1"
  ]

  tags = {
    Name = "vpn_conn_1"
  }
}

# Creates second of two (2/2) EC2 VPN Connections for redundancy,
# attaches to Amazon Customer Gateway which allows creation
# of tunnels (two created here) to connect to GCP Network
resource "aws_vpn_connection" "aws_vpn_conn_2" {
  vpn_gateway_id      = aws_vpn_gateway.aws_vpn_gw.id
  customer_gateway_id = aws_customer_gateway.aws_customer_gw_2.id
  type                = "ipsec.1"
  static_routes_only  = false

  tunnel1_inside_cidr   = var.TUNNEL3_INSIDE_CIDR
  tunnel1_preshared_key = var.TPK_2_1
  tunnel1_ike_versions = [
    "ikev1"
  ]

  tunnel2_inside_cidr   = var.TUNNEL4_INSIDE_CIDR
  tunnel2_preshared_key = var.TPK_2_2
  tunnel2_ike_versions = [
    "ikev1"
  ]

  tags = {
    Name = "vpn_conn_2"
  }
}

# Defines a VPN Gateway outside of Google (on the AWS Side),
# defines interface to all four AWS Tunnels created by AWS VPN Connection resource(s)
resource "google_compute_external_vpn_gateway" "gcp_external_vpn_gateway" {
  name            = "external-vpn-gateway"
  project         = var.GCP_PROJECT
  redundancy_type = "FOUR_IPS_REDUNDANCY"
  description     = "An externally managed VPN gateway"

  interface {
    id         = 0
    ip_address = aws_vpn_connection.aws_vpn_conn_1.tunnel1_address
  }

  interface {
    id         = 1
    ip_address = aws_vpn_connection.aws_vpn_conn_1.tunnel2_address
  }

  interface {
    id         = 2
    ip_address = aws_vpn_connection.aws_vpn_conn_2.tunnel1_address
  }

  interface {
    id         = 3
    ip_address = aws_vpn_connection.aws_vpn_conn_2.tunnel2_address
  }

}

# Creates first of four (1/4) Google VPN tunnels
resource "google_compute_vpn_tunnel" "gcp_tunnel_1" {
  name                            = "tunnel1"
  project                         = var.GCP_PROJECT
  region                          = var.GCP_REGION
  vpn_gateway                     = google_compute_ha_vpn_gateway.gcp_ha_gateway.name
  vpn_gateway_interface           = 0
  peer_external_gateway           = google_compute_external_vpn_gateway.gcp_external_vpn_gateway.name
  peer_external_gateway_interface = google_compute_external_vpn_gateway.gcp_external_vpn_gateway.interface[0].id
  ike_version                     = 1
  shared_secret                   = var.TPK_1_1
  router                          = google_compute_router.gcp_router.id
}

# Creates second of four (2/4) Google VPN tunnels
resource "google_compute_vpn_tunnel" "gcp_tunnel_2" {
  name                            = "tunnel2"
  project                         = var.GCP_PROJECT
  region                          = var.GCP_REGION
  vpn_gateway                     = google_compute_ha_vpn_gateway.gcp_ha_gateway.name
  vpn_gateway_interface           = 0
  peer_external_gateway           = google_compute_external_vpn_gateway.gcp_external_vpn_gateway.name
  peer_external_gateway_interface = google_compute_external_vpn_gateway.gcp_external_vpn_gateway.interface[1].id
  ike_version                     = 1
  shared_secret                   = var.TPK_1_2
  router                          = google_compute_router.gcp_router.id
}

# Creates third of four (3/4) Google VPN tunnels
resource "google_compute_vpn_tunnel" "gcp_tunnel_3" {
  name                            = "tunnel3"
  project                         = var.GCP_PROJECT
  region                          = var.GCP_REGION
  vpn_gateway                     = google_compute_ha_vpn_gateway.gcp_ha_gateway.name
  vpn_gateway_interface           = 1
  peer_external_gateway           = google_compute_external_vpn_gateway.gcp_external_vpn_gateway.name
  peer_external_gateway_interface = google_compute_external_vpn_gateway.gcp_external_vpn_gateway.interface[2].id
  ike_version                     = 1
  shared_secret                   = var.TPK_2_1
  router                          = google_compute_router.gcp_router.id
}

# Creates fourth of four (4/4) Google VPN tunnels
resource "google_compute_vpn_tunnel" "gcp_tunnel_4" {
  name                            = "tunnel4"
  project                         = var.GCP_PROJECT
  region                          = var.GCP_REGION
  vpn_gateway                     = google_compute_ha_vpn_gateway.gcp_ha_gateway.name
  vpn_gateway_interface           = 1
  peer_external_gateway           = google_compute_external_vpn_gateway.gcp_external_vpn_gateway.name
  peer_external_gateway_interface = google_compute_external_vpn_gateway.gcp_external_vpn_gateway.interface[3].id
  ike_version                     = 1
  shared_secret                   = var.TPK_2_2
  router                          = google_compute_router.gcp_router.id
}

# Propagates Amazon VPN Gateway route(s)
resource "aws_vpn_gateway_route_propagation" "aws_rt_propagation" {
  vpn_gateway_id = aws_vpn_gateway.aws_vpn_gw.id
  route_table_id = var.AWS_ROUTE_TABLE_ID
}

# Creates first of four (1/4) Google Cloud Router interfaces
resource "google_compute_router_interface" "gcp_router_interface_1" {
  name       = "interface-1"
  project    = var.GCP_PROJECT
  region     = var.GCP_REGION
  router     = google_compute_router.gcp_router.name
  vpn_tunnel = google_compute_vpn_tunnel.gcp_tunnel_1.id
}

# Creates second of four (2/4) Google Cloud Router interfaces
resource "google_compute_router_interface" "gcp_router_interface_2" {
  name       = "interface-2"
  project    = var.GCP_PROJECT
  region     = var.GCP_REGION
  router     = google_compute_router.gcp_router.name
  vpn_tunnel = google_compute_vpn_tunnel.gcp_tunnel_2.id
}

# Creates third of four (3/4) Google Cloud Router interfaces
resource "google_compute_router_interface" "gcp_router_interface_3" {
  name       = "interface-3"
  project    = var.GCP_PROJECT
  region     = var.GCP_REGION
  router     = google_compute_router.gcp_router.name
  vpn_tunnel = google_compute_vpn_tunnel.gcp_tunnel_3.id
}

# Creates fourth of four (4/4) Google Cloud Router interfaces
resource "google_compute_router_interface" "gcp_router_interface_4" {
  name       = "interface-4"
  project    = var.GCP_PROJECT
  region     = var.GCP_REGION
  router     = google_compute_router.gcp_router.name
  vpn_tunnel = google_compute_vpn_tunnel.gcp_tunnel_4.id
}

# Creates first of four (1/4) Google Cloud Router peer connection to AWS
resource "google_compute_router_peer" "gcp_router_peer_1" {
  name            = "router-peer-1"
  project         = var.GCP_PROJECT
  region          = var.GCP_REGION
  router          = google_compute_router.gcp_router.name
  ip_address      = var.GCP_ROUTER_IP_ADDR_1
  peer_ip_address = var.GCP_ROUTER_PEER_IP_ADDR_1
  peer_asn        = 65002
  interface       = google_compute_router_interface.gcp_router_interface_1.name
}

# Creates second of four (2/4) Google Cloud Router peer connection to AWS
resource "google_compute_router_peer" "gcp_router_peer_2" {
  name            = "router-peer-2"
  project         = var.GCP_PROJECT
  region          = var.GCP_REGION
  router          = google_compute_router.gcp_router.name
  ip_address      = var.GCP_ROUTER_IP_ADDR_2
  peer_ip_address = var.GCP_ROUTER_PEER_IP_ADDR_2
  peer_asn        = 65002
  interface       = google_compute_router_interface.gcp_router_interface_2.name
}

# Creates third of four (3/4) Google Cloud Router peer connection to AWS
resource "google_compute_router_peer" "gcp_router_peer_3" {
  name            = "router-peer-3"
  project         = var.GCP_PROJECT
  region          = var.GCP_REGION
  router          = google_compute_router.gcp_router.name
  ip_address      = var.GCP_ROUTER_IP_ADDR_3
  peer_ip_address = var.GCP_ROUTER_PEER_IP_ADDR_3
  peer_asn        = 65002
  interface       = google_compute_router_interface.gcp_router_interface_3.name
}

# Creates fourth of four (4/4) Google Cloud Router peer connection to AWS
resource "google_compute_router_peer" "gcp_router_peer_4" {
  name            = "router-peer-4"
  project         = var.GCP_PROJECT
  region          = var.GCP_REGION
  router          = google_compute_router.gcp_router.name
  ip_address      = var.GCP_ROUTER_IP_ADDR_4
  peer_ip_address = var.GCP_ROUTER_PEER_IP_ADDR_4
  peer_asn        = 65002
  interface       = google_compute_router_interface.gcp_router_interface_4.name
}
