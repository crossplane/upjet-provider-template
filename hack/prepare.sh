#!/usr/bin/env bash

# Copyright 2021 Upbound Inc.

# Please set ProviderNameLower & ProviderNameUpper environment variables before running this script.
# See: https://github.com/crossplane/terrajet/blob/main/docs/generating-a-provider.md
set -euo pipefail

REPLACE_FILES='./* ./.github :!build/** :!go.* :!hack/prepare.sh'
# shellcheck disable=SC2086
git grep -l 'template' -- ${REPLACE_FILES} | xargs sed -i.bak "s/template/${ProviderNameLower}/g"
# shellcheck disable=SC2086
git grep -l 'Template' -- ${REPLACE_FILES} | xargs sed -i.bak "s/Template/${ProviderNameUpper}/g"
# We need to be careful while replacing "template" keyword in go.mod as it could tamper
# some imported packages under require section.
sed -i.bak "s/upjet-provider-template/provider-${ProviderNameLower}/g" go.mod

# Clean up the .bak files created by sed
git clean -fd

git mv "internal/clients/template.go" "internal/clients/${ProviderNameLower}.go"
git mv "cluster/images/upjet-provider-template" "cluster/images/provider-${ProviderNameLower}"

# We need to remove this api folder otherwise first `make generate` fails with
# the following error probably due to some optimizations in go generate with v1.17:
# generate: open /Users/hasanturken/Workspace/crossplane-contrib/upjet-provider-template/apis/null/v1alpha1/zz_generated.deepcopy.go: no such file or directory
rm -rf apis/null