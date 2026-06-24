# Checklist — tiered, profile-gated

Walk every item. For each, record **status** (✅ pass / ❌ fail / ⚠️ partial / N-A), **evidence**
(`file:line` or command output), and a one-line **remediation**. Tier meanings and verdict gating are
in `SKILL.md`. "Gate" = the profile axis that makes an item apply (see `baseline.md` §Profiles); if the
profile doesn't match, mark the item **N-A**, don't fail it. Full conventions + evidence anchors per
item are in `baseline.md` (same category numbers).

Legend — Tier: **M**=MUST, **S**=SHOULD, **N**=NICE.

## 0. Gate — is this an Upjet provider?
| ID | Check | How |
|---|---|---|
| 0.1 | `go.mod` requires `crossplane/upjet[/v2]` | `grep upjet go.mod` |
| 0.2 | Has `config/`, `apis/`, `Makefile` | `ls` |

If 0.1 fails → stop; this skill does not apply.

## 1. Repository structure & build system
| ID | Item | Tier | Gate | How to check |
|---|---|---|---|---|
| 1.1 | Standard top-level layout (`apis config internal cmd examples examples-generated package build hack cluster/test generate .github`) | M | — | `ls` |
| 1.2 | `go.mod` requires `upjet`, `crossplane-runtime`, `terraform-provider-<x>` at coherent versions | M | — | `go.mod` |
| 1.3 | `Makefile` defines `PROVIDER_NAME`, `PROJECT_REPO`, `TERRAFORM_PROVIDER_SOURCE/VERSION`, `PLATFORMS`, `SUBPACKAGES`, `GO_SUBDIRS` | M | — | read `Makefile` head |
| 1.4 | `build/` is a submodule → `github.com/crossplane/build`; Makefile includes `build/makelib/*.mk` | S | standard build | `.gitmodules`, `grep makelib Makefile` |
| 1.5 | Dependency versions reasonably current (Go, upjet, runtime) | N | — | `go.mod` (informational only) |

## 2. Code-generation pipeline
| ID | Item | Tier | Gate | How to check |
|---|---|---|---|---|
| 2.1 | `cmd/generator/main.go` loads config provider(s) + runs upjet `pipeline.Run` | M | — | read file |
| 2.2 | `generate/generate.go` orchestrates controller-gen + angryjet (+ resolver) | M | — | read file |
| 2.3 | Generated files prefixed `zz_` with `DO NOT EDIT` header | M | — | `head apis/**/zz_*_types.go` |
| 2.4 | TF schema captured (`config/schema.json`) + metadata (`config/provider-metadata.yaml`) | S | — | `ls config/` |
| 2.5 | upjet `resolver` step present (cross-group refs) | S | — | `grep resolver generate/generate.go` |
| 2.6 | Generated resource list recorded (`config/generated.lst` or similar) | N | — | `ls config/` |

## 3. External-name & resource configuration
| ID | Item | Tier | Gate | How to check |
|---|---|---|---|---|
| 3.1 | `config/externalname.go` external-name map(s) present & populated | M | — | read file |
| 3.2 | Resources use meaningful external-name strategies (not blanket `IdentifierFromProvider`) | S | — | scan map; ratio of `IdentifierFromProvider` |
| 3.3 | Per-service `Configure(p *config.Provider)` + registry (`ProviderConfiguration.AddConfig`) | S | — | `config/<scope>/<svc>/config.go`, `provider.go` |
| 3.4 | Group/Kind overrides (`config/overrides.go`/`groups.go`, `ReplaceGroupWords`) | S | — | read file |
| 3.5 | Cross-resource references configured (`config.Reference`) | S | — | grep `Reference{` in `config/` |
| 3.6 | Untested external names segregated (`externalnamenottested.go`) | N | — | `ls config/` |

## 4. API types & versioning
| ID | Item | Tier | Gate | How to check |
|---|---|---|---|---|
| 4.1 | `apis/<scope>/<svc>/<version>/` with generated `zz_*_types.go`, `zz_*_terraformed.go`, deepcopy/managed | M | — | `ls apis/...` |
| 4.2 | Hand-written ProviderConfig API per scope (`types.go`+`register.go`) | M | — | `apis/<scope>/<version>/types.go` |
| 4.3 | `zz_register.go` aggregates groups into scheme | M | — | read file |
| 4.4 | Stored versions are `v1beta1`+ (not alpha-only) for mature resources | S | — | scan version dirs |
| 4.5 | Multi-version services wire conversion hubs/spokes | S | multi-version | `ls **/zz_generated.conversion_*.go` |

## 5. Crossplane v2 scope architecture  *(N-A unless profile = v2)*
| ID | Item | Tier | Gate | How to check |
|---|---|---|---|---|
| 5.1 | Dual `apis/cluster/` + `apis/namespaced/` trees | M | v2 | `ls apis/` |
| 5.2 | Namespaced groups use `.m.` suffix (`<svc>.<prov>.m.upbound.io`) | M | v2 | `grep groupName apis/namespaced/**` |
| 5.3 | `config/` split `cluster/` + `namespaced/`, each with registry | M | v2 | `ls config/` |
| 5.4 | Two ProviderConfig kinds (cluster + namespaced) | M | v2 | `apis/*/v1beta1/types.go` |
| 5.5 | (v1 provider) consider v2 namespaced migration | N | v1 | note only — never a failure |

## 6. Family provider & packaging
| ID | Item | Tier | Gate | How to check |
|---|---|---|---|---|
| 6.1 | `package/crossplane.yaml.tmpl` valid metadata (maintainer/source/license, xp version constraint) | M | — | read file |
| 6.2 | `package/crds/` generated CRDs present | M | — | `ls package/crds | wc -l` |
| 6.3 | `capabilities: [SafeStart]` declared | S | — | `grep SafeStart package/crossplane.yaml.tmpl` |
| 6.4 | Family split: `provider-family-<prov>` label + `dependsOn` + per-service `SUBPACKAGES` | S | family / multi-service | `grep provider-family`; `Makefile` |
| 6.5 | Publishes to `xpkg.upbound.io/<org>` | S | — | publish workflow |

## 7. Controller runtime wiring
| ID | Item | Tier | Gate | How to check |
|---|---|---|---|---|
| 7.1 | Generated controllers expose `Setup` | M | — | `grep -r "func Setup" internal/controller | head` |
| 7.2 | `internal/clients/<prov>.go` `TerraformSetupBuilder` resolving ProviderConfig credentials | M | — | read file |
| 7.3 | ProviderConfig credential sources (Secret/env/fs/federation) handled | M | — | clients file |
| 7.4 | `SetupGated` (SafeStart) alongside `Setup` | S | — | `grep -r "func SetupGated" internal/controller | head` |
| 7.5 | `internal/features/features.go` defines management-policies + ESS flags | S | — | read file |
| 7.6 | Standard `cmd/provider/*/zz_main.go` flags (`--sync --poll --max-reconcile-rate --enable-management-policies` …) | S | — | grep flags |
| 7.7 | `internal/bootcheck` runs in `init()` | N | — | `ls internal/bootcheck` |
| 7.8 | `ProviderConfigSpec` embeds `ReconciliationPolicy` from `upjet/v2/apis/configuration/v1alpha1` | N | — | `grep -r "ReconciliationPolicy" apis/*/v1beta1/types.go` |

## 8. Examples & e2e coverage  *(see baseline.md §8 + commands.md §Examples)*
| ID | Item | Tier | Gate | How to check |
|---|---|---|---|---|
| 8.1 | Both `examples/` **and** `examples-generated/` exist | M | — | `ls` |
| 8.2 | `examples-generated/` = 1 example/resource, all carry `example-id` | M | — | file count == `example-id` count |
| 8.3 | `examples/` is a real curated set (carries the 3 annotations) | M | — | grep annotations |
| 8.4 | **Coverage** = `|G∩E| / (|G| − manual-intervention)`; report tested count + **untested gap `G\E`** | S | — | commands.md §Examples |
| 8.5 | Curated examples differ in content from generated twins (not byte-identical copies) | N | — | diff sampled ids |
| 8.6 | Near-complete coverage (small `G\E`) | N | — | from 8.4 |

## 9. Testing & linting
| ID | Item | Tier | Gate | How to check |
|---|---|---|---|---|
| 9.1 | `make test` runs unit tests; table-driven `*_test.go` exist (esp. config) | M | — | `find . -name '*_test.go' | head` |
| 9.2 | `.golangci.yml` enables the standard linter set (read the **list**, not file size) | M | — | read `.golangci.yml` |
| 9.3 | `.golangci.yml` excludes generated `zz_*`; goimports local-prefix = module | S | — | read file |
| 9.4 | uptest e2e wired (`cluster/test/setup.sh`, `make uptest`, `UPTEST_EXAMPLE_LIST`) | S | — | read setup.sh + Makefile |
| 9.5 | `make crddiff` + `make schema-version-diff` breaking-change guards | S | — | `grep -E 'crddiff|schema-version-diff' Makefile` |

## 10. CI/CD & governance
| ID | Item | Tier | Gate | How to check |
|---|---|---|---|---|
| 10.1 | `.github/workflows/ci.yml` runs lint + unit tests | M | — | read file |
| 10.2 | CI verifies committed generated code is current (`check-diff`/generate job) | M | — | grep in ci.yml |
| 10.3 | `LICENSE` (Apache-2.0) + `README` | M | — | `ls` |
| 10.4 | `report-breaking-changes` (crddiff + schema-version-diff) job | S | — | ci.yml |
| 10.5 | `publish-provider-packages.yaml` + `uptest-trigger.yml` | S | — | `ls .github/workflows` |
| 10.6 | `OWNERS.md`/`CODEOWNERS`; `tag.yaml`, `stale.yml`; credential docs | N | — | `ls` |
