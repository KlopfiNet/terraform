output "velero_user_secret" {
  value = "${minio_iam_user.velero_user.secret}"
  sensitive = true
}