# Report template

Fill this in. Keep every finding backed by `file:line` or command output. Delete N-A categories'
detail but keep them in the scorecard marked N/A with the reason.

---

```markdown
# ⚠️ Experimental - validate all results
# Upjet Provider Best Practices Review — <provider name>

- **Target:** <repo / path>  ·  **Commit:** <sha>  ·  **Reviewed:** <date>
- **Measured against:** official Upbound `provider-upjet-{aws,azure,gcp}` conventions (baseline.md)

## Detected profile
- **Generator:** upjet vN  ·  **Backend:** Plugin-SDK / Plugin-Framework / no-fork
- **Crossplane model:** v2 (cluster+namespaced) / v1 (single-scope)
- **Packaging:** family (N service packages) / monolith-only
- **Build:** crossplane/build submodule / custom
- *(Tiers below are gated on this profile; items not applicable are marked N/A.)*

## Scorecard
| # | Category | MUST | SHOULD | NICE | Status |
|---|----------|------|--------|------|--------|
| 1 | Repo structure & build | x/x | x/x | x/x | ✅/⚠️/❌/NA |
| 2 | Code generation | | | | |
| 3 | External-name & config | | | | |
| 4 | API types & versioning | | | | |
| 5 | v2 scope architecture | | | | NA if v1 |
| 6 | Family & packaging | | | | |
| 7 | Controller runtime wiring | | | | |
| 8 | Examples & e2e coverage | | | | |
| 9 | Testing & linting | | | | |
| 10 | CI/CD & governance | | | | |

**e2e example coverage:** `<tested>/<generated>` ≈ `<raw pct>%`  ·  untested gap `<G\E>` =
  `<actionable>` actionable + `<manual>` manual-intervention  ·  curated-only `<E\G>`.

## Overall verdict: **FOLLOWING-BEST-PRACTICES / FOLLOWING-BEST-PRACTICES-WITH-GAPS / NOT-FOLLOWING-BEST-PRACTICES**
> Gating: any MUST failure → NOT-FOLLOWING-BEST-PRACTICES; only SHOULD/NICE gaps → FOLLOWING-BEST-PRACTICES-WITH-GAPS; clean → FOLLOWING-BEST-PRACTICES.
One-paragraph rationale.

## Findings
For each category, list only items that are ❌ / ⚠️ (and noteworthy ✅). Format:

### N. <Category>
- **[MUST] ❌ <item>** — <what's wrong>. Evidence: `path:line`. Fix: <one line, cite baseline>.
- **[SHOULD] ⚠️ <item>** — <gap>. Evidence: `path`. Fix: <one line>.

## Top remediation priorities
1. **(MUST)** …
2. **(MUST)** …
3. **(SHOULD)** …

## Untested resources (examples gap)
<the `G \ E` list, or a count + link if long>
```

---

**Verdict gating rule (apply mechanically):**
- ≥1 MUST fail → `NOT-FOLLOWING-BEST-PRACTICES`
- 0 MUST fail, ≥1 SHOULD/NICE gap → `FOLLOWING-BEST-PRACTICES-WITH-GAPS`
- all pass / only N-A → `FOLLOWING-BEST-PRACTICES`
