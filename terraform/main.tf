# https://cloud.google.com/architecture/build-ha-vpn-connections-google-cloud-aws
# https://oleg-pershin.medium.com/site-to-site-vpn-between-gcp-and-aws-with-dynamic-bgp-routing-7d7e0366036d
# https://medium.com/google-cloud/dynamic-routing-with-cloud-router-9ff5c362d833

resource "google_compute_network" "gcp_vpc" {
  project                 = var.GCP_PROJECT
  name                    = "custom-vpc"
  auto_create_subnetworks = false
  mtu                     = 1460
  routing_mode            = "GLOBAL"
}

resource "google_compute_subnetwork" "gcp_priv_subnet" {
  project       = var.GCP_PROJECT
  name          = "test-subnetwork"
  ip_cidr_range = "10.2.0.0/24"
  region        = "us-east1"
  network       = google_compute_network.gcp_vpc.id
}

resource "google_compute_ha_vpn_gateway" "gcp_ha_gateway_1" {
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

resource "aws_customer_gateway" "aws_customer_gw_1" {
  bgp_asn    = 65001
  ip_address = google_compute_ha_vpn_gateway.gcp_ha_gateway_1.vpn_interfaces.0.ip_address
  type       = "ipsec.1"

  tags = {
    Name = "cgw_1"
  }
}

resource "aws_customer_gateway" "aws_customer_gw_2" {
  bgp_asn    = 65001
  ip_address = google_compute_ha_vpn_gateway.gcp_ha_gateway_1.vpn_interfaces.1.ip_address
  type       = "ipsec.1"

  tags = {
    Name = "cgw_2"
  }
}

resource "aws_vpn_gateway" "aws_vpn_gw" {
  vpc_id          = var.AWS_VPC_ID
  amazon_side_asn = 65002

  tags = {
    Name = "vpngw_1"
  }

}

resource "aws_vpn_gateway_attachment" "vpn_attachment" {
  vpc_id         = var.AWS_VPC_ID
  vpn_gateway_id = aws_vpn_gateway.aws_vpn_gw.id
}

resource "aws_vpn_connection" "aws_vpn_conn_1" {
  vpn_gateway_id      = aws_vpn_gateway.aws_vpn_gw.id
  customer_gateway_id = aws_customer_gateway.aws_customer_gw_1.id
  type                = "ipsec.1"
  static_routes_only  = false

  tunnel1_inside_cidr   = "169.254.40.24/30"
  tunnel1_preshared_key = var.TPK_1_1
  tunnel1_ike_versions = [
    "ikev1"
  ]

  tunnel2_inside_cidr   = "169.254.41.24/30"
  tunnel2_preshared_key = var.TPK_1_2
  tunnel2_ike_versions = [
    "ikev1"
  ]

  tags = {
    Name = "vpn_conn_1"
  }
}

resource "aws_vpn_connection" "aws_vpn_conn_2" {
  vpn_gateway_id      = aws_vpn_gateway.aws_vpn_gw.id
  customer_gateway_id = aws_customer_gateway.aws_customer_gw_2.id
  type                = "ipsec.1"
  static_routes_only  = false

  tunnel1_inside_cidr   = "169.254.42.24/30"
  tunnel1_preshared_key = var.TPK_2_1
  tunnel1_ike_versions = [
    "ikev1"
  ]

  tunnel2_inside_cidr   = "169.254.43.24/30"
  tunnel2_preshared_key = var.TPK_2_2
  tunnel2_ike_versions = [
    "ikev1"
  ]

  tags = {
    Name = "vpn_conn_2"
  }
}


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

resource "google_compute_vpn_tunnel" "gcp_tunnel_1" {
  name                            = "tunnel1"
  project                         = var.GCP_PROJECT
  region                          = var.GCP_REGION
  vpn_gateway                     = google_compute_ha_vpn_gateway.gcp_ha_gateway_1.name
  vpn_gateway_interface           = 0
  peer_external_gateway           = google_compute_external_vpn_gateway.gcp_external_vpn_gateway.name
  peer_external_gateway_interface = google_compute_external_vpn_gateway.gcp_external_vpn_gateway.interface[0].id
  ike_version                     = 1
  shared_secret                   = var.TPK_1_1
  router                          = google_compute_router.gcp_router.id
}

resource "google_compute_vpn_tunnel" "gcp_tunnel_2" {
  name                            = "tunnel2"
  project                         = var.GCP_PROJECT
  region                          = var.GCP_REGION
  vpn_gateway                     = google_compute_ha_vpn_gateway.gcp_ha_gateway_1.name
  vpn_gateway_interface           = 0
  peer_external_gateway           = google_compute_external_vpn_gateway.gcp_external_vpn_gateway.name
  peer_external_gateway_interface = google_compute_external_vpn_gateway.gcp_external_vpn_gateway.interface[1].id
  ike_version                     = 1
  shared_secret                   = var.TPK_1_2
  router                          = google_compute_router.gcp_router.id
}

resource "google_compute_vpn_tunnel" "gcp_tunnel_3" {
  name                            = "tunnel3"
  project                         = var.GCP_PROJECT
  region                          = var.GCP_REGION
  vpn_gateway                     = google_compute_ha_vpn_gateway.gcp_ha_gateway_1.name
  vpn_gateway_interface           = 1
  peer_external_gateway           = google_compute_external_vpn_gateway.gcp_external_vpn_gateway.name
  peer_external_gateway_interface = google_compute_external_vpn_gateway.gcp_external_vpn_gateway.interface[2].id
  ike_version                     = 1
  shared_secret                   = var.TPK_2_1
  router                          = google_compute_router.gcp_router.id
}

resource "google_compute_vpn_tunnel" "gcp_tunnel_4" {
  name                            = "tunnel4"
  project                         = var.GCP_PROJECT
  region                          = var.GCP_REGION
  vpn_gateway                     = google_compute_ha_vpn_gateway.gcp_ha_gateway_1.name
  vpn_gateway_interface           = 1
  peer_external_gateway           = google_compute_external_vpn_gateway.gcp_external_vpn_gateway.name
  peer_external_gateway_interface = google_compute_external_vpn_gateway.gcp_external_vpn_gateway.interface[3].id
  ike_version                     = 1
  shared_secret                   = var.TPK_2_2
  router                          = google_compute_router.gcp_router.id
}


resource "aws_vpn_gateway_route_propagation" "aws_rt_propagation" {
  vpn_gateway_id = aws_vpn_gateway.aws_vpn_gw.id
  route_table_id = var.AWS_ROUTE_TABLE_ID
}


resource "google_compute_router_interface" "gcp_router_interface_1" {
  name       = "interface-1"
  project    = var.GCP_PROJECT
  region     = var.GCP_REGION
  router     = google_compute_router.gcp_router.name
  vpn_tunnel = google_compute_vpn_tunnel.gcp_tunnel_1.id
}

resource "google_compute_router_interface" "gcp_router_interface_2" {
  name       = "interface-2"
  project    = var.GCP_PROJECT
  region     = var.GCP_REGION
  router     = google_compute_router.gcp_router.name
  vpn_tunnel = google_compute_vpn_tunnel.gcp_tunnel_2.id
}

resource "google_compute_router_interface" "gcp_router_interface_3" {
  name       = "interface-3"
  project    = var.GCP_PROJECT
  region     = var.GCP_REGION
  router     = google_compute_router.gcp_router.name
  vpn_tunnel = google_compute_vpn_tunnel.gcp_tunnel_3.id
}

resource "google_compute_router_interface" "gcp_router_interface_4" {
  name       = "interface-4"
  project    = var.GCP_PROJECT
  region     = var.GCP_REGION
  router     = google_compute_router.gcp_router.name
  vpn_tunnel = google_compute_vpn_tunnel.gcp_tunnel_4.id
}

resource "google_compute_router_peer" "gcp_router_peer_1" {
  name            = "router-peer-1"
  project         = var.GCP_PROJECT
  region          = var.GCP_REGION
  router          = google_compute_router.gcp_router.name
  ip_address      = "169.254.40.26"
  peer_ip_address = "169.254.40.25"
  peer_asn        = 65002
  interface       = google_compute_router_interface.gcp_router_interface_1.name
}

resource "google_compute_router_peer" "gcp_router_peer_2" {
  name            = "router-peer-2"
  project         = var.GCP_PROJECT
  region          = var.GCP_REGION
  router          = google_compute_router.gcp_router.name
  ip_address      = "169.254.41.26"
  peer_ip_address = "169.254.41.25"
  peer_asn        = 65002
  interface       = google_compute_router_interface.gcp_router_interface_2.name
}

resource "google_compute_router_peer" "gcp_router_peer_3" {
  name            = "router-peer-3"
  project         = var.GCP_PROJECT
  region          = var.GCP_REGION
  router          = google_compute_router.gcp_router.name
  ip_address      = "169.254.42.26"
  peer_ip_address = "169.254.42.25"
  peer_asn        = 65002
  interface       = google_compute_router_interface.gcp_router_interface_3.name
}

resource "google_compute_router_peer" "gcp_router_peer_4" {
  name            = "router-peer-4"
  project         = var.GCP_PROJECT
  region          = var.GCP_REGION
  router          = google_compute_router.gcp_router.name
  ip_address      = "169.254.43.26"
  peer_ip_address = "169.254.43.25"
  peer_asn        = 65002
  interface       = google_compute_router_interface.gcp_router_interface_4.name
}
