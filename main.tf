provider "aws" {
  region = "ap-northeast-1"
}

resource "aws_instance" "example" {
  ami           = "ami-072298436ce5cb0c4"
  instance_type = "t2.micro"

  tags = {
    Name = "example"
  }
}
