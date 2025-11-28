---
description: Automate OpenShift Tests Extension (OTE) migration for component repositories
---

# OTE Migration Assistant

You are helping migrate a component repository to use the openshift-tests-extension (OTE) framework.

## Context

The openshift-tests-extension framework allows external repositories to contribute tests to openshift-tests' suites. This migration process will:

1. Collect all necessary configuration information
2. Set up the repository structure
3. Clone/update source and target repositories
4. Copy test files and testdata to customizable destinations
5. Generate all necessary boilerplate code
6. Apply environment selectors and filters
7. Set up test suites and registrations

## Migration Workflow

### Phase 1: Cleanup

No files to delete in this phase.

### Phase 2: User Input Collection (9 inputs)

Collect all necessary information from the user before starting the migration.

#### Input 1: Extension Name

Ask: "What is the name of your extension?"
- Example: "sdn", "router", "storage", "cluster-network-operator"
- This will be used for directory names and identifiers

#### Input 2: Working Directory

Ask: "What is the working directory path where the tests-extension will be created?"
- Explain: This is where we'll create the `tests-extension/` directory structure
- Options:
  - Provide an existing directory path
  - Provide a new directory path (we'll create it)
- Example: `/home/user/workspace/my-extension-tests`

#### Input 3: Validate Git Status (if existing directory)

If the working directory already exists:
- Check if it's a git repository
- If yes, run `git status` and verify it's clean
- If there are uncommitted changes, ask user to commit or stash them first
- If no, continue without git validation

#### Input 4: Source Repository URL

Ask: "What is the Git URL of the source repository containing the tests?"
- Example: `https://github.com/openshift/origin.git`
- This is where the original test files are located

#### Input 5: Target Repository URL

Ask: "What is the Git URL of the target repository (component repository)?"
- Example: `https://github.com/openshift/sdn.git`
- This is where the OTE integration will be added

#### Input 6: Source Test File Path

Ask: "What is the relative path to test files in the source repository?"
- Default: `test/extended/`
- Example: `test/e2e/`, `test/integration/`
- This is where we'll copy test files FROM

#### Input 7: Source Testdata Path

Ask: "What is the relative path to testdata in the source repository?"
- Default: `test/extended/testdata/`
- Example: `test/e2e/testdata/`, `test/fixtures/`
- Enter "none" if no testdata exists

#### Input 8: Destination Test Path (⭐ CUSTOMIZABLE)

Ask: "What is the destination path for test files in tests-extension?"
- Default: `test/e2e/`
- This is customizable - users can specify any path
- Example: `test/integration/`, `pkg/tests/`

#### Input 9: Destination Testdata Path (⭐ CUSTOMIZABLE)

Ask: "What is the destination path for testdata in tests-extension?"
- Default: `test/testdata/`
- This is customizable - users can specify any path
- Example: `pkg/testdata/`, `test/fixtures/`

**Display all collected inputs** for user confirmation:
```
Migration Configuration:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Extension: <extension-name>
Working Directory: <working-dir>

Source Repository: <source-repo-url>
  Test Files: <source-test-path>
  Testdata: <source-testdata-path>

Target Repository: <target-repo-url>

Destination Paths (in tests-extension/):
  Test Files: <dest-test-path>
  Testdata: <dest-testdata-path>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Ask for confirmation before proceeding.

### Phase 3: Repository Setup (2 steps)

#### Step 1: Clone/Update Source Repository

```bash
cd <working-dir>
mkdir -p repos

# Clone or update source repo
if [ -d "repos/source" ]; then
    echo "Updating source repository..."
    cd repos/source
    git fetch origin
    git pull
    cd ../..
else
    echo "Cloning source repository..."
    git clone <source-repo-url> repos/source
fi
```

#### Step 2: Clone/Update Target Repository

```bash
# Clone or update target repo
if [ -d "repos/target" ]; then
    echo "Updating target repository..."
    cd repos/target
    git fetch origin
    git pull
    cd ../..
else
    echo "Cloning target repository..."
    git clone <target-repo-url> repos/target
fi
```

### Phase 4: Structure Creation (4 steps)

#### Step 1: Create tests-extension/ Directory

```bash
cd <working-dir>
mkdir -p tests-extension
```

#### Step 2: Create cmd/ and User-Specified Test Directories

Create the directory structure with user-specified paths:

```bash
cd tests-extension

# Create cmd directory
mkdir -p cmd/<extension-name>

# Create destination test directory (customizable path)
mkdir -p <dest-test-path>

# Create destination testdata directory (customizable path)
mkdir -p <dest-testdata-path>

# Create .bingo directory for go-bindata
mkdir -p .bingo
```

#### Step 3: Copy Test Files to Custom Destination

```bash
# Copy test files from source to custom destination
cp -r ../repos/source/<source-test-path>/* <dest-test-path>/

# Count and display copied files
echo "Copied $(find <dest-test-path> -name '*_test.go' | wc -l) test files"
```

#### Step 4: Copy Testdata to Custom Destination

```bash
# Copy testdata if it exists (skip if user specified "none")
if [ "<source-testdata-path>" != "none" ]; then
    cp -r ../repos/source/<source-testdata-path>/* <dest-testdata-path>/
    echo "Copied testdata files to <dest-testdata-path>"
else
    echo "Skipping testdata copy (none specified)"
fi
```

### Phase 5: Code Generation (5 steps)

#### Step 1: Generate go.mod

Create `tests-extension/go.mod`:

```go
module github.com/<org>/<extension-name>-tests-extension

go 1.21

require (
    github.com/openshift-eng/openshift-tests-extension latest
    github.com/onsi/ginkgo/v2 latest
    github.com/onsi/gomega latest
)
```

Then run:
```bash
cd tests-extension
go mod tidy
```

#### Step 2: Generate cmd/main.go

Create `tests-extension/cmd/<extension-name>/main.go` with the custom testdata path:

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

	// Import testdata package (uses custom path)
	"github.com/<org>/<extension-name>-tests-extension/<dest-testdata-path-normalized>"

	// Import test packages (uses custom path)
	_ "github.com/<org>/<extension-name>-tests-extension/<dest-test-path-normalized>"
)

func main() {
	registry := e.NewRegistry()
	ext := e.NewExtension("<org>", "payload", "<extension-name>")

	// Add main test suite
	ext.AddSuite(e.Suite{
		Name:    "<org>/<extension-name>/tests",
		Parents: []string{"openshift/conformance/parallel"},
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
		re := regexp.MustCompile(` + "`\\[platform:([a-z]+)\\]`" + `)
		if match := re.FindStringSubmatch(spec.Name); match != nil {
			platform := match[1]
			spec.Include(et.PlatformEquals(platform))
		}
	})

	// Add testdata validation and cleanup hooks
	specs.AddBeforeAll(func() {
		// List available fixtures
		fixtures := testdata.ListFixtures()
		fmt.Printf("Loaded %d test fixtures\n", len(fixtures))

		// Optional: Validate required fixtures
		// requiredFixtures := []string{
		//     "manifests/deployment.yaml",
		// }
		// if err := testdata.ValidateFixtures(requiredFixtures); err != nil {
		//     panic(fmt.Sprintf("Missing required fixtures: %v", err))
		// }
	})

	specs.AddAfterAll(func() {
		if err := testdata.CleanupFixtures(); err != nil {
			fmt.Printf("Warning: failed to cleanup fixtures: %v\n", err)
		}
	})

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

**Note:** Replace `<dest-testdata-path-normalized>` and `<dest-test-path-normalized>` with the paths converted to Go import format (e.g., `test/testdata` stays as `test/testdata`).

#### Step 3: Create bindata.mk

Create `tests-extension/bindata.mk`:

```makefile
# Bindata generation for testdata files
# This file is included by the main Makefile

# Ensure DEST_TESTDATA_PATH is set (customizable)
DEST_TESTDATA_PATH ?= <dest-testdata-path>

# Generate bindata.go from testdata directory
.PHONY: bindata
bindata: $(DEST_TESTDATA_PATH)/bindata.go

$(DEST_TESTDATA_PATH)/bindata.go: $(GO_BINDATA) $(shell find $(DEST_TESTDATA_PATH) -type f -not -name 'bindata.go' 2>/dev/null)
	@echo "Generating bindata from $(DEST_TESTDATA_PATH)..."
	mkdir -p $(@D)
	$(GO_BINDATA) -nocompress -nometadata \
		-pkg testdata -o $@ -prefix "$(shell dirname $(DEST_TESTDATA_PATH))" $(DEST_TESTDATA_PATH)/...
	gofmt -s -w $@
	@echo "Bindata generated successfully at $@"

.PHONY: clean-bindata
clean-bindata:
	rm -f $(DEST_TESTDATA_PATH)/bindata.go
```

#### Step 4: Create Makefile (Using Custom Testdata Path)

Create `tests-extension/Makefile`:

```makefile
# Include bingo variables for tool management
include .bingo/Variables.mk

# Set custom testdata path
DEST_TESTDATA_PATH := <dest-testdata-path>
export DEST_TESTDATA_PATH

# Include bindata targets
include bindata.mk

# Build extension binary
.PHONY: build
build: bindata
	go build -o <extension-name> ./cmd/<extension-name>

# Run tests
.PHONY: test
test:
	go test ./...

# List all tests
.PHONY: list
list: build
	./<extension-name> list

# Clean generated files
.PHONY: clean
clean: clean-bindata
	rm -f <extension-name>

.PHONY: help
help:
	@echo "Available targets:"
	@echo "  bindata     - Generate bindata.go from $(DEST_TESTDATA_PATH)"
	@echo "  build       - Build extension binary (includes bindata)"
	@echo "  test        - Run Go tests"
	@echo "  list        - List all available tests"
	@echo "  clean       - Remove generated files"
```

#### Step 5: Create fixtures.go (in Custom Testdata Path)

Create `tests-extension/<dest-testdata-path>/fixtures.go`:

```go
package testdata

import (
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
	"sort"
	"strings"
)

var (
	// fixtureDir is where extracted fixtures are stored
	fixtureDir string
)

// init sets up the temporary directory for fixtures
func init() {
	var err error
	fixtureDir, err = ioutil.TempDir("", "testdata-fixtures-")
	if err != nil {
		panic(fmt.Sprintf("failed to create fixture directory: %v", err))
	}
}

// FixturePath returns the filesystem path to a test fixture file.
// This replaces functions like compat_otp.FixturePath().
//
// The file is extracted from embedded bindata to the filesystem on first access.
// Files are extracted to a temporary directory that persists for the test run.
//
// Example:
//   configPath := testdata.FixturePath("manifests/config.yaml")
//   data, err := os.ReadFile(configPath)
func FixturePath(relativePath string) string {
	targetPath := filepath.Join(fixtureDir, relativePath)

	// Check if already extracted
	if _, err := os.Stat(targetPath); err == nil {
		return targetPath
	}

	// Create parent directory
	if err := os.MkdirAll(filepath.Dir(targetPath), 0755); err != nil {
		panic(fmt.Sprintf("failed to create directory for %s: %v", relativePath, err))
	}

	// Try to restore single asset
	if err := RestoreAsset(fixtureDir, relativePath); err != nil {
		// If single file fails, try restoring as directory
		if err := RestoreAssets(fixtureDir, relativePath); err != nil {
			panic(fmt.Sprintf("failed to restore fixture %s: %v", relativePath, err))
		}
	}

	// Set appropriate permissions for directories
	if info, err := os.Stat(targetPath); err == nil && info.IsDir() {
		filepath.Walk(targetPath, func(path string, info os.FileInfo, err error) error {
			if err != nil {
				return err
			}
			if info.IsDir() {
				os.Chmod(path, 0755)
			} else {
				os.Chmod(path, 0644)
			}
			return nil
		})
	}

	return targetPath
}

// CleanupFixtures removes all extracted fixture files.
// Call this in test cleanup (e.g., AfterAll hook).
func CleanupFixtures() error {
	if fixtureDir != "" {
		return os.RemoveAll(fixtureDir)
	}
	return nil
}

// GetFixtureData reads and returns the contents of a fixture file directly from bindata.
// Use this for small files that don't need to be written to disk.
//
// Example:
//   data, err := testdata.GetFixtureData("config.yaml")
func GetFixtureData(relativePath string) ([]byte, error) {
	// Normalize path - bindata uses "testdata/" prefix
	cleanPath := relativePath
	if len(cleanPath) > 0 && cleanPath[0] == '/' {
		cleanPath = cleanPath[1:]
	}

	return Asset(filepath.Join("testdata", cleanPath))
}

// MustGetFixtureData is like GetFixtureData but panics on error.
// Useful in test initialization code.
func MustGetFixtureData(relativePath string) []byte {
	data, err := GetFixtureData(relativePath)
	if err != nil {
		panic(fmt.Sprintf("failed to get fixture data for %s: %v", relativePath, err))
	}
	return data
}

// Component-specific helper functions

// FixtureExists checks if a fixture exists in the embedded bindata.
// Use this to validate fixtures before accessing them.
//
// Example:
//   if testdata.FixtureExists("manifests/deployment.yaml") {
//       path := testdata.FixturePath("manifests/deployment.yaml")
//   }
func FixtureExists(relativePath string) bool {
	cleanPath := relativePath
	if len(cleanPath) > 0 && cleanPath[0] == '/' {
		cleanPath = cleanPath[1:]
	}
	_, err := Asset(filepath.Join("testdata", cleanPath))
	return err == nil
}

// ListFixtures returns all available fixture paths in the embedded bindata.
// Useful for debugging and test discovery.
//
// Example:
//   fixtures := testdata.ListFixtures()
//   fmt.Printf("Available fixtures: %v\n", fixtures)
func ListFixtures() []string {
	names := AssetNames()
	fixtures := make([]string, 0, len(names))
	for _, name := range names {
		// Remove "testdata/" prefix for cleaner paths
		if strings.HasPrefix(name, "testdata/") {
			fixtures = append(fixtures, strings.TrimPrefix(name, "testdata/"))
		}
	}
	sort.Strings(fixtures)
	return fixtures
}

// ListFixturesInDir returns all fixtures within a specific directory.
//
// Example:
//   manifests := testdata.ListFixturesInDir("manifests")
//   // Returns: ["manifests/deployment.yaml", "manifests/service.yaml", ...]
func ListFixturesInDir(dir string) []string {
	allFixtures := ListFixtures()
	var matching []string
	prefix := dir
	if !strings.HasSuffix(prefix, "/") {
		prefix = prefix + "/"
	}
	for _, fixture := range allFixtures {
		if strings.HasPrefix(fixture, prefix) {
			matching = append(matching, fixture)
		}
	}
	return matching
}

// GetManifest is a convenience function for accessing manifest files.
// Equivalent to FixturePath("manifests/" + name).
//
// Example:
//   deploymentPath := testdata.GetManifest("deployment.yaml")
func GetManifest(name string) string {
	return FixturePath(filepath.Join("manifests", name))
}

// GetConfig is a convenience function for accessing config files.
// Equivalent to FixturePath("configs/" + name).
//
// Example:
//   configPath := testdata.GetConfig("settings.yaml")
func GetConfig(name string) string {
	return FixturePath(filepath.Join("configs", name))
}

// ValidateFixtures checks that all expected fixtures are present in bindata.
// Call this in BeforeAll to catch missing testdata early.
//
// Example:
//   required := []string{"manifests/deployment.yaml", "configs/config.yaml"}
//   if err := testdata.ValidateFixtures(required); err != nil {
//       panic(err)
//   }
func ValidateFixtures(required []string) error {
	var missing []string
	for _, fixture := range required {
		if !FixtureExists(fixture) {
			missing = append(missing, fixture)
		}
	}
	if len(missing) > 0 {
		return fmt.Errorf("missing required fixtures: %v", missing)
	}
	return nil
}

// GetFixtureDir returns the temporary directory where fixtures are extracted.
// Use this if you need to pass a directory path to external tools.
//
// Example:
//   fixtureRoot := testdata.GetFixtureDir()
func GetFixtureDir() string {
	return fixtureDir
}
```

### Phase 6: Bingo Setup for go-bindata

Create the `.bingo/` directory structure for go-bindata tool management:

#### Create `.bingo/go-bindata.mod`:

```go
module _

go 1.19

require github.com/go-bindata/go-bindata v3.1.2+incompatible
```

#### Create `.bingo/Variables.mk`:

```makefile
# Auto generated binary variables helper managed by https://github.com/bwplotka/bingo v0.9. DO NOT EDIT.
# All tools are designed to be build inside $GOBIN.
BINGO_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
GOPATH ?= $(shell go env GOPATH)
GOBIN  ?= $(firstword $(subst :, ,${GOPATH}))/bin
GO     ?= $(shell which go)

# Below generated variables ensure that every time a tool under each variable is invoked, the correct version
# will be used; reinstalling only if needed.
# For example for go-bindata variable:
#
# In your main Makefile (for non array binaries):
#
#include .bingo/Variables.mk # Assuming -dir was set to .bingo .
#
#command: $(GO_BINDATA)
#	@echo "Running go-bindata"
#	@$(GO_BINDATA) <flags/args..>
#
GO_BINDATA := $(GOBIN)/go-bindata-v3.1.2+incompatible
$(GO_BINDATA): $(BINGO_DIR)/go-bindata.mod
	@# Install binary/ries using Go 1.14+ build command. This is using bwplotka/bingo-controlled, separate go module with pinned dependencies.
	@echo "(re)installing $(GOBIN)/go-bindata-v3.1.2+incompatible"
	@cd $(BINGO_DIR) && GOWORK=off $(GO) build -mod=mod -modfile=go-bindata.mod -o=$(GOBIN)/go-bindata-v3.1.2+incompatible github.com/go-bindata/go-bindata/go-bindata
```

#### Create `.bingo/.gitignore`:

```
# Ignore everything
*

# But not these files:
!.gitignore
!*.mod
!*.sum
!Variables.mk
!variables.env
!README.md
```

#### Create `.bingo/README.md`:

```markdown
# Bingo Managed Tools

This directory contains Go module files for pinning development tool versions.

## Tools

- `go-bindata` - Embeds binary data into Go programs

## Usage

The Makefile automatically builds tools as needed using:
```bash
make bindata  # Builds go-bindata if needed and generates bindata.go
```

## How It Works

- Tool versions are pinned in `*.mod` files
- `Variables.mk` contains Makefile integration
- Tools are built with `go build -modfile=<tool>.mod`
- **No need to install bingo globally** - everything is self-contained

## Updating Tool Versions

If you have bingo installed:
```bash
bingo get github.com/go-bindata/go-bindata/go-bindata@<version>
```

Or manually edit `go-bindata.mod` and update the version.
```

#### Create `.gitignore` Entry:

Add to `tests-extension/.gitignore`:

```
# Generated bindata file
<dest-testdata-path>/bindata.go

# Built binaries
<extension-name>
```

### Phase 7: Test Migration (2 steps)

#### Step 1: Add Testdata Import

Search all test files in `<dest-test-path>` and add the testdata import:

```bash
# Find all test files
find <dest-test-path> -name '*_test.go' -type f

# For each file, check if it uses FixturePath and add import if needed
```

Add to test files:
```go
import (
    "github.com/<org>/<extension-name>-tests-extension/<dest-testdata-path-normalized>"
)
```

#### Step 2: Replace FixturePath Calls

Search and replace in all test files:

**Search for patterns:**
```bash
grep -r "compat_otp.FixturePath" <dest-test-path>/
grep -r "exutil.FixturePath" <dest-test-path>/
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

**Using component-specific helpers:**
```go
// Instead of:
deploymentPath := testdata.FixturePath("manifests/deployment.yaml")

// Use convenience function:
deploymentPath := testdata.GetManifest("deployment.yaml")

// Instead of:
configPath := testdata.FixturePath("configs/settings.yaml")

// Use convenience function:
configPath := testdata.GetConfig("settings.yaml")
```

**Remove old imports:**
```go
// Remove or comment out:
// "github.com/openshift/origin/test/extended/util/compat_otp"
// "github.com/openshift/origin/test/extended/util"
```

### Phase 8: Documentation (1 step)

#### Generate Migration Summary

Provide a comprehensive summary:

```markdown
# OTE Migration Complete! 🎉

## Summary

Successfully migrated **<extension-name>** to OpenShift Tests Extension (OTE) framework.

## Created Structure

```
tests-extension/
├── .bingo/                           # go-bindata tool management (committed)
│   ├── go-bindata.mod
│   ├── Variables.mk
│   ├── .gitignore
│   └── README.md
├── cmd/
│   └── <extension-name>/
│       └── main.go                   # OTE entry point
├── <dest-test-path>/                 # Test files (custom path)
│   └── *_test.go
├── <dest-testdata-path>/             # Testdata files (custom path)
│   ├── bindata.go                    # Generated (run 'make bindata')
│   └── fixtures.go                   # Wrapper functions
├── repos/                            # Cloned repositories
│   ├── source/                       # Source repo
│   └── target/                       # Target repo
├── go.mod
├── Makefile                          # Build targets
├── bindata.mk                        # Bindata generation rules
└── .gitignore
```

## Configuration

**Extension:** <extension-name>
**Working Directory:** <working-dir>

**Source Repository:** <source-repo-url>
  - Test Files: <source-test-path>
  - Testdata: <source-testdata-path>

**Target Repository:** <target-repo-url>

**Destination Paths:** (⭐ Customized)
  - Test Files: <dest-test-path>
  - Testdata: <dest-testdata-path>

## Files Created/Modified

### Generated Code
- ✅ `cmd/<extension-name>/main.go` - OTE entry point with filters and hooks
- ✅ `<dest-testdata-path>/fixtures.go` - Testdata wrapper functions
- ✅ `go.mod` - Go module with OTE dependencies
- ✅ `Makefile` - Build targets (custom testdata path: <dest-testdata-path>)
- ✅ `bindata.mk` - Bindata generation rules

### Bingo Infrastructure
- ✅ `.bingo/go-bindata.mod` - Pinned go-bindata version
- ✅ `.bingo/Variables.mk` - Makefile integration
- ✅ `.bingo/.gitignore` - Bingo directory gitignore
- ✅ `.bingo/README.md` - Documentation

### Test Files
- ✅ Copied **X** test files to `<dest-test-path>/`
- ✅ Copied **Y** testdata files to `<dest-testdata-path>/`
- ✅ Updated imports to use `testdata.FixturePath()`
- ✅ Replaced old `compat_otp.FixturePath()` calls

## Statistics

- **Test files:** X files
- **Testdata files:** Y files (or "none" if not applicable)
- **Platform filters:** Detected from labels and test names
- **Test suites:** 1 main suite (`<org>/<extension-name>/tests`)

## Next Steps

### 1. Generate Bindata

```bash
cd <working-dir>/tests-extension
make bindata
```

This creates `<dest-testdata-path>/bindata.go` with embedded test data.
**Note:** You don't need to install bingo - the Makefile handles everything!

### 2. Update Dependencies

```bash
go get github.com/openshift-eng/openshift-tests-extension@latest
go mod tidy
```

### 3. Build Extension

```bash
make build
# Or manually:
# go build -o <extension-name> ./cmd/<extension-name>
```

### 4. Validate Tests

```bash
# List all discovered tests
make list
# Or: ./<extension-name> list

# Run tests in dry-run mode
./<extension-name> run --dry-run

# Test platform filtering
./<extension-name> run --platform=aws --dry-run
```

### 5. Run Tests

```bash
# Run all tests
./<extension-name> run

# Run specific test
./<extension-name> run "test name pattern"

# Run with platform filter
./<extension-name> run --platform=aws
```

## Customization Options

### Add More Environment Filters

Edit `cmd/<extension-name>/main.go` and add filters:

```go
// Network filter
specs.Walk(func(spec *et.ExtensionTestSpec) {
    if strings.Contains(spec.Name, "[network:ovn]") {
        spec.Include(et.NetworkEquals("ovn"))
    }
})

// Topology filter
specs.Walk(func(spec *et.ExtensionTestSpec) {
    re := regexp.MustCompile(` + "`\\[topology:(ha|single)\\]`" + `)
    if match := re.FindStringSubmatch(spec.Name); match != nil {
        spec.Include(et.TopologyEquals(match[1]))
    }
})
```

### Add Custom Test Suites

```go
// Slow tests suite
ext.AddSuite(e.Suite{
    Name: "<org>/<extension-name>/slow",
    Qualifiers: []string{
        ` + "`labels.exists(l, l==\"SLOW\")`" + `,
    },
})

// Conformance tests suite
ext.AddSuite(e.Suite{
    Name: "<org>/<extension-name>/conformance",
    Qualifiers: []string{
        ` + "`labels.exists(l, l==\"Conformance\")`" + `,
    },
})
```

### Add More Hooks

```go
// Before each test
specs.AddBeforeEach(func() {
    // Setup for each test
})

// After each test
specs.AddAfterEach(func(res *et.ExtensionTestResult) {
    if res.Result == et.ResultFailed {
        // Collect diagnostics on failure
    }
})
```

## Important Notes

- **Always run `make bindata` before building** to regenerate embedded testdata
- **`<dest-testdata-path>/bindata.go` is in .gitignore** - regenerated on each build
- **`.bingo/` directory IS committed** - contains tool version configuration
- **No need to install bingo** - Makefile uses `go build -modfile`
- **Use `testdata.FixturePath()`** in tests to replace `compat_otp.FixturePath()`
- **Cleanup is automatic** - `CleanupFixtures()` hook is already added

## Troubleshooting

### Tests not discovered
- Check that test files are in `<dest-test-path>/`
- Verify imports in `cmd/<extension-name>/main.go`
- Ensure test packages are not vendored

### Bindata errors
- Run `make bindata` before building
- Check that `<dest-testdata-path>/` exists and contains files
- Verify `.bingo/Variables.mk` is present

### Platform filters not working
- Check test name patterns (case-sensitive)
- Verify label format: `Platform:aws` (capital P)
- Test with: `./<extension-name> run --platform=aws --dry-run`

## Resources

- [OTE Framework Enhancement](https://github.com/openshift/enhancements/pull/1676)
- [OTE Framework Repository](https://github.com/openshift-eng/openshift-tests-extension)
- [Environment Selectors Documentation](https://github.com/openshift-eng/openshift-tests-extension/blob/main/pkg/extension/extensiontests/environment.go)

```

## Validation Steps

After migration, guide the user through validation:

1. **Build the extension:**
   ```bash
   cd <working-dir>/tests-extension
   make build
   ```

2. **List tests:**
   ```bash
   ./<extension-name> list
   ```

3. **Run dry-run:**
   ```bash
   ./<extension-name> run --dry-run
   ```

4. **Verify environment filtering:**
   ```bash
   ./<extension-name> run --platform=aws --dry-run
   ./<extension-name> run --platform=gcp --dry-run
   ```

5. **Run actual tests:**
   ```bash
   # Run all tests
   ./<extension-name> run

   # Run specific test
   ./<extension-name> run "test name"
   ```

## Important Implementation Notes

### Path Normalization

When converting file paths to Go import paths:
- `test/testdata` → `test/testdata` (no change needed)
- `pkg/test/data` → `pkg/test/data`
- Remove leading/trailing slashes
- Replace any non-Go-identifier characters if present

### Git Repository Handling

- Always check if `repos/source` and `repos/target` exist before cloning
- Use `git fetch && git pull` for updates
- Handle authentication errors gracefully
- Allow user to specify branch if needed (default: main/master)

### Error Handling

- Verify directories exist before copying
- Check for write permissions
- Warn if files will be overwritten
- Validate Go module structure
- Ensure testdata path is not empty if files are being copied

### Template Placeholders

Replace these placeholders with actual values:
- `<extension-name>` - Extension name from user input
- `<org>` - Organization extracted from target repo URL
- `<working-dir>` - Working directory path
- `<source-repo-url>` - Source repository URL
- `<target-repo-url>` - Target repository URL
- `<source-test-path>` - Source test file path
- `<source-testdata-path>` - Source testdata path
- `<dest-test-path>` - Destination test path
- `<dest-testdata-path>` - Destination testdata path
- `<dest-testdata-path-normalized>` - Go import path for testdata
- `<dest-test-path-normalized>` - Go import path for tests

## Begin Migration

Start by collecting all user inputs from Phase 2, then proceed through each phase systematically!
