locals {
  manifest = {
    base = merge(local.base, {
      exclude-packages = setsubtract(local.base.exclude-packages, [
        "python3",
        "python3-libs",
        "perl-interpreter",
        "grubby",
        "NetworkManager-libnm",
      ])
    })
    vrrp = local.vrrp
    kubernetes = local.kubernetes
    nvidia = local.nvidia
    desktop-environment = local.desktop_environment
  }
  image = {
    image-base = local.image_base
  }
}

resource "local_file" "manifests" {
  for_each = merge(local.manifest, local.image, {
    manifest = merge(local.silverblue_release, {
      include = [
        for f in keys(local.manifest) :
        "${f}.yaml"
      ]
    })
  }, {
    image = merge(local.nvidia_image, {
      include = "${keys(local.image)[0]}.yaml"
    })
  })

  content  = yamlencode(each.value)
  filename = "${path.module}/../${each.key}.yaml"
}