provider "aws" {
  region = "ap-northeast-1" # 東京リージョン
}

# EC2インスタンス
resource "aws_instance" "example" {
  ami                    = "ami-0f415cc2783de6675"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.instance.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World!" > index.html
              nohup busybox httpd -f -p ${var.server_port} &
              EOF

  # user_dataが変更された場合、インスタンスを再起動する
  user_data_replace_on_change = true

  tags = {
    Name = "example"
  }
}

# セキュリティグループ EC2インスタンス用
resource "aws_security_group" "instance" {
  name = "example-instance"

  # 全IPからの8080ポートへのアクセスのみを許可
  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # アウトバウンドは全許可
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# output: apply後に表示する出力値
output "instance_public_ip" {
  value = aws_instance.example.public_ip
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

variable "server_port" {
  description = "HTTPリクエストを受け付けるポート番号"
  type        = number
  default     = 8080
}
