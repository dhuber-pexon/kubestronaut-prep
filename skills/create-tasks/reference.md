# Curriculum reference (cache)

Re-verify against [cncf/curriculum](https://github.com/cncf/curriculum) and LF exam pages before each generate. Weights below are a starting cache for 2025–2026-style curricula.

## Focus

- **Primary:** CKA, CKS
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
| Supply Chain Security | 20% | Image provenance, admission, signed images concepts, Dockerfile/K8s hygiene |
| Monitoring, Logging and Runtime Security | 20% | Audit policy, falco-style rules as files, runtime alerts |
| Cluster Setup | 15% | NetworkPolicy defaults, Ingress TLS, CIS-ish baseline as manifests |
| Cluster Hardening | 15% | API server flags as config files, RBAC least privilege, Pod Security |
| System Hardening | 10% | kubelet/config file edits (file-grade on kind/macOS), kernel/module notes |

## kind / macOS guidance

**Live-friendly:** Deployments, Services, NetworkPolicy, RBAC, PSS labels, probes, PVCs (local), ConfigMaps/Secrets, Jobs, Ingress (if controller installed — otherwise file-only Ingress).

**File-grade preferred:** kube-apiserver audit policy, kubelet config hardening, AppArmor profiles, node OS packages.

## Flavor × exam cheat sheet

| Flavor | Best exams |
|--------|------------|
| greenfield | all |
| repair | CKA, CKAD |
| diagnose | CKA (troubleshooting), CKAD |
| harden | CKS |
| speed | CKAD, CKA workloads/networking |

## Session mix examples

**3-task drill:** CKA diagnose (exam) · CKS harden (killer) · CKAD greenfield (warmup)

**5-task drill:** CKA troubleshooting · CKA networking · CKS supply-chain · CKS runtime/file · CKAD speed

## Official links

- https://github.com/cncf/curriculum
- https://training.linuxfoundation.org/certification/certified-kubernetes-administrator-cka/
- https://training.linuxfoundation.org/certification/certified-kubernetes-application-developer-ckad/
- https://training.linuxfoundation.org/certification/certified-kubernetes-security-specialist/
- https://kubernetes.io/docs/
