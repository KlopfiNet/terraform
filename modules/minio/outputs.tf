#output "velero_user_sa_key" {
#  value     = minio_iam_service_account.velero_service_account.access_key
#  sensitive = false
#}
#
#output "velero_user_sa_secret" {
#  value     = minio_iam_service_account.velero_service_account.secret_key
#  sensitive = true
#}

output "user_sa_credentials" {
  value = {
    for name, vars in minio_iam_service_account.service_account :
    name => {
      access_key = vars.access_key
      secret_key = vars.secret_key
    }
  }
  sensitive = true
}