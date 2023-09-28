output "sg-alb_id" {
    value = aws_security_group.alb.id
}

output "alb-listener-http_arn" {
    value = aws_alb_listener.http.arn
}

# output "alb-listener-https_arn" {
#     value = aws_alb_listener.https.arn
# }
