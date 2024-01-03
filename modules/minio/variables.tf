variable "buckets" {
  description = "Bucket configuration"
  type        = list(any)

  // Validate that each bucket is unique
  validation {
    condition     = length(var.buckets) == length(toset(var.buckets))
    error_message = "All bucket names must be unique."
  }
}