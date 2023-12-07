terraform {
  required_providers {
    minio = {
      source  = "aminueza/minio"
      version = "2.0.1"
    }
  }
}

provider "minio" {
  minio_server   = local.minio_endpoint
  minio_ssl      = true
  minio_insecure = true # CA distrust
  #minio_user     = var.minio_user
  #minio_password = var.minio_password
}