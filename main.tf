/* 
VPC Configuration
*/

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.prefix}-vpc"
  cidr = var.vpc_cidr

  azs             = var.az_list
  private_subnets = var.private_subnet_cidrs
  public_subnets  = var.public_subnet_cidrs

  enable_nat_gateway = true
}

/*
EC2 Instance Configuration
*/

resource "aws_instance" "instance" {
  ami           = var.ami_id
  instance_type = "t3.micro"

  // Do not associate public IP with instance to prevent external access
  associate_public_ip_address = false
  key_name                    = "john2"

  subnet_id              = module.vpc.private_subnets[0]
  vpc_security_group_ids = [aws_security_group.sg.id]
  user_data              = <<EOF
#!/bin/bash

apt update -y
apt install nginx -y
apt install openssl -y

mkdir /var/www/custom_site
touch /var/www/custom_site/index.html
echo 'Hello World' >> /var/www/custom_site/index.html

openssl req -x509 -newkey rsa:4096 -keyout /etc/ssl/key.pem -out /etc/ssl/cert.pem -sha256 -days 365 -nodes -subj '/CN=${aws_lb.nlb.dns_name}'

cat <<EOT > /etc/nginx/sites-available/custom_site 
server {
  listen 443 ssl;
  server_name ${aws_lb.nlb.dns_name};
  ssl_certificate /etc/ssl/cert.pem;
  ssl_certificate_key /etc/ssl/key.pem;
  
  root /var/www/custom_site;
  
  location / {
    try_files \$uri \$uri/ =404;
  }
}
EOT

ln -s /etc/nginx/sites-available/custom_site  /etc/nginx/sites-enabled/custom_site 

systemctl reload nginx
  EOF

  tags = {
    Name = "${var.prefix}-instance"
  }
/*
  lifecycle {
    ignore_changes = [user_data]
  }
*/
}

resource "aws_security_group" "sg" {
  name        = "${var.prefix}-sg"
  description = "Allow HTTPS inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "TLS from Internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

/*
Load Balancer Config
*/

resource "aws_lb" "nlb" {
  name               = "${var.prefix}-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = module.vpc.public_subnets

  enable_cross_zone_load_balancing = true
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = "443"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

resource "aws_lb_target_group" "tg" {
  name        = "${var.prefix}-tg"
  port        = 443
  protocol    = "TCP"
  target_type = "instance"
  vpc_id      = module.vpc.vpc_id
}

resource "aws_lb_target_group_attachment" "tga" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.instance.id
  port             = 443
}