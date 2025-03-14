data "terraform_remote_state" "rs" {
  backend = "s3"
  config = {
    bucket                      = "terraform"
    key                         = "state/kubernetes_service-0.tfstate"
    region                      = "auto"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    use_path_style              = true
  }
}

resource "local_file" "matchbox-ca-cert" {
  content  = data.terraform_remote_state.rs.outputs.matchbox.ca.cert_pem
  filename = "matchbox-ca.crt"
}
