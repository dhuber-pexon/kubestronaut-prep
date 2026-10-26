# Curriculum reference (cache)

Re-verify against [cncf/curriculum](https://github.com/cncf/curriculum) and LF exam pages before each generate. Weights below are a starting cache for 2025–2026-style curricula.

## Focus

- **Primary:** CKS
- **Secondary:** CKA
- **Refresh:** CKAD
- **Out of v1:** KCNA, KCSA (MCQ)

## CKA domains

| Domain | Weight | Example task angles |
|--------|--------|---------------------|
| Troubleshooting | 30% | CrashLoop, control-plane, DNS, Services, node NotReady |
| Cluster Architecture, Installation & Configuration | 25% | kubeadm, RBAC, HA ideas, Helm/Kustomize, CRD/operators, CNI/CSI/CRI concepts |
| Services & Networking | 20% | Service types, Ingress, Gateway API, NetworkPolicy, CoreDNS |
| Workloads & Scheduling | 15% | Deployments, rollouts, affinity/taints, ConfigMap/Secret |
| Storage | 10% | PV/PVC, StorageClass, access modes, reclaim |

## CKAD domains (refresh)

| Domain | Weight | Example task angles |
|--------|--------|---------------------|
| Application Environment, Configuration and Security | 25% | Requests/limits, ConfigMap/Secret, SA, SecurityContext, quotas |
| Application Design and Build | 20% | Jobs/CronJobs, multi-container, volumes |
| Application Deployment | 20% | Rolling update, canary/blue-green, Helm/Kustomize |
| Services and Networking | 20% | Services, Ingress, NetworkPolicy basics |
| Application Observability and Maintenance | 15% | Probes, logs, debugging, API deprecations |

## CKS domains

| Domain | Weight | Example task angles |
|--------|--------|---------------------|
| Minimize Microservice Vulnerabilities | 20% | SecurityContext, PSS, Secrets, SA token, NetworkPolicy |
| Supply Chain Security | 20% | Trivy/kubesec scans (`cluster/tool.sh`), admission (Gatekeeper, ImagePolicyWebhook), signed images concepts, Dockerfile/K8s hygiene |
| Monitoring, Logging and Runtime Security | 20% | Audit policy + log on the apiserver (live), Falco rules/alerts (`addons.sh falco`), immutability |
| Cluster Setup | 15% | NetworkPolicy defaults, Ingress TLS (`addons.sh traefik`), kube-bench CIS findings |
| Cluster Hardening | 15% | kube-apiserver flags via static-pod manifest (live), RBAC least privilege, Pod Security |
| System Hardening | 10% | kubelet config on nodes (live), seccomp profiles, AppArmor/kernel/module notes (file-grade) |

## Lab guidance (kind on Podman)

**Live-friendly:** Deployments, Services, NetworkPolicy, RBAC, PSS labels, probes, PVCs (local), ConfigMaps/Secrets, Jobs, kube-apiserver audit/encryption/admission flags, kubelet config, seccomp, etcd backup/restore, Ingress/Gateway (after `cluster/addons.sh traefik`), Gatekeeper, Falco, kube-bench.

**File-grade preferred:** AppArmor profiles, gVisor/RuntimeClass handlers, node OS packages and kernel hardening.

Full matrix: [cluster/README.md](../../cluster/README.md#live-vs-file-graded).

## Flavor × exam cheat sheet

| Flavor | Best exams |
|--------|------------|
| greenfield | all |
| repair | CKA, CKAD |
| diagnose | CKA (troubleshooting), CKAD |
| harden | CKS |
| speed | CKAD, CKA workloads/networking |

## Session mix examples

**3-task drill:** CKS harden (killer) · CKS supply-chain or runtime (exam) · CKA diagnose (exam)

**5-task drill:** CKS cluster harden · CKS supply-chain · CKS runtime · CKA troubleshooting · CKAD speed

## Official links

- https://github.com/cncf/curriculum
- https://training.linuxfoundation.org/certification/certified-kubernetes-administrator-cka/
- https://training.linuxfoundation.org/certification/certified-kubernetes-application-developer-ckad/
- https://training.linuxfoundation.org/certification/certified-kubernetes-security-specialist/
- https://kubernetes.io/docs/
