output "alb_endpoint_url" {
  value       = aws_lb.app_lb.dns_name
  description = "Returns the ALB URL"
}