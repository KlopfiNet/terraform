resource "minio_iam_user" "velero_user" {
  name          = "velero"
  force_destroy = true
  tags = {
    tag-key = "kubernetes"
  }
}

resource "minio_iam_user_policy_attachment" "velero" {
  user_name   = minio_iam_user.velero_user.id
  policy_name = minio_iam_policy.velero_policy.id
}

resource "minio_iam_service_account" "velero_service_account" {
  target_user = minio_iam_user.velero_user.name

  # Not specifying this lets the SA inherit the user policy
  # However, the dumdum provider assumes that you explicitly provide a policy here
  #policy      = minio_iam_policy.velero_policy.policy

  lifecycle {
    ignore_changes = [policy]
  }
}