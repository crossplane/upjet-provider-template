/*
Copyright 2021 Upbound Inc.
*/

package config

import (
	// Note(turkenh): we are importing this to embed provider schema document
	_ "embed"

	"github.com/hashicorp/terraform-plugin-sdk/v2/helper/schema"

	tjconfig "github.com/upbound/upjet/pkg/config"

	"github.com/upbound/official-provider-template/config/null"
)

const (
	resourcePrefix = "template"
	modulePath     = "github.com/upbound/official-provider-template"
)

//go:embed schema.json
var providerSchema string

// GetProvider returns provider configuration
func GetProvider() *tjconfig.Provider {
	defaultResourceFn := func(name string, terraformResource *schema.Resource, opts ...tjconfig.ResourceOption) *tjconfig.Resource {
		r := tjconfig.DefaultResource(name, terraformResource)
		// Add any provider-specific defaulting here. For example:
		//   r.ExternalName = tjconfig.IdentifierFromProvider
		return r
	}

	pc := tjconfig.NewProviderWithSchema([]byte(providerSchema), resourcePrefix, modulePath,
		tjconfig.WithDefaultResourceFn(defaultResourceFn))

	for _, configure := range []func(provider *tjconfig.Provider){
		// add custom config functions
		null.Configure,
	} {
		configure(pc)
	}

	pc.ConfigureResources()
	return pc
}
