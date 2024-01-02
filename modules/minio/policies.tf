resource "minio_iam_policy" "velero_policy" {
  name   = "velero-bucket"
  policy = <<-EOF
    {
        "Version":"2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "s3:ListBucket",
                    "s3:ListAllMyBuckets",
                    "s3:GetBucketLocation"
                ],
                "Resource": "arn:aws:s3:::${minio_s3_bucket.velero_bucket.bucket}"
            },
            {
                "Effect": "Allow",
                "Action": [
                    "s3:PutObject",
                    "s3:GetObject",
                    "s3:GetObjectVersion",
                    "s3:DeleteObject"
                ],
                "Resource": "arn:aws:s3:::${minio_s3_bucket.velero_bucket.bucket}/*"
            }
        ]
    }
EOF
}