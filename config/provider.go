/*
Copyright 2021 Upbound Inc.
*/

package config

import (
	// Note(turkenh): we are importing this to embed provider schema document
	_ "embed"

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
	pc := tjconfig.NewProvider([]byte(providerSchema), resourcePrefix, modulePath, "",
		tjconfig.WithIncludeList(ExternalNameConfigured()),
		tjconfig.WithDefaultResourceOptions(
			ExternalNameConfigurations(),
		))

	for _, configure := range []func(provider *tjconfig.Provider){
		// add custom config functions
		null.Configure,
	} {
		configure(pc)
	}

	pc.ConfigureResources()
	return pc
}
