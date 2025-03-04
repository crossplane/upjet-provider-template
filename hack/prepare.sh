#!/usr/bin/env bash
set -euox pipefail

: ${PROVIDER_NAME_LOWER:=$(read -r -p "Lower case provider name (ex. github): " PROVIDER_NAME_LOWER; echo -n "${PROVIDER_NAME_LOWER}")}
: ${PROVIDER_NAME_NORMAL:=$(read -r -p "Normal case provider name (ex. GitHub): " PROVIDER_NAME_NORMAL; echo -n "${PROVIDER_NAME_NORMAL}")}
: ${ORGANIZATION_NAME:=$(read -r -p "Organization (ex. upbound, my-org-name): " ORGANIZATION_NAME; echo -n "${ORGANIZATION_NAME}")}
: ${CRD_ROOT_GROUP:=$(read -r -p "CRD rootGroup (ex. upbound.io, crossplane.io): " CRD_ROOT_GROUP; echo -n "${CRD_ROOT_GROUP}")}

REPLACE_FILES='./* ./.github :!build/** :!go.* :!hack/prepare.sh'
# shellcheck disable=SC2086
git grep -l 'template' -- ${REPLACE_FILES} | xargs sed -i.bak "s/upjet-provider-template/provider-${PROVIDER_NAME_LOWER}/g"
# shellcheck disable=SC2086
git grep -l 'template' -- ${REPLACE_FILES} | xargs sed -i.bak "s/template/${PROVIDER_NAME_LOWER}/g"
# shellcheck disable=SC2086
git grep -l "upbound/provider-${PROVIDER_NAME_LOWER}" -- ${REPLACE_FILES} | xargs sed -i.bak "s|upbound/provider-${PROVIDER_NAME_LOWER}|${ORGANIZATION_NAME}/provider-${PROVIDER_NAME_LOWER}|g"
# shellcheck disable=SC2086
git grep -l 'Template' -- ${REPLACE_FILES} | xargs sed -i.bak "s/Template/${PROVIDER_NAME_NORMAL}/g"
# shellcheck disable=SC2086
git grep -l "upbound.io" -- "apis/v1*" | xargs sed -i.bak "s|upbound.io|${CRD_ROOT_GROUP}|g"
# shellcheck disable=SC2086
git grep -l "upbound.io" -- "cluster/test/setup.sh" | xargs sed -i.bak "s|upbound.io|${CRD_ROOT_GROUP}|g"
# shellcheck disable=SC2086
git grep -l "ujconfig\.WithRootGroup(\"${PROVIDER_NAME_LOWER}.upbound\.io\")" -- "config/provider.go" | xargs sed -i.bak "s|ujconfig.WithRootGroup(\"${PROVIDER_NAME_LOWER}.upbound.io\")|ujconfig.WithRootGroup(\"${CRD_ROOT_GROUP}\")|g"

# We need to be careful while replacing "template" keyword in go.mod as it could tamper
# some imported packages under require section.
sed -i.bak "s|upbound/upjet-provider-template|${ORGANIZATION_NAME}/provider-${PROVIDER_NAME_LOWER}|g" go.mod
sed -i.bak -e "s|PROJECT_REPO ?= github.com/upbound/|PROJECT_REPO ?= github.com/${ORGANIZATION_NAME}/|g" -e "s|\(blob/main/internal/\)${PROVIDER_NAME_LOWER}s|\1templates|g" Makefile
sed -i.bak "s/\[YEAR\]/$(date +%Y)/g" LICENSE

# Clean up the .bak files created by sed
git clean -fd

git mv "internal/clients/template.go" "internal/clients/${PROVIDER_NAME_LOWER}.go"
git mv "cluster/images/upjet-provider-template" "cluster/images/provider-${PROVIDER_NAME_LOWER}"

# We need to remove this api folder otherwise first `make generate` fails with
# the following error probably due to some optimizations in go generate with v1.17:
# generate: open /Users/hasanturken/Workspace/crossplane-contrib/upjet-provider-template/apis/null/v1alpha1/zz_generated.deepcopy.go: no such file or directory
rm -rf apis/null
# remove the sample directory which was a configuration in the template
rm -rf config/null
