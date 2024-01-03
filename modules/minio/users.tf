resource "minio_iam_user" "user" {
  for_each = toset(var.buckets)

  name          = each.key
  force_destroy = true
  tags = {
    tag-key = each.key
  }
}

resource "minio_iam_user_policy_attachment" "pol_attach" {
  for_each = toset(var.buckets)

  user_name   = minio_iam_user.user[each.key].id
  policy_name = minio_iam_policy.policy[each.key].id
}

resource "minio_iam_service_account" "service_account" {
  for_each = toset(var.buckets)

  target_user = minio_iam_user.user[each.key].name

  # Not specifying this lets the SA inherit the user policy
  # However, the dumdum provider assumes that you explicitly provide a policy here
  #policy      = minio_iam_policy.velero_policy.policy

  lifecycle {
    ignore_changes = [policy]
  }
}