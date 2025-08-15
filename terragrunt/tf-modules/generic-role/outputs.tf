output "generic_role" {
  value = {
    arn  = aws_iam_role.this.arn
    name = aws_iam_role.this.name
  }
}
