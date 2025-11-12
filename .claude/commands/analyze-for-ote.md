---
description: Analyze a repository to understand what's needed for OTE migration
---

# OTE Migration Preparation

You are preparing a component repository for openshift-tests-extension (OTE) migration by setting up the necessary infrastructure and template code.

## Task

Prepare the target repository for OTE migration by:
1. Collecting repository information
2. Creating the OTE file structure
3. Generating testdata extraction utilities
4. Creating template code for OTE interfaces

## Steps

### 1. Collect Target Repository Information

Ask the user for the following information about the **target repository** (where OTE will be integrated):

**Required Information:**
- Target repository path (default: current directory)
- Extension name (e.g., "sdn", "cluster-network-operator")
- Target directory for OTE code (default: `cmd/<extension-name>`)
- Go module name (read from `go.mod` if exists, otherwise ask)

**Display collected info:**
```
Target Repository Configuration:
- Path: /path/to/target/repo
- Extension: <extension-name>
- OTE Directory: cmd/<extension-name>
- Module: github.com/org/repo
```

### 2. Collect Test Cases and Test Data Locations

Ask the user for the following information in two separate questions:

**Question 1: Test Cases Location**
Ask: "What is the absolute path to the directory containing your test case files?"
- No default value
- User must provide the full path to where test files (*_test.go) are located
- Example: `/home/user/repos/openshift/private-tests/test/e2e`

**Question 2: Test Data Location**
Ask: "What is the absolute path to the directory containing your test data files? (Enter 'none' if no test data exists)"
- No default value
- User must provide the full path to where test data files are located
- Allow user to specify "none" if no test data exists
- Example: `/home/user/repos/openshift/private-tests/test/e2e/testdata` or `none`

**Display collected info:**
```
Test Cases and Test Data Configuration:
- Test Cases Location: /path/to/test/cases
- Test Data Location: /path/to/test/data (or "none")
```

### 3. Create File Structure in Target Repository

Create the following directory structure in the target repository:

```
target-repo/
├── cmd/
│   └── <extension-name>/
│       └── main.go                    # OTE entry point (template)
├── pkg/
│   └── <extension-name>/
│       ├── testdata/
│       │   ├── extractor.go           # Testdata extraction utility
│       │   └── extractor_test.go      # Tests for extractor
│       └── extension/
│           ├── extension.go           # OTE extension interface implementation
│           └── extension_test.go      # Tests for extension
└── test/
    ├── e2e/                           # Test files (copied from private repo)
    └── testdata/                      # Test data files (copied from private repo)
```

**Implementation:**
```bash
# Create directories
mkdir -p cmd/<extension-name>
mkdir -p pkg/<extension-name>/testdata
mkdir -p pkg/<extension-name>/extension
mkdir -p test/e2e
mkdir -p test/testdata
```

### 4. Setup Bingo Configuration for go-bindata

Create `.bingo/` directory structure to manage go-bindata tool version. This allows users to build go-bindata without installing bingo globally.

**Create `.bingo/go-bindata.mod`:**

```go
module _

go 1.19

require github.com/go-bindata/go-bindata v3.1.2+incompatible
```

**Create `.bingo/Variables.mk`:**

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

**Create `.bingo/.gitignore`:**

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

**Create `.bingo/README.md`:**

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

**Note:** The `.bingo/` directory should be committed to git. Users will NOT need to install bingo - the Makefile builds tools using `go build -modfile`.

### 5. Create Makefile for Bindata Generation

Create or update `Makefile` in the repository root with bindata generation rules.

**Makefile:**

```makefile
# Include bingo variables for tool management
include .bingo/Variables.mk

# Generate bindata.go from test/testdata directory
.PHONY: bindata
bindata: test/testdata/bindata.go

test/testdata/bindata.go: $(GO_BINDATA) $(shell find test/testdata -type f -not -name 'bindata.go' 2>/dev/null)
	@echo "Generating bindata from test/testdata..."
	mkdir -p $(@D)
	$(GO_BINDATA) -nocompress -nometadata \
		-pkg testdata -o $@ -prefix "test" test/testdata/...
	gofmt -s -w $@
	@echo "Bindata generated successfully"

.PHONY: clean-bindata
clean-bindata:
	rm -f test/testdata/bindata.go
```

**Key points:**
- `include .bingo/Variables.mk` - Imports `$(GO_BINDATA)` variable
- `$(GO_BINDATA)` dependency automatically builds go-bindata if missing
- Users don't need to install bingo - Makefile handles everything

**Parameters explained:**
- `-nocompress` - Don't compress embedded data (faster runtime access)
- `-nometadata` - Don't include file modification times/modes
- `-pkg testdata` - Generated code will be in package `testdata`
- `-o test/testdata/bindata.go` - Output file path
- `-prefix "test"` - Strip "test" prefix from embedded paths
- `test/testdata/...` - Source directory (embeds all files recursively)

### 6. Generate Testdata Wrapper Functions

Create `test/testdata/fixtures.go` with wrapper functions that provide a clean API for accessing embedded testdata.

**Generate this file:**

```go
package testdata

import (
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
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
```

**Key wrapper functions:**

1. **`FixturePath(relativePath) string`** - Main replacement for `compat_otp.FixturePath()`
2. **`CleanupFixtures() error`** - Cleanup extracted files (call in AfterAll hook)
3. **`GetFixtureData(relativePath) ([]byte, error)`** - Direct access to embedded data
4. **`MustGetFixtureData(relativePath) []byte`** - Panic version for test init

### 7. Create .gitignore Entry

Add bindata.go to .gitignore since it's a generated file:

```bash
# Create or update .gitignore
if [ -f .gitignore ]; then
    # Add if not already present
    grep -q "test/testdata/bindata.go" .gitignore || echo "test/testdata/bindata.go" >> .gitignore
else
    echo "test/testdata/bindata.go" > .gitignore
fi
```

### 8. Create OTE Extension Template

Generate `pkg/<extension-name>/extension/extension.go` with OTE interface template:

```go
package extension

import (
    "github.com/openshift-eng/openshift-tests-extension/pkg/extension"
    et "github.com/openshift-eng/openshift-tests-extension/pkg/extensiontests"
)

const (
    // ExtensionName is the name of this extension
    ExtensionName = "<extension-name>"
)

// Extension implements the OTE Extension interface
type Extension struct{}

// NewExtension creates a new extension instance
func NewExtension() *Extension {
    return &Extension{}
}

// Name returns the extension name
func (e *Extension) Name() string {
    return ExtensionName
}

// Register registers the extension with OTE
func (e *Extension) Register(ext *extension.Extension) error {
    // Register test suites
    ext.AddSuite(extension.Suite{
        Name:    "openshift/<component>/tests",
        Parents: []string{"openshift/conformance/parallel"},
    })

    // TODO: Add more suites as needed
    // Example:
    // ext.AddSuite(extension.Suite{
    //     Name: "openshift/<component>/conformance",
    //     Qualifiers: []string{
    //         `labels.exists(l, l=="Conformance")`,
    //     },
    // })

    return nil
}

// BuildTestSpecs builds and configures test specs
func (e *Extension) BuildTestSpecs(specs *et.ExtensionTestSpecBuilder) error {
    // TODO: Add platform filters
    // Example:
    // specs.Walk(func(spec *et.ExtensionTestSpec) {
    //     re := regexp.MustCompile(`\[platform:([a-z]+)\]`)
    //     if match := re.FindStringSubmatch(spec.Name); match != nil {
    //         platform := match[1]
    //         spec.Include(et.PlatformEquals(platform))
    //     }
    // })

    // TODO: Add label-based filters
    // Example:
    // specs.Walk(func(spec *et.ExtensionTestSpec) {
    //     for label := range spec.Labels {
    //         if strings.HasPrefix(label, "Platform:") {
    //             platformName := strings.TrimPrefix(label, "Platform:")
    //             spec.Include(et.PlatformEquals(platformName))
    //         }
    //     }
    // })

    return nil
}

// SetupHooks configures test lifecycle hooks
func (e *Extension) SetupHooks(specs *et.ExtensionTestSpecBuilder) error {
    // TODO: Add BeforeAll hook for test setup
    // Example:
    // specs.AddBeforeAll(func() {
    //     // Initialize test framework
    //     // Extract test data
    // })

    // TODO: Add AfterEach hook for cleanup
    // Example:
    // specs.AddAfterEach(func(res *et.ExtensionTestResult) {
    //     if res.Result == et.ResultFailed {
    //         // Collect diagnostics
    //     }
    // })

    // TODO: Add AfterAll hook
    // Example:
    // specs.AddAfterAll(func() {
    //     // Cleanup test data
    // })

    return nil
}
```

### 9. Create Main Entry Point Template

Generate `cmd/<extension-name>/main.go`:

```go
package main

import (
    "github.com/openshift-eng/openshift-tests-extension/pkg/extension"

    ext "<module-name>/pkg/<extension-name>/extension"

    // Import test packages here
    // _ "<module-name>/test/e2e"
)

func main() {
    // Create and register extension
    e := ext.NewExtension()

    if err := extension.Run(e); err != nil {
        panic(err)
    }
}
```

### 10. Copy Test Files and Test Data

After creating the structure and templates:

1. **Copy test files** to target repo:
   ```bash
   cp -r <test-cases-location>/* <target-repo>/test/e2e/
   ```
   Use the absolute path provided by the user in Question 1.

2. **Copy test data** to target repo (skip if user specified "none"):
   ```bash
   cp -r <test-data-location>/* <target-repo>/test/testdata/
   ```
   Use the absolute path provided by the user in Question 2.
   If user specified "none", skip this step.

3. **Verify the copy**:
   - List copied files
   - Count test files
   - Check test data integrity (if applicable)

### 11. Generate Summary Report

Provide a summary of what was created:

```markdown
# OTE Migration Preparation Complete

## Created Directory Structure

### Build Infrastructure
- `.bingo/` - go-bindata version management (committed to git)
  - `go-bindata.mod` - Pinned go-bindata version
  - `go-bindata.sum` - Checksums
  - `Variables.mk` - Makefile integration
  - `.gitignore` - Bingo directory gitignore
  - `README.md` - Documentation
- `Makefile` - Build targets for bindata generation
- `.gitignore` - Updated to ignore generated bindata.go

### OTE Framework Code
- `cmd/<extension-name>/main.go` - OTE entry point template
- `pkg/<extension-name>/extension/extension.go` - OTE extension interface
- `pkg/<extension-name>/extension/extension_test.go` - Extension tests

### Testdata Handling
- `test/testdata/fixtures.go` - Wrapper functions for testdata access
  - `FixturePath()` - Replaces `compat_otp.FixturePath()`
  - `CleanupFixtures()` - Cleanup hook
  - `GetFixtureData()` - Direct access to embedded data
- `test/testdata/bindata.go` - (Will be generated by `make bindata`)

### Test Files
- `test/e2e/` - Test files (copied from <test-cases-location>)
- `test/testdata/` - Test data files (copied from <test-data-location>)

## Files Copied
- Test files: X files from <test-cases-location>
- Test data: Y files from <test-data-location> (or "none" if not applicable)

## Next Steps

1. **Generate bindata from testdata files:**
   ```bash
   make bindata
   ```
   This creates `test/testdata/bindata.go` with embedded test data.
   **Note:** You don't need to install bingo - the Makefile handles everything!

2. **Update `go.mod` dependencies:**
   ```bash
   go get github.com/openshift-eng/openshift-tests-extension
   go mod tidy
   ```

3. **Import test packages in `cmd/<extension-name>/main.go`:**
   ```go
   import (
       _ "<module-name>/test/e2e"
   )
   ```

4. **Review generated template code:**
   - `pkg/<extension-name>/extension/extension.go` - OTE interface implementation
   - `test/testdata/fixtures.go` - Testdata wrapper functions
   - `cmd/<extension-name>/main.go` - Main entry point

5. **Build and test:**
   ```bash
   # Generate bindata and build
   make bindata
   go build ./cmd/<extension-name>

   # List tests
   ./<extension-name> list

   # Dry run
   ./<extension-name> run --dry-run
   ```

6. **Run `/migrate-ote` to complete the migration:**
   - Implements platform filters based on test patterns
   - Adds test suites
   - Updates test code to use `testdata.FixturePath()`
   - Adds cleanup hooks
   - Generates final main.go implementation

## Important Notes

- **Always run `make bindata` before building** to regenerate embedded testdata
- **`test/testdata/bindata.go` is in .gitignore** - it's regenerated on each build
- **`.bingo/` directory IS committed** - contains tool version configuration
- **No need to install bingo** - Makefile uses `go build -modfile` to build tools
- **Use `testdata.FixturePath()`** in your tests to replace `compat_otp.FixturePath()`
- **Cleanup is automatic** - `/migrate-ote` will add the `CleanupFixtures()` hook
```

## Implementation Notes

**Error Handling:**
- Verify directories exist before copying
- Check for write permissions in target repo
- Warn if files will be overwritten
- Validate Go module structure

**Template Placeholders:**
- Replace `<extension-name>` with actual extension name
- Replace `<module-name>` with actual Go module path
- Replace `<component>` with component name from extension name

Start by asking the user for the target repository path and extension name.
