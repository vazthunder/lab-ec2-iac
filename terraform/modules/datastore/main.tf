resource "aws_s3_bucket" "deploy" {
  bucket = "${var.project}-${var.env}-deploy"

  tags = {
    Group = "${var.project}-${var.env}"
  }
}

resource "aws_s3_bucket" "static" {
  bucket = "${var.project}-${var.env}-static"

  tags = {
    Group = "${var.project}-${var.env}"
  }
}

resource "aws_s3_bucket_ownership_controls" "static" {
  bucket = aws_s3_bucket.static.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
  depends_on = [ aws_s3_bucket_public_access_block.static ]
}

resource "aws_s3_bucket_public_access_block" "static" {
  bucket = aws_s3_bucket.static.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "static" {
  bucket = aws_s3_bucket.static.id

  policy = jsonencode({
    Version: "2012-10-17"
    Id: "static-public-read"
    Statement: [{
      Effect: "Allow"
      Principal: "*"
      Action: "s3:GetObject"
      Resource: "arn:aws:s3:::${aws_s3_bucket.static.id}/*"
    }]
  })

  depends_on = [ aws_s3_bucket_ownership_controls.static ]
}
