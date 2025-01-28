provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

resource "helm_release" "cilium" {
  name      = "cilium"
  namespace = "kube-system"

  chart      = "cilium"
  repository = "https://helm.cilium.io"
  version    = "1.16.6"

  # https://www.talos.dev/v1.9/kubernetes-guides/network/deploying-cilium/#without-kube-proxy
  values = [yamlencode({
    egressGateway = {
      enabled = true
    }
    bpf = {
      hostLegacyRouting = true # Otherwise, DNS resolution seems to fail (talos 1.9.2, cilium 1.16.6)
      masquerade        = true
    }

    # https://github.com/siderolabs/talos/issues/8836#issuecomment-2158601983
    bandwidthManager = {
      enabled = false
      bbr     = true
    }

    kubeProxyReplacement = true
    ipam = {
      mode = "kubernetes"
      operator = {
        clusterPoolIPv4PodCIDRList: ["10.43.0.0/16"]
      }
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