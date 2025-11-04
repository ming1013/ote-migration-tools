---
description: Analyze a repository to understand what's needed for OTE migration
---

# OTE Migration Analysis

You are analyzing a component repository to determine what's needed for openshift-tests-extension (OTE) migration.

## Task

Analyze the target repository and provide a comprehensive migration report WITHOUT making any changes.

## Steps

### 1. Ask for Repository Path

Ask the user for the repository path to analyze (or use current directory).

### 2. Check for E2E Tests and Offer to Copy

**Check for existing e2e tests:**
- Search for test files in common e2e directories: `test/e2e/`, `e2e/`, `tests/e2e/`
- Look for files matching `*_test.go` with Ginkgo patterns (`Describe`, `It`, `Context`)

**If NO e2e tests found:**
1. Inform the user: "No e2e tests found in the repository."
2. Ask: "Would you like to copy e2e tests from another repository/directory?"
3. If YES:
   - Ask for source path/repo: "Please provide the path to the source repository or directory containing e2e tests"
   - Ask for source test directory: "Which directory contains the tests? (e.g., test/e2e, e2e)"
   - Ask for destination: "Where should tests be copied to in the target repo? (default: test/e2e)"
   - Copy the tests using appropriate tools (Bash cp command)
   - Confirm: "✅ Copied e2e tests from [source] to [destination]"
4. If NO:
   - Warn: "⚠️ Migration will proceed but no tests will be available for analysis"
   - Ask: "Continue anyway? (y/N)"

**If e2e tests EXIST:**
1. Inform the user: "Found X e2e test files in [directories]"
2. Ask: "Would you like to add more e2e tests from another source? (y/N)"
3. If YES:
   - Ask for source path: "Please provide the path to the additional e2e tests"
   - Ask for source test directory: "Which directory contains the tests? (e.g., test/e2e, e2e)"
   - Ask about merge strategy: "How should we handle conflicts? (skip/overwrite/rename)"
   - Copy the tests with the chosen strategy
   - Confirm: "✅ Added additional e2e tests from [source]"
4. If NO:
   - Proceed with analysis

### 3. Discover Test Files

After handling e2e test copying, search for ALL Ginkgo test files:
- Files containing `Describe(`, `Context(`, `It(` patterns
- Typically in `test/`, `e2e/`, `pkg/` directories
- File pattern: `*_test.go`

### 4. Extract Test Metadata

For each test file and test case, extract:

**Test Names:**
- Count total number of tests
- List unique test name prefixes (e.g., `[sig-network]`, `[platform:aws]`)

**Platform Patterns:**
- Tests with `[platform:xxx]` in names
- Tests with `Platform:xxx` labels (if Ginkgo v2 labels are used)
- Group by platform (aws, gcp, azure, etc.)

**Lifecycle Indicators:**
- Tests with `SLOW` label
- Tests with `Lifecycle:Blocking` or `Lifecycle:Informing`
- Tests marked as disruptive/serial

**Test Organization:**
- Common sig-* patterns
- Suite indicators
- Conformance markers

### 5. Identify Hooks

Look for:
- `BeforeAll()` / `AfterAll()` calls
- `BeforeEach()` / `AfterEach()` calls
- `BeforeSuite()` / `AfterSuite()` calls
- Any setup/teardown code that needs migration

### 6. Check Dependencies

Examine `go.mod`:
- Current Ginkgo version
- Whether OTE is already a dependency
- Other testing framework dependencies

### 7. Generate Migration Report

Provide a detailed report with:

```markdown
# OTE Migration Analysis Report

## Repository: <repo-name>

## Test Discovery
- **Total tests found**: X
- **Test files**: Y
- **Test directories**: list directories

## Platform Distribution
### Platform-specific tests:
- aws: X tests
  - Example: [test names]
- gcp: Y tests
  - Example: [test names]
- azure: Z tests
  - Example: [test names]
- Platform-agnostic: N tests

## Test Patterns Found

### Naming Patterns:
- `[sig-xxx]`: count and list
- `[platform:xxx]`: count and list
- `[Conformance]`: count
- `[Serial]`: count
- Other patterns: list

### Label Patterns:
- `Platform:xxx`: count and list
- `SLOW`: count
- `Lifecycle:xxx`: count and types

## Recommended Filter Code

Based on patterns found, here's the suggested filter code:

```go
// Platform filters from labels
specs.Walk(func(spec *et.ExtensionTestSpec) {
    for label := range spec.Labels {
        if strings.HasPrefix(label, "Platform:") {
            platformName := strings.TrimPrefix(label, "Platform:")
            spec.Include(et.PlatformEquals(platformName))
        }
    }
})

// Platform filters from test names
specs.Walk(func(spec *et.ExtensionTestSpec) {
    re := regexp.MustCompile(`\[platform:([a-z]+)\]`)
    if match := re.FindStringSubmatch(spec.Name); match != nil {
        platform := match[1]
        spec.Include(et.PlatformEquals(platform))
    }
})

// Add other pattern-specific filters here...
```

## Hooks to Migrate

List any BeforeAll/AfterAll/BeforeEach/AfterEach that need attention:
- File: path/to/file.go
- Type: BeforeAll
- Purpose: [describe what it does]

## Suggested Suites

Based on test organization, recommend:
1. Main suite: `<org>/<component>/tests`
   - Parents: `openshift/conformance/parallel`
2. Custom suites:
   - `<org>/<component>/slow` - for SLOW labeled tests
   - `<org>/<component>/platform-specific` - for platform tests
   - etc.

## Migration Complexity

**Complexity Level**: [Simple/Medium/Complex]

**Why**:
- [Reason 1]
- [Reason 2]

## Next Steps

1. Run `/migrate-ote` to perform the migration
2. Review and adjust the generated code
3. Test with `go build ./cmd/<extension-name>`
4. Validate with `./cmd/<extension-name> list`

## Potential Issues

List any concerns:
- [ ] Vendored tests detected
- [ ] Non-Ginkgo tests present
- [ ] Complex setup/teardown logic
- [ ] Dependencies need updating
```

## Analysis Tips

- Use `Grep` to search for patterns across multiple files
- Use `Glob` to find all test files efficiently
- Count occurrences of each pattern type
- Identify outliers or unusual patterns
- Look for inconsistencies in naming/labeling

## E2E Test Copying Implementation Notes

When copying e2e tests:

**Directory Detection:**
```bash
# Check for e2e test directories
Glob: "test/e2e/**/*_test.go"
Glob: "e2e/**/*_test.go"
Glob: "tests/e2e/**/*_test.go"
```

**Copying Tests:**
```bash
# Create destination directory if needed
Bash: mkdir -p <target-repo>/<destination-dir>

# Copy tests from source
Bash: cp -r <source-path>/<source-dir>/* <target-repo>/<destination-dir>/

# For selective copying (skip conflicts)
Bash: cp -n <source-path>/<source-dir>/* <target-repo>/<destination-dir>/

# For overwrite
Bash: cp -rf <source-path>/<source-dir>/* <target-repo>/<destination-dir>/
```

**Validation After Copy:**
- Re-scan for test files to confirm tests were copied
- Count files before and after
- List what was copied for user confirmation

**Common Source Locations:**
- OpenShift origin e2e tests: `openshift/origin/test/extended/`
- Component-specific templates
- Shared test libraries

Start by asking the user for the repository path to analyze.
