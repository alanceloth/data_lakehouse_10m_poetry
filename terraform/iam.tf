# iam.tf
resource "aws_iam_role" "rds_s3_access" {
  name = "rds-s3-access-role"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {
        "Service": "rds.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "rds_s3_policy" {
  name = "rds-s3-policy"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::${aws_s3_bucket.crm_bucket.bucket}",
        "arn:aws:s3:::${aws_s3_bucket.crm_bucket.bucket}/*"
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "rds_s3_attach" {
  role       = aws_iam_role.rds_s3_access.name
  policy_arn = aws_iam_policy.rds_s3_policy.arn
}
