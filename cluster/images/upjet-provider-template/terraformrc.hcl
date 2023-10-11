# SPDX-FileCopyrightText: 2023 The Crossplane Authors <https://crossplane.io>
#
# SPDX-License-Identifier: Apache-2.0

provider_installation {
  filesystem_mirror {
    path    = "/terraform/provider-mirror"
    include = ["*/*"]
  }
  direct {
    exclude = ["*/*"]
  }
}
