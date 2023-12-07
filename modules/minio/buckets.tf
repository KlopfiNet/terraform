resource "minio_s3_bucket" "velero_bucket" {
  bucket = local.velero_bucket_name
  acl    = "public"
}

resource "minio_s3_bucket_versioning" "version" {
  bucket = minio_s3_bucket.velero_bucket.bucket

  versioning_configuration {
    status = "Enabled"
  }
}