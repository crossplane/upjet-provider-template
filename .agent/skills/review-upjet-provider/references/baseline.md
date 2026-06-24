# Baseline: what an official Upbound Upjet provider looks like

The reference standard, distilled from `upbound/provider-upjet-{aws,azure,gcp}`. Use this so the
review is **self-contained** — you do not need an official provider checked out to compare against.
Evidence anchors are relative paths that are consistent across all three official providers.

> Terminology: a resource's **`example-id`** is the value of the `meta.upbound.io/example-id`
> annotation, formatted `<group>/<version>/<resource>` (e.g. `pubsub/v1beta1/topic`). It is the key
> uptest uses to select an example, and the correct join key when comparing example sets.

---

## Profiles — detect first (SKILL step 1)

These four axes decide which checklist items apply. Read the signal, record the value, and state it
in the report. A legitimately "lower" profile must NOT be failed for missing higher-profile features.

| Axis | Where to read the signal | Values & meaning |
|---|---|---|
| **Generator** | `go.mod` require block | `github.com/crossplane/upjet` or `/v2` (modern, expected) vs `crossplane-contrib/terrajet` (legacy — most checks below won't map). |
| **Generation backend** | which maps exist in `config/externalname*.go` | `TerraformPluginSDKExternalNameConfigs` (SDKv2), `TerraformPluginFrameworkExternalNameConfigs` (TF plugin framework), `CLIReconciledExternalNameConfigs` / "no-fork". A provider may use more than one. Tells you which connector + external-name map to expect. |
| **Crossplane model** | presence of `apis/namespaced/`, `.m.` group suffix, `crossplane-runtime/v2` in `go.mod` | **v2** = dual `apis/cluster/` + `apis/namespaced/` trees with `<svc>.<prov>.upbound.io` (cluster) and `<svc>.<prov>.m.upbound.io` (namespaced) groups, two ProviderConfig kinds. **v1** = single cluster-scoped tree, `crossplane-runtime` v1. v2 gates Category 5. |
| **Packaging** | multiple `cmd/provider/<svc>/` dirs, `SUBPACKAGES` in `Makefile`, `provider-family-*` label in `package/crossplane.yaml.tmpl` | **family** = monolith (often deprecated) + per-service packages + a `provider-family-<prov>` config package. **monolith-only** = single binary. family gates Category 6 family items. |
| **Build system** | `.gitmodules`, `Makefile` includes | **standard** = `build/` submodule → `github.com/crossplane/build`, Makefile includes `build/makelib/{common,golang,k8s_tools,imagelight,xpkg}.mk`. **custom** = anything else (raises risk; most makelib-derived checks become "verify manually"). |

---

## Category 1 — Repository structure & build system

**Convention.** Standard top-level layout: `apis/ config/ internal/ cmd/ examples/ examples-generated/
package/ build/ hack/ cluster/test/ generate/ .github/`. `build/` is a **git submodule** pointing at
`https://github.com/crossplane/build`. The `Makefile` defines `PROVIDER_NAME`, `PROJECT_REPO`
(`github.com/<org>/provider-<name>[/v2]`), `TERRAFORM_PROVIDER_SOURCE/VERSION`,
`PLATFORMS := linux_amd64 linux_arm64`, `SUBPACKAGES ?= monolith`, `GO_SUBDIRS += cmd internal apis generate`,
and includes the makelib `.mk` files. `go.mod` pins `upjet`, `crossplane-runtime`, and the
`terraform-provider-<x>` at coherent versions on a current Go toolchain.

**Evidence anchors.** `.gitmodules`; `Makefile` (var block + `include build/makelib/*.mk`); `go.mod`.

**Tier rationale.** Standard layout + reproducible build = MUST. The `crossplane/build` submodule
specifically is SHOULD (custom but equivalent build systems exist). Version *currency* is NICE.

---

## Category 2 — Code-generation pipeline

**Convention.** Generation is reproducible and not hand-maintained. `cmd/generator/main.go` loads the
config provider(s) (`config.GetProvider()` and, for v2, `config.GetProviderNamespaced()`) and runs
upjet's `pipeline.Run`. `generate/generate.go` orchestrates: scrape TF docs → `config/provider-metadata.yaml`;
run the generator; `controller-gen` for deepcopy + CRDs; `crossplane-tools/angryjet` for method sets;
upjet `resolver` for cross-group references. The TF schema is captured at `config/schema.json`. All
generated files are prefixed `zz_` and carry a `// Code generated ... DO NOT EDIT.` header. A
`config/generated.lst` (or equivalent) records the generated resource list.

**Evidence anchors.** `cmd/generator/main.go`; `generate/generate.go`; `config/schema.json`;
`config/provider-metadata.yaml`; any `apis/**/zz_*_types.go` header; `config/generated.lst`.

**Tier rationale.** Working `cmd/generator` + `generate.go` + `zz_`/DO-NOT-EDIT markers = MUST
(without these the provider can't be regenerated/maintained). Resolver + metadata scraping = SHOULD.

---

## Category 3 — External-name & resource configuration

**Convention.** `config/externalname.go` holds the external-name map(s) keyed by Terraform resource
name. Resources should use a *meaningful* external-name strategy (`NameAsIdentifier`,
`TemplatedStringAsIdentifier`, `IdentifierFromProvider`, custom extractors) — not a blanket
`IdentifierFromProvider` for everything. Per-service `config/<scope>/<svc>/config.go` files expose a
`Configure(p *config.Provider)` that registers references, late-init, sensitive fields, etc., and are
collected via a registry (`ProviderConfiguration.AddConfig(...)`). Group/Kind overrides live in
`config/groups.go` / `config/overrides.go` (e.g. `ReplaceGroupWords`). Untested external names are
tracked explicitly (`config/externalnamenottested.go`) rather than silently mixed in.

**Evidence anchors.** `config/externalname.go`; `config/<scope>/<svc>/config.go`;
`config/<scope>/provider.go` (registry); `config/overrides.go`/`groups.go`; `config/externalnamenottested.go`.

**Tier rationale.** External-name map present & resources configured = MUST. Registry pattern +
references + group overrides = SHOULD. Explicit untested-name segregation = NICE.

---

## Category 4 — API types & versioning

**Convention.** `apis/<scope>/<svc>/<version>/` with stored versions `v1beta1`+ (no `v1alpha1` as the
sole/stored version for mature resources). Generated `zz_*_types.go`, `zz_*_terraformed.go`,
`zz_generated.{deepcopy,managed,managedlist}.go`. When a service has multiple versions, conversion is
wired (`zz_generated.conversion_hubs.go` / `conversion_spokes.go`). A hand-written ProviderConfig API
(`types.go` + `register.go`) exists per scope. `zz_register.go` aggregates all groups into the scheme.

**Evidence anchors.** `apis/<scope>/<svc>/<version>/zz_*_types.go`; `apis/<scope>/<version>/types.go`
(ProviderConfig); `apis/<scope>/zz_register.go`; any `zz_generated.conversion_*.go`.

**Tier rationale.** Versioned API tree + ProviderConfig types + scheme registration = MUST.
`v1beta1`+ maturity (not alpha) and conversion webhooks for multi-version = SHOULD.

---

## Category 5 — Crossplane v2 scope architecture  *(gate: v2 only)*

**Convention.** v2 providers ship **dual scopes**: `apis/cluster/` (groups `<svc>.<prov>.upbound.io`,
cluster-scoped) and `apis/namespaced/` (groups `<svc>.<prov>.m.upbound.io`, namespaced). `config/` is
likewise split `cluster/` + `namespaced/`, each with its own `provider.go`/registry. Two ProviderConfig
kinds exist (a cluster `ProviderConfig` and the namespaced one). The binary wires up both managers /
schemes.

**Evidence anchors.** `apis/cluster/` & `apis/namespaced/`; `+groupName=<svc>.<prov>.m.upbound.io` in
namespaced `zz_groupversion_info.go`; `config/cluster/` & `config/namespaced/`; `cmd/provider/*/zz_main.go`.

**Tier rationale.** For a v2 provider: dual scope + both ProviderConfigs = MUST. For a v1 provider:
**entire category N/A** — optionally note "consider v2 namespaced migration" as NICE, never a failure.

---

## Category 6 — Family provider & packaging

**Convention.** `package/crossplane.yaml.tmpl` or `package/crossplane.yaml` declares `capabilities: [SafeStart]`, maintainer/source/
license annotations, a Crossplane version constraint, and (for family members) the
`pkg.crossplane.io/provider-family-<prov>` label + `dependsOn` the `provider-family-<prov>` config
package. `package/crds/` holds generated CRDs (+ `package/kustomize/`).
Family providers build per-service packages via `SUBPACKAGES` and publish to `xpkg.upbound.io/<org>`.
Family provider layout should only be used for providers with a high amount of resources (>100) that do not have many cross-group references (e.g. group `compute` does not strongly depend on references to group `network`)

**Evidence anchors.** `package/crossplane.yaml.tmpl`; `package/crossplane.yaml`; `package/crds/`;
`Makefile` (`SUBPACKAGES`, xpkg targets); `.github/workflows/publish-provider-packages.yaml`.

**Tier rationale.** Valid package metadata + generated CRDs + RBAC = MUST. `SafeStart` capability =
SHOULD. Family split (`provider-family-*`, per-service packages) = SHOULD **only if multi-service**;
for a small/monolith-only provider, family items are N/A.

---

## Category 7 — Controller runtime wiring

**Convention.** Generated controllers expose `Setup` **and** `SetupGated` (SafeStart — controllers
register through a gate keyed on CRD availability). `internal/features/features.go` defines
`EnableBetaManagementPolicies`. `internal/clients/<prov>.go`
provides a `TerraformSetupBuilder` resolving ProviderConfig credentials from multiple sources
(Secret / env / filesystem / IRSA-or-impersonation / Upbound federation). `internal/bootcheck` runs in
`init()`. `cmd/provider/*/zz_main.go` exposes the standard flags: `--debug`, `--sync` (1h), `--poll`
(10m), `--poll-state-metric` (5s), `--max-reconcile-rate` (100), `--leader-election`,
`--enable-management-policies` (true), `--enable-changelogs` (false), webhook/metrics/health bind addrs.
`ProviderConfigSpec` exposes `ReconciliationPolicy` from `github.com/crossplane/upjet/v2/apis/configuration/v1alpha1`

**Evidence anchors.** `internal/controller/**/zz_*setup.go` (Setup + SetupGated); `internal/features/features.go`;
`internal/clients/<prov>.go`; `internal/bootcheck/`; `cmd/provider/*/zz_main.go`;` apis/*/v1beta1/types.go`; flag block.

**Tier rationale.** Controller Setup + credential-resolving client + ProviderConfig usage = MUST.
SafeStart (`SetupGated`), management-policies, standard flag set = SHOULD. ReconciliationPolicy = NICE.

---

## Category 8 — Examples & e2e coverage

**Convention.** **Both** `examples/` and `examples-generated/` exist.
- `examples-generated/` is the upjet auto-generated set — exactly **one example per resource**, every
  file carrying a `meta.upbound.io/example-id`. It is regenerated by `make generate` and represents
  "all generatable resources".
- `examples/` is the **human-curated** set that uptest actually runs end-to-end. A maintainer copies a
  generated example here and edits it so it really works (real values, dependency resources). Examples
  carry `meta.upbound.io/example-id`, `testing.upbound.io/example-name`, and where relevant
  `upjet.upbound.io/manual-intervention: <reason>` (resources that legitimately cannot be auto-e2e-tested).
  `<reason>` of manual intervation should be descriptive for future human and agent developers.

**The coverage metric** (compute it; see `commands.md` §Examples). Let `G` = set of `example-id`s in
`examples-generated/`, `E` = set of `example-id`s in `examples/`.
- **e2e-tested = `|G ∩ E|`** — resources with both a generated and a curated example.
- **coverage% = `|G ∩ E| / |G|`** — the raw headline (tested over all generated).
- **untested gap = `G \ E`** — generated but never curated → **not e2e tested**. List these, and split
  the gap by manual-intervention: `gap_manual` = ids annotated `upjet.upbound.io/manual-intervention`
  (expected — can't be auto-e2e-tested) vs **`gap_actionable`** = the rest (the real coverage debt).
  Do the manual-intervention adjustment **on the gap, not the denominator** — manual-intervention
  examples are usually curated (so they sit in `E`, not in the gap); subtracting them from the
  denominator would double-count and inflate the percentage.
- `E \ G` (curated with no generated twin) is usually hand-written or stale — note, don't fail.
- The two dirs use **different layouts** (`examples-generated/` is split `cluster/`+`namespaced/`;
  `examples/` is often per-service legacy layout and may hold multiple files per resource) — that is
  why you join on `example-id`, not on path or file count.
- **Content-diff signal:** for ids in `G ∩ E`, the curated file should *differ* from its generated
  twin (a human filled it in). A byte-identical copy is "promoted but possibly not curated" — flag it.

**Reference point (official `provider-upjet-aws`, at analysis time):** `|G|`≈1329, `|G ∩ E|`≈1130
(tested) → **raw coverage ≈ 85%**; untested gap `|G \ E|`≈199 — for AWS almost all *actionable*, because
its manual-intervention examples are curated (they live in `E`, not the gap). Use as a sanity scale, not
a hard threshold.

**Evidence anchors.** `examples/`, `examples-generated/`; the three annotations; `cluster/test/setup.sh`.

**Tier rationale.** Both dirs exist + a real curated set + annotations = MUST. Healthy coverage
(uptest wired, gap reasonable) = SHOULD. Near-complete coverage = NICE. If `examples-generated/` is
absent (some v1 providers), coverage can't be computed this way — note the degrade and assess
`examples/` + uptest wiring qualitatively.

---

## Category 9 — Testing & linting

**Convention.** Unit tests are table-driven and co-located (`*_test.go`), notably for external-name
configs and shared `config/**/common`. `.golangci.yml` is golangci-lint **v2** enabling roughly
`errcheck, govet, gocyclo (min 10), gocritic, goconst, revive (confidence 0.8), staticcheck, unconvert,
unused, misspell, nakedret`, excludes generated `zz_*`, sets `goimports` local-prefix = module path,
and a long timeout (~90m). E2E is uptest-driven via `cluster/test/setup.sh` (seeds ProviderConfig(s),
reads `UPTEST_EXAMPLE_LIST`). Breaking-change guards `make crddiff` and `make schema-version-diff` exist.

**Evidence anchors.** `.golangci.yml` (read the enabled-linters list — not the file size);
`config/**/*_test.go`; `cluster/test/setup.sh`; `Makefile` (`uptest`, `crddiff`, `schema-version-diff`).

**Tier rationale.** A working `make test` + a real `.golangci.yml` linter set = MUST. uptest wiring +
crddiff/schema-version-diff = SHOULD. Broad unit-test coverage of config = NICE.

---

## Category 10 — CI/CD & governance

**Convention.** `.github/workflows/`: `ci.yml` runs detect-noop, lint, unit tests, a generate/`check-diff`
job (proves committed generated code matches `make generate`), and `report-breaking-changes`
(crddiff + schema-version-diff). `uptest-trigger.yml` runs e2e on a PR comment. `publish-provider-packages.yaml`
pushes packages to `xpkg.upbound.io/<org>` or to `xpkg.crossplane.io/<org>`. `tag.yaml`, `stale.yml` present. Governance: `OWNERS.md`/
`CODEOWNERS`, `LICENSE` (Apache-2.0), `README`, and credential docs.

**Evidence anchors.** `.github/workflows/{ci,uptest-trigger,publish-provider-packages,tag,stale}.y*ml`;
`OWNERS.md`/`CODEOWNERS`; `LICENSE`.

**Tier rationale.** CI that lints + tests + verifies generated-code-is-current = MUST. crddiff/schema
breaking-change job + publish workflow + uptest trigger = SHOULD. stale/tag automation, rich docs = NICE.
