# Testing Configuration

This repo has three test layers, all validating the "Magento 2 in-a-box" Docker images:

1. **Playwright E2E** (`tests/*.spec.ts`) - drives a running Magento/Mage-OS container through the storefront, customer account, cart and checkout flows.
2. **Bash unit tests** (`tests/*.test.sh`) - validate the install scripts (e.g. `install-hyva-checkout`) without running a real Composer install.
3. **PHP integration tests** (`Test/`) - a Magento integration-test module run inside the container with Magento's `TestFramework`.

## Test Framework

- E2E: `@playwright/test` (Chromium project, `fullyParallel: false`, 1 retry)
- Bash: plain `bash` assertion scripts, exit 0 on pass / 1 on fail
- PHP: PHPUnit via `Magento\TestFramework` (integration suite)

## TDD Methodology

Each task follows strict Red -> Green -> Refactor:

1. Write a failing test for one requirement
2. Write the minimum code to pass
3. Refactor while tests stay green
4. Repeat for the next requirement
5. Commit when the task is complete

For E2E, "code" usually means the Dockerfile, entrypoint, or install scripts under `magento/` and `mage-os/`; the spec is the failing test that proves the image behaves correctly.

## Commands

```bash
# Run all Playwright E2E tests against a running container
npm test
# headed (watch the browser)
npm run test:headed

# Run a single spec
npx playwright test tests/cart-and-checkout.spec.ts

# Run a single test by title
npx playwright test -g "add a product to the cart"

# Point the suite at a specific container
BASE_URL=http://localhost:1234 npm test

# Bash unit tests for the install scripts
bash tests/install-hyva-checkout.test.sh

# PHP integration tests (inside the Magento container)
vendor/bin/phpunit -c dev/tests/integration/phpunit.xml Test/
```

## Parallel Execution

- Playwright is parallel-capable but this project pins `fullyParallel: false` in `playwright.config.ts`, because the specs share one Magento instance and mutate cart/customer state. Keep it serial unless tests are isolated.
- To debug a single failure, narrow with `-g "<title>"` rather than enabling parallelism.

## Test File Locations

- E2E specs: `tests/*.spec.ts`
- Bash unit tests: `tests/*.test.sh`
- PHP integration tests: `Test/` (namespace `MichielGerritsen\ExampleTest\`)

## Coverage Requirements

No coverage percentage - this is an end-to-end suite. The goal is that the critical image-validation flows stay covered:

- Storefront loads (homepage, login page, empty cart)
- Customer account registration and login
- Add to cart and reach checkout (sample-data images)
- Install scripts guard correctly (bash tests)

When a new image feature or install script lands, add a spec that proves it from the outside.

## Test Naming Convention

- Playwright: `test("<does something>", ...)` inside a `test.describe("<area>")` block, behavior-described in plain language.
- Bash: each assertion prints a clear pass/fail line so CI logs pinpoint the failure.
- PHP: `it<Behavior>` style camelCase method names for new tests.

## Flaky Tests

When a test is flaky or fails only in CI, run it at least 10 times in a row before declaring it fixed:

```bash
for i in $(seq 1 10); do npx playwright test -g "<title>" || break; done
```

Known sources of flake in this suite: Varnish-cached form keys (wait for `form_key` to populate), KnockoutJS-hidden fields (use keyboard input, not `fill()`), and slow first-byte on a cold container (specs use 30s timeouts on storefront actions).
