## VAULT
data "vault_auth_backends" "Active_Directory" {
  type = "oidc"
}

resource "vault_namespace" "child_namespace" {
  path = var.namespace_path
}

resource "vault_identity_entity" "namespace_admin" {
  name     = var.entity_name
  policies = ["${vault_policy.namespace_admin_policy.name}"]
  # metadata  = {
  #   foo = "bar"
  # }
  external_policies = true

}

resource "vault_identity_entity_policies" "policies" {
  policies = [
    "${vault_policy.namespace_admin_policy.name}"
  ]
  exclusive = true
  entity_id = vault_identity_entity.namespace_admin.id
}

resource "vault_identity_entity_alias" "entity_alias" {
  name           = vault_identity_entity.namespace_admin.name
  mount_accessor = data.vault_auth_backends.Active_Directory.accessors[0]
  canonical_id   = vault_identity_entity.namespace_admin.id
}

resource "vault_policy" "namespace_admin_policy" {
  name   = "${var.entity_name}-policy"
  policy = <<EOT
# Manage namespaces
path "${vault_namespace.child_namespace.path}/sys/namespaces/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
path "${vault_namespace.child_namespace.path}/+/sys/namespaces/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
# Manage policies
path "${vault_namespace.child_namespace.path}/sys/policies/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
path "${vault_namespace.child_namespace.path}/+/sys/policies/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
# List policies
path "${vault_namespace.child_namespace.path}/sys/policies/acl" {
  capabilities = ["list"]
}
path "${vault_namespace.child_namespace.path}/+/sys/policies/acl" {
  capabilities = ["list"]
}
# Enable and manage secrets engines
path "${vault_namespace.child_namespace.path}/sys/mounts/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
path "${vault_namespace.child_namespace.path}/+/sys/mounts/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
# List available secrets engines
path "${vault_namespace.child_namespace.path}/sys/mounts" {
  capabilities = ["read"]
}
path "${vault_namespace.child_namespace.path}/+/sys/mounts" {
  capabilities = ["read"]
}
EOT
}


### GCP

data "google_compute_subnetwork" "dest_subnet" {
  name   = var.dest_gcp_network_name
  region = var.dest_region
}

# gcp network 읽기
data "google_compute_network" "dest_network" {
  name = var.dest_gcp_network_name
}

# GCP VPC Network
data "google_compute_network" "vpc_network" {
  name = var.dest_gcp_network_name #"default"
}
# AWS Transit Gateway
data "aws_ec2_transit_gateway" "hub_TGW" {
  id = var.Hub_TGW_ID
}
####
# GCP Static IP for VPN
resource "google_compute_address" "vpn_static_ip" {
  name   = "gcp-vpn-ip"
  region = var.dest_region
}
###########

resource "google_compute_ha_vpn_gateway" "ha_gateway1" {
  region  = var.dest_region
  name    = "gcp-vpn-to-aws-1"
  network = data.google_compute_network.vpc_network.id
}

resource "google_compute_external_vpn_gateway" "external_gateway" {
  name            = "aws-external-gateway"
  description     = "An externally managed VPN gateway"
  redundancy_type = "TWO_IPS_REDUNDANCY"
  interface {
    id         = 0
    ip_address = aws_vpn_connection.vpn_connection.tunnel1_address
  }
    interface {
    id         = 1
    ip_address = aws_vpn_connection.vpn_connection.tunnel2_address
  }
}


# resource "google_compute_forwarding_rule" "fr_esp" {
#   name        = "ip-fr-esp"
#   ip_protocol = "ESP"
#   ip_address  = google_compute_address.vpn_static_ip.address
#   target      = google_compute_ha_vpn_gateway.ha_gateway1.id
# }
resource "google_compute_router" "router1" {
  name    = "ha-vpn-router1"
  region  = var.dest_region
  network = data.google_compute_network.dest_network.name
  bgp { #64514
    asn = var.GCP_route_asn
  }
}

# GCP VPN Tunnel
resource "google_compute_vpn_tunnel" "vpn_tunnel_1" {
  # depends_on = [ google_compute_forwarding_rule.vpn_forwarding_rule_1 ]
  name                            = "gcp-to-aws-tunnel-1"
  peer_external_gateway           = google_compute_external_vpn_gateway.external_gateway.id
  peer_external_gateway_interface = 0
  shared_secret                   = var.shared_secret_1
  vpn_gateway                     = google_compute_ha_vpn_gateway.ha_gateway1.id
  router                          = google_compute_router.router1.id
  vpn_gateway_interface           = 0
  region                          = var.dest_region
  ike_version                     = 2
}


# resource "google_compute_vpn_tunnel" "vpn_tunnel_2" {
#   # depends_on = [ google_compute_forwarding_rule.vpn_forwarding_rule_1 ]
#   name                  = "gcp-to-aws-tunnel-2"
#   peer_ip               = aws_vpn_connection.vpn_connection.tunnel2_address
#   shared_secret         = var.shared_secret_2
#   vpn_gateway           = google_compute_ha_vpn_gateway.ha_gateway1.id
#   router                = google_compute_router.router1.id
#   vpn_gateway_interface = 1
#   region                = var.dest_region
#   ike_version           = 2
# }

resource "google_compute_router_interface" "router1_interface1" {
  name       = "hcp-hvn-router-interface"
  router     = google_compute_router.router1.name
  region     = var.dest_region
  ip_range   = "${aws_vpn_connection.vpn_connection.tunnel1_cgw_inside_address}/30"
  vpn_tunnel = google_compute_vpn_tunnel.vpn_tunnel_1.name
}

resource "google_compute_router_peer" "router1_peer1" {
  name                      = "hcp-hvn-router1-peer1"
  interface                 = google_compute_router_interface.router1_interface1.name
  peer_asn                  = var.peer_asn #64515
  ip_address                = aws_vpn_connection.vpn_connection.tunnel1_cgw_inside_address
  peer_ip_address           = aws_vpn_connection.vpn_connection.tunnel1_vgw_inside_address
  router                    = google_compute_router.router1.name
  region                    = var.dest_region
}


##########3#

# GCP VPN Gateway
# resource "google_compute_vpn_gateway" "vpn_gateway" {
#   name    = "gcp-vpn-gateway-${var.dest_region}-to-aws"
#   network = data.google_compute_network.vpc_network.self_link
#   region  = var.dest_region
# }
####


# AWS Customer Gateway
resource "aws_customer_gateway" "customer_gateway" {
  bgp_asn    = var.GCP_route_asn
  ip_address = google_compute_ha_vpn_gateway.ha_gateway1.vpn_interfaces[0].ip_address
  # GCP's VPN public IP
  type = "ipsec.1"
}

# AWS VPN Connection
resource "aws_vpn_connection" "vpn_connection" {
  customer_gateway_id = aws_customer_gateway.customer_gateway.id
  transit_gateway_id  = data.aws_ec2_transit_gateway.hub_TGW.id
  type                = "ipsec.1"

  static_routes_only = false

  # 다른 것들과 겹치면 안되기에 tunnel ip cidr 관리가 해당 프로젝트의 주요 과제가 될 것으로 보임 
  tunnel1_preshared_key = var.shared_secret_1
  tunnel2_preshared_key = var.shared_secret_2
}

# AWS Transit Gateway VPC Attachment
data "aws_ec2_transit_gateway_route_table" "Tokyo_TGW_RT" {
  id = var.Hub_TGW_RT_ID
}
data "aws_ec2_transit_gateway_vpn_attachment" "hub_TGW_attach" {
  transit_gateway_id = data.aws_ec2_transit_gateway.hub_TGW.id
  vpn_connection_id  = aws_vpn_connection.vpn_connection.id
}

resource "aws_ec2_transit_gateway_route_table_association" "tokyo_to_prj_route" {
  transit_gateway_attachment_id  = data.aws_ec2_transit_gateway_vpn_attachment.hub_TGW_attach.id
  transit_gateway_route_table_id = data.aws_ec2_transit_gateway_route_table.Tokyo_TGW_RT.id
}
resource "aws_ec2_transit_gateway_route_table_propagation" "tokyo_to_prj_route" {
  transit_gateway_attachment_id  = data.aws_ec2_transit_gateway_vpn_attachment.hub_TGW_attach.id
  transit_gateway_route_table_id = data.aws_ec2_transit_gateway_route_table.Tokyo_TGW_RT.id
}

#### HVN Route configure

data "hcp_hvn" "vault_hvn" {
  hvn_id = var.hvn_id
}

data "hcp_aws_transit_gateway_attachment" "hvn_connection" {
  hvn_id                        = var.hvn_id
  transit_gateway_attachment_id = var.HVN_Attach_ID
}

resource "hcp_hvn_route" "example-peering-route" {
  hvn_link         = data.hcp_hvn.vault_hvn.self_link
  hvn_route_id     = "${var.gcp_project_id}-route"
  destination_cidr = data.google_compute_subnetwork.dest_subnet.ip_cidr_range
  target_link      = data.hcp_aws_transit_gateway_attachment.hvn_connection.self_link
}
