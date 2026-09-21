# Local kind lab

| Script | Purpose |
|--------|---------|
| `up.sh` | Create cluster `kubestronaut` (1 control-plane + 2 workers) |
| `down.sh` | Delete the cluster |
| `status.sh` | Show nodes / namespaces |
| `kind.yaml` | kind cluster config |

```bash
./cluster/up.sh
./cluster/status.sh
./cluster/down.sh
```

Requires: Docker (or compatible runtime), [kind](https://kind.sigs.k8s.io/), kubectl.

**CKS note:** On macOS/kind, host-level hardening (AppArmor, live kubelet CIS) is not enforced — practice those as file-edit tasks graded by `/review`.
