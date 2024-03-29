resource "minio_iam_policy" "policy" {
  for_each = toset(var.buckets)

  name   = "${each.key}-bucket"
  policy = <<-EOF
    {
        "Version":"2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "s3:ListBucket",
                    "s3:ListAllMyBuckets",
                    "s3:GetBucketLocation",
                    "s3:GetBucketObjectLockConfiguration"
                ],
                "Resource": "arn:aws:s3:::${minio_s3_bucket.bucket[each.key].bucket}"
            },
            {
                "Effect": "Allow",
                "Action": [
                    "s3:GetObject",
                    "s3:DeleteObject",
                    "s3:PutObject",
                    "s3:AbortMultipartUpload",
                    "s3:ListMultipartUploadParts"
                ],
                "Resource": "arn:aws:s3:::${minio_s3_bucket.bucket[each.key].bucket}/*"
            }
        ]
    }
EOF
}