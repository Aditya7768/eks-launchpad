provider "aws" {
    region = "us-west-2"
}

resource "aws_s3_bucket" "terraform_state"{
    bucket = "demo-terraform-eks-state-saad-bucket"

    lifecycle {
        prevent_destroy = false
    }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-eks-state-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
