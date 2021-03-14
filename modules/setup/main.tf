/*
resource "null_resource" "set_permissions_of_ssh_keys" {
  provisioner "local-exec" {
    command = <<-EOF
      chmod 600 id_rsa
      chmod 644 id_rsa.pub
    EOF
  }
}
*/

resource "aws_key_pair" "deployer" {
  #depends_on = [null_resource.set_permissions_of_ssh_keys]
  key_name   = "workshop-deployment-key"
  public_key = file("id_rsa.pub")
}

output "aws_public_key_name" {
    value = aws_key_pair.deployer.key_name
}