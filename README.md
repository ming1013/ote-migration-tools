# OTE Migration Tools

Automated migration tools for integrating OpenShift component repositories with the [openshift-tests-extension (OTE)](https://github.com/openshift/enhancements/pull/1676) framework.

## Overview

This repository contains a Claude Code slash command that automates the complete process of migrating OpenShift component repositories to use the OTE framework. The tool handles everything from repository setup to code generation with customizable destination paths.

## Features

- 🔍 **Complete automation** - One command handles the entire migration
- ⚡ **Simplified inputs** - Source repo hardcoded, just specify subfolder names
- 📁 **Customizable paths** - Configure test and testdata destinations
- 🔄 **Repository management** - Use existing local repos or automatic cloning
- 🏗️ **Structure creation** - Creates all necessary directories and files
- 🤖 **Code generation** - Generates OTE integration boilerplate
- 🏷️ **Pattern detection** - Identifies platform filters, labels, and test organization
- 📊 **Comprehensive reports** - Detailed migration summary with next steps

## Command

### `/migrate-ote`

Performs the complete OTE migration in one workflow:

**What it does:**
1. **Collects user inputs** - Extension name, directories, repository URLs, custom paths
2. **Sets up repositories** - Clones/updates source and target repositories
3. **Creates structure** - Builds tests-extension/ with customizable paths
4. **Copies files** - Moves test files and testdata to specified destinations
5. **Generates code** - Creates go.mod, main.go, Makefile, fixtures.go
6. **Migrates tests** - Updates imports and FixturePath calls
7. **Provides validation** - Gives comprehensive next steps and validation guide

**Key Features:**
- ⭐ **Customizable test path** (default: `test/e2e/`)
- ⭐ **Customizable testdata path** (default: `test/testdata/`)
- 🔄 **Automatic repository cloning/updating**
- ✅ **Git status validation** for working directory
- 📦 **Auto-install go-bindata** for generating embedded testdata

## Quick Start

### 1. Install to Your Workspace

```bash
# Clone this repo
git clone https://github.com/YOUR_USERNAME/ote-migration-tools.git
cd ote-migration-tools

# Copy commands to your workspace (optional - or run directly from this repo)
# cp -r .claude ~/my-workspace/
```

### 2. Run the Migration

```bash
# Navigate to where you want to run the migration
cd ~/my-workspace

# Restart Claude Code if you copied .claude/ commands

# Run the complete migration
/migrate-ote
```

### 3. Follow the Prompts

The command will collect the following information:

**Source repository is always:** `git@github.com:openshift/openshift-tests-private.git`

1. **Extension name** (e.g., "sdn", "router", "storage")
2. **Working directory** where tests-extension/ will be created
3. **Local openshift-tests-private path** ⭐ (optional - or will clone it)
4. **Test subfolder** under test/extended/ (e.g., "networking", "router")
5. **Testdata subfolder** under test/extended/testdata/ (default: same as test subfolder)
6. **Local target repository path** ⭐ (optional - or clone from URL)
7. **Target repository URL** (if not using local repo)
8. **Destination test path** ⭐ (default: `test/e2e/`) - CUSTOMIZABLE
9. **Destination testdata path** ⭐ (default: `test/testdata/`) - CUSTOMIZABLE

### 4. Build and Validate

After migration completes:

```bash
cd <working-dir>/tests-extension

# Generate bindata
make bindata

# Update dependencies
go get github.com/openshift-eng/openshift-tests-extension@latest
go mod tidy

# Build extension
make build

# List tests to verify
make list

# Test platform filtering
./<extension-name> run --platform=aws --dry-run
```

## Example Workflow

### Example: Migrating SDN Tests

```bash
# Start in your workspace
cd ~/workspace

# Run migration command
/migrate-ote

# Provide inputs when prompted:
# Extension name: sdn
# Working directory: /home/user/workspace/sdn-migration
# Local openshift-tests-private: [Enter] or /home/user/repos/openshift-tests-private
# Test subfolder: networking               ← subfolder under test/extended/
# Testdata subfolder: [Enter] or networking ← subfolder under test/extended/testdata/
# Local target repo: [Enter] or /home/user/repos/sdn
# Target repo: git@github.com:openshift/sdn.git (if not using local)
# Dest test path: test/e2e/                ← customizable
# Dest testdata path: test/testdata/       ← customizable

# After migration completes, navigate to tests-extension
cd sdn-migration/tests-extension

# Generate bindata and build
make bindata
go get github.com/openshift-eng/openshift-tests-extension@latest
go mod tidy
make build

# Validate
./sdn list
./sdn run --platform=aws --dry-run
```

## What Gets Generated

### Complete Directory Structure

```
<working-dir>/
├── tests-extension/                   # Main extension directory
│   ├── cmd/
│   │   └── <extension-name>/
│   │       └── main.go               # OTE entry point
│   ├── <dest-test-path>/             # Test files (CUSTOMIZABLE)
│   │   └── *_test.go
│   ├── <dest-testdata-path>/         # Testdata (CUSTOMIZABLE)
│   │   ├── bindata.go                # Generated
│   │   └── fixtures.go               # Wrapper functions
│   ├── go.mod                        # Go module
│   ├── Makefile                      # Build targets
│   └── bindata.mk                    # Bindata generation
└── repos/                            # Cloned repositories (if not using local)
    ├── openshift-tests-private/      # Source repository
    └── target/                       # Target repository
```

### Generated Code Files

#### 1. `cmd/<extension-name>/main.go`

Complete OTE entry point with:
- Extension and suite registration
- Platform filters (from labels and test names)
- Testdata validation and cleanup hooks
- Test package imports (using custom paths)

#### 2. `<dest-testdata-path>/fixtures.go`

Comprehensive testdata wrapper with:
- `FixturePath()` - Replaces `compat_otp.FixturePath()`
- `CleanupFixtures()` - Cleanup hook
- `GetFixtureData()` - Direct access to embedded data
- `FixtureExists()` - Validation helper
- `ListFixtures()` - Debugging helper
- `GetManifest()`, `GetConfig()` - Convenience functions
- `ValidateFixtures()` - Required fixtures validation

#### 3. `Makefile` and `bindata.mk`

Build system with:
- Custom testdata path configuration
- Automatic go-bindata installation (via `go install`)
- Bindata generation target
- Build, test, list, clean targets

## Customization After Migration

### Add More Environment Filters

Edit `cmd/<extension-name>/main.go`:

```go
// Network filter
specs.Walk(func(spec *et.ExtensionTestSpec) {
    if strings.Contains(spec.Name, "[network:ovn]") {
        spec.Include(et.NetworkEquals("ovn"))
    }
})

// Topology filter
specs.Walk(func(spec *et.ExtensionTestSpec) {
    re := regexp.MustCompile(`\[topology:(ha|single)\]`)
    if match := re.FindStringSubmatch(spec.Name); match != nil {
        spec.Include(et.TopologyEquals(match[1]))
    }
})
```

### Add Custom Test Suites

```go
// Slow tests suite
ext.AddSuite(e.Suite{
    Name: "openshift/<extension>/slow",
    Qualifiers: []string{
        `labels.exists(l, l=="SLOW")`,
    },
})

// Conformance tests suite
ext.AddSuite(e.Suite{
    Name: "openshift/<extension>/conformance",
    Qualifiers: []string{
        `labels.exists(l, l=="Conformance")`,
    },
})
```

### Add Test Lifecycle Hooks

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

## Supported Patterns

The migration tool automatically detects and handles:

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

## Troubleshooting

### Slash command not showing up
- Ensure `.claude/commands/` exists in your workspace or repo
- Restart Claude Code after installation
- Verify files are not corrupted

### Repository cloning fails
- Check repository URL is correct and accessible
- Verify you have proper authentication (SSH keys or credentials)
- Ensure git is installed and configured

### Tests not discovered
- Check that test files are in `<dest-test-path>/`
- Verify test packages are imported in `main.go`
- Ensure tests aren't in vendored directories
- Run `go mod tidy` to fix any import issues

### Bindata generation fails
- Ensure testdata directory exists and contains files
- Verify go-bindata is installed (Makefile auto-installs it)
- Run: `make bindata`

### Platform filters not working
- Verify the filter pattern matches your test naming
- Check label format (case-sensitive: `Platform:aws`)
- Test with: `./<extension> run --platform=aws --dry-run`

## Advanced Usage

### Specifying Custom Paths

When prompted for destination paths, you can specify any valid relative path:

**Example - Using pkg/ directory:**
- Destination test path: `pkg/e2e/tests/`
- Destination testdata path: `pkg/e2e/testdata/`

**Example - Matching source structure:**
- Destination test path: `test/extended/`
- Destination testdata path: `test/extended/testdata/`

The tool will:
- Create the directories automatically
- Update all import paths in generated code
- Configure Makefile with custom paths
- Update bindata generation to use custom paths

### Working with Multiple Extensions

You can run multiple migrations in the same workspace:

```bash
# First extension
/migrate-ote
# Extension: sdn
# Working dir: /workspace/sdn-migration

# Second extension
/migrate-ote
# Extension: router
# Working dir: /workspace/router-migration
```

Each migration gets its own isolated `tests-extension/` and `repos/` directories.

### Using Local or Remote Repositories

The tool provides flexible repository options:
- **Use existing local repositories:** Provide paths to your already cloned repos
  - Optionally update them with `git fetch && git pull` when prompted
  - Useful when you already have repos checked out with specific branches
- **Clone from URLs:** Leave local paths empty to clone fresh copies
  - **First run:** Clones repositories from URLs into `repos/` directory
  - **Subsequent runs:** Updates existing clones with `git fetch && git pull`

This flexibility allows you to:
- Work with specific branches in your local repos
- Re-run the migration with updated source code
- Avoid redundant cloning if you already have the repositories

## Repository Structure

```
ote-migration-tools/
├── .claude/
│   └── commands/
│       ├── migrate-ote.md        # Complete migration command
│       └── README.md             # Command documentation
├── install.sh                    # Installation script
└── README.md                     # This file
```

## Installation Options

### Method 1: Use Directly

```bash
git clone https://github.com/YOUR_USERNAME/ote-migration-tools.git
cd ote-migration-tools
# Run /migrate-ote from Claude Code
```

### Method 2: Copy to Workspace

```bash
git clone https://github.com/YOUR_USERNAME/ote-migration-tools.git
cp -r ote-migration-tools/.claude ~/my-workspace/
cd ~/my-workspace
# Restart Claude Code
# Run /migrate-ote
```

### Method 3: Install Script

```bash
git clone https://github.com/YOUR_USERNAME/ote-migration-tools.git
cd ote-migration-tools
./install.sh ~/my-workspace
```

## Contributing

Contributions welcome! To improve the migration tool:

1. Fork this repository
2. Edit `.claude/commands/migrate-ote.md`
3. Test with real repositories
4. Submit a pull request

## Resources

- [OTE Framework Enhancement](https://github.com/openshift/enhancements/pull/1676)
- [OTE Framework Repository](https://github.com/openshift-eng/openshift-tests-extension)
- [Example Integration](https://github.com/openshift-eng/openshift-tests-extension/blob/main/cmd/example-tests/main.go)
- [Environment Selectors](https://github.com/openshift-eng/openshift-tests-extension/blob/main/pkg/extension/extensiontests/environment.go)

## What's New

### Latest Changes (v2.3)

- ✅ **Simplified inputs** - Source repo hardcoded to `openshift-tests-private`
- ✅ **Subfolder-based paths** - Just specify subfolder names under test/extended/
- ✅ **Fewer questions** - Reduced from 13 to 9-12 inputs (conditional)

### Previous Changes (v2.2)

- ✅ **Removed all hidden files/directories** - No `.bingo/` or `.gitignore` created
- ✅ **Simpler go-bindata setup** - Auto-installs via `go install` (no bingo needed)
- ✅ **Cleaner output** - No unnecessary infrastructure files

### Previous Changes (v2.1)

- ✅ **Local repository support** - Use existing local repos instead of cloning

### Previous Changes (v2.0)

- ✅ **Unified workflow** - Single `/migrate-ote` command (removed `/analyze-for-ote`)
- ✅ **Customizable paths** - Test and testdata destinations are fully configurable
- ✅ **Repository management** - Automatic cloning and updating
- ✅ **Working directory** - Create or use existing directories with git validation
- ✅ **Enhanced validation** - Git status checking for existing directories
- ✅ **Comprehensive summary** - Detailed migration report with all paths and statistics

### Migration from v1.0

If you were using the old two-step workflow:

**Old workflow:**
```bash
/analyze-for-ote  # Prepare infrastructure
# Manual steps: make bindata, go get, uncomment imports
/migrate-ote      # Complete migration
```

**New workflow:**
```bash
/migrate-ote  # Everything in one command!
# Manual steps: make bindata, go get (listed in migration summary)
```

## License

[Add your license here]

## Author

minl@redhat.com
