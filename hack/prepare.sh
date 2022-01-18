#!/usr/bin/env bash

# Copyright 2021 The Crossplane Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Please set ProviderNameLower & ProviderNameUpper environment variables before running this script.
# See: https://github.com/crossplane/terrajet/blob/main/docs/generating-a-provider.md
set -euo pipefail

REPLACE_FILES='./* ./.github :!build/** :!go.sum :!hack/prepare.sh'
# shellcheck disable=SC2086
git grep -l 'template' -- ${REPLACE_FILES} | xargs sed -i.bak "s/template/${ProviderNameLower}/g"
# shellcheck disable=SC2086
git grep -l 'Template' -- ${REPLACE_FILES} | xargs sed -i.bak "s/Template/${ProviderNameUpper}/g"
# Clean up the .bak files created by sed
git clean -fd

git mv "internal/clients/template.go" "internal/clients/${ProviderNameLower}.go"
git mv "cluster/images/provider-jet-template" "cluster/images/provider-jet-${ProviderNameLower}"
git mv "cluster/images/provider-jet-template-controller" "cluster/images/provider-jet-${ProviderNameLower}-controller"
