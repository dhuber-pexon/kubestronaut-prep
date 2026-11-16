# cks-toolbox: every CLI the lab needs, so nothing is installed on the Mac.
#
# Built locally by ./cks inside the Podman VM. Every tool is open source and free
# (Apache-2.0 / MIT / BSD), pinned to a version and verified against its published
# sha256 before it is installed. To bump a tool: change its version and both checksums.
#
# Sources: dl.k8s.io, get.helm.sh and GitHub releases. Anonymous downloads, no accounts.
FROM docker.io/library/debian:trixie-slim@sha256:a72b4433de1cf7d6bae0c4cee74d0547f58601a643b3375f070c51600d63b6b2

LABEL io.cks.lab="true" \
      org.opencontainers.image.title="cks-toolbox" \
      org.opencontainers.image.description="Local CKS practice toolbox (kubectl, kind, trivy, kubesec, kube-linter, cosign, bom, helm)"

ARG TARGETARCH
# Must match the Podman service in the VM; ./cks passes the server version in.
ARG PODMAN_VERSION=6.2.0

ARG KUBECTL_VERSION=v1.37.2
ARG KIND_VERSION=v0.33.0
ARG HELM_VERSION=v4.3.2
# trivy: v0.76.2 is clear of all GHSA advisories (only v0.69.4 was compromised in 03/2026).
ARG TRIVY_VERSION=0.76.2
ARG KUBESEC_VERSION=v2.15.0
ARG KUBELINTER_VERSION=v0.8.3
ARG COSIGN_VERSION=v3.1.4
ARG BOM_VERSION=v0.8.0

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      bash-completion ca-certificates curl iproute2 jq less nano netcat-openbsd openssl procps vim \
 && rm -rf /var/lib/apt/lists/*

RUN case "${TARGETARCH}" in \
      arm64) \
        KUBECTL_SHA=fcc16f63186659d9722014b7e02d5fdd2d4e669cb8c0ab66365d7d3b8ba03509; \
        KIND_SHA=20022bee6cfcd5086cb7234d218e3454e6090022f2a8f55d1fa7fcf42c3867a2; \
        HELM_SHA=df31cb61680ef728f82c770e5280dd565617bee6b039d37e85c677288be4bbb0; \
        TRIVY_SHA=ab9d51f86e6a5fb936f605faff6b593ac51bc378fff4d3e8b9d58358b9c367c3; TRIVY_ARCH=ARM64; \
        KUBESEC_SHA=062022450df830854747e705421b307b7d0db1ea2527a37a104d27cd0681936d; \
        KUBELINTER_SHA=802e1b09eabd08f6f0a060a6b8ab2bf7bc7e6bf4f673bb2692303704c84b3e22; KUBELINTER_FILE=kube-linter-linux_arm64.tar.gz; \
        COSIGN_SHA=ade83b7aac62e131cacfe96d958948b2150cc9efec46a570a2649b8e27dedad2; \
        BOM_SHA=921ad8ecd43b79b6f33122a6e85cb2a663e47b54007f08aceaf4e844a9c007cd ;; \
      amd64) \
        KUBECTL_SHA=c04487523e7aa7d1493f7808174c899db93d7a9cf57531420cd76b9bd415f8f4; \
        KIND_SHA=aee6151561422756b764a4ae28e7f44cda5af5a9eead3cc9985112b1de8d8e0d; \
        HELM_SHA=d1c0278d46beab79582d7e50f5b3dc206944ba8e577cde618513fd07daa53983; \
        TRIVY_SHA=bc0fc726e017b8927a62b2d3531d7a84ee01769daf5c99ed866dced54089fdbf; TRIVY_ARCH=64bit; \
        KUBESEC_SHA=69a03d83c53112499971755de4741d149d9ed0ab5cdea4682efb5cf95c6ef8e7; \
        KUBELINTER_SHA=1a6d8419b11971372971fdbc22682b684ebfb7cf1c39591662d1b6ca736c41df; KUBELINTER_FILE=kube-linter-linux.tar.gz; \
        COSIGN_SHA=424e2c97d0b45fd7a6b608a87f090f35633f4c23ece5f092d48bba11aaf4bbfa; \
        BOM_SHA=cafd00b75a8df860fec54d19b9e24fb48556c0848d0abf9e40cd2eabb11a8710 ;; \
      *) echo "unsupported architecture: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    fetch() { curl -fsSL --retry 3 -o "$2" "$1"; echo "$3  $2" | sha256sum -c -; }; \
    cd /tmp; \
    fetch "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${TARGETARCH}/kubectl" kubectl "$KUBECTL_SHA"; \
    install -m 0755 kubectl /usr/local/bin/kubectl; \
    fetch "https://github.com/kubernetes-sigs/kind/releases/download/${KIND_VERSION}/kind-linux-${TARGETARCH}" kind "$KIND_SHA"; \
    install -m 0755 kind /usr/local/bin/kind; \
    fetch "https://get.helm.sh/helm-${HELM_VERSION}-linux-${TARGETARCH}.tar.gz" helm.tgz "$HELM_SHA"; \
    tar -xzf helm.tgz "linux-${TARGETARCH}/helm"; install -m 0755 "linux-${TARGETARCH}/helm" /usr/local/bin/helm; \
    fetch "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-${TRIVY_ARCH}.tar.gz" trivy.tgz "$TRIVY_SHA"; \
    tar -xzf trivy.tgz trivy; install -m 0755 trivy /usr/local/bin/trivy; \
    fetch "https://github.com/controlplaneio/kubesec/releases/download/${KUBESEC_VERSION}/kubesec_linux_${TARGETARCH}.tar.gz" kubesec.tgz "$KUBESEC_SHA"; \
    tar -xzf kubesec.tgz kubesec; install -m 0755 kubesec /usr/local/bin/kubesec; \
    fetch "https://github.com/stackrox/kube-linter/releases/download/${KUBELINTER_VERSION}/${KUBELINTER_FILE}" kube-linter.tgz "$KUBELINTER_SHA"; \
    tar -xzf kube-linter.tgz kube-linter; install -m 0755 kube-linter /usr/local/bin/kube-linter; \
    fetch "https://github.com/sigstore/cosign/releases/download/${COSIGN_VERSION}/cosign-linux-${TARGETARCH}" cosign "$COSIGN_SHA"; \
    install -m 0755 cosign /usr/local/bin/cosign; \
    fetch "https://github.com/kubernetes-sigs/bom/releases/download/${BOM_VERSION}/bom-${TARGETARCH}-linux" bom "$BOM_SHA"; \
    install -m 0755 bom /usr/local/bin/bom; \
    # podman-remote: the version follows the VM, so it is checked against the release's own shasums file.
    curl -fsSL --retry 3 -o shasums "https://github.com/podman-container-tools/podman/releases/download/v${PODMAN_VERSION}/shasums"; \
    curl -fsSL --retry 3 -o "podman-remote-static-linux_${TARGETARCH}.tar.gz" \
      "https://github.com/podman-container-tools/podman/releases/download/v${PODMAN_VERSION}/podman-remote-static-linux_${TARGETARCH}.tar.gz"; \
    grep " podman-remote-static-linux_${TARGETARCH}.tar.gz\$" shasums | sha256sum -c -; \
    tar -xzf "podman-remote-static-linux_${TARGETARCH}.tar.gz"; \
    install -m 0755 "bin/podman-remote-static-linux_${TARGETARCH}" /usr/local/bin/podman; \
    rm -rf /tmp/*; \
    kubectl completion bash > /usr/share/bash-completion/completions/kubectl; \
    helm completion bash > /usr/share/bash-completion/completions/helm; \
    kind completion bash > /usr/share/bash-completion/completions/kind

# Non-interactive `podman exec` calls (Claude, ./cks kubectl) need no bashrc.
ENV KUBECONFIG=/root/.kube/config \
    KIND_EXPERIMENTAL_PROVIDER=podman \
    CONTAINER_HOST=unix:///run/podman/podman.sock \
    EDITOR=vim \
    LANG=C.UTF-8

COPY rootfs/ /
RUN chmod 0755 /usr/local/bin/ssh /usr/local/bin/sudo /usr/local/bin/cks-teardown /usr/local/bin/cks-lab-nodes

WORKDIR /root
CMD ["sleep", "infinity"]
