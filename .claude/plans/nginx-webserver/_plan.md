# Plan: Serve storefront via base-image nginx + PHP-FPM

## Created
2026-06-11

## Status
completed

## Objective
Replace the PHP built-in dev server (`php -S`) with the nginx + PHP-FPM stack the updated base image now ships, in both the magento/ and mage-os/ image variants, so e2e tests run against a concurrent webserver while ENABLE_VARNISH keeps working exactly as before.

## Related Issues
none

## Discovery Notes
- All files named in the source brief exist. `magento/entrypoint.sh` and `mage-os/entrypoint.sh` are byte-identical; the two `templates/supervisord-webserver.conf` files are identical too.
- Webserver `COPY` lines: `magento/Dockerfile-2.3:81`, `magento/Dockerfile-2.4:82`, `magento/Dockerfile-with-replacements:69`, `mage-os/Dockerfile:59`. Each installs `templates/supervisord-webserver.conf` as `/etc/supervisor/conf.d/webserver.conf` (the `php -S 0.0.0.0:80` program).
- **Gap the brief missed:** `magento/Dockerfile-with-replacements:67` runs `rm -f /etc/supervisor/conf.d/php-fpm.conf` ("this image uses the PHP built-in web server, not FPM"). With nginx serving through PHP-FPM that line removes nginx's only backend and must be deleted. None of the other three Dockerfiles touch php-fpm.
- All four images run `deploy:mode:set developer`. Decision: **keep developer mode** (nginx+fpm concurrency is the speedup).
- **Ownership decision (revised after investigating real usage):** the old `php -S` ran as **root**, so `/data` was uniformly root-owned and the webserver could always write `var/`, `generated/`, `pub/static`, `pub/media`. The base image's nginx FPM pool currently runs as **www-data** (`zz-magento.conf` sets no user/group, inheriting the Debian default). Real consumers (e.g. the Mollie extension's e2e workflow) `docker exec` as root and run `setup:upgrade`/`setup:di:compile`/`setup:static-content:deploy`/`indexer:reindex` AFTER container start, then hit the storefront. Those root-run commands re-own `/data` as root; a build-time or entrypoint chown cannot fix it because there is no hook after the consumer's commands. Decision: **run FPM as root** (parity with the old `php -S`) via a one-line change in the BASE image (`user = root`/`group = root` in `zz-magento.conf`), captured in `base-image-fpm-root-prompt.md`. These downstream Dockerfiles therefore add **no chown**. **The base change is shipped and verified (2026-06-12):** `zz-magento.conf` has `user/group = root`, the stock `www.conf` is removed, and php-fpm runs as root via the `-R` flag. The downstream plan is now unblocked end to end.
- The entrypoint process-monitor loop greps for `php`, which still matches the php-fpm master process, so it stays valid after `php -S` is gone.
- No README/example/CI/test-script references to `php -S`, `phpserver`, or `router.php`, so docs need no change. `phpserver/router.php` stays in place (unused, harmless).

## Scope

### In Scope
- Remove the `php -S` supervisord program (both templates) and the now-redundant ENABLE_VARNISH port-switch in both entrypoints.
- In each Dockerfile: drop the webserver `COPY` and activate the base image's Magento nginx config (`cp /etc/nginx/available/magento.conf /etc/nginx/conf.d/default.conf`). No chown.
- Remove the `rm -f php-fpm.conf` line in `Dockerfile-with-replacements`.
- Keep ENABLE_VARNISH behavior identical (port switch now handled by the inherited `./start-services`).
- Author the base image change brief (`base-image-fpm-root-prompt.md`) that makes FPM run as root; this plan depends on that base change being built/published first.
- Provide a validation runbook (curl + ENABLE_VARNISH + consumer runtime sequence + Playwright) and run the existing bash unit tests.

### Out of Scope
- The base image change itself (FPM-as-root) lives in `magento2-docker-base-images`; this plan only writes the brief and depends on it. See `base-image-fpm-root-prompt.md`.
- Switching images to production mode (kept developer per decision).
- Changing the base image FROM tag (assumed pointing at a base build that has BOTH nginx support and FPM-as-root once the base change ships).
- Removing `phpserver/router.php` (unused, left in place).
- Any change to the PHP integration-test module or Playwright spec content (specs are run only to confirm no regression).
- Any chown in these Dockerfiles (root-parity FPM makes it unnecessary, and it could not survive the consumers' root-run runtime commands anyway).

## Success Criteria
- [ ] No `php -S` program remains: both `supervisord-webserver.conf` templates deleted and no Dockerfile COPYs them.
- [ ] Each Dockerfile activates `magento.conf` as `default.conf` and contains no `chown`.
- [ ] `Dockerfile-with-replacements` no longer removes `php-fpm.conf`.
- [ ] Both entrypoints have the port-switch block removed and remain byte-identical to each other.
- [x] Base image change (`base-image-fpm-root-prompt.md`) is built/published and the `FROM` tags resolve to a base that serves via nginx and runs FPM as root. (Verified 2026-06-12.)
- [ ] FPM worker processes run as `root` in the running container (parity with the old `php -S`).
- [ ] Default mode: response headers contain `200 OK` from nginx; a category/product page renders. Varnish mode: response headers contain `X-Magento-Tags` (matching the CI probes in `.github/workflows/*.yml`).
- [ ] The consumer runtime sequence (`composer require`, `deploy:mode:set developer`, `setup:di:compile` as root) completes, di:compile succeeds with FPM present, and an uncached storefront page still renders afterward with no permission error in `var/log`.
- [ ] Existing Playwright specs (storefront, cart-and-checkout, customer-account) pass against a built container.
- [ ] `bash tests/install-hyva-checkout.test.sh` still passes.
- [ ] Code follows project standards.

## Task Overview
| Task | Description | Depends On | Status |
|------|-------------|------------|--------|
| 001 | Remove php -S port-switch from both entrypoints | - | completed |
| 002 | Migrate magento/Dockerfile-2.3 to nginx | - | completed |
| 003 | Migrate magento/Dockerfile-2.4 to nginx | - | completed |
| 004 | Migrate magento/Dockerfile-with-replacements to nginx (+ keep php-fpm) | - | completed |
| 005 | Migrate mage-os/Dockerfile to nginx | - | completed |
| 006 | Delete both supervisord-webserver.conf templates | 002,003,004,005 | completed |
| 007 | Validate (curl, Varnish, Playwright, bash tests) | 001,002,003,004,005,006 | completed (core validated on php84/2.4.8; Playwright skipped per user) |

## Architecture Notes
- The base image autostarts nginx (`/etc/nginx/conf.d/default.conf` serving `/data`), defines `upstream fastcgi_backend { server 127.0.0.1:9000; }`, runs PHP-FPM on 127.0.0.1:9000, and ships an inactive `/etc/nginx/available/magento.conf` that `include`s `/data/nginx.conf.sample`. Activation = copying that wrapper over `default.conf`.
- The `cp magento.conf default.conf` is a build-time RUN; `/data/nginx.conf.sample` only needs to exist at runtime (it ships with the Magento/Mage-OS codebase in `/data`), so the RUN can sit after the install block alongside the chown.
- ENABLE_VARNISH port switch is now owned by the inherited `./start-services`, which rewrites nginx `listen 80;` to `listen 8080;`. The entrypoint must stop doing its own sed against the (now deleted) `webserver.conf`.

## Risks & Mitigations
- **Webserver cannot write var/generated/pub/static/pub/media** -> root old behavior is restored by running FPM as root (base image change, `base-image-fpm-root-prompt.md`); `/data` stays uniformly root-owned. No chown in these Dockerfiles. Task 007 proves it by loading an uncached page after a root-run di:compile and checking `var/log` for permission errors and that fpm workers run as root.
- **Consumers re-own /data as root at runtime** -> consumers (e.g. Mollie) and this repo's CI run `composer require` + `deploy:mode:set developer` + `setup:di:compile` as ROOT against the live container after start, re-owning `/data/vendor`/`/data/generated`/`var`. With FPM-as-root this is a non-issue (root webserver + root files agree); the rejected alternative (chown to www-data) could not survive this because there is no hook after the consumer's commands.
- **php-fpm not running at runtime** (replacements variant) -> remove the `rm -f php-fpm.conf` line; validation confirms `curl` returns 200 (not 502). The original removal existed because runtime `setup:di:compile` needs `generated/` unlocked; with `ondemand` FPM and no concurrent traffic during the di:compile step, no worker holds handles. Task 007 confirms di:compile still succeeds with FPM present.
- **Base dependency** -> RESOLVED. The base image ships both nginx support and FPM-as-root (verified 2026-06-12). Remaining check in task 007: confirm the `FROM` tags in these Dockerfiles resolve to that base build (the published tag is current), not a stale cached layer.
- **Entrypoints drift apart** -> task 001 edits both identically and asserts they stay byte-identical.
- **Building images is heavy / may not be possible in this environment** -> task 007 is a runbook the maintainer (or CI) executes; the file-edit tasks are independently verifiable by inspection.
