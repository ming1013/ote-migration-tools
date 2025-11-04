# OTE Migration Slash Commands

This directory contains Claude Code slash commands to help automate OpenShift Tests Extension (OTE) migration for component repositories.

## Available Commands

### `/analyze-for-ote`

**Purpose**: Analyze a repository to understand what's needed for OTE migration without making any changes.

**Usage**:
```
/analyze-for-ote
```

**What it does**:
- Discovers all Ginkgo tests in the repository
- Extracts test metadata (platforms, labels, patterns)
- Identifies hooks and setup/teardown code
- Generates a comprehensive migration report
- Recommends filter code and suite structure
- Assesses migration complexity

**When to use**:
- Before starting migration to understand scope
- To get an overview of test organization
- To identify potential migration challenges
- To plan the migration approach

**Output**: A detailed analysis report with recommendations

---

### `/migrate-ote`

**Purpose**: Perform the full OTE migration by generating all necessary code and configuration.

**Usage**:
```
/migrate-ote
```

**What it does**:
1. Analyzes the existing test structure
2. Gathers migration information (extension name, suites, etc.)
3. Generates `cmd/<extension-name>/main.go` with complete boilerplate
4. Updates `go.mod` dependencies
5. Applies platform and environment filters
6. Sets up test suites
7. Provides validation steps

**When to use**:
- After analyzing the repo with `/analyze-for-ote`
- When ready to perform the actual migration
- To generate OTE integration code

**Output**:
- Generated `cmd/<extension-name>/main.go`
- Updated `go.mod`
- Migration summary
- Validation instructions

---

## Typical Workflow

### Option 1: Analysis First (Recommended)

1. **Analyze the repository**:
   ```
   /analyze-for-ote
   ```
   Review the analysis report to understand what will be migrated.

2. **Perform the migration**:
   ```
   /migrate-ote
   ```
   Follow the prompts to complete the migration.

3. **Validate**:
   ```bash
   go build ./cmd/<extension-name>
   ./<extension-name> list
   ```

### Option 2: Direct Migration

If you're already familiar with the repository:

1. **Run migration directly**:
   ```
   /migrate-ote
   ```

2. **Validate**:
   ```bash
   go build ./cmd/<extension-name>
   ./<extension-name> list
   ```

---

## Examples

### Example 1: Migrating openshift/sdn

```bash
# Navigate to the repo
cd ~/repos/openshift/sdn

# Analyze
/analyze-for-ote
# Review the report...

# Migrate
/migrate-ote
# Answer prompts:
# - Extension name: sdn
# - Category: payload
# - Parent suite: openshift/conformance/parallel

# Build and test
go build ./cmd/sdn
./sdn list
./sdn run --platform=aws
```

### Example 2: Migrating openshift/cluster-storage-operator

```bash
cd ~/repos/openshift/cluster-storage-operator

# Quick analysis
/analyze-for-ote

# Perform migration
/migrate-ote
# Extension name: storage
# Category: payload
# Parent suite: openshift/conformance/parallel
# Custom suite: openshift/storage/slow (for SLOW tests)

# Validate
go build ./cmd/storage
./storage list --suite openshift/storage/slow
```

---

## What Gets Generated

The `/migrate-ote` command generates:

### 1. Main Entry Point (`cmd/<extension-name>/main.go`)

Complete boilerplate including:
- Extension and suite registration
- Ginkgo test spec building
- Platform filters (from labels and test names)
- Custom suite definitions
- Hook placeholders

### 2. Platform Filter Code

Automatically generated based on detected patterns:

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

### 3. Suite Definitions

```go
ext.AddSuite(e.Suite{
    Name:    "openshift/<extension-name>/tests",
    Parents: []string{"openshift/conformance/parallel"},
})
```

---

## Supported Patterns

The commands detect and handle:

### Platform Patterns
- `[platform:aws]` in test names → `et.PlatformEquals("aws")`
- `Platform:gcp` labels → `et.PlatformEquals("gcp")`

### Environment Patterns
- `[sig-network]` → Suite organization
- `[Conformance]` → Conformance suite membership
- `SLOW` label → Slow test suite

### Lifecycle Patterns
- `Lifecycle:Blocking` (default)
- `Lifecycle:Informing`

---

## Customization

After running `/migrate-ote`, you may want to customize:

1. **Add more environment filters**:
   ```go
   specs.Walk(func(spec *et.ExtensionTestSpec) {
       if strings.Contains(spec.Name, "[network:ovn]") {
           spec.Include(et.NetworkEquals("ovn"))
       }
   })
   ```

2. **Add hooks**:
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

3. **Add more suites**:
   ```go
   ext.AddSuite(e.Suite{
       Name: "openshift/<extension>/conformance",
       Qualifiers: []string{
           `labels.exists(l, l=="Conformance")`,
       },
   })
   ```

---

## Troubleshooting

### Tests not showing up
- Ensure test files are imported in `main.go`
- Check that tests aren't in vendored directories
- Verify Ginkgo tests are properly structured

### Platform filters not working
- Verify the filter pattern matches your test naming
- Check label format (exact match required)
- Test with: `./extension run --platform=aws --dry-run`

### Build errors
- Run `go mod tidy`
- Verify import paths match your repository
- Check that all test packages are imported

---

## Additional Resources

- [OTE Framework Documentation](https://github.com/openshift/enhancements/pull/1676)
- [Example Integration](../cmd/example-tests/main.go)
- [Environment Selectors](../pkg/extension/extensiontests/environment.go)

---

## Contributing

To improve these migration commands:

1. Edit the markdown files:
   - `analyze-for-ote.md` - Analysis command
   - `migrate-ote.md` - Migration command

2. Add new patterns or filters as needed

3. Test with real repositories and update based on findings
