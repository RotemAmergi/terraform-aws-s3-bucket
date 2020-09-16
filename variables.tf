provider "aws" {
  region = "eu-west-1"
}
variable "create_bucket" {
  description = "Controls if S3 bucket should be created"
  type        = bool
  default     = true
}

variable "site_name" {
    type        = string
    default     = "test"
}
variable "s3_origin_id" {
  type        = string
  default     = "S3-test"
}