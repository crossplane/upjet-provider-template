// SPDX-FileCopyrightText: 2023 The Crossplane Authors <https://crossplane.io>
//
// SPDX-License-Identifier: Apache-2.0

package controller

import (
	resource "github.com/crossplane/upjet-provider-template/internal/controller/null/resource"
	providerconfig "github.com/crossplane/upjet-provider-template/internal/controller/providerconfig"
	"github.com/crossplane/upjet/pkg/controller"
	ctrl "sigs.k8s.io/controller-runtime"
)

// Setup creates all controllers with the supplied logger and adds them to
// the supplied manager.
func Setup(mgr ctrl.Manager, o controller.Options) error {
	for _, setup := range []func(ctrl.Manager, controller.Options) error{
		resource.Setup,
		providerconfig.Setup,
	} {
		if err := setup(mgr, o); err != nil {
			return err
		}
	}
	return nil
}
