
resource "aws_key_pair" "deployer" {
  key_name   = "workshop-deployment-key"
  public_key = file("id_rsa.pub")
}

output "aws_public_key_name" {
    value = aws_key_pair.deployer.key_name
}