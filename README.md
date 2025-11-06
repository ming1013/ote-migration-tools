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
- Collects private repository info (test directory, testdata directory)
- Creates complete OTE file structure in target repository
- Generates testdata extraction utilities with embed support
- Creates template code for OTE interface implementation
- Copies test files and test data from private repository

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
├── cmd/
│   └── <extension-name>/
│       └── main.go                    # OTE entry point
├── pkg/
│   └── <extension-name>/
│       ├── testdata/
│       │   ├── extractor.go           # Testdata extraction utility
│       │   └── extractor_test.go      # Tests for extractor
│       └── extension/
│           ├── extension.go           # OTE extension interface
│           └── extension_test.go      # Tests for extension
└── test/
    ├── e2e/                           # Test files (copied from private repo)
    └── testdata/                      # Test data files (copied from private repo)
```

### Main Entry Point (`cmd/<extension-name>/main.go`)

Complete boilerplate including:
- Extension and suite registration
- Test package imports
- OTE framework initialization

### Testdata Extractor (`pkg/<extension-name>/testdata/extractor.go`)

A utility that manages test data files during test execution. This is needed because:

**Why it exists:**
- Your test data files from `test/testdata/` are embedded into the compiled binary using Go's `//go:embed` directive
- Some tests need actual files on the filesystem (not just embedded data)
- The extractor bridges between embedded data (in the binary) and filesystem-based data (needed at runtime)

**What it provides:**
- `NewExtractor(targetDir)` - Creates a new extractor instance
- `Extract()` - Writes all embedded test data to the filesystem
- `Clean()` - Removes extracted files after tests complete
- `GetPath(relativePath)` - Returns the filesystem path to an extracted file

**Example usage:**
```go
extractor := testdata.NewExtractor("/tmp/my-test-data")
extractor.Extract()  // Extracts all embedded test data to filesystem
defer extractor.Clean()  // Cleanup when done

// Now tests can access files on the filesystem
configPath := extractor.GetPath("config.yaml")
// Use configPath in your tests
```

This is particularly useful when tests need to read configuration files, manifests, or other test fixtures that must exist as actual files on disk.

### Extension Implementation (`pkg/<extension-name>/extension/extension.go`)

OTE interface implementation with:
- Extension registration and naming
- Suite definitions
- Platform filters (from both labels and test names)
- Custom suite definitions
- Hook placeholders for setup/teardown

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
