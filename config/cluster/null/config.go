package null

import (
	ujconfig "github.com/crossplane/upjet/v2/pkg/config"
)

// Configure configures the null group
func Configure(p *ujconfig.Provider) {
	p.AddResourceConfigurator("null_resource", func(r *ujconfig.Resource) {
		r.Kind = "Resource"
		// And other overrides.
	})
}
