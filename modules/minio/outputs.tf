output "velero_user_sa_key" {
  value     = minio_iam_service_account.velero_service_account.access_key
  sensitive = false
}

output "velero_user_sa_secret" {
  value     = minio_iam_service_account.velero_service_account.secret_key
  sensitive = true
}