/*
Copyright 2021 Upbound Inc.
*/

package null

import (
	tjconfig "github.com/upbound/upjet/pkg/config"
)

// Configure configures the null group
func Configure(p *tjconfig.Provider) {
	p.AddResourceConfigurator("null_resource", func(r *tjconfig.Resource) {
		r.Kind = "Resource"
		// And other overrides.
	})
}
