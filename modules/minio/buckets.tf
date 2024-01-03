resource "minio_s3_bucket" "bucket" {
  for_each = toset(var.buckets)

  bucket = each.key
  acl    = "public"
}

resource "minio_s3_bucket_versioning" "version" {
  for_each = toset(var.buckets)

  bucket = minio_s3_bucket.bucket[each.key].bucket

  versioning_configuration {
    status = "Enabled"
  }
}