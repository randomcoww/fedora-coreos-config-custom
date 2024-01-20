locals {
  manifest = {
    base = local.base
    vrrp = local.vrrp
    kubernetes = local.kubernetes
  }
  image = {
    image-base = local.image_base
  }
}

resource "local_file" "manifests" {
  for_each = merge(local.manifest, local.image, {
    manifest = merge(local.coreos_release, {
      include = [
        for f in keys(local.manifest) :
        "${f}-${var.variant}.yaml"
      ]
    })
  }, {
    image = merge(local.coreos_image, {
      include = [
        for f in keys(local.image) :
        "${f}-${var.variant}.yaml"
      ]
    })
  })
  content  = yamlencode(each.value)
  filename = "${path.module}/../${each.key}-${var.variant}.yaml"
}