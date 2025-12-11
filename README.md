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
- 📦 **Proper Go modules** - Follows the 5-step Go module initialization workflow with k8s.io pinning
- 🔧 **Robust dependency resolution** - Retry logic, explicit downloads, and fallback instructions for network issues
- ✨ **Auto-migration** - Automatically replaces `compat_otp.FixturePath()` and updates imports
- ✅ **Build verification** - Automatically verifies the build works before completion
- 🏷️ **Pattern detection** - Identifies platform filters, labels, and test organization
- 📊 **Comprehensive reports** - Detailed migration summary with next steps

## Command

### `/migrate-ote`

Performs the complete OTE migration in one workflow:

**What it does:**
1. **Collects user inputs** - Extension name, directories, repository URLs
2. **Sets up repositories** - Clones/updates source and target repositories (using smart remote detection)
3. **Creates structure** - Builds tests-extension/ with test/e2e and test/testdata directories
4. **Copies files** - Moves test files to test/e2e/ and testdata to test/testdata/
5. **Vendors dependencies** - Automatically vendors Go dependencies (compat_otp, exutil, etc.)
6. **Generates code** - Creates go.mod, cmd/main.go, Makefile, fixtures.go
7. **Migrates tests** - Automatically replaces `compat_otp.FixturePath()` and `exutil.FixturePath()` with `testdata.FixturePath()`, updates imports, and cleans up old imports
8. **Provides validation** - Gives comprehensive next steps and validation guide

**Key Features:**
- 🔄 **Smart repository management** with remote detection
- 📦 **Automatic dependency vendoring** (compat_otp, exutil, etc.)
- 📁 **Two directory strategies** - multi-module or single-module
- ✅ **Git status validation** for working directory
- 🛠️ **Auto-install go-bindata** for generating embedded testdata

## Directory Structure Strategies

Choose the strategy that best fits your repository:

### Option 1: Multi-Module Strategy (Recommended for existing repos)

**Best for:** Component repos with existing `cmd/` and `test/` directories

**Structure:**
```
your-repo/                           # Existing repository root
├── cmd/
│   └── extension/main.go           # OTE extension binary
├── test/
│   ├── e2e/                        # Test files
│   │   └── go.mod                  # Separate test module
│   ├── testdata/                   # Test data
│   ├── Makefile                    # Test build targets
│   └── bindata.mk                  # Bindata generation
├── go.mod                          # Root module (updated with replace section)
└── Makefile                        # Root Makefile (updated)
```

**Benefits:**
- Integrates cleanly into existing repository structure
- Keeps test dependencies separate from main module
- Uses Go workspace/replace directive pattern
- Tests live alongside existing code

### Option 2: Single-Module Strategy (Isolated)

**Best for:** Standalone test extensions or prototyping

**Structure:**
```
working-dir/
└── tests-extension/                 # Isolated directory
    ├── cmd/main.go                 # OTE entry point
    ├── test/
    │   ├── e2e/                    # Test files
    │   └── testdata/               # Test data
    ├── vendor/                     # Vendored dependencies
    └── go.mod                      # Single module
```

**Benefits:**
- Self-contained and portable
- No changes to existing repository
- Easy to move or distribute separately
- Simpler module management

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

### 4. Build and Validate

After migration completes, the tool will have already:
1. ✅ Initialized Go modules (`go mod init`)
2. ✅ Added dependencies with correct versions (`go get github.com/openshift/origin@<version-from-openshift-tests-private>`)
3. ✅ Added k8s.io replace directives to pin module versions (prevents "module found but does not contain package" errors)
4. ✅ Resolved all transitive dependencies (`go mod tidy`)
5. ✅ Verified the build works (`go build`)
6. ✅ Replaced `compat_otp.FixturePath()` with `testdata.FixturePath()`
7. ✅ Updated imports to use new testdata package

You should have these files ready to commit:
- `go.mod` and `go.sum` (both root and test modules for multi-module strategy)
  - go.mod now includes replace directives for k8s.io/* modules
  - Uses the same openshift/origin version as openshift-tests-private
- All generated code files (main.go, fixtures.go, Makefile, etc.)

**Dependency Resolution:**
The tool automatically:
- Reads the correct `openshift/origin` version from your local `openshift-tests-private/go.mod`
- Reads the `k8s.io/*` module versions from `openshift-tests-private/go.mod`
- Adds replace directives to pin all k8s.io modules to the correct version
- This ensures compatibility and prevents dependency resolution errors

**Optional: Manual validation:**

```bash
cd <working-dir>/tests-extension  # or <working-dir> for multi-module

# List tests to verify
make list  # or make list-tests for multi-module

# Test platform filtering
./<extension-name> run --platform=aws --dry-run

# Run actual tests
./<extension-name> run
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
│   │   └── main.go                   # OTE entry point
│   ├── test/
│   │   ├── e2e/                      # Test files
│   │   │   └── *_test.go
│   │   └── testdata/                 # Testdata
│   │       ├── bindata.go            # Generated
│   │       └── fixtures.go           # Wrapper functions
│   ├── vendor/                       # Vendored dependencies (auto-generated)
│   ├── go.mod                        # Go module
│   ├── go.sum                        # Dependency checksums
│   ├── Makefile                      # Build targets
│   └── bindata.mk                    # Bindata generation
└── repos/                            # Cloned repositories (if not using local)
    ├── openshift-tests-private/      # Source repository
    └── target/                       # Target repository
```

### Generated Code Files

#### 1. `cmd/main.go`

Complete OTE entry point with:
- Extension and suite registration
- Platform filters (from labels and test names)
- Testdata validation and cleanup hooks
- Test package imports (test/e2e and test/testdata)

#### 2. `test/testdata/fixtures.go`

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
- Automatic go-bindata installation (via `go install`)
- Bindata generation target (test/testdata/)
- Build, test, list, clean targets

## Customization After Migration

### Add More Environment Filters

Edit `cmd/main.go`:

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
- The Makefile will auto-install go-bindata if not present
- If installation fails, manually install: `go install github.com/go-bindata/go-bindata/v3/go-bindata@latest`
- Then run: `make bindata`

### Platform filters not working
- Verify the filter pattern matches your test naming
- Check label format (case-sensitive: `Platform:aws`)
- Test with: `./<extension> run --platform=aws --dry-run`

## Advanced Usage

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
  - **Automatic checkout:** If not on main/master, automatically checks out main/master before updating
  - **Branch detection:** Tries main first, falls back to master
  - Ensures updates always happen from the default branch
- **Clone from URLs:** Leave local paths empty to clone fresh copies
  - **First run:** Clones repositories from URLs into `repos/` directory
  - **Subsequent runs:** Updates existing clones with `git fetch && git pull`

This flexibility allows you to:
- Work with specific branches in your local repos
- Re-run the migration with updated source code
- Avoid redundant cloning if you already have the repositories
- Safe updates with automatic checkout to main/master

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

### Latest Changes (v2.12)

- ✅ **Complete k8s.io module pinning** - Matches working router tests-extension configuration
  - Added missing `k8s.io/cri-client` replace directive
  - Added missing `k8s.io/dynamic-resource-allocation` replace directive
  - **CRITICAL:** Added `k8s.io/kubernetes => github.com/openshift/kubernetes` fork replace
  - Total of 31 k8s.io replace directives (same as successful migrations)
  - Automatically extracts OpenShift Kubernetes fork version from openshift-tests-private
  - Enhanced verification to check for all critical replace directives

### Previous Changes (v2.11)

- ✅ **Fully automated test migration** - No more manual TODOs!
  - Automatically replaces `compat_otp.FixturePath()` with `testdata.FixturePath()`
  - Automatically replaces `exutil.FixturePath()` with `testdata.FixturePath()`
  - Automatically adds testdata package imports to test files
  - Automatically cleans up old compat_otp/exutil imports
  - Zero manual edits required after migration completes
- ✅ **Robust dependency resolution** - Network interruption handling
  - Automatic retry logic for `go get` operations
  - Explicit `go mod download` step to verify all dependencies
  - Clear error messages and recovery instructions if downloads fail
  - Retry mechanism for `go mod tidy` operations
  - Complete troubleshooting guide in migration summary

### Previous Changes (v2.10)

- ✅ **Fixed `// indirect` dependencies issue** - Added Step 2.5 to run `go mod tidy` AFTER creating main.go
  - This ensures dependencies are correctly marked as direct (not `// indirect`)
  - Previously, `go get` ran before main.go existed, causing all deps to be marked as indirect
  - Now properly updates go.mod after main.go is created with all imports

### Previous Changes (v2.9)

- ✅ **Proper Go module initialization sequence** - Now follows the correct 4-step workflow:
  1. `go mod init` - Creates go.mod with module declaration
  2. `go get` - Adds dependencies with specific versions
  3. `go mod tidy` - Resolves all transitive dependencies
  4. `go build` - Verifies everything works before commit
- ✅ **Fixed go.mod replace directive** - Removes invalid local filesystem replace directives for github.com/openshift/origin
- ✅ **Added Dockerfile updates** - Following machine-config-operator PR #4665 pattern for building OTE binary
- ✅ **Added tests-ext-build Makefile target** - Proper OTE binary compilation target matching OpenShift conventions
- ✅ **Improved build process** - Binary compression with gzip and proper placement in /usr/bin/
- ✅ **go.sum generation** - Automatically creates and validates go.sum files for both root and test modules

### Previous Changes (v2.8)

- ✅ **Automatic branch checkout** - Auto-switches to main/master before git pull
- ✅ **Smart branch detection** - Tries main first, falls back to master
- ✅ **Safe updates** - Ensures repositories are always updated from default branch
- ✅ **Error handling** - Exits gracefully if neither main nor master exists

### Previous Changes (v2.7)

- ✅ **Multi-module go.mod location** - Test module now at `test/e2e/go.mod` (not `test/go.mod`)
- ✅ **Smart replace directive** - Automatically adds to existing replace section in go.mod
- ✅ **Dockerfile integration** - Added complete guide for building extension binary in component images
- ✅ **Updated structure** - Cleaner separation: `test/e2e/` for code and module, `test/testdata/` for data

### Previous Changes (v2.6)

- ✅ **Two directory strategies** - Choose between multi-module (integrated) or single-module (isolated)
- ✅ **Multi-module support** - Integrate into existing repos with separate test module and replace directive
- ✅ **Single-module support** - Create isolated tests-extension directory (original approach)
- ✅ **Flexible module management** - Separate go.mod for tests in multi-module strategy

### Previous Changes (v2.5)

- ✅ **Hardcoded destination paths** - Test files always go to `test/e2e/`, testdata to `test/testdata/`
- ✅ **Simplified inputs** - Reduced from 9-12 inputs to 7-10 inputs (removed customizable paths)
- ✅ **Standardized structure** - Consistent directory layout across all migrations

### Previous Changes (v2.4)

- ✅ **Simplified cmd structure** - Creates `cmd/main.go` directly (no nested extension-name directory)
- ✅ **Automatic vendoring** - Vendors Go dependencies (compat_otp, exutil) after copying test files
- ✅ **Smart git cloning** - Uses remote detection pattern to avoid duplicate clones

### Previous Changes (v2.3)

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
