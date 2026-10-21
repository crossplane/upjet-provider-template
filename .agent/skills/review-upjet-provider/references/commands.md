# Optional read-only commands

Run these from the **provider repo root** to gather evidence. They are read-only and degrade
gracefully — if a tool (`go`, `golangci-lint`, `crddiff`, terraform) is missing, skip that command and
fall back to reading files; note in the report that the check was file-based only. Never run `make`
targets that build images, deploy, or hit a cloud.

Set the path once:
```bash
P=/abs/path/to/provider     # the target provider repo
cd "$P"
```

## Profile detection
```bash
grep -E 'crossplane/upjet|crossplane-runtime|terraform-provider' go.mod   # generator + runtime + tf provider
ls config/externalname*.go && grep -hoE 'TerraformPlugin(SDK|Framework)ExternalNameConfigs|CLIReconciledExternalNameConfigs' config/*.go | sort -u   # backend
[ -d apis/namespaced ] && echo "v2 (namespaced present)" || echo "v1 (single-scope)"
grep -rhoE '\.m\.[a-z.]*upbound\.io' apis/namespaced 2>/dev/null | sort -u | head   # .m. groups
ls -d cmd/provider/*/ 2>/dev/null | wc -l    # >1 service dir → family
grep -E '^SUBPACKAGES' Makefile
git -C "$P" submodule status 2>/dev/null      # build/ submodule pin
```

## Examples — the e2e coverage metric  (key on example-id, NOT file count)
```bash
# extract the example-id sets (whitespace-tolerant), one id per resource example
grep -rh "meta.upbound.io/example-id" examples-generated | sed 's/.*example-id: *//' | sort -u > /tmp/gen.ids
grep -rh "meta.upbound.io/example-id" examples            | sed 's/.*example-id: *//' | sort -u > /tmp/cur.ids

G=$(wc -l < /tmp/gen.ids); E=$(wc -l < /tmp/cur.ids)
comm -12 /tmp/gen.ids /tmp/cur.ids > /tmp/tested.ids      # G ∩ E  = e2e-tested
comm -23 /tmp/gen.ids /tmp/cur.ids > /tmp/gap.ids         # G \ E  = generated but NOT curated (untested)
TESTED=$(wc -l < /tmp/tested.ids); GAP=$(wc -l < /tmp/gap.ids)
EXTRA=$(comm -13 /tmp/gen.ids /tmp/cur.ids | wc -l)       # E \ G  = curated w/o generated twin (hand-written/stale)

# manual-intervention as an example-id SET (not a file count — stay consistent with G/E)
grep -rl "upjet.upbound.io/manual-intervention" examples examples-generated 2>/dev/null \
  | xargs grep -h "meta.upbound.io/example-id" 2>/dev/null | sed 's/.*example-id: *//' | sort -u > /tmp/manual.ids
GAP_MANUAL=$(comm -12 /tmp/gap.ids /tmp/manual.ids | wc -l)     # untested AND manual-intervention (expected)
GAP_ACTIONABLE=$(comm -23 /tmp/gap.ids /tmp/manual.ids | wc -l) # the REAL coverage debt

echo "generated=$G curated=$E tested(G∩E)=$TESTED gap(G\\E)=$GAP (manual=$GAP_MANUAL actionable=$GAP_ACTIONABLE) extra(E\\G)=$EXTRA"
echo "raw coverage% = TESTED / G"                          # headline figure (adjust the GAP, not the denominator)

# the actionable untested resources (gap minus expected manual-intervention)
comm -23 /tmp/gap.ids /tmp/manual.ids
```
Notes:
- `examples-generated/` and `examples/` use **different directory layouts** — that is why you join on
  `example-id`, never on path or raw file count.
- If `examples-generated/` is absent, this metric can't be computed — assess `examples/` + uptest
  wiring qualitatively and say so.
- Content-diff spot check (sampled id present in both): the curated file should differ from its
  generated twin. To find a generated twin by id: `grep -rl "example-id: <id>" examples-generated`.

## External-name strategy distribution
```bash
grep -hoE 'config\.[A-Za-z]+|IdentifierFromProvider' config/externalname.go | sort | uniq -c | sort -rn | head
# a very high share of bare IdentifierFromProvider across all resources is a smell (item 3.2)
```

## Controller / runtime conventions
```bash
grep -rl "func SetupGated" internal/controller | head      # SafeStart (7.4)
grep -rl "func Setup(" internal/controller | head           # base Setup (7.1)
grep -hE 'EnableBetaManagementPolicies|EnableAlphaExternalSecretStores' internal/features/features.go
grep -hE 'enable-management-policies|max-reconcile-rate|--poll|--sync' cmd/provider/*/zz_main.go | sort -u | head
```

## Packaging / capabilities
```bash
grep -nE 'SafeStart|provider-family|dependsOn|meta.crossplane.io' package/crossplane.yaml.tmpl
grep -nE 'SafeStart|provider-family|dependsOn|meta.crossplane.io' package/crossplane.yaml
ls package/crds | wc -l
```

## Linting — read the enabled set, not the file size
```bash
sed -n '1,80p' .golangci.yml          # inspect the actual enabled linters / version / exclusions
golangci-lint version 2>/dev/null && golangci-lint run --timeout 5m ./config/... 2>&1 | tail -20   # optional, may be slow
```

## CI jobs present
```bash
ls .github/workflows
grep -rhoE 'crddiff|schema-version-diff|check-diff|uptest|publish' .github/workflows | sort -u
grep -E 'crddiff|schema-version-diff|uptest' Makefile
```

## Breaking-change tooling (optional, needs tools)
```bash
make crddiff 2>&1 | tail -20            # only if uptest/crddiff tool installed
make schema-version-diff 2>&1 | tail -20
```
