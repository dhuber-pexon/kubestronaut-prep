# CKS reference (authoritative cache)

The CKS curriculum, **v1.37**, as Markdown. This file is the source of truth for task generation.
Refresh it only when the learner asks. The source is the CNCF CKS curriculum, published with the Linux Foundation
exam page: https://training.linuxfoundation.org/certification/certified-kubernetes-security-specialist-cks/.
When refreshing, re-transcribe it into this Markdown file. Never download PDFs into the repo.

**Exam:** CKS · performance-based (tasks in live clusters) · 2 hours · 15–20 tasks · pass mark 67 % ·
Kubernetes **v1.37** (the lab runs v1.37 too).

## Domains and competencies

### Cluster Setup — 15 %
- Use network security policies to restrict cluster-level access
- Use the CIS benchmark to review the security configuration of Kubernetes components (etcd, kubelet, kubedns, kube-apiserver)
- Properly set up Ingress objects with TLS
- Protect node metadata and endpoints
- Verify platform binaries before deploying

### Cluster Hardening — 15 %
- Use role-based access control to minimize exposure
- Exercise caution with service accounts, e.g. disable defaults, minimize permissions on newly created ones
- Restrict access to the Kubernetes API
- Upgrade Kubernetes to avoid vulnerabilities

### System Hardening — 10 %
- Minimize the host OS footprint (reduce the attack surface)
- Use least-privilege identity and access management
- Minimize external access to the network
- Appropriately use kernel hardening tools such as AppArmor and seccomp

### Minimize Microservice Vulnerabilities — 20 %
- Use appropriate Pod Security Standards
- Manage Kubernetes Secrets
- Understand and implement isolation techniques (multi-tenancy, sandboxed containers, etc.)
- Implement pod-to-pod encryption (Cilium, Istio)

### Supply Chain Security — 20 %
- Minimize the base image footprint
- Understand your supply chain (e.g. SBOM, CI/CD, artifact repositories)
- Secure your supply chain (permitted registries, sign and validate artifacts, etc.)
- Perform static analysis of user workloads and container images (e.g. Kubesec, KubeLinter)

### Monitoring, Logging and Runtime Security — 20 %
- Perform behavioral analytics to detect malicious activities
- Detect threats within physical infrastructure, apps, networks, data, users and workloads
- Investigate and identify phases of attack and bad actors within the environment
- Ensure immutability of containers at runtime
- Use Kubernetes audit logs to monitor access

## Task angles per domain, with how the lab grades them

`live` = graded against the running lab. `file` = graded from `work/` only (see the lab limits in CLAUDE.md).

| Domain | Task angles | Grading |
|---|---|---|
| Cluster Setup | default-deny + allow-list NetworkPolicies; egress policies that block the node metadata IP and node ports; kube-bench findings fixed on the control plane (`kube-bench run --targets master` on the node); Ingress with a TLS Secret (spec only, there is no ingress controller); `sha512sum` / `sha256sum` check of kubelet/kubectl binaries on a node against a given checksum | live (Ingress: spec) |
| Cluster Hardening | Role/ClusterRole least privilege, `kubectl auth can-i --as`; ServiceAccount with `automountServiceAccountToken: false`; removing a dangerous ClusterRoleBinding; apiserver flags `--anonymous-auth=false`, `--authorization-mode=Node,RBAC`, NodeRestriction; restricting the API to localhost; kubeadm upgrade plan (file) | live (upgrade: file) |
| System Hardening | find and remove a rogue package/service/user inside a node; seccomp `RuntimeDefault` and `Localhost` profiles in `/var/lib/kubelet/seccomp/profiles/`; AppArmor profile + pod `appArmorProfile` field | live (AppArmor: file) |
| Microservice Vulnerabilities | PSA labels (`enforce: restricted`) and fixing pods to comply; securityContext (runAsNonRoot, drop ALL, readOnlyRootFilesystem, allowPrivilegeEscalation false); Secrets mounted as files, not env; EncryptionConfiguration (aescbc / secretbox) and re-encrypting existing Secrets, verified with `etcdctl`; RuntimeClass `gvisor` (object + pod spec); Cilium/Istio mTLS (manifests only) | live (gVisor runtime, Cilium/Istio: file) |
| Supply Chain | trivy image scan → pick/replace images with no CRITICAL; SBOM with `bom` or `trivy --format spdx-json/cyclonedx`; ValidatingAdmissionPolicy allowing only permitted registries; ImagePolicyWebhook admission config files; cosign `generate-key-pair` + `sign-blob` / `verify-blob` (local keys only, never a public transparency log); kubesec / kube-linter findings fixed; Dockerfile hardening (non-root, minimal/distroless base, pinned tags) | live (webhook backend: file) |
| Monitoring & Runtime | audit Policy + `--audit-policy-file` / `--audit-log-path` / max-age flags, then find a culprit in the audit log; Falco rule edits + reading alerts (`./cks addon falco`); find and kill a pod doing something bad (reading `/etc/shadow`, spawning a shell); immutability: `readOnlyRootFilesystem`, no shell/package manager, emptyDir for writable paths | live (Falco: best effort) |

## Flavor × domain cheat sheet

| Flavor | Best domains |
|---|---|
| greenfield | Microservice Vulnerabilities, Supply Chain, Cluster Hardening |
| repair | Cluster Setup (NetworkPolicy), Cluster Hardening (apiserver flags) |
| diagnose | Monitoring & Runtime (audit log, alerts), Cluster Hardening (RBAC deny) |
| harden | System Hardening, Microservice Vulnerabilities, Cluster Setup |
| investigate | Monitoring & Runtime (audit log / Falco forensics), System Hardening (rogue process/user) |
| speed | NetworkPolicy, RBAC, securityContext, Secrets |

## Session mix examples

- **3-task drill:** Cluster Hardening repair (exam) · Supply Chain greenfield (warmup) · Monitoring investigate (killer)
- **5-task drill:** NetworkPolicy harden · PSA + securityContext speed · EncryptionConfiguration (killer) · trivy + VAP permitted registries · audit policy investigate

## Docs the learner may use (as in the exam)

- https://kubernetes.io/docs/ and https://kubernetes.io/blog/
- The docs of the tools that ship in the lab: trivy, falco, etcd, kube-bench, cosign, kubesec, kube-linter.
  Link to the project's own documentation site, never to a vendor portal that needs an account.
