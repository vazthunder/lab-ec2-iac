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

resource "aws_s3_bucket_policy" "static-public-read" {
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
}
