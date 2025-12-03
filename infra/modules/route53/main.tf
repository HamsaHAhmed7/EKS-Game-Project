resource "aws_route53_zone" "eks_zone" {
  name = "eks.${var.domain}"
}

resource "aws_route53_record" "delegation" {
  zone_id = var.parent_zone_id
  name    = "eks.${var.domain}"
  type    = "NS"
  ttl     = 300
  records = aws_route53_zone.eks_zone.name_servers
}
