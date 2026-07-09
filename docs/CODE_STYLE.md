# Code Style

The project enforces consistent formatting and linting through **SwiftLint** and **swift-format**. Both tools must be installed and all checks must pass before opening a pull request.

## Installation

```bash
brew install swiftlint
brew install swift-format
```

## Running the Formatter

Run from the **repository root**:

```bash
# Check only — reports violations without modifying files
./scripts/format.sh --check

# Auto-fix — applies safe automatic fixes
./scripts/format.sh --fix
```

## SwiftLint

SwiftLint configuration lives in `.swiftlint.yml` at the repository root. Key rules and thresholds:

| Setting | Value |
|---|---|
| Line length warning | 120 characters |
| Line length error | 140 characters |
| `print()` usage | Banned (use a proper logger) |
| Snapshot directories | Excluded (`__Snapshots__`, `*SnapshotTests`) |

The `no_print` custom rule enforces the logger requirement. Violations at the error level block CI.

## swift-format

Formatting configuration lives in `.swift-format` at the repository root. The formatter is applied by `scripts/format.sh` and covers indentation, blank lines, import ordering, and trailing whitespace.

## Editor Integration

Most editors can be configured to run SwiftLint and swift-format on save. Consult your editor's documentation for the relevant plugin or extension. Ensure the tool versions match those required by the project to avoid false positives.

## CI Enforcement

The CI workflow runs `./scripts/format.sh --check` on every pull request. Formatting or lint errors will fail the build. Fix all issues locally before pushing.

## Guidelines

- Do not suppress SwiftLint rules with inline comments (`// swiftlint:disable`) unless there is a strong, documented reason.
- Keep functions short and focused. SwiftLint's complexity and length rules reflect intended limits.
- Prefer `let` over `var` where the value does not change.
- Use `async/await` over callback-based APIs for new code.
- Avoid `print()` — use the project's logger instead.
