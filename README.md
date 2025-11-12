# OTE Migration Tools

Automated migration tools for integrating OpenShift component repositories with the [openshift-tests-extension (OTE)](https://github.com/openshift/enhancements/pull/1676) framework.

## Overview

This repository contains Claude Code slash commands that automate the process of migrating OpenShift component repositories to use the OTE framework. These tools analyze your existing Ginkgo tests and generate all the necessary integration code.

## Features

- 🔍 **Automatic test discovery** - Finds and analyzes all Ginkgo tests
- 🏷️ **Pattern detection** - Identifies platform filters, labels, and test organization
- 🤖 **Code generation** - Creates complete OTE integration boilerplate
- 📊 **Migration reports** - Provides detailed analysis before migration
- ⚡ **Quick setup** - One command to install to any repo

## Available Commands

### `/analyze-for-ote`

Prepares a repository for OTE migration by setting up infrastructure and template code:
- Collects target repository info (path, extension name, module)
- Collects test cases and test data locations
- Creates complete OTE file structure in target repository
- Sets up `.bingo/` directory for go-bindata version management (committed to git)
- Generates Makefile with bindata generation target
- Creates testdata wrapper functions (`test/testdata/fixtures.go`)
- Creates template code for OTE interface implementation
- Copies test files and test data to target repository

### `/migrate-ote`

Performs the full migration:
- Generates `cmd/<extension-name>/main.go`
- Creates platform filters (from labels and test names)
- Sets up test suites
- Updates dependencies
- Provides validation steps

## Quick Start

### 1. Install to Your Target Repository

```bash
# Clone this repo
git clone https://github.com/YOUR_USERNAME/ote-migration-tools.git
cd ote-migration-tools

# Install to your target repository
./install.sh ~/path/to/your/openshift-component-repo
```

### 2. Use the Commands

```bash
# Navigate to your repo
cd ~/path/to/your/openshift-component-repo

# Restart Claude Code to load the slash commands

# Prepare the repo with infrastructure and templates (recommended first step)
/analyze-for-ote

# Complete the migration with specific implementations
/migrate-ote
```

### 3. Build and Validate

```bash
# Build the extension
go build ./cmd/<extension-name>

# List tests
./<extension-name> list

# Test platform filtering
./<extension-name> run --platform=aws
```

## Installation

### Method 1: Using the Install Script (Recommended)

```bash
./install.sh ~/path/to/target/repo
```

### Method 2: Manual Copy

```bash
cp -r .claude ~/path/to/target/repo/
```

## Supported Patterns

The migration tools automatically detect and handle:

### Platform Filters
- `[platform:aws]` in test names → `et.PlatformEquals("aws")`
- `Platform:gcp` labels → `et.PlatformEquals("gcp")`

### Test Organization
- `[sig-network]` patterns → Suite categorization
- `[Conformance]` markers → Conformance suite membership
- `SLOW` labels → Slow test suite

### Lifecycle
- `Lifecycle:Blocking` (default)
- `Lifecycle:Informing`

## Examples

### Example 1: Migrating openshift/sdn

```bash
# Install tools
./install.sh ~/repos/openshift/sdn
cd ~/repos/openshift/sdn

# Restart Claude Code

# Analyze
/analyze-for-ote

# Migrate
/migrate-ote
# - Extension name: sdn
# - Category: payload
# - Parent suite: openshift/conformance/parallel

# Build and test
go build ./cmd/sdn
./sdn list
./sdn run --platform=aws
```

### Example 2: Preparing Infrastructure First

```bash
./install.sh ~/repos/openshift/cluster-network-operator
cd ~/repos/openshift/cluster-network-operator

# Restart Claude Code

# Prepare infrastructure and templates first
/analyze-for-ote
# Provides:
# - Target repo: ~/repos/openshift/cluster-network-operator
# - Extension name: cluster-network-operator
# - Private repo: ~/repos/openshift/private-tests
# - Creates file structure and templates

# Review generated templates, then complete migration
/migrate-ote
```

## What Gets Generated

### Directory Structure

```
target-repo/
├── .bingo/                            # go-bindata version management (committed to git)
│   ├── go-bindata.mod                 # Pinned go-bindata version
│   ├── go-bindata.sum                 # Checksums
│   ├── Variables.mk                   # Makefile integration
│   ├── .gitignore                     # Bingo directory gitignore
│   └── README.md                      # Documentation
├── cmd/
│   └── <extension-name>/
│       └── main.go                    # OTE entry point
├── pkg/
│   └── <extension-name>/
│       └── extension/
│           ├── extension.go           # OTE extension interface
│           └── extension_test.go      # Tests for extension
├── test/
│   ├── e2e/                           # Test files (copied from private repo)
│   └── testdata/
│       ├── bindata.go                 # Generated embedded testdata
│       └── fixtures.go                # Testdata wrapper functions
├── Makefile                           # Build targets (bindata generation)
└── .gitignore                         # Ignores generated bindata.go
```

### Main Entry Point (`cmd/<extension-name>/main.go`)

Complete boilerplate including:
- Extension and suite registration
- Test package imports
- OTE framework initialization

### Extension Implementation (`pkg/<extension-name>/extension/extension.go`)

The core OTE integration code that connects your tests to the OpenShift Tests Extension framework.

**Why it exists:**
- OTE needs to know how to organize and run your tests
- It defines which tests run on which platforms/environments
- It sets up the test execution lifecycle
- It integrates your tests into the broader openshift-tests suite structure

**What it implements:**

The file implements the OTE Extension interface with four required methods:

1. **`Name()`** - Returns your extension's name
   - Example: "sdn", "router", "network"

2. **`Register(ext *extension.Extension)`** - Registers test suites with OTE
   - Defines which suites your tests belong to
   - Sets parent suites (e.g., "openshift/conformance/parallel")
   - Can create custom suites (e.g., "slow tests", "conformance tests")

3. **`BuildTestSpecs(specs *ExtensionTestSpecBuilder)`** - Configures test filtering
   - Applies platform filters (AWS, GCP, Azure, etc.)
   - Applies network filters, topology filters, architecture filters
   - Reads filters from test labels or test name patterns like `[platform:aws]`

4. **`SetupHooks(specs *ExtensionTestSpecBuilder)`** - Sets up test lifecycle hooks
   - `BeforeAll` - runs once before all tests (e.g., extract test data, setup framework)
   - `AfterEach` - runs after each test (e.g., collect diagnostics on failure)
   - `AfterAll` - runs once after all tests (e.g., cleanup)

**Example code snippets:**

```go
// Register a test suite
func (e *Extension) Register(ext *extension.Extension) error {
    ext.AddSuite(extension.Suite{
        Name:    "openshift/router/tests",
        Parents: []string{"openshift/conformance/parallel"},
    })
    return nil
}

// Apply platform filters from test names
func (e *Extension) BuildTestSpecs(specs *et.ExtensionTestSpecBuilder) error {
    specs.Walk(func(spec *et.ExtensionTestSpec) {
        re := regexp.MustCompile(`\[platform:([a-z]+)\]`)
        if match := re.FindStringSubmatch(spec.Name); match != nil {
            platform := match[1]
            spec.Include(et.PlatformEquals(platform))
        }
    })
    return nil
}

// Setup test lifecycle hooks
func (e *Extension) SetupHooks(specs *et.ExtensionTestSpecBuilder) error {
    specs.AddBeforeAll(func() {
        // Initialize test framework, extract test data
    })

    specs.AddAfterEach(func(res *et.ExtensionTestResult) {
        if res.Result == et.ResultFailed {
            // Collect diagnostics on failure
        }
    })
    return nil
}
```

The `/migrate-ote` command will populate this template with specific implementations based on your test patterns.

### Testdata Handling (`test/testdata/fixtures.go` and `bindata.go`)

The migration tools set up a robust testdata handling system using go-bindata to embed test data files into your binary.

**Why this approach:**
- Test data files are embedded into the compiled binary (self-contained executable)
- Files are extracted to the filesystem at runtime (some tests need actual files on disk)
- Provides drop-in replacement for functions like `compat_otp.FixturePath()`
- Uses bingo configuration (committed to git) for version pinning and reproducible builds

**What gets generated:**

1. **`.bingo/` directory** - Tool version management (committed to git)
   - `go-bindata.mod` - Pins go-bindata version
   - `Variables.mk` - Makefile integration with `$(GO_BINDATA)` variable
   - `.gitignore`, `README.md` - Documentation
   - **Key point:** Users don't need to install bingo - Makefile uses `go build -modfile`

2. **`Makefile`** - Bindata generation target
   ```makefile
   include .bingo/Variables.mk

   bindata: test/testdata/bindata.go
   test/testdata/bindata.go: $(GO_BINDATA) $(shell find test/testdata -type f -not -name 'bindata.go')
       $(GO_BINDATA) -nocompress -nometadata \
           -pkg testdata -o $@ -prefix "test" test/testdata/...
   ```

3. **`test/testdata/bindata.go`** - Generated file (auto-created by `make bindata`)
   - Contains all testdata files as embedded byte arrays
   - Provides `Asset()`, `RestoreAsset()`, `RestoreAssets()` functions
   - **Should be in .gitignore** (regenerated during builds)

4. **`test/testdata/fixtures.go`** - Wrapper functions
   ```go
   // Main function - replaces compat_otp.FixturePath()
   func FixturePath(relativePath string) string

   // Cleanup function - call in AfterAll hook
   func CleanupFixtures() error

   // Direct access to embedded data
   func GetFixtureData(relativePath string) ([]byte, error)
   func MustGetFixtureData(relativePath string) []byte
   ```

**Usage workflow:**

```bash
# 1. Generate bindata from test/testdata directory
make bindata
# Makefile automatically builds go-bindata from .bingo/go-bindata.mod
# No manual installation needed!

# 2. Build your extension
go build ./cmd/<extension-name>

# 3. The binary now contains all testdata embedded
./<extension-name> run
```

**In your test code:**

```go
// Old way (private repo)
configPath := compat_otp.FixturePath("config.yaml")

// New way (OTE with bindata)
configPath := testdata.FixturePath("config.yaml")

// The file is automatically extracted from bindata to a temp directory
data, err := os.ReadFile(configPath)
```

**Lifecycle integration:**

The cleanup hook is automatically added to `main.go`:
```go
specs.AddAfterAll(func() {
    if err := testdata.CleanupFixtures(); err != nil {
        fmt.Printf("Warning: failed to cleanup fixtures: %v\n", err)
    }
})
```

This ensures extracted files are removed after test execution completes.

**Follows operator-framework-olm pattern:**
This approach matches [operator-framework-olm/tests-extension](https://github.com/openshift/operator-framework-olm/tree/main/tests-extension) where `.bingo/` is committed and users don't need to install bingo globally.

### Platform Filter Code

Example generated code:

```go
// From Platform: labels
specs.Walk(func(spec *et.ExtensionTestSpec) {
    for label := range spec.Labels {
        if strings.HasPrefix(label, "Platform:") {
            platformName := strings.TrimPrefix(label, "Platform:")
            spec.Include(et.PlatformEquals(platformName))
        }
    }
})

// From [platform:xxx] in test names
specs.Walk(func(spec *et.ExtensionTestSpec) {
    re := regexp.MustCompile(`\[platform:([a-z]+)\]`)
    if match := re.FindStringSubmatch(spec.Name); match != nil {
        platform := match[1]
        spec.Include(et.PlatformEquals(platform))
    }
})
```

### Suite Definitions

```go
ext.AddSuite(e.Suite{
    Name:    "openshift/<component>/tests",
    Parents: []string{"openshift/conformance/parallel"},
})
```

## Repository Structure

```
ote-migration-tools/
├── .claude/
│   └── commands/
│       ├── analyze-for-ote.md    # Analysis command
│       ├── migrate-ote.md        # Migration command
│       └── README.md             # Command documentation
├── install.sh                    # Installation script
└── README.md                     # This file
```

## Customization

After migration, you may want to customize:

### Add More Environment Filters

```go
specs.Walk(func(spec *et.ExtensionTestSpec) {
    if strings.Contains(spec.Name, "[network:ovn]") {
        spec.Include(et.NetworkEquals("ovn"))
    }
})
```

### Add Hooks

```go
specs.AddBeforeAll(func() {
    // Initialize framework
})

specs.AddAfterEach(func(res *et.ExtensionTestResult) {
    if res.Result == et.ResultFailed {
        // Collect diagnostics
    }
})
```

### Add Custom Suites

```go
ext.AddSuite(e.Suite{
    Name: "openshift/<component>/conformance",
    Qualifiers: []string{
        `labels.exists(l, l=="Conformance")`,
    },
})
```

## Troubleshooting

### Slash commands not showing up

- Ensure `.claude/commands/` exists in your target repo
- Restart Claude Code after installation
- Verify files are not corrupted

### Tests not discovered

- Check that test files are imported in `main.go`
- Verify tests aren't in vendored directories
- Ensure Ginkgo tests are properly structured

### Platform filters not working

- Verify the filter pattern matches your test naming
- Check label format (case-sensitive)
- Test with: `./extension run --platform=aws --dry-run`

## Contributing

Contributions welcome! To improve the migration tools:

1. Fork this repository
2. Edit the command files in `.claude/commands/`
3. Test with real repositories
4. Submit a pull request

## Resources

- [OTE Framework Enhancement](https://github.com/openshift/enhancements/pull/1676)
- [OTE Framework Repo](https://github.com/openshift-eng/openshift-tests-extension)
- [Example Integration](https://github.com/openshift-eng/openshift-tests-extension/blob/main/cmd/example-tests/main.go)
- [Environment Selectors](https://github.com/openshift-eng/openshift-tests-extension/blob/main/pkg/extension/extensiontests/environment.go)

## License

[Add your license here]

## Author

minl@redhat.com
