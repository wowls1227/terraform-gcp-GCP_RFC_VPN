### VAULT
## vault hostname은 TFE에 private 네트워크 망이 연결된걸로 가정하고 지정 사용

# variable set
variable "vault_hostname" {
  default = ""
  description = "Vault Cluster의 hostname, Private url 사용"
}

# variable set
variable "admin_token" {
  default = ""
  description = "Vault의 관리자 TOKEN"
}

#required
variable "namespace_path" {
  # default = "prj1-other-region-namespace"
  description = "새로 생성할 vault namespace path"
}
# required
variable "entity_name" {
  # default = "admin-#123"
  description = "AD와 연동된 사용자 이메일 입력, vault에 client 사전생성용도"
}


variable "gcp_key_json" {
  sensitive = true
  description = "gcp key json 파일 내용을 입력"
}

### AWS 

#####HUB
## Vault ClusteR 와 동일한 region에 연결된 TGW 자원 사용


# variable set
variable "Hub_region" {
  default   = "ap-northeast-1"
  sensitive = true
  description = "현재 HCP HVN과 연결된 TGW의 region"
}

# variable set
variable "Hub_Access_key" {
  default   = ""
  sensitive = true
  description = "현재 HCP HVN과 연결된 TGW를 사용할 권한의 access key"
}

# variable set
variable "Hub_Secret_key" {
  default   = ""
  sensitive = true
  description = "현재 HCP HVN과 연결된 TGW를 사용할 권한의 secret access key"
}

# variable set
variable "Hub_TGW_ID" {
  default = "tgw-0a02ad1afff4009bb"
  description = "현재 HCP HVN과 연결된 TGW ID"
}

# variable set
variable "Hub_TGW_RT_ID" {
  default = "tgw-rtb-085ca58a812f8bb98"
  description = "현재 HCP HVN과 연결된 TGW의 route table ID"
}

# variable set
variable "Hub_TGW_attach_id" {
  default = "tgw-attach-0425ec5ca9d8997e9"
  description = "현재 HCP HVN과 연결된 TGW attachment ID"
}

# required
variable "GCP_route_asn" {
  default = "65100"
  description = "현재 HCP HVN과 연결할 GCP route에 대한 asn"
}

# required
variable "peer_asn" {
  default = "64512"
  description = "현재 HCP HVN과 연결할 GCP BGP Peer에 대한 asn"
}

# required
variable "shared_secret_1" {
  default = "thisisterraformconnected"
  description = "AWS TGW와 GCP VPN 연결을 위한 암호1"
}

# required
variable "shared_secret_2" {
  default = "thisisterraformconnected"
  description = "AWS TGW와 GCP VPN 연결을 위한 암호2"
}

###### DEST 
# Vault Clutser를 사용할 과제 계정의 네트워크 자원 사용, Source의 TGW 와 연결됨

# required
variable "gcp_project_id" {
  # default = "lucid-inquiry-436906-g0"
  description = "연결할 gcp의 project ID"
}

# required
variable "dest_region" {
  # default = "asia-northeast3"
  description = "연결할 gcp subnet의 리전"
}

# required
variable "dest_gcp_network_name" {
  # default = "default"
  description = "연결할 gcp vpc의 이름"
}


# # required
# variable "tunnel1_inside_cidr" {
#   default = "169.254.10.0/30"
# }

# # required
# variable "tunnel2_inside_cidr" {
#   default = "169.254.11.0/30"
# }

#### HCP

# variable set
variable "hcp_project_id" {
  default = ""
}

# variable set
variable "hcp_client_id" {
  default   = ""
  sensitive = true
}

# variable set
variable "hcp_client_secret" {
  default   = ""
  sensitive = true
}

# variable set
variable "hvn_id" {
  default = ""
}

# variable set
variable "HVN_Attach_ID" {
  default = ""
}

# variable set
variable "hcp_hvn_cidr" {
  default = ""
}