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

### 2. Collect Private Repository Information

Ask the user for information about the **private repository** (source of tests and test data):

**Required Information:**
- Private repository path
- Test files directory (e.g., `test/e2e`, `e2e`, `tests/e2e`)
  - Auto-detect by searching for `*_test.go` files, show options to user
- Test data directory (e.g., `test/e2e/testdata`, `testdata`, `fixtures`)
  - Auto-detect common locations, show options to user
  - Allow user to specify "none" if no test data exists

**Display collected info:**
```
Private Repository Configuration:
- Path: /path/to/private/repo
- Test Directory: test/e2e
- Test Data Directory: test/e2e/testdata
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

### 4. Create Testdata Extraction Utilities

Generate `pkg/<extension-name>/testdata/extractor.go` with the following template:

```go
package testdata

import (
    "embed"
    "fmt"
    "os"
    "path/filepath"
)

//go:embed ../../../test/testdata
var testDataFS embed.FS

// Extractor handles extracting embedded test data to the filesystem
type Extractor struct {
    targetDir string
}

// NewExtractor creates a new testdata extractor
func NewExtractor(targetDir string) *Extractor {
    return &Extractor{
        targetDir: targetDir,
    }
}

// Extract writes all embedded test data to the target directory
func (e *Extractor) Extract() error {
    if err := os.MkdirAll(e.targetDir, 0755); err != nil {
        return fmt.Errorf("failed to create target directory: %w", err)
    }

    return e.extractDir("test/testdata", e.targetDir)
}

// extractDir recursively extracts a directory from the embedded FS
func (e *Extractor) extractDir(embedPath, targetPath string) error {
    entries, err := testDataFS.ReadDir(embedPath)
    if err != nil {
        return fmt.Errorf("failed to read directory %s: %w", embedPath, err)
    }

    for _, entry := range entries {
        srcPath := filepath.Join(embedPath, entry.Name())
        dstPath := filepath.Join(targetPath, entry.Name())

        if entry.IsDir() {
            if err := os.MkdirAll(dstPath, 0755); err != nil {
                return fmt.Errorf("failed to create directory %s: %w", dstPath, err)
            }
            if err := e.extractDir(srcPath, dstPath); err != nil {
                return err
            }
        } else {
            if err := e.extractFile(srcPath, dstPath); err != nil {
                return err
            }
        }
    }

    return nil
}

// extractFile extracts a single file from the embedded FS
func (e *Extractor) extractFile(embedPath, targetPath string) error {
    data, err := testDataFS.ReadFile(embedPath)
    if err != nil {
        return fmt.Errorf("failed to read file %s: %w", embedPath, err)
    }

    if err := os.WriteFile(targetPath, data, 0644); err != nil {
        return fmt.Errorf("failed to write file %s: %w", targetPath, err)
    }

    return nil
}

// Clean removes the extracted test data directory
func (e *Extractor) Clean() error {
    return os.RemoveAll(e.targetDir)
}

// GetPath returns a path to an extracted file
func (e *Extractor) GetPath(relativePath string) string {
    return filepath.Join(e.targetDir, relativePath)
}
```

Also generate `pkg/<extension-name>/testdata/extractor_test.go`:

```go
package testdata

import (
    "os"
    "path/filepath"
    "testing"
)

func TestExtractor(t *testing.T) {
    tmpDir := t.TempDir()

    extractor := NewExtractor(tmpDir)

    // Test extraction
    if err := extractor.Extract(); err != nil {
        t.Fatalf("Failed to extract testdata: %v", err)
    }

    // Verify directory exists
    if _, err := os.Stat(tmpDir); os.IsNotExist(err) {
        t.Errorf("Target directory was not created")
    }

    // Test cleanup
    if err := extractor.Clean(); err != nil {
        t.Errorf("Failed to clean testdata: %v", err)
    }
}
```

### 5. Create OTE Extension Template

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

### 6. Create Main Entry Point Template

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

### 7. Copy Test Files and Test Data

After creating the structure and templates:

1. **Copy test files** from private repo to target repo:
   ```bash
   cp -r <private-repo>/<test-dir>/* <target-repo>/test/e2e/
   ```

2. **Copy test data** from private repo to target repo:
   ```bash
   cp -r <private-repo>/<testdata-dir>/* <target-repo>/test/testdata/
   ```

3. **Verify the copy**:
   - List copied files
   - Count test files
   - Check test data integrity

### 8. Generate Summary Report

Provide a summary of what was created:

```markdown
# OTE Migration Preparation Complete

## Created Directory Structure
- cmd/<extension-name>/main.go
- pkg/<extension-name>/testdata/extractor.go
- pkg/<extension-name>/testdata/extractor_test.go
- pkg/<extension-name>/extension/extension.go
- test/e2e/ (test files copied from private repo)
- test/testdata/ (test data copied from private repo)

## Files Copied
- Test files: X files from <private-repo>/<test-dir>
- Test data: Y files from <private-repo>/<testdata-dir>

## Next Steps

1. Review the generated template code in:
   - `pkg/<extension-name>/extension/extension.go`
   - `cmd/<extension-name>/main.go`

2. Update `go.mod` dependencies:
   ```bash
   go get github.com/openshift-eng/openshift-tests-extension
   go mod tidy
   ```

3. Import test packages in `cmd/<extension-name>/main.go`:
   ```go
   import (
       _ "<module-name>/test/e2e"
   )
   ```

4. Implement TODOs in the extension code:
   - Add platform filters in `BuildTestSpecs()`
   - Add test suites in `Register()`
   - Add lifecycle hooks in `SetupHooks()`

5. Build and test:
   ```bash
   go build ./cmd/<extension-name>
   ./<extension-name> list
   ./<extension-name> run --dry-run
   ```

6. Run `/migrate-ote` to complete the migration with specific implementations
```

## Implementation Notes

**Auto-detection Tips:**
- For test directories: Search for `*_test.go` files containing Ginkgo patterns
- For testdata: Look in common locations relative to test directories
- Always show detected options and let user confirm or override

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
