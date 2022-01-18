// +build generate

/*
Copyright 2021 The Crossplane Authors.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package main

import (
	"fmt"
	"os"
	"path/filepath"

	tf "github.com/hashicorp/terraform-provider-hashicups/hashicups"

	"github.com/crossplane/terrajet/pkg/pipeline"
	// Comment out the line below, if your Terraform provider uses an old
	// version (<v2) of github.com/hashicorp/terraform-plugin-sdk.
	// "github.com/crossplane/terrajet/pkg/types/conversion"

	"github.com/crossplane-contrib/provider-jet-template/config"
)

func main() {
	if len(os.Args) < 2 || os.Args[1] == "" {
		panic("root directory is required to be given as argument")
	}
	absRootDir, err := filepath.Abs(os.Args[1])
	if err != nil {
		panic(fmt.Sprintf("cannot calculate the absolute path of %s", os.Args[1]))
	}
	resourceMap := tf.Provider().ResourcesMap
	// Comment out the line below instead of the above, if your Terraform
	// provider uses an old version (<v2) of github.com/hashicorp/terraform-plugin-sdk.
	// resourceMap := conversion.GetV2ResourceMap(tf.Provider())
	pipeline.Run(config.GetProvider(resourceMap), absRootDir)
}
