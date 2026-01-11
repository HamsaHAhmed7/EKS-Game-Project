resource "aws_route53_zone" "eks" {
  name = "eks.${var.domain}"

  tags = merge(var.common_tags, {
    Name = "${var.project}-eks-zone"
  })
}

resource "aws_route53_record" "delegation" {
  zone_id = var.parent_zone_id
  name    = aws_route53_zone.eks.name
  type    = "NS"
  ttl     = 300
  records = aws_route53_zone.eks.name_servers
}
