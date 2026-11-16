# Post-Podman steps

**Status:**
- **Done:** the lab is fully written (`./cks`, toolbox and node images, Claude Code skills, hooks and settings).
- **Verified:** everything that can be checked without Podman: macOS bash 3.2 syntax and the 67 guard tests.
- **Unverified:** every part that touches the container engine (Part A). Applies to the state of branch
  `feat/cks-only-with-docker-standalone` after commit `5944290`.

**How to use this file**
1. Work through **Part A** in order. It tests what already exists.
2. Then pick features from **Part B**, top to bottom.
3. Tick the boxes. After each step, add a line to the [Results log](#results-log).
4. When a check fails: fix it, re-run `bash .claude/hooks/test-guards.sh` and `/bin/bash -n cks`, then continue.
5. All constraints still apply:
   - CKS only
   - Podman is the only install on the Mac
   - nothing reachable beyond `127.0.0.1`
   - nothing changed outside this folder
   - free, open-source tools only

Commands marked **(exam shell)** run inside `./cks`. Commands marked **(Mac)** run in a normal VS Code terminal.

---

## Part A — Bring-up verification

### A0 Preflight (Mac)

- [ ] `podman --version` prints a stable release (no `-rc` / `-dev`).
- [ ] `podman machine list` shows no other VM running. Stop it if there is one; only one VM can run at a time.
- [ ] Record the baseline: `ls -la ~/.kube ~/.docker 2>&1`. Both should be absent or unchanged by the end of Part A.
- [ ] `./cks status` reports `VM 'cks': missing`.

### A1 First boot: `./cks` (Mac)

- [ ] Run `./cks` and note the duration of each phase in the Results log:
  - VM init
  - image builds (toolbox and node build in parallel)
  - cluster creation
- [ ] macOS asks for Documents access for the VM helper (krunkit or vfkit). Click **Allow**.
- [ ] Podman does **not** ask to change the default connection (`--update-connection=false` works).
- [ ] You land in the exam shell (`cks:…$`) and see the banner.
- [ ] **(exam shell)** `k get nodes -o wide`: `cks-control-plane` and `cks-worker` are Ready on **v1.37.x**.
- [ ] **(exam shell)** `ssh cks-control-plane`, then `sudo -i`, then `ls /etc/kubernetes/manifests`. `exit` back out.
- [ ] **(exam shell)** `trivy --version; kubesec version; kube-linter version; cosign version; bom version`. All tools respond.

**If it fails**

| Symptom | Likely cause | Look at |
|---|---|---|
| `unknown flag: --update-connection` | the flag name differs in this Podman version | `upd_conn_flag` in [cks](cks) |
| "The VM cannot read this project folder" | macOS prompt missed or denied | `check_folder_access`; System Settings → Privacy & Security → Files and Folders |
| Toolbox build fails downloading `podman-remote` (404) | Podman server version has a suffix (e.g. `6.2.0-dev`) | `image_tags`, `PODMAN_VERSION` in [lab/toolbox/Dockerfile](lab/toolbox/Dockerfile) |
| Node build stops at the `config_path` assertion | kind changed its containerd config format | registry block in [lab/node/Dockerfile](lab/node/Dockerfile) |
| `kind create cluster` cannot talk to Podman | socket path or SELinux inside the VM | `ensure_toolbox` (socket mount, `label=disable`) |
| `kind create` fails with `already allocated` twice | API port collision | retry loop in `create_cluster` |
| `podman update --restart` error | older Podman | `create_cluster` (errors are ignored; just confirm A3's reboot test) |
| Nodes stay NotReady | not enough VM resources | `CKS_VM_CPUS` / `CKS_VM_MEMORY_MB`, then `./cks purge` and start again |

Full logs are in `.cks/logs/` (machine, build-toolbox, build-node, cluster, seed, teardown).

### A2 Local-only and privacy proof (Mac)

- [ ] `./cks verify-local` prints only ✔ lines:
  - no `local-only:` findings
  - **no** "could not list the folders shared with the VM" warning
- [ ] `podman machine inspect cks`: under `Mounts`, only this project folder (and, on Podman 6, `~/.config/containers`).
- [ ] `netstat -an -p tcp | grep LISTEN`: the lab's API port appears **only** as `127.0.0.1.<port>`.
- [ ] `lsof -nP -iTCP -sTCP:LISTEN -c gvproxy -c krunkit -c vfkit`: every address is `127.0.0.1` or `[::1]`.
- [ ] `ls -la ~/.kube ~/.docker 2>&1` is unchanged against A0.
- [ ] **Negative test 1 (static config).**
  1. Add this under the control-plane node in [lab/kind.yaml](lab/kind.yaml), using loopback so nothing is exposed even if it gets created:
     ```yaml
     extraPortMappings: [{containerPort: 30000, hostPort: 30000, listenAddress: "127.0.0.1"}]
     ```
  2. `./cks verify-local` must report a finding and exit non-zero.
  3. Revert the file.
  - **Known gap to fix in A6:** `cmd_up` runs the static check only *after* `create_cluster`. Move the static part of `audit_local` before cluster creation, so a bad `kind.yaml` never gets created.
- [ ] **Negative test 2 (runtime).**
  1. **Create** (do not start) a container with a wildcard binding:
     ```bash
     podman --connection cks-root create --name cks-negtest -p 0.0.0.0:18080:80 docker.io/library/busybox:1.37
     ```
     It isn't running, so nothing is exposed, but its configuration is what the audit inspects.
  2. `./cks verify-local` must report `cks-negtest … only 127.0.0.1 is allowed`.
  3. `./cks up` must tear the lab down.
  4. Clean up: `podman --connection cks-root rm cks-negtest`.

### A3 Lifecycle

- [ ] `exit` in the exam shell, then Enter:
  - within about 20 s, `podman --connection cks-root ps -a` shows no `cks-*` containers
  - `podman machine list` shows `cks` stopped
- [ ] `exit`, then `n`: you're back in the shell and the lab is untouched.
- [ ] Ctrl-D in the exam shell is ignored (`IGNOREEOF`).
- [ ] Close the terminal **tab** while in the exam shell:
  - same teardown as `exit`
  - `.cks/logs/teardown.log` shows the reaper running
- [ ] `CKS_KEEP=1 ./cks`, then `exit`: the lab keeps running. `./cks status` shows `created by: kept`. Then `./cks down`.
- [ ] Second terminal, `./cks` while the first is open: it says "Opening an extra shell". Exit it: the lab stays up.
- [ ] `./cks reset` (Mac, second terminal) while the exam shell is open:
  - the shell survives
  - `k get nodes` works again after the reset
- [ ] Take-over:
  1. ask Claude to run `./cks up`
  2. then run `./cks` yourself
  3. it prints "Taking over the running lab cluster" and does **not** rebuild
- [ ] Claude session end with **no** exam shell open: the lab is torn down (`.cks/logs/teardown.log`).
- [ ] `/clear` in Claude: the lab is **not** torn down.
- [ ] Close the whole VS Code window with no exam shell open: does the SessionEnd hook fire? **Record yes or no.**
  If no, document it in quick-start ("run `./cks down` or `exit` the shell before closing VS Code").
- [ ] No resurrection:
  1. `CKS_KEEP=1 ./cks`, `exit`
  2. `podman machine stop cks && podman machine start cks`
  3. `podman --connection cks-root ps`: no node containers running (restart policy `no`)
  4. clean up with `./cks down`

### A4 CKS capability matrix (live)

All rows run in the exam shell. Use throwaway namespaces and delete them afterwards (or just `./cks reset`).
**The pass column decides the live-vs-file matrix in README and CLAUDE.md.**

| # | Capability | Test | Pass |
|---|---|---|---|
| 1 | NetworkPolicy | two pods in `np-test`; `wget -qO- -T 3` from one to the other; then apply a default-deny ingress policy | works before, times out after |
| 2 | RBAC | `k auth can-i list secrets --as system:serviceaccount:default:default` | `no` |
| 3 | Pod Security Admission | `k label ns psa-test pod-security.kubernetes.io/enforce=restricted`; `k -n psa-test run x --image=nginx:1.29-alpine` | rejected with a PSA message |
| 4 | securityContext / immutability | pod with `readOnlyRootFilesystem: true`; `k exec … -- touch /x` | write fails |
| 5 | Encryption at rest | on the control plane: EncryptionConfiguration (aescbc) + `--encryption-provider-config` + volume mount; create a Secret; then `etcdctl --cacert /etc/kubernetes/pki/etcd/ca.crt --cert /etc/kubernetes/pki/etcd/server.crt --key /etc/kubernetes/pki/etcd/server.key get /registry/secrets/default/<name> \| cat -v \| head` | value starts with `k8s:enc:aescbc:v1:` |
| 6 | seccomp Localhost | on `cks-worker`: profile in `/var/lib/kubelet/seccomp/profiles/audit.json`; pod with `type: Localhost`, `nodeName: cks-worker` | pod Running |
| 7 | Audit logging | audit Policy + `--audit-policy-file`, `--audit-log-path`, hostPath mounts; wait for kube-apiserver to restart (`crictl ps` on the node) | log file fills with events |
| 8 | Admission / API flags | `--enable-admission-plugins=NodeRestriction,…`, `--anonymous-auth=false` | apiserver healthy; `curl -k https://cks-control-plane:6443/version` from the toolbox returns 401 |
| 9 | kubelet hardening | set `readOnlyPort: 0` in `/var/lib/kubelet/config.yaml`; `systemctl restart kubelet` | node back to Ready |
| 10 | CIS benchmark | `ssh cks-control-plane kube-bench run --targets master \| tail -20` | a report with PASS/FAIL/WARN totals |
| 11 | Permitted registries | ValidatingAdmissionPolicy + binding that only allows `registry.k8s.io/` images | an `nginx` pod is denied; `registry.k8s.io/pause:3.10` is admitted |
| 12 | trivy | `trivy image --severity CRITICAL nginx:1.25` twice | the second run reuses the DB from the `cks-trivy-cache` volume (no DB download) |
| 13 | Static analysis | `kubesec scan pod.yaml`; `kube-linter lint pod.yaml` | both report findings locally (no network calls to kubesec.io) |
| 14 | SBOM | `bom generate --image registry.k8s.io/pause:3.10 -o /tmp/pause.spdx` (check `bom generate --help`) | SPDX file written |
| 15 | cosign offline | `COSIGN_PASSWORD= cosign generate-key-pair`; sign-blob and verify-blob with the offline flags from CLAUDE.md. **Proof of offline:** run the same commands in a no-network container: `podman --connection cks-root run --rm --network none -v "$PWD:$PWD" -w "$PWD" <toolbox image> cosign …` (Mac) | succeeds with `--network none`. **Fix the flag names in CLAUDE.md and README if v3.1.4 differs** |
| 16 | Binary verification | `ssh cks-worker sha256sum /usr/bin/kubelet` vs the published `kubelet.sha256` for the node's version and arch | match. If kind builds its own binaries, record it and adapt the task wording |
| 17 | docker.io mirror | on a node: `crictl pull docker.io/library/busybox:1.37` and `containerd config dump \| grep -A1 config_path` | pull works; `config_path` points at `/etc/containerd/certs.d` |
| 18 | Falco | `./cks addon falco` (Mac); then `k exec <pod> -- cat /etc/shadow`; `k -n falco logs ds/falco \| grep -i shadow` | alert visible, **or** the clear fallback message. Record which |

AppArmor, running gVisor, Cilium/Istio encryption, kubeadm upgrade and Ingress TLS stay file-graded unless B7 changes that.

### A5 Claude Code integration

- [ ] A new Claude session shows the SessionStart line ("CKS lab: VM 'cks' running; cluster present; …").
- [ ] **Permissions:**
  - **without** a prompt: `./cks status`, `./cks kubectl get po -A`, `./cks node cks-worker -- uptime`
  - **with** a prompt: `./cks reset`, `./cks down`, `./cks purge --yes`, `git push`, WebFetch, and any Edit inside a `work/` folder
  - **denied:** claude.ai connectors / MCP tools, Artifacts, reading `~/.ssh/…`
- [ ] **Guard, main session:** ask Claude to run a command that publishes `0.0.0.0` or uses `kubectl` directly. It is blocked with a reason.
- [ ] **Guard, subagent:** ask a subagent to do the same. It is blocked too (project hooks apply to subagents).
- [ ] **Skills:**
  - `/create-tasks 3 hard`:
    - session created under `sessions/`
    - `given/` is used for starter files and `work/` stays empty
    - `./cks seed` ran; symptoms are reported, fixes are not
  - `/hint` three times escalates through levels 1, 2 and 3, and `.meta/hint-level` ends at `3`
  - `/grade <task>`: "Mode: files + live lab", with evidence per item
  - `/grade sessions/<id>`:
    - one `cks-grader` per task, in parallel
    - a grader's attempt to run a changing command (e.g. `./cks kubectl delete …`) is blocked by `grader-guard.sh`
  - `/exam-session`:
    - 15–16 tasks, about 100 points
    - `./cks reset sessions/<id>` (prompted)
    - every seed applied
  - `/explain-solution <task>`: walkthrough in chat; nothing written into `work/`
- [ ] **Telemetry opt-out:** check whether Claude Code honours `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` / `DISABLE_TELEMETRY` from **project** settings
  (`/status`, or the docs for your version). Record the answer. If they aren't honoured, document setting them in your user settings or shell instead.

### A6 Close out bring-up

- [ ] Fix every finding from A1–A5.
- [ ] Move the static `kind.yaml` check before cluster creation (A2 known gap).
- [ ] Update the live-vs-file matrix ([README.md](README.md), [CLAUDE.md](CLAUDE.md)) and the cosign flags.
- [ ] Update [quick-start.md](quick-start.md) with real timings, the real macOS prompt wording, and the VS Code window-close answer.
- [ ] `bash .claude/hooks/test-guards.sh` and `/bin/bash -n cks` are green.
- [ ] Commit: `fix: podman bring-up`.

---

## Part B — Next features (priority order)

Each feature lists **Why**, **Implement**, **Test** and **Constraints**. Keep all `./cks` code bash 3.2 / BSD-userland compatible.
No feature may publish a port, write outside this folder, or need an account.

### B1 `./cks selftest` and `./cks smoke`: automate Part A

- **Why:** Part A is long and manual. Every later change should be re-checkable with one command.
- **Implement:**
  - `selftest` (no lab needed):
    - `bash -n` on `cks`, the hooks, the rootfs scripts and the seed template
    - `.claude/hooks/test-guards.sh`
    - shellcheck from a pinned `docker.io/koalaman/shellcheck` image run **in the VM** (`p run --rm --network none -v "$ROOT:$ROOT:ro" …`)
    - `plutil -lint`-style JSON parse of `.claude/settings.json`
    - the content grep (other certs, PDFs, absolute home paths, Bitnami)
  - `smoke` (lab must be up):
    - runs A2 and the scriptable rows of A4 (1–4, 10–14, 17) in a throwaway namespace `cks-smoke`
    - prints a PASS/FAIL table, cleans up, and exits non-zero on any FAIL
    - node-level rows (5–9) stay manual: they restart kube-apiserver
  - Reuse `tb`, `audit_local`, `cmd_node` and `with_timeout` from [cks](cks). Add both commands to `cmd_help` and to the `allow` list in `.claude/settings.json`.
- **Test:** green on a fresh lab. Temporarily break one check (e.g. a wrong expected value) and confirm it turns red with a clear message.
- **Constraints:** shellcheck runs with `--network none` and a read-only mount. Nothing is installed on the Mac.

### B2 Keep live work across destroy-every-time

- **Why:** every exit destroys the cluster, so `/grade` loses live evidence the learner created.
- **Implement:**
  - `snapshot_active` in `cks`, called by `finish_owner` and `cmd_down` *before* the reaper runs. For each task of the active session, it writes `sessions/<id>/tasks/<t>/.lab-snapshot/`:
    - `kubectl get all,netpol,role,rolebinding,sa,secret -n <task ns> -o yaml`, with Secret data redacted
    - copies of node files named in the rubric (kube-apiserver manifest, audit policy, kubelet config)
  - Rubric template: add a "Snapshot paths" section listing the node files to capture.
  - [/grade](.claude/skills/grade/SKILL.md) and [cks-grader](.claude/agents/cks-grader.md) use the snapshot when the lab is down ("Mode: files + snapshot").
  - Optional, opt-in `./cks reapply`: `kubectl apply -f` every `work/*.yaml` of the active session after a fresh cluster.
- **Test:** solve a task, `exit`, then `/grade` shows the live evidence from the snapshot. The snapshot never contains Secret values.
- **Constraints:** the snapshot stays under the gitignored `sessions/`. Teardown must still finish within about 20 s, so time-box the snapshot with `with_timeout`.

### B3 Task validation: are generated tasks solvable and is the rubric right?

- **Why:** an LLM-generated rubric can be wrong. Catching that before the learner starts saves frustration.
- **Implement:**
  - [create-tasks](.claude/skills/create-tasks/SKILL.md) also writes `.meta/solution/` (manifests and node commands). It's hidden like the rubric; `/hint` still never reads `.meta/`.
  - `./cks validate <task>`:
    1. seed, then run every rubric probe: each must **fail**
    2. apply the solution, then run the probes: each must **pass**
    3. re-run the seed to restore the learner's starting point
  - create-tasks runs `validate` for each task when the lab is up, and reports only "validated" or "rubric fixed". No solution details.
- **Test:** a deliberately wrong probe (wrong namespace) is caught. A correct task validates without the learner seeing anything.
- **Constraints:** `.meta/solution/` is under gitignored `sessions/`. `/grade` and `/explain-solution` rules stay unchanged.

### B4 Pull-through image cache in the VM

- **Why:** every fresh cluster pulls the same images again. That's slower, adds outbound traffic, and risks Docker Hub rate limits.
- **Implement:**
  - A `cks-cache` container (`registry:2` / CNCF Distribution, Apache-2.0) on the `kind` network:
    - one pull-through proxy per upstream (docker.io, registry.k8s.io)
    - a persistent volume `cks-image-cache`
    - **no published port**
  - Node `hosts.toml`: the cache first, then `mirror.gcr.io`, then the upstream.
  - `cks-teardown` keeps the cache; `./cks purge` removes it.
- **Test:**
  - The second fresh start shows cache hits in `podman logs cks-cache`, and no layer downloads for task images.
  - Record warm-start time before and after.
  - `./cks verify-local` still passes, since the audit covers every container in the VM.
- **Constraints:** the cache lives only in the VM. It holds public images only, never credentials.

### B5 Local OCI registry for supply-chain tasks

- **Why:** "sign and validate artifacts" and "permitted registries" are best practised with a registry you control, fully offline.
- **Implement:**
  - Second role of the Distribution image: `cks-registry:5000` on the `kind` network (no published port).
  - Node `hosts.toml` entry for it (plain HTTP inside the VM network).
  - In the toolbox: `podman build` / `podman push` to it.
  - create-tasks can then use:
    - cosign image signing and verification (local keys, transparency log off)
    - ValidatingAdmissionPolicy that allows only `cks-registry:5000/`
    - trivy scans of locally built images
- **Test:**
  1. build and push an image
  2. `cosign sign --key …` offline
  3. `cosign verify` succeeds
  4. a ValidatingAdmissionPolicy admits `cks-registry:5000/app` and denies `nginx`
- **Constraints:** nothing leaves the VM. No signature is uploaded to a public log.

### B6 Exam realism

- **Why:** the real exam is timed and spread over several kubectl contexts.
- **Implement:**
  - `./cks exam start <minutes>` / `./cks exam stop`:
    - deadline stored in `.cks/run/exam-deadline`
    - the toolbox `PS1` shows the remaining minutes, and warns at 15 and 0
    - `/exam-session` offers to start it
    - `/grade` reports overtime
  - Contexts: after cluster creation, add per-task contexts to the toolbox kubeconfig (same cluster, a user/namespace per task). [create-tasks](.claude/skills/create-tasks/SKILL.md) states `kubectl config use-context <ctx>` at the top of each TASK.md, like the exam.
- **Test:**
  - the timer shows in every shell (including a second `./cks`) and survives `./cks reset`
  - context switching works
  - a task done in the wrong context fails `/grade` with a clear hint
- **Constraints:** none beyond the defaults (local files in `.cks/` only).

### B7 More live coverage (spikes with go/no-go)

| Spike | Go criterion | If no-go |
|---|---|---|
| Traefik (MIT) as `./cks addon ingress`, ClusterIP only | an Ingress with a TLS Secret answers `curl -k --resolve app.cks:443:<svc-ip> https://app.cks` from the toolbox | Ingress TLS stays spec-graded |
| gVisor `runsc` (Apache-2.0) in the node image as a containerd handler (`--platform=systrap`) | a pod with `runtimeClassName: gvisor` runs and `dmesg` shows gVisor | stays file-graded; document why |
| ImagePolicyWebhook with a tiny in-cluster backend (pinned, OSS) | the apiserver denies an image the backend rejects; `defaultAllow: false` behaves as documented | config-file grading only |

AppArmor needs no spike: the Podman VM kernel has no AppArmor LSM, so it stays file-graded.

### B8 Maintenance: `lab/bump.sh` (read-only report)

- **Why:** pinned versions age. Security fixes (e.g. for trivy) should be noticed, not missed.
- **Implement:** a script run in the toolbox (`./cks bump-report`). It queries upstream releases anonymously and prints:
  - current vs latest version and the new sha256 for every pinned tool and image digest
  - new security advisories for trivy, kind and cosign

  It **never edits files**; you or Claude apply bumps deliberately.
- **Test:** the output matches a manual check of one tool. Running it twice without network fails gracefully.
- **Constraints:** read-only, anonymous GitHub API (rate limit 60/h). No token.

### B9 Performance budget

- **Why:** destroy-every-time only works if starting again is quick.
- **Implement:**
  - measure and log (in `.cks/logs/timings.log`):
    - cold first run, warm start and teardown
    - `./cks kubectl get ns` round-trip
  - tune the `CKS_VM_CPUS` / `CKS_VM_MEMORY_MB` defaults and kind's `--wait`
- **Targets:** warm start ≤ 90 s (with B4), teardown ≤ 20 s, `./cks kubectl` overhead ≤ 0.5 s.
- **Test:** three consecutive warm starts stay within target. Record them in the Results log.

---

## Results log

| Date | Step | Result | Notes / fix commit |
|---|---|---|---|
| | A0 | | |
| | A1 | | VM init … s · builds … s · cluster … s |
| | A2 | | |
| | A3 | | VS Code window close fires SessionEnd: yes / no |
| | A4 | | Falco: live / fallback · cosign flags: … |
| | A5 | | telemetry opt-out honoured from project settings: yes / no |
| | A6 | | |
