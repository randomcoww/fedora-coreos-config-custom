manifests = [
  "base",
  "vrrp",
  "kubernetes",
  "nvidia",
  "kvm",
  "desktop-environment",
  "sunshine",
  "release-silverblue",
]
exclude_packages = [
  "python",
  "python2",
  "python2-libs",
  "perl",
  "nodejs",
  "dnf",
  "cowsay",
  "initscripts",
  "plymouth",
  "NetworkManager",
  "NetworkManager-initscripts-ifcfg-rh",
  "PackageKit",
]
image_base = "image-base"
image_params = {
  size = 4
  extra-kargs = [
    "rd.driver.blacklist=nouveau",
    "modprobe.blacklist=nouveau",
    "nvidia_drm.modeset=1",
  ]
}