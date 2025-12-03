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

### Phase 2: User Input Collection (up to 12 inputs, some conditional)

Collect all necessary information from the user before starting the migration.

**Note:** Source repository is always `git@github.com:openshift/openshift-tests-private.git`

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

#### Input 4: Local Source Repository (Optional)

Ask: "Do you have a local clone of openshift-tests-private? If yes, provide the path (or press Enter to clone it):"
- If provided: Use this existing local repository
- If empty: Will clone `git@github.com:openshift/openshift-tests-private.git`
- Example: `/home/user/repos/openshift-tests-private`

#### Input 5: Update Local Source Repository (if local source provided)

If a local source repository path was provided:
Ask: "Do you want to update the local source repository? (git fetch && git pull) [Y/n]:"
- Default: Yes
- If yes: Run `git fetch && git pull` in the local repo
- If no: Use current state

#### Input 6: Source Test Subfolder

Ask: "What is the test subfolder name under test/extended/?"
- Example: "networking", "router", "storage", "templates"
- This will be used as: `test/extended/<subfolder>/`
- Leave empty to use all of `test/extended/`

#### Input 7: Source Testdata Subfolder (Optional)

Ask: "What is the testdata subfolder name under test/extended/testdata/? (or press Enter to use same as test subfolder)"
- Default: Same as Input 6 (test subfolder)
- Example: "networking", "router", etc.
- This will be used as: `test/extended/testdata/<subfolder>/`
- Enter "none" if no testdata exists

#### Input 8: Local Target Repository (Optional)

Ask: "Do you have a local clone of the target repository? If yes, provide the path (or press Enter to clone from URL):"
- If provided: Use this existing local repository
  - Can be absolute path: `/home/user/repos/sdn`
  - Can be relative path: `../sdn`
  - Can be current directory: `.`
- If empty: Will ask for URL to clone (Input 9)
- After providing a path, you will be asked in Input 10 if you want to update it

#### Input 9: Target Repository URL (if no local target provided)

If no local target repository was provided in Input 8:
Ask: "What is the Git URL of the target repository (component repository)?"
- Example: `git@github.com:openshift/sdn.git`
- This is where the OTE integration will be added

#### Input 10: Update Local Target Repository (if local target provided)

**IMPORTANT:** This input is REQUIRED when Input 8 provided a local path.

If a local target repository path was provided in Input 8:
1. First, check if the path is a git repository (has `.git` directory)
2. If it IS a git repository, ask:
   "Do you want to update the local target repository? (git fetch && git pull) [Y/n]:"
   - Default: Yes
   - User can answer: Y (yes) or N (no)
3. If it is NOT a git repository, skip this question and show warning

**Examples:**
- User provided: `/home/user/repos/sdn` → Ask this question
- User provided: `.` (current directory) → Ask this question if it's a git repo
- User pressed Enter in Input 8 → Skip this question (will clone instead)

**Action:**
- If yes: Run `cd <target-path> && git fetch origin && git pull`
- If no: Use current state without updating

#### Input 11: Destination Test Path (⭐ CUSTOMIZABLE)

Ask: "What is the destination path for test files in tests-extension?"
- Default: `test/e2e/`
- This is customizable - users can specify any path
- Example: `test/integration/`, `pkg/tests/`

#### Input 12: Destination Testdata Path (⭐ CUSTOMIZABLE)

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

Source Repository (openshift-tests-private):
  URL: git@github.com:openshift/openshift-tests-private.git
  Local Path: <local-source-path> (or "Will clone")
  Test Subfolder: test/extended/<test-subfolder>/
  Testdata Subfolder: test/extended/testdata/<testdata-subfolder>/

Target Repository:
  Local Path: <local-target-path> (or "Will clone from URL")
  URL: <target-repo-url> (if cloning)

Destination Paths (in tests-extension/):
  Test Files: <dest-test-path>
  Testdata: <dest-testdata-path>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Ask for confirmation before proceeding.

### Phase 3: Repository Setup (2 steps)

#### Step 1: Setup Source Repository

**Hardcoded Source:** `git@github.com:openshift/openshift-tests-private.git`

Two scenarios:

**A) If user provided local source repository path:**
```bash
cd <working-dir>
mkdir -p repos

# Use the local repo path directly
SOURCE_REPO="<local-source-path>"

# Update if user requested
if [ "<update-source>" = "yes" ]; then
    echo "Updating openshift-tests-private repository..."
    cd "$SOURCE_REPO"
    git fetch origin
    git pull
    cd - > /dev/null
fi
```

**B) If no local source repository (need to clone):**
```bash
cd <working-dir>
mkdir -p repos

# Clone or update openshift-tests-private
if [ -d "repos/openshift-tests-private" ]; then
    echo "Updating openshift-tests-private repository..."
    cd repos/openshift-tests-private
    git fetch origin
    git pull
    cd ../..
    SOURCE_REPO="repos/openshift-tests-private"
else
    echo "Cloning openshift-tests-private repository..."
    git clone git@github.com:openshift/openshift-tests-private.git repos/openshift-tests-private
    SOURCE_REPO="repos/openshift-tests-private"
fi
```

**Set source paths based on subfolder inputs:**
```bash
# Set full source paths
if [ -z "<test-subfolder>" ]; then
    SOURCE_TEST_PATH="$SOURCE_REPO/test/extended"
else
    SOURCE_TEST_PATH="$SOURCE_REPO/test/extended/<test-subfolder>"
fi

if [ "<testdata-subfolder>" = "none" ]; then
    SOURCE_TESTDATA_PATH=""
elif [ -z "<testdata-subfolder>" ]; then
    SOURCE_TESTDATA_PATH="$SOURCE_REPO/test/extended/testdata"
else
    SOURCE_TESTDATA_PATH="$SOURCE_REPO/test/extended/testdata/<testdata-subfolder>"
fi
```

#### Step 2: Setup Target Repository

Two scenarios:

**A) If user provided local target repository path:**
```bash
# Use the local repo path directly in subsequent steps
TARGET_REPO="<local-target-path>"

# Check if it's a git repository and update if user requested
if [ -d "$TARGET_REPO/.git" ]; then
    if [ "<update-target>" = "yes" ]; then
        echo "Updating target repository at $TARGET_REPO..."
        cd "$TARGET_REPO"
        git fetch origin
        git pull
        cd - > /dev/null
        echo "Target repository updated successfully"
    else
        echo "Using target repository at $TARGET_REPO (not updating)"
    fi
else
    echo "Warning: $TARGET_REPO is not a git repository"
fi
```

**B) If no local target repository (need to clone):**
```bash
# Clone or update target repo
if [ -d "repos/target" ]; then
    echo "Updating target repository..."
    cd repos/target
    git fetch origin
    git pull
    cd ../..
    TARGET_REPO="repos/target"
else
    echo "Cloning target repository..."
    git clone <target-repo-url> repos/target
    TARGET_REPO="repos/target"
fi
```

**Note:** In subsequent phases, use `$SOURCE_REPO` and `$TARGET_REPO` variables instead of hardcoded `repos/source` and `repos/target` paths.

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
```

#### Step 3: Copy Test Files to Custom Destination

```bash
# Copy test files from source to custom destination
# Use $SOURCE_TEST_PATH variable (set in Phase 3)
cp -r "$SOURCE_TEST_PATH"/* <dest-test-path>/

# Count and display copied files
echo "Copied $(find <dest-test-path> -name '*_test.go' | wc -l) test files from $SOURCE_TEST_PATH"
```

#### Step 4: Copy Testdata to Custom Destination

```bash
# Copy testdata if it exists (skip if user specified "none")
# Use $SOURCE_TESTDATA_PATH variable (set in Phase 3)
if [ -n "$SOURCE_TESTDATA_PATH" ]; then
    cp -r "$SOURCE_TESTDATA_PATH"/* <dest-testdata-path>/
    echo "Copied testdata files from $SOURCE_TESTDATA_PATH to <dest-testdata-path>"
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

# go-bindata tool
GO_BINDATA ?= $(shell go env GOPATH)/bin/go-bindata

# Install go-bindata if not present
.PHONY: install-go-bindata
install-go-bindata:
	@which go-bindata > /dev/null 2>&1 || \
		(echo "Installing go-bindata..." && \
		go install github.com/go-bindata/go-bindata/v3/go-bindata@latest)

# Generate bindata.go from testdata directory
.PHONY: bindata
bindata: install-go-bindata $(DEST_TESTDATA_PATH)/bindata.go

$(DEST_TESTDATA_PATH)/bindata.go: $(shell find $(DEST_TESTDATA_PATH) -type f -not -name 'bindata.go' 2>/dev/null)
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

### Phase 6: Test Migration (2 steps)

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

### Phase 7: Documentation (1 step)

#### Generate Migration Summary

Provide a comprehensive summary:

```markdown
# OTE Migration Complete! 🎉

## Summary

Successfully migrated **<extension-name>** to OpenShift Tests Extension (OTE) framework.

## Created Structure

```
tests-extension/
├── cmd/
│   └── <extension-name>/
│       └── main.go                   # OTE entry point
├── <dest-test-path>/                 # Test files (custom path)
│   └── *_test.go
├── <dest-testdata-path>/             # Testdata files (custom path)
│   ├── bindata.go                    # Generated (run 'make bindata')
│   └── fixtures.go                   # Wrapper functions
├── repos/                            # Cloned repositories (if not using local)
│   ├── openshift-tests-private/      # Source repo
│   └── target/                       # Target repo
├── go.mod
├── Makefile                          # Build targets
└── bindata.mk                        # Bindata generation rules
```

## Configuration

**Extension:** <extension-name>
**Working Directory:** <working-dir>

**Source Repository:** git@github.com:openshift/openshift-tests-private.git
  - Local Path: <local-source-path> (or "Cloned to repos/openshift-tests-private")
  - Test Subfolder: test/extended/<test-subfolder>/
  - Testdata Subfolder: test/extended/testdata/<testdata-subfolder>/

**Target Repository:** <target-repo-url>
  - Local Path: <local-target-path> (or "Cloned to repos/target")

**Destination Paths:** (⭐ Customized)
  - Test Files: <dest-test-path>
  - Testdata: <dest-testdata-path>

## Files Created/Modified

### Generated Code
- ✅ `cmd/<extension-name>/main.go` - OTE entry point with filters and hooks
- ✅ `<dest-testdata-path>/fixtures.go` - Testdata wrapper functions
- ✅ `go.mod` - Go module with OTE dependencies
- ✅ `Makefile` - Build targets (custom testdata path: <dest-testdata-path>)
- ✅ `bindata.mk` - Bindata generation rules (auto-installs go-bindata)

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
**Note:** The Makefile will automatically install go-bindata if not present!

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
- **`<dest-testdata-path>/bindata.go` is generated** - not committed to git
- **go-bindata is auto-installed** - Makefile uses `go install` if not present
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
- Ensure go-bindata is installed (Makefile auto-installs it)

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
