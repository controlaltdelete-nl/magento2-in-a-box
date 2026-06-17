# Architecture

"Magento 2 in-a-box" builds pre-installed Magento 2 and Mage-OS Docker images so a full environment is available with a single `docker run`. The images are the product; the test suites validate that they boot and behave correctly.

## Directory Structure

- `magento/` - Docker build context for Magento 2 images
  - `Dockerfile-2.3`, `Dockerfile-2.4`, `Dockerfile-with-replacements` - per-version image builds
  - `entrypoint.sh` - container start logic (sets URL, starts services)
  - `scripts/` - build/install helpers, including `install-hyva-checkout`
  - `templates/`, `patches/` - config templates and version patches
- `mage-os/` - Docker build context for Mage-OS images
  - `Dockerfile`, `entrypoint.sh`, `scripts/`, `templates/`
  - shares `install-hyva-checkout` with `magento/` via symlink
- `tests/` - validation suites
  - `*.spec.ts` - Playwright E2E specs run against a running container
  - `*.test.sh` - bash unit tests for the install scripts
- `Test/` - PHP Magento integration-test module (`MichielGerritsen\ExampleTest\`)
- `.github/workflows/` - CI: builds and tests each Magento/Mage-OS version matrix
- `examples/` - usage examples
- `test-2.3.sh`, `test-2.4.sh` - top-level scripts that spin up a container and run checks
- `playwright.config.ts` - E2E config (Chromium, serial, baseURL from `BASE_URL`)

## Patterns Used

- **Image-as-product**: the deliverable is a set of tagged Docker images (`php{ver}-fpm-magento{ver}`, optional `-sample-data`). Code changes are validated by rebuilding and running the suites.
- **Shared scripts via symlink**: `install-hyva-checkout` is one file linked into both `magento/` and `mage-os/`; edit the source, the symlink covers the other.
- **External-validation testing**: Playwright treats the container as a black box and asserts real storefront behavior (no internal mocks).
- **PHP integration tests**: run inside the container against the real Magento app using `Magento\TestFramework` and config fixtures.

## Conventions

- Tests live under `tests/` regardless of language; the PHP module lives under `Test/`.
- Specs target `BASE_URL` (default `http://magento.test`); never hardcode a host.
- Account for Magento runtime quirks in E2E: Varnish caching (form-key timing), KnockoutJS (hidden fields), and cold-start latency (generous timeouts).
- New image behavior gets a spec that proves it from the outside before the build change is considered done.

## Docker / Runtime

- Images run on PHP 8.x (current builds target php83 / php84) with PHP-FPM.
- Default admin: `exampleuser` / `examplepassword123`; two-factor auth disabled by default.
- `URL` env var configures the base URL the container serves; `-sample-data` tag variants include catalog data the cart/checkout specs depend on.

## Key Integrations

- **GitHub Actions** builds the full version matrix and runs the suites per image (`magento-2.3.yml`, `magento-2.4.yml`, `mage-os.yml`, `magento-with-replacements.yml`).
- **Hyva Checkout** install path is covered by `install-hyva-checkout` plus its bash unit tests.
- **DDEV / Docker** is how the container is run locally; outside Docker, DDEV is used to talk to it.
