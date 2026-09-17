# Architecture

Pre-installed Magento 2 and Mage-OS Docker images for testing extensions. This page covers what the code does not tell you; read the Dockerfiles and workflows for the details.

## Layout

| Path | What it is |
|------|------------|
| `magento/Dockerfile-2.4` | Magento Open Source image, built from the `mirror.mage-os.org` project zip |
| `magento/Dockerfile-with-replacements` | Same, with `yireo/magento2-replace-all` applied to strip optional modules |
| `mage-os/Dockerfile` | Mage-OS image, built with `composer create-project` from `repo.mage-os.org` |
| `*/entrypoint.sh` | Runtime startup, identical in both folders |
| `*/scripts`, `*/templates` | Build and runtime helpers copied into the image |
| `tests/` | Playwright tests run against every built image |
| `Test/` | Example extension (`michielgerritsen/exampletest`) used as a CI smoke test |
| `examples/github` | Workflows for users of the images, not used by this repo's CI |

## Build

Everything runs in one big `RUN` layer so services can stay up during the install:

1. `./start-services` from the base image (MySQL, Elasticsearch, PHP-FPM, nginx).
2. Download and `composer update` Magento or Mage-OS, then `setup:install` with fixed credentials (`exampleuser` / `examplepassword123`).
3. Developer mode, optional sample data, 2FA disabled, static content deploy, `setup:di:compile`, reindex.
4. Create `/data/extensions` and register it as a Composer path repository, so users `docker cp` their module there and `composer require` it.
5. Install PHPStan and `bitexpert/phpstan-magento`, then clean caches and `.git` folders to shrink the image.

After that layer the integration test config templates are copied into `dev/tests/integration/etc/`, and `patch-phpunit-xml.php` generates `phpunit.xml` for the integration and unit suites, pointing at `/data/extensions/**/Test/{Integration,Unit}` with Allure removed.

## Runtime

`entrypoint.sh` starts the services, then writes config straight into `core_config_data` (base URL, Varnish, flat tables) so Magento only bootstraps once for a single `cache:flush`. `CUSTOM_ENTRYPOINT_COMMAND` or a mounted `custom-entrypoint.sh` runs after the base URL and Varnish settings and before flat tables and 2FA. The script then loops and exits when MySQL, Elasticsearch, PHP or Varnish dies, so the container stops instead of hanging.

## CI and publishing

| Workflow | Triggers | Builds |
|----------|----------|--------|
| `magento-2.4.yml` | PR, Monday 00:00, manual | Magento matrix, split into `build` and a frozen `build-legacy` because of GitHub's 256-entry matrix cap. Each entry calls `magento-2.4-build.yml` |
| `mage-os.yml` | PR, Monday 00:00, manual | Mage-OS matrix |
| `magento-with-replacements.yml` | PR, Monday 00:00, manual | Replacement variants |
| `check-new-versions.yml` | Daily 06:00, manual | Nothing; fails when a recent `magento/magento2` or `mage-os/mageos-magento2` tag is missing from the matrices |

None of them run on push. After merging to `master`, trigger the workflow by hand if the images should update before Monday.

Each matrix entry builds, starts the container, checks the webserver (Varnish randomly on or off), runs Playwright, installs the example module, runs `setup:di:compile`, and runs `.github/scripts/phpstan-smoke.sh`. Only on `master` does it push, to ghcr.io and to the deprecated Docker Hub names (see `AGENTS.md`).

Tags: `<php>-magento<version>[-sample-data]` or `<php>-mage-os<version>[-sample-data]`. Mage-OS and Magento entries with `MAIN_VERSION` also get `magento<version>` / `mage-os<version>`, entries with `LATEST` get `latest` / `latest-sample-data`. Those extra tags are ghcr.io only. Adding a version means adding matrix entries and a row in the README version matrix.

## Gotchas

- **Base image lives elsewhere.** nginx, PHP-FPM, MySQL, search, Varnish and `start-services` come from `ghcr.io/controlaltdelete-nl/magento2-docker-base-images/magento2-base-image`. It is amd64 only; on Apple Silicon build with `docker build --platform linux/amd64`, which is slow under emulation.
- **Scripts are duplicated on purpose.** Magento builds use `magento/` as the Docker build context and Mage-OS uses `mage-os/`, so neither can see the other's files. A fix to a shared script or to `entrypoint.sh` usually needs to land in both folders.
- **Mage-OS gets less testing than Magento.** The Magento workflows run the example integration test; `mage-os.yml` installs the example module but never runs phpunit. No workflow exercises the unit suite or GraphQL.
- **Version-specific workarounds.** `apply-2.4-patches.php` pins `webonyx/graphql-php` below 15.31.0 for Magento 2.4.6 to 2.4.8 (reason not recorded) and is not applied to Mage-OS. `bitexpert/phpstan-magento` 0.40 to 0.43 is excluded because of https://github.com/bitExpert/phpstan-magento/issues/356; `phpstan-smoke.sh` guards against a regression.
- **Most of `magento/scripts` is legacy.** `patch-AC2855.php`, `downgrade-monolog.php`, `remove-paypal-braintree.php`, `upgrade-to-composer-2.php` and most of `apply-2.4-patches.php` only act on Magento 2.4.0 to 2.4.5.
- **Unused files.** `magento/scripts/enable-flat-catalog` is copied into the image but the entrypoint enables flat tables with SQL instead. `mage-os/templates/memory-limit-php.ini` and `*/scripts/install-sample-data` are not referenced anywhere.
