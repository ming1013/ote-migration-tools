---
description: Automate OpenShift Tests Extension (OTE) migration for component repositories
---

# OTE Migration Assistant

You are helping migrate a component repository to use the openshift-tests-extension (OTE) framework.

## Context

The openshift-tests-extension framework allows external repositories to contribute tests to openshift-tests' suites. You need to help automate this migration by:

1. Analyzing the existing test structure
2. Generating the necessary boilerplate code
3. Extracting and applying environment selectors (platform filters, labels, etc.)
4. Setting up test suites and registrations

## Migration Steps

### Step 1: Analyze Target Repository

Ask the user for the target repository path (or use current directory if already in the target repo).

Then analyze:
- Find all Ginkgo test files (files with `Describe`, `It`, `Context` patterns)
- Extract test names and identify patterns:
  - `[platform:xxx]` in test names
  - `Platform:xxx` labels
  - `[sig-xxx]` patterns
  - Lifecycle labels (`Lifecycle:Blocking`, `Lifecycle:Informing`, or labels like `SLOW`)
  - Other environment-related patterns
- Identify existing test structure and organization
- Check for existing BeforeAll/AfterAll/BeforeEach/AfterEach hooks

### Step 2: Gather Migration Information

Ask the user for:
- Extension name (e.g., "sdn", "network", "storage")
- Extension category (typically "payload" for most components)
- Extension identifier (usually same as extension name)
- Parent suite(s) they want to integrate with (e.g., "openshift/conformance/parallel")
- Whether to create custom suites and their names

### Step 3: Generate Main Entry Point

Create `cmd/<extension-name>/main.go` with:

```go
package main

import (
	"fmt"
	"os"
	"regexp"
	"strings"

	"github.com/spf13/cobra"

	"github.com/openshift-eng/openshift-tests-extension/pkg/cmd"
	e "github.com/openshift-eng/openshift-tests-extension/pkg/extension"
	et "github.com/openshift-eng/openshift-tests-extension/pkg/extension/extensiontests"
	g "github.com/openshift-eng/openshift-tests-extension/pkg/ginkgo"

	// Import your test packages here
	_ "<repository-path>/test/e2e"
)

func main() {
	registry := e.NewRegistry()
	ext := e.NewExtension("<org>", "<category>", "<extension-name>")

	// Add suites
	ext.AddSuite(e.Suite{
		Name:    "<org>/<suite-name>",
		Parents: []string{"<parent-suite>"},
	})

	// Build test specs from Ginkgo
	specs, err := g.BuildExtensionTestSpecsFromOpenShiftGinkgoSuite()
	if err != nil {
		panic(fmt.Sprintf("couldn't build extension test specs from ginkgo: %+v", err.Error()))
	}

	// Apply platform filters based on Platform: labels
	specs.Walk(func(spec *et.ExtensionTestSpec) {
		for label := range spec.Labels {
			if strings.HasPrefix(label, "Platform:") {
				platformName := strings.TrimPrefix(label, "Platform:")
				spec.Include(et.PlatformEquals(platformName))
			}
		}
	})

	// Apply platform filters based on [platform:xxx] in test names
	specs.Walk(func(spec *et.ExtensionTestSpec) {
		re := regexp.MustCompile(`\[platform:([a-z]+)\]`)
		if match := re.FindStringSubmatch(spec.Name); match != nil {
			platform := match[1]
			spec.Include(et.PlatformEquals(platform))
		}
	})

	// TODO: Add hooks if needed
	// specs.AddBeforeAll(func() {
	// 	// Initialize test framework
	// })
	//
	// specs.AddAfterEach(func(res *et.ExtensionTestResult) {
	// 	// Collect diagnostics on failure
	// })

	ext.AddSpecs(specs)
	registry.Register(ext)

	root := &cobra.Command{
		Long: "<Extension Name> Tests",
	}

	root.AddCommand(cmd.DefaultExtensionCommands(registry)...)

	if err := func() error {
		return root.Execute()
	}(); err != nil {
		os.Exit(1)
	}
}
```

Fill in the placeholders with actual values from Step 2.

### Step 4: Update Dependencies

Check if `go.mod` exists and add/update OTE dependency:

```bash
go get github.com/openshift-eng/openshift-tests-extension@latest
```

### Step 5: Use Testdata Infrastructure

**Prerequisites:** Ensure you have run `/analyze-for-ote` first, which sets up:
- `.bingo/` directory with go-bindata tool
- `Makefile` with bindata generation target
- `test/testdata/fixtures.go` with wrapper functions

**Verify prerequisites:**

```bash
# Check that infrastructure exists
test -d .bingo && test -f Makefile && test -f test/testdata/fixtures.go
```

If any of these are missing, run `/analyze-for-ote` first to set up the infrastructure.

#### 5.1: Generate bindata.go

Run the Makefile target to generate the bindata.go file:

```bash
make bindata
```

**What happens:**
- Makefile automatically builds go-bindata from `.bingo/go-bindata.mod`
- Generates `test/testdata/bindata.go` with all testdata files embedded
- **No need to install bingo or go-bindata manually** - Makefile handles everything!

**Verify generation:**
```bash
# Check the generated file exists
ls -lh test/testdata/bindata.go

# Verify it contains embedded assets
grep -o "func Asset" test/testdata/bindata.go | head -5
```

#### 5.2: Update Test Code to Use New Wrapper

Search for existing testdata access patterns and update them:

**Common patterns to find and replace:**

```bash
# Search for old patterns
grep -r "compat_otp.FixturePath" test/
grep -r "exutil.FixturePath" test/
```

**Before:**
```go
configPath := compat_otp.FixturePath("config.yaml")
manifestPath := exutil.FixturePath("manifests/deployment.yaml")
```

**After:**
```go
configPath := testdata.FixturePath("config.yaml")
manifestPath := testdata.FixturePath("manifests/deployment.yaml")
```

**Update imports:**
```go
import (
    // Add this
    "<module-path>/test/testdata"

    // Remove or comment out old imports
    // "github.com/openshift/origin/test/extended/util/compat_otp"
)
```

#### 5.3: Integrate with OTE Hooks

Update `cmd/<extension-name>/main.go` to add fixture cleanup in hooks:

```go
// Add after building specs and before AddSpecs
specs.AddAfterAll(func() {
    if err := testdata.CleanupFixtures(); err != nil {
        fmt.Printf("Warning: failed to cleanup fixtures: %v\n", err)
    }
})
```

Full context in main.go:
```go
// Build test specs from Ginkgo
specs, err := g.BuildExtensionTestSpecsFromOpenShiftGinkgoSuite()
if err != nil {
    panic(fmt.Sprintf("couldn't build extension test specs from ginkgo: %+v", err.Error()))
}

// Apply filters...
specs.Walk(func(spec *et.ExtensionTestSpec) {
    // ... filter logic ...
})

// Add cleanup hook
specs.AddAfterAll(func() {
    if err := testdata.CleanupFixtures(); err != nil {
        fmt.Printf("Warning: failed to cleanup fixtures: %v\n", err)
    }
})

ext.AddSpecs(specs)
```


### Step 6: Apply Additional Filters

Based on the analysis in Step 1, generate additional filter code for patterns found:

- For network-related patterns: `spec.Include(et.NetworkEquals("ovn"))`
- For topology patterns: `spec.Include(et.TopologyEquals("ha"))`
- For architecture patterns: `spec.Include(et.ArchitectureEquals("amd64"))`
- For multiple platforms: `spec.Include(et.Or(et.PlatformEquals("aws"), et.PlatformEquals("gcp")))`
- For complex conditions: `spec.Include(et.And(...))`

Add these filters to the `specs.Walk()` sections in main.go.

### Step 7: Handle Custom Suites

If the user wants custom suites (e.g., "slow tests", "fast tests"), generate:

```go
// Fast tests suite
ext.AddSuite(e.Suite{
	Name: "<org>/<extension>/fast",
	Qualifiers: []string{
		`!labels.exists(l, l=="SLOW")`,
	},
})

// Slow tests suite
ext.AddSuite(e.Suite{
	Name: "<org>/<extension>/slow",
	Qualifiers: []string{
		`labels.exists(l, l=="SLOW")`,
	},
})
```

### Step 8: Generate Migration Summary

Provide a summary showing:
- Files created/modified
- Number of tests discovered
- Platform filters applied
- Suites created
- Next steps (build, test, verify)

## Validation Steps

After migration, guide the user to:

1. Build the extension:
   ```bash
   go build ./cmd/<extension-name>
   ```

2. List tests:
   ```bash
   ./<extension-name> list
   ```

3. Run a test:
   ```bash
   ./<extension-name> run "<test-name>"
   ```

4. Verify environment filtering works:
   ```bash
   ./<extension-name> run --platform=aws
   ```

## Important Notes

- ALWAYS use `specs.Walk()` for applying filters iteratively
- Use capture groups in regex for cleaner extraction: `\[platform:([a-z]+)\]`
- The `Include()` method supports ORing when called multiple times
- Default lifecycle is "Blocking" - only add explicit labels for "Informing" tests
- Exclude vendored tests by default (already handled by `BuildExtensionTestSpecsFromOpenShiftGinkgoSuite`)

## Example Patterns to Detect

Common test name patterns:
- `[platform:aws]` → `et.PlatformEquals("aws")`
- `[sig-network]` → Tag for suite organization
- `[Conformance]` → Should be in conformance suite
- `[Serial]` → May need special handling
- `[Disruptive]` → Lifecycle consideration

Common label patterns:
- `Platform:aws` → `et.PlatformEquals("aws")`
- `SLOW` → Add to slow test suite
- `Lifecycle:Informing` → Already handled by framework
- `Suite:openshift/network` → Suite membership

Begin by asking the user for the repository path and proceed with the migration!
