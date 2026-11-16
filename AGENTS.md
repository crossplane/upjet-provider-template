# upjet-provider-template — Agent Guide

This is a **Crossplane v2 Upjet provider template**. It wraps any Terraform provider and generates cluster-scoped and namespaced Crossplane managed resources from a declarative config, with no hand-written controllers.

> **Bootstrap**: If you are setting up a new provider from this template, invoke the `bootstrap-upjet-provider` skill before touching any files.
> **Adding a resource**: Use the `add-upjet-resource` skill.

---

## Architecture

### Dual-scope generation

Every resource is generated **twice** from the same `config/`:

| Scope | Root group | ProviderConfig kind | API version example |
|---|---|---|---|
| Cluster | `template.crossplane.io` | `ProviderConfig` | `null.template.crossplane.io/v1alpha1` |
| Namespaced | `template.m.crossplane.io` | `ClusterProviderConfig` | `null.template.m.crossplane.io/v1alpha1` |

`config/provider.go` calls `GetProvider()` (cluster) and `GetProviderNamespaced()` (namespaced). The generator in `cmd/generator/main.go` runs `pipeline.Run(GetProvider(), GetProviderNamespaced(), rootDir)`.

CRD group formula: `<shortGroup>.<rootGroup>` — e.g. short group `null` + root group `template.crossplane.io` → `null.template.crossplane.io`.

### Codegen pipeline

`make generate` runs these steps in order:
1. Downloads Terraform ≤1.5 via `build/` submodule tools.
2. Initialises a minimal `.work/terraform/main.tf.json` and runs `terraform providers schema -json` → **`config/schema.json`** (do not edit).
3. Clones the TF provider repo (sparse, tag pinned) and scrapes its docs → **`config/provider-metadata.yaml`** (do not edit).
4. Runs `go generate ./apis/...` which invokes:
   - `cmd/generator/main.go` → rewrites `apis/cluster/`, `apis/namespaced/`, `internal/controller/cluster/`, `internal/controller/namespaced/`, `examples-generated/`, `config/generated.lst`.
   - `controller-gen` → `package/crds/`.
   - `angryjet` → managed-resource methodsets.

---

## Repository structure

```
config/
  provider.go               ← resourcePrefix, modulePath, WithRootGroup, group imports  ✏️
  external_name.go          ← ExternalNameConfigs (also gates generation include list)  ✏️
  schema.json               ← TF provider schema                                        🚫 generated
  provider-metadata.yaml    ← scraped TF provider docs                                  🚫 generated
  generated.lst             ← list of generated resource names                          🚫 generated
  cluster/<group>/config.go ← per-group AddResourceConfigurator (cluster scope)         ✏️
  namespaced/<group>/config.go ← same, namespaced scope (must match cluster)            ✏️
  cluster/provider.go       ← registers group Configure functions (cluster)             ✏️
  namespaced/provider.go    ← registers group Configure functions (namespaced)          ✏️

apis/
  cluster/                  ← generated API types (zz_* files)                          🚫 generated
  namespaced/               ← generated API types (zz_* files)                          🚫 generated
  generate.go               ← //go:generate directives that drive make generate         ✏️ rarely

internal/
  clients/                  ← TF setup fn; provider credential extraction               ✏️
  controller/cluster/       ← generated controllers                                     🚫 generated
  controller/namespaced/    ← generated controllers                                     🚫 generated
  features/                 ← feature flags                                             ✏️ rarely

cmd/
  generator/main.go         ← runs pipeline.Run(GetProvider(), GetProviderNamespaced()) ✏️ rarely
  provider/main.go          ← provider binary entry point                              ✏️ rarely

package/
  crossplane.yaml           ← provider name in the OCI package                         ✏️
  crds/                     ← generated CRD manifests                                  🚫 generated

examples/
  cluster/<group>/          ← curated E2E examples (cluster scope)                     ✏️
  namespaced/<group>/       ← curated E2E examples (namespaced scope)                  ✏️
  cluster/providerconfig/   ← ProviderConfig + Secret template                         ✏️
  namespaced/providerconfig/← ProviderConfig + ClusterProviderConfig + Secret template ✏️
  install.yaml              ← provider install manifest                                ✏️

examples-generated/         ← raw generated examples (starting point only)             🚫 generated

cluster/test/setup.sh       ← E2E cluster setup: creates Secret + ProviderConfig       ✏️

Makefile                    ← provider knobs at the top (see below)                    ✏️
build/                      ← crossplane/build submodule — do not edit                 🚫 submodule
```

`✏️` = hand-written (safe to edit). `🚫` = generated or submodule (never edit directly).

---

## Makefile knobs

These variables at the top of `Makefile` must be updated when bootstrapping a new provider:

```makefile
PROJECT_NAME                   # repo name, e.g. provider-upjet-aws
TERRAFORM_PROVIDER_SOURCE      # TF registry source, e.g. hashicorp/aws
TERRAFORM_PROVIDER_REPO        # git clone URL for pulling docs
TERRAFORM_PROVIDER_VERSION     # TF provider version (must be < 1.6 licensed)
TERRAFORM_PROVIDER_DOWNLOAD_NAME  # binary name on releases.hashicorp.com
TERRAFORM_NATIVE_PROVIDER_BINARY  # binary filename with version suffix
TERRAFORM_DOCS_PATH            # relative path to docs dir inside the TF provider repo
```

`PROJECT_REPO` is derived as `github.com/crossplane/$(PROJECT_NAME)` — update it if the Go module path differs from this pattern.

---

## Key commands

```bash
# After any fresh clone or worktree — MUST run first
git submodule update --init --recursive

# Full codegen (schema pull + doc scrape + code generation)
make generate

# Run only the Go generator (schema + metadata already present)
go run cmd/generator/main.go "$PWD"

# Verify compilation
go build ./...

# Run provider out-of-cluster (needs a kubeconfig)
make run

# E2E test (builds provider, spins up a KinD cluster, runs uptest/chainsaw)
UPTEST_EXAMPLE_LIST="examples/cluster/<group>/<kind>.yaml" \
UPTEST_CLOUD_CREDENTIALS="$(cat path/to/creds.json)" \
UPTEST_DATASOURCE_PATH="path/to/datasource.ini" \
make e2e

# After any E2E run — ALWAYS clean up in this order
kubectl delete managed --all --all-namespaces
kind delete cluster --name local-dev
```

---

## Config key concepts

### ExternalNameConfigs gates generation

A resource absent from `config/external_name.go` is **never generated**, even if it is in `GroupMap`. Adding a resource here is always step one.

### Group and Kind naming

Upjet derives `shortGroup` and `Kind` from the TF resource name by default (strips the provider prefix, splits on `_`). Override via:
- `config/groups.go` `GroupMap` — if the provider uses versioned or multi-word group names.
- `r.ShortGroup` / `r.Kind` inside an `AddResourceConfigurator` call.

### References

Cross-resource references (`r.References["field"] = config.Reference{...}`) go in both `config/cluster/<group>/config.go` AND `config/namespaced/<group>/config.go`. These files must stay in sync.

### Sensitive fields

Any TF attribute marked `Sensitive: true` becomes `<field>SecretRef` in the CRD (references a `v1/Secret`). The plain field name is absent from `forProvider`. Check CRD `keys` when a field seems missing.

---

## E2E setup

`cluster/test/setup.sh` runs during `make e2e`. It:
1. Creates a `provider-secret` Secret in `crossplane-system` from `$UPTEST_CLOUD_CREDENTIALS`.
2. Applies a `ProviderConfig` (cluster scope) and a `ProviderConfig` (namespaced scope, in `crossplane-system`).

Update this file to match the new provider's auth structure when bootstrapping.

The `UPTEST_DATASOURCE_PATH` ini file resolves `${data.<key>}` placeholders in example YAML files (e.g. `parentId: ${data.aws_account_id}`).

---

## Crossplane v2 notes

- Both scopes are `SafeStart`-capable (`package/crossplane.yaml`).
- Cluster-scoped ProviderConfig kind for namespaced resources is **`ClusterProviderConfig`** (not `ProviderConfig`).
- Managed resources in the namespaced scope reference it with `providerConfigRef.kind: ClusterProviderConfig`.
- Namespace for namespaced managed resources and Secrets: **`upbound-system`** in examples (or whatever namespace the user creates them in).
