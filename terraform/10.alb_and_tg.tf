
resource "aws_lb" "alb_web" {
  name               = "alb-web"
  internal           = false
  load_balancer_type = "application"
  subnets            = "data.aws_subnet.public_subnets[*].id"
  security_groups    = "data.aws_security_group.Security_vpc_musad.id"       

  enable_deletion_protection = false

  tags = {
    Name = "alb_web"
  }
}

resource "aws_lb_target_group" "tg_web" {
  name        = "tg-web"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = "data.aws_vpc.main.id"                       
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

  certificate_arn = var.certificate_arn 
}
