resource "aws_instance" "backend" {
  ami           = var.ami
  instance_type = var.instance_type
  subnet_id     = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  key_name      = var.key_name
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              # Add your business logic installation here
              EOF
  tags = {
    Name = "backend-instance"
  }
}
