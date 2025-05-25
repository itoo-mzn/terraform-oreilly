provider "aws" {
  region = "ap-northeast-1"
}

resource "aws_instance" "example" {
  ami                    = "ami-0f415cc2783de6675"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.instance.id]

  user_data = <<EOF
              #!/bin/bash
              echo "Hello, World!" > index.html
              nohup busybox httpd -f -p ${var.server_port} &
              EOF

  # user_dataが変更された場合、インスタンスを再起動する
  user_data_replace_on_change = true

  # key_name = aws_key_pair.this.key_name

  tags = {
    Name = "example"
  }
}

resource "aws_security_group" "instance" {
  name = "example-instance"

  # 全IPからの8080ポートへのアクセスを許可
  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# SSHして調査したときの残骸
# variable "key_name" {
#   type    = string
#   default = "ec2_key"
# }
# resource "aws_key_pair" "this" {
#   key_name   = var.key_name
#   public_key = file("${var.key_name}.pub")
# }

variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type        = number
  default     = 8080
}

output "instance_public_ip" {
  value = aws_instance.example.public_ip
}
