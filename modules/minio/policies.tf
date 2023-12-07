resource "minio_iam_policy" "velero_policy" {
  name   = "velero-bucket"
  policy = <<-EOF
    {
        "Version":"2012-10-17",
        "Statement": [
            {
            "Sid":"ListAllBucket",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:DeleteObject"
            ],
            "Principal":"*",
            "Resource": "arn:aws:s3:::${minio_s3_bucket.velero_bucket.bucket}/*"
            }
        ]
    }
EOF
}