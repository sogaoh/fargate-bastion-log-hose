resource "aws_iam_role" "this" {
  name = var.generic_role_name

  tags = var.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "sts:AssumeRole",
        Principal = {
          Service = [var.service]
        },
      },
    ]
  })
}
resource "aws_iam_role_policy_attachment" "this" {
  count      = length(var.generic_policy_arns)
  role       = aws_iam_role.this.name
  policy_arn = var.generic_policy_arns[count.index]
}
