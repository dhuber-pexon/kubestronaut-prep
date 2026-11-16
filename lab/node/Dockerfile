# cks-node: the kind node image used for every lab node.
#
# Base: kindest/node v1.37.0, the Kubernetes minor of the CKS v1.37 curriculum. It is pinned
# by the digest published in the kind v0.33.0 release notes.
# Added to make node work feel like the exam ("ssh" to a node, then sudo -i):
#   - vim-tiny, less, curl  for editing /etc/kubernetes/manifests, kubelet config, …
#   - etcdctl, etcdutl      for checking encryption at rest
#   - kube-bench + cfg      for CIS benchmark tasks (kube-bench run --targets master)
#   - a sudo shim           nodes run as root; `sudo -i` keeps working
#   - a node prompt + hint  typing a lab tool (trivy, …) on a node points back to the exam shell
#   - a docker.io mirror    pulls go through mirror.gcr.io first, then docker.io, so Docker Hub's
#                           anonymous rate limit never forces a login. The lab is rebuilt every time.
# Everything is open source and pinned/checksum-verified.
FROM docker.io/kindest/node:v1.37.0@sha256:a1ed56cfb0e7b93589bdf97c8cd566405a265939e3620fc4f5de89adff580ae5

LABEL io.cks.lab="true"

ARG TARGETARCH
ARG ETCD_VERSION=v3.7.3
ARG KUBEBENCH_VERSION=0.16.0

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl less vim-tiny \
 && rm -rf /var/lib/apt/lists/* \
 && ln -sf /usr/bin/vim.tiny /usr/local/bin/vim

RUN case "${TARGETARCH}" in \
      arm64) ETCD_SHA=ce4c08f5f43d99f0d1993552ce2906829c0366077a97e5e52529337f151a29fb; \
             KUBEBENCH_SHA=64500561f5fcaa3f86fe951ed26bbfc28f7bbf3d2eac13843abfd2924955d10b ;; \
      amd64) ETCD_SHA=5dfa9cc3b3ce3b4b491fbcc2057d3daa166bcc6676f743fcd20f8e5760cb9775; \
             KUBEBENCH_SHA=82dbc7e598740dc9344d41f8ad0b8210d57c4c00bdb2c5f1d8a69a2b98baddcf ;; \
      *) echo "unsupported architecture: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    fetch() { curl -fsSL --retry 3 -o "$2" "$1"; echo "$3  $2" | sha256sum -c -; }; \
    cd /tmp; \
    fetch "https://github.com/etcd-io/etcd/releases/download/${ETCD_VERSION}/etcd-${ETCD_VERSION}-linux-${TARGETARCH}.tar.gz" etcd.tgz "$ETCD_SHA"; \
    tar -xzf etcd.tgz; \
    install -m 0755 "etcd-${ETCD_VERSION}-linux-${TARGETARCH}/etcdctl" "etcd-${ETCD_VERSION}-linux-${TARGETARCH}/etcdutl" /usr/local/bin/; \
    fetch "https://github.com/aquasecurity/kube-bench/releases/download/v${KUBEBENCH_VERSION}/kube-bench_${KUBEBENCH_VERSION}_linux_${TARGETARCH}.tar.gz" kube-bench.tgz "$KUBEBENCH_SHA"; \
    mkdir kb && tar -xzf kube-bench.tgz -C kb; \
    install -m 0755 kb/kube-bench /usr/local/bin/kube-bench; \
    mkdir -p /etc/kube-bench && cp -r kb/cfg /etc/kube-bench/cfg; \
    rm -rf /tmp/*

# docker.io pulls: mirror.gcr.io first, docker.io as fallback (containerd hosts.toml).
# kind's config.toml (v2 format) has no registry section, so config_path is added once.
# The build then fails closed if config_path does not point at certs.d.
RUN mkdir -p /etc/containerd/certs.d/docker.io \
 && printf '%s\n' \
      'server = "https://registry-1.docker.io"' \
      '' \
      '[host."https://mirror.gcr.io"]' \
      '  capabilities = ["pull", "resolve"]' \
      > /etc/containerd/certs.d/docker.io/hosts.toml \
 && if ! grep -q 'config_path' /etc/containerd/config.toml; then \
      printf '\n[plugins."io.containerd.grpc.v1.cri".registry]\n  config_path = "/etc/containerd/certs.d"\n' >> /etc/containerd/config.toml; \
    fi \
 && grep -q 'config_path = "/etc/containerd/certs.d"' /etc/containerd/config.toml

COPY rootfs/ /
RUN chmod 0755 /usr/local/bin/sudo \
 && chmod 0644 /etc/profile.d/cks-node.sh
