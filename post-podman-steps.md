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
- [ ] `podman machine list` is empty. If the installer's last step made you run `podman machine init`, remove that VM
  (`podman-machine-default` shares all of `/Users`): `podman machine rm podman-machine-default`.
- [ ] Remove the installer's helper service, which the lab doesn't need: `sudo /opt/podman/bin/podman-mac-helper uninstall`.
- [ ] Record the baseline: `ls -la ~/.kube ~/.docker 2>&1`. Both should be absent or unchanged by the end of Part A.
- [ ] `./cks status` reports `VM 'cks': missing`.

### A1 First boot: `./cks` (Mac)

- [ ] Run `./cks` and note the duration of each phase in the Results log:
  - VM init
  - image builds (toolbox and node build in parallel)
  - cluster creation
- [ ] If macOS asks for Documents access for the VM helper (krunkit or vfkit), click **Allow**. From the VS Code terminal there is usually no prompt.
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

- [ ] `./cks verify-local` prints only ✔ lines, including "the VM shares only this project folder with the Mac".
- [ ] Cross-check by hand (Mac): `podman machine ssh cks findmnt -t virtiofs` lists only this project folder.
  (Podman 6.2's `machine inspect` no longer lists mounts.)
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
  - Also: `./cks up` with the bad file must refuse **before** starting anything (`audit_static` runs first since fix F3).
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
- [ ] Update the live-vs-file matrix ([README.md](README.md), [CLAUDE.md](CLAUDE.md)) and the cosign flags.
- [ ] Update [quick-start.md](quick-start.md) with real timings, the real macOS prompt wording, and the VS Code window-close answer.
- [ ] `bash .claude/hooks/test-guards.sh` and `/bin/bash -n cks` are green.
- [ ] Commit: `fix: podman bring-up`.

---

## Part B — Next features (priority order)

Each feature lists **Why**, **Implement**, **Test** and **Constraints**. Keep all `./cks` code bash 3.2 / BSD-userland compatible.
No feature may publish a port, write outside this folder, or need an account.

### B1 `./cks selftest` and `./cks smoke`: automate Part A ✅ done (2026-11-17)

> **Status:** implemented as planned. `./cks selftest`: 10 checks in about 10 s (ShellCheck v0.11.0 pinned by digest,
> `--network none`, read-only mount). `./cks smoke`: 18 checks in about 45 s (`lab/tests/smoke.sh`, runs in the toolbox).
> Negative test: a broken script with a syntax error and the F14 pattern made `selftest` fail with file and line.

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

### B2 Keep live work across destroy-every-time ✅ implemented (2026-11-17)

> **Status:** `lab/snapshot.sh` runs before every teardown, reset and leftover rebuild (about 1 s) and writes
> `sessions/<id>/.lab-snapshot/` per the task's `.meta/snapshot.conf` (fallback: `t<NN>-…` namespaces named in TASK.md).
> Secret values, `*/pki/*`, `*.key`, `*.pem` are never saved; `secret:`/`token:`/`password:` values are redacted.
> `/grade` and `cks-grader` grade "files + snapshot" when the lab is off. `./cks smoke` checks it (19 checks).
> Not done: the optional `./cks reapply` (applying `work/` YAML blindly could create static-pod copies as Pods).

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
| 2026-11-16 | A0 | pass | Podman 6.2.0, provider libkrun. The installer's `podman machine init` created `podman-machine-default` (shares all of `/Users`, `/private`, `/var/folders`); removed before the run. Baseline: `~/.kube/config` dated 2 Feb 2026, 5638 bytes; `~/.docker` absent |
| 2026-11-16 | A1 (simple run) | pass | `./cks` from the VS Code terminal: VM + both images ≈ 1–2 min, cluster ≈ 2 min, **about 4 min in total** to the exam shell. 2 nodes Ready on v1.37.0, containerd 2.3.4, Fedora kernel 7.2. **No macOS Documents prompt appeared** (the VS Code terminal already has access). trivy 0.76.2 in the exam shell (not on nodes, as intended) |
| 2026-11-16 | A2 (partial) | pass, 1 finding | **Shares (checked inside the VM with findmnt):** only the project folder; the VM sees 1 entry in Documents vs 58 on the Mac; nodes have no `/Users`. **Ports:** only the API is published, on `127.0.0.1:32897`. **Mac:** no non-loopback TCP listener at all; gvproxy/krunkit listen on loopback only. **Images:** docker.io pull via `mirror.gcr.io` works (test pod Running in 4 s). **After purge:** `~/.kube/config` and `~/.docker` unchanged. **Finding F1** below |
| 2026-11-16 | A3 (partial) | pass | `exit` → Enter: cluster and toolbox deleted, VM stopped about 20 s later, no lock/owner files left. `./cks purge`: no VMs, connections, VM processes or `.cks/` remain. Other lifecycle cases not run yet |
| 2026-11-16 | Re-run after fixes | pass | `podman-mac-helper` removed (no launch daemon or process; stale socket file in `/var/run` has no listener and is cleared on reboot). Images rebuilt automatically; nodes Ready on v1.37.0 about 75 s after cluster start. **Documents boundary, checked without reading anything above `…/GitHub/Personal`:** krunkit is configured to share exactly one folder (the project); VM processes hold no open files in Documents outside the project; the VM, the exam-shell container and the mount tables show only the project folder; the VM's `…/Personal` is the VM's own disk (`/`, xfs), not the Mac folder; nodes have no Mac folders; no symlinks in the project. `verify-local`: ✔ API on 127.0.0.1 only, ✔ VM shares only the project folder (**F1 verified**). Typing `trivy` on a node shows the exam-shell hint (**F6 verified**). Teardown: cluster and toolbox deleted, VM stopped |
| 2026-11-16 | A3 (rest) | pass, 3 findings fixed | Ctrl-D ignored (bash says "Use logout"); `exit`/`logout` → `n` returns to the shell; a second `./cks` opens an extra shell and leaves the lab untouched. `./cks reset` with the shell attached: 57 s, audit passed, shell kept working (`k get nodes` OK). VM stop/start with a kept lab: nodes stay stopped (restart policy `no`). **Tab close:** first killed the VM (F13), after the fix the clean teardown runs (deleting cluster, then stopping VM). Take-over: a lab started by Claude (`./cks up`, 48 s warm start) is taken over by `./cks` without a rebuild. Findings F13–F15 below |
| 2026-11-17 | A3 Claude session end | pass, 1 finding fixed | Tested with a throwaway second chat tab, evidence in `.cks/logs/session-end.log`. **`/clear`** → `reason=clear`, ignored, lab kept ✅. **Closing a chat tab** ends the session → `reason=other` → a lab started without a `./cks` shell (`./cks up`) is torn down ✅ (VM stopped about 20 s later). Opening a tab causes no event. Two unexplained `reason=other` events at 11:03:59/11:04:00 (while the lab was starting) did not recur. **F16** below |
| | A3 VS Code window close | | Leave the lab running at the end of a day and quit VS Code (Cmd+Q); next session: read `.cks/logs/session-end.log`. Fires SessionEnd: yes / no |
| 2026-11-17 | B1 | pass | `./cks selftest`: syntax (17 scripts), bash 3.2 UTF-8 and syntax pitfalls, 80 guard tests, JSON, kind config, tracked files, CKS-only, no home paths, ShellCheck errors: all PASS. ShellCheck warnings reviewed once: 1 dead variable and 1 masked return value fixed, template placeholders intended. `./cks smoke`: 18/18 PASS in 42 s (API, nodes, NetworkPolicy, read-only root fs, seccomp RuntimeDefault, RBAC, PSA, VAP, kube-bench, etcdctl, registry mirror, kubelet checksum, kubesec/kube-linter/cosign offline, trivy, SBOM) |
| 2026-11-17 | B2 | pass | Files written by the lab into the project belong to the Mac user (uid 501), deletable without sudo. Snapshot takes about 1 s. Smoke check (19/19): objects and node files saved, a Secret with a known value is not in the snapshot (neither plain nor base64), `pki/ca.key` requested via snapshot.conf is refused. **End to end:** the learner labelled `t02-gallery` in the exam shell → `exit` → teardown log shows "Saving a snapshot…" before deletion → `/grade 02` with the lab off: "Mode: files + snapshot", labels pass, Deployment still insecure → PARTIAL 2/5 (before B2: files only, 0/5). Namespace fallback from TASK.md (`t<NN>-…`) worked, since the drill predates snapshot.conf |
| 2026-11-16 | A4 | pass (18/18 live), 2 findings fixed | 1 NetworkPolicy deny-all enforced (kindnet) · 2 RBAC `can-i` no · 3 PSA restricted rejects (4 violations listed) · 4 read-only root fs · 5 encryption at rest: etcd value `k8s:enc:aescbc:v1:key1`, plaintext absent · 6 seccomp Localhost pod Running · 7 audit log fills (1982 lines) · 8 NodeRestriction on; anonymous `/version` 200 → 401 with `--anonymous-auth=false`, apiserver stable 2 min · 9 kubelet `streamingConnectionIdleTimeout` 0s → 5m0s, picked up after restart · 10 kube-bench 43 PASS / 9 FAIL / 8 WARN · 11 VAP denies nginx, admits registry.k8s.io · 12 trivy 61 s (DB download), then 2 s (cache volume) · 13 kube-linter 8 errors offline; kubesec needed GitHub (F8) · 14 bom SPDX, 31 packages · 15 cosign offline only with a local signing config (F9) · 16 kubelet sha256 matches dl.k8s.io · 17 docker.io pull via mirror · 18 **Falco live** (modern eBPF on the libkrun kernel; detects reading `/etc/shadow`) |
| 2026-11-16 | A5 | pass, 3 findings fixed | Denied automatically: reads in `~/.ssh` and `~/.kube` (probed with non-existent file names), MCP connectors (none available). Prompted (you denied): `git push`, web access, writing into `work/` (folder stayed empty). Guard blocks `kubectl` and tunnels in a subagent too. `/create-tasks 2 warmup`: session created and seeded. `/hint` ×2 → `.meta/hint-level` 1 → 2. `/grade` session: 2 parallel `cks-grader`s, FAIL 0/4 + 0/5 as expected (empty `work/`), delete attempt blocked, SESSION.md + `state/progress.md` written. `/explain-solution 01`: walkthrough in chat, nothing in `work/`. `/exam-session` skipped (its parts are covered; use it as the first real mock). Telemetry opt-out from project settings: **unverified** (not observable from inside); set the same variables in your user settings if you want certainty |
| 2026-11-16 | A6 | done | All findings F1–F15 fixed; docs, matrix, timings updated; guard tests 80/80; committed (not pushed) |

### Findings from the Part A test runs (2026-11-16)

| # | Finding | Impact | Fix (✅ = done and verified) |
|---|---|---|---|
| F1 ✅ | `podman machine inspect` (6.2) has no `Mounts` field, so `verify-local` only warns "could not list the folders shared with the VM", and `./cks status` prints `?` | the shared-folder check is not enforced | read the real shares from inside the VM: `podman machine ssh cks findmnt -rn -t virtiofs -o TARGET` (verified: returns exactly the project folder); fail closed when it can't be read |
| F2 ✅ | `guard.sh` splits commands on `;`, `&&` and `\|` even inside quotes, so a quoted `sh -c '… && trivy …'` was blocked as a Mac command | false positives for Claude | reuse the quote-aware neutraliser from `grader-guard.sh` before splitting; add test cases |
| F3 ✅ | The static `lab/kind.yaml` check runs only after the cluster is created (known gap) | a bad config would exist briefly | run the static audit first in `cmd_up` |
| F4 ✅ | No macOS Documents prompt when started from the VS Code terminal | quick-start says to expect one | reword: "macOS *may* ask…" |
| F5 ✅ | The Podman `.pkg` installer also installed **podman-mac-helper** as a root launch daemon (`/Library/LaunchDaemons/com.github.containers.podman.helper-<user>.plist`, socket `/var/run/podman-helper-<user>.socket`) plus `/etc/paths.d/podman-pkg`. VM start then printed "Another process was listening on the default Docker API socket address" | local Unix socket only, no network exposure; but it is a system-level component the lab doesn't need | quick-start: say the installer adds it and how to remove it (`sudo /opt/podman/bin/podman-mac-helper uninstall`); include it in the uninstall section |
| F6 ✅ | `trivy` typed inside `ssh cks-control-plane` gave "command not found" | user confusion | show a one-line note when entering a node shell ("you're on node …; tools like trivy are in the exam shell; `exit` to return") |
| F7 ✅ | `guard.sh`: a quoted assignment value with a space (`K="./cks kubectl"`) was read as the command `kubectl` | false positive | spaces inside quotes are part of the word |
| F8 ✅ | **kubesec downloads JSON schemas from GitHub on every scan**; offline it silently returns "score 0" | outbound request per scan (download only, no upload); misleading results offline | schemas (pinned commit, sha256-verified) bundled in the toolbox; a `kubesec` wrapper uses them. Verified with `--network none`: score −39 with correct findings |
| F9 ✅ | **cosign 3 has no `--tlog-upload`**; a plain `cosign sign-blob --key …` would publish to Sigstore's public transparency log | privacy: signature metadata to a public log | `cosign` wrapper adds a local signing config (no tlog, no TSA, no CA). Verified offline: sign, verify (`--insecure-ignore-tlog=true`), tamper rejected, keyless refused |
| F10 ✅ | create-tasks said to create `work/.gitkeep`, which triggers the `work/` ask prompt (and sessions are gitignored) | needless prompt | create empty `work/` folders with mkdir |
| F11 ✅ | `cks-grader` couldn't list `work/` (no `ls`) and guessed file names | slower, less reliable grading | grader instructions: list with the Glob tool |
| F12 ✅ | `grader-guard.sh` blocked the rubric probe `auth can-i delete …` because of the word `delete` | read-only RBAC checks not gradable live | `auth can-i` / `auth whoami` allowed directly after kubectl; `auth reconcile` now blocked |
| F13 ✅ | **Closing the terminal tab killed the VM** (krunkit/gvproxy stayed in the terminal's session) before the teardown could delete the cluster | unclean shutdown, leftovers in the VM | VM started in its own session (`in_new_session`); verified: VM processes have no terminal, tab close runs the full clean teardown |
| F14 ✅ | `./cks` crashed with `s…: unbound variable` once an active session existed: macOS bash 3.2 read the bytes of `…` as part of `$s` | crash after cluster creation, before seeding and the audit | `${s}…`; no other occurrences |
| F16 ✅ | The SessionEnd reason filter lived in the settings `matcher`, so ignored calls (`/clear`) left no trace and Test 1 could not be proven | no evidence | the hook runs for every reason, ignores `clear`/`resume` itself and logs every call to `.cks/logs/session-end.log` |
| F15 ✅ | An outdated toolbox was never replaced on `./cks`, because the starting process already counted as "owner" | fixes in the toolbox image not picked up | only a *different* live owner keeps the old toolbox |
