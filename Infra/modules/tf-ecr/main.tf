locals {
  repos = toset(var.repository_names)

  common_tags = var.tags

}

resource "aws_ecr_repository" "this" {
  for_each             = local.repos
  name                 = each.value
  tags = merge(local.common_tags, { Name = each.value })
}

