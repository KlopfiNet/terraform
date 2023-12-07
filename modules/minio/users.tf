resource "minio_iam_user" "velero_user" {
  name          = "velero"
  force_destroy = true
  tags = {
    tag-key = "kubernetes"
  }
}

resource "minio_iam_user_policy_attachment" "velero_policy" {
  user_name   = minio_iam_user.velero_user.id
  policy_name = minio_iam_policy.velero_policy.id
}