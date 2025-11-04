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

Analyzes a repository without making changes. Provides:
- Test count and distribution
- Platform-specific test detection
- Pattern analysis (platforms, labels, etc.)
- Migration complexity assessment
- Recommended filter code

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

# Analyze the repo first (recommended)
/analyze-for-ote

# Perform the migration
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

### Example 2: Analyzing Before Migration

```bash
./install.sh ~/repos/openshift/cluster-network-operator
cd ~/repos/openshift/cluster-network-operator

# Restart Claude Code

# Just analyze first
/analyze-for-ote
# Review the report...

# Decide whether to proceed
/migrate-ote
```

## What Gets Generated

### Main Entry Point (`cmd/<extension-name>/main.go`)

Complete boilerplate including:
- Extension and suite registration
- Ginkgo test spec building
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
