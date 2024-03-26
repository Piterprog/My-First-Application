
resource "aws_lb" "alb_web" {
  name               = "alb-web"
  internal           = false
  load_balancer_type = "application"
  subnets            = ["subnet-0bf3ed62be2d2984d", "subnet-08c413be331a5c39a"] 
  security_groups    = ["sg-05ef7b5e4cf2b433c"]       

  enable_deletion_protection = false

  tags = {
    Name = "alb_web"
  }
}

resource "aws_lb_target_group" "tg_web" {
  name        = "tg-web"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = "vpc-0213b8ce21396f811"                        
  target_type = "instance"

  health_check {
    path                = "/"
    protocol            = "HTTP"
    port                = "traffic-port"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb_web.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.alb_web.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_web.arn
  }

  certificate_arn = "YOUR_CERTIFICATE_ARN_HERE"  # Замените на ARN вашего SSL/TLS сертификата
}
