terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "4.4.0"
    }
  }
}

# provider "hcp" {

# }
provider "vault" {
  address   = var.vault_hostname
  token     = var.admin_token
  namespace = "admin"
}


provider "hcp" {
  client_id     = var.hcp_client_id
  client_secret = var.hcp_client_secret
  project_id    = var.hcp_project_id
}
provider "aws" {
  region     = var.Hub_region
  access_key = var.Hub_Access_key
  secret_key = var.Hub_Secret_key
}

provider "google" {
  credentials = var.gcp_key_json
  project     = var.gcp_project_id
  region      = var.dest_region
}
