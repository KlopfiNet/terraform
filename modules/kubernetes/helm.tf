data "helm_template" "cilium" {
  name      = "cilium"
  namespace = "kube-system"

  chart      = "cilium"
  repository = "https://helm.cilium.io"
  version    = "1.16.6"

  kube_version = var.kubernetes_version

  include_crds = true

  # https://www.talos.dev/v1.9/kubernetes-guides/network/deploying-cilium/#without-kube-proxy
  values = [yamlencode({
    kubeProxyReplacement = true
    ipam = {
      mode = "kubernetes"
    }
    securityContext = {
      capabilities = {
        ciliumAgent      = ["CHOWN", "KILL", "NET_ADMIN", "NET_RAW", "IPC_LOCK", "SYS_ADMIN", "SYS_RESOURCE", "DAC_OVERRIDE", "FOWNER", "SETGID", "SETUID"]
        cleanCiliumState = ["NET_ADMIN", "SYS_ADMIN", "SYS_RESOURCE"]
      }
    }
    cgroup = {
      autoMount = {
        enabled = false
      }
      hostRoot = "/sys/fs/cgroup"
    }
    k8sServiceHost = "localhost"
    k8sServicePort = 7445
  })]
}