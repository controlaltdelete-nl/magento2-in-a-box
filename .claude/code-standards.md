# Code Standards

This repo mixes TypeScript (Playwright specs), Bash (Docker entrypoints, install scripts, test scripts), Dockerfiles, and a small PHP module. Apply the standard for the file you are editing.

## Linting

No linter or formatter is configured in this project (no ESLint, Prettier, or PHP CS Fixer in `devDependencies`). There is no lint command to run.

- Match the style of the surrounding file rather than introducing a tool.
- Keep TypeScript clean enough to pass `tsc` if it were run; avoid implicit `any`.
- For Bash, keep `set -u` (and `set -e` where the script already uses it) intact.

## Pre-commit Checks

- The relevant test layer passes: `npm test` for spec changes, `bash tests/<name>.test.sh` for script changes.
- Dockerfile / entrypoint changes are validated by rebuilding the affected image and running the E2E suite against it.
- No secrets or credentials committed (the install scripts detect credentials at runtime).

## TypeScript (Playwright specs)

- `const` by default, `let` only when reassignment is needed.
- Prefer role/text locators (`getByRole`, `getByText`) over brittle CSS selectors.
- Booleans and boolean-returning helpers start with `is` / `has` / `can` / `should`.
- No default exports for shared helpers; export named functions.
- Comments only where the DOM behavior is genuinely surprising (e.g. KnockoutJS hidden fields, Varnish form-key timing) - those are worth keeping.

## Bash

- Shebang `#!/bin/bash`, `set -u` minimum.
- Quote all expansions: `"$var"`.
- Resolve paths relative to the script: `REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"`.
- The `install-hyva-checkout` script is shared between `magento/` and `mage-os/` via symlink; edit the real file, not the copy.

## PHP (`Test/`)

- `declare(strict_types=1)` on new files; typed parameters and return types including `: void`.
- `ObjectManager::getInstance()` is allowed here because this is Magento integration-test code (fixtures/test setup), not production code.
- Test methods describe behavior in camelCase (`itReturnsConfiguredStoreName`).
- Keep the current copyright year (2026) on new files that include a header.

## Naming Conventions

- TS variables/functions: `camelCase`
- TS types/interfaces: `PascalCase`
- PHP classes: `PascalCase`, one class per file, filename matches class
- Bash variables: `UPPER_SNAKE_CASE` for script-level constants, lowercase for locals
- Constants: `SCREAMING_SNAKE_CASE`

## General

- No em dashes in code, comments, commit messages, or docs.
- Before introducing a magic string or number, check for an existing constant.
- Early returns / guard clauses over nested conditionals.
