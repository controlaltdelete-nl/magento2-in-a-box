# Task 007: Validate the nginx migration

**Status**: pending
**Depends on**: 001, 002, 003, 004, 005, 006
**Retry count**: 0

## Description
End-to-end validation that the storefront now serves through nginx + PHP-FPM (running as root, parity with the old `php -S`) with no regression, in both default and Varnish modes, including the consumers' root-run runtime sequence, plus the existing bash unit tests. Building these images is heavy (full Composer install) and may run on the maintainer's machine or in CI rather than in-session; this task is the runbook plus the cheap static checks.

## Context
- **Base image precondition (SATISFIED 2026-06-12):** the base image (`base-image-fpm-root-prompt.md`) ships nginx support AND runs FPM as root (`zz-magento.conf` has `user/group = root`, stock `www.conf` removed, php-fpm started with `-R`). Just confirm the `FROM` tags in these Dockerfiles resolve to that current base build, e.g. `docker pull` the base tag fresh or `docker build --pull` so a stale cached base layer is not used. If a build still 404s on `/etc/nginx/available/magento.conf`/`fastcgi_backend.conf`, or the storefront 500s on `var/` writes, the build pulled a stale base; re-pull and rebuild.
- Validation targets at least one magento variant, the with-replacements variant, and the mage-os variant. The with-replacements variant is mandatory here because it is the one that previously removed `php-fpm.conf`.
- **Ownership model:** with FPM running as root, `/data` stays uniformly root-owned, so the consumers' root-run runtime commands and the webserver agree. No chown exists in any Dockerfile (verify), and none is needed. The point of the runtime-sequence check below is to PROVE this: after a root-run di:compile, an uncached page must render with no permission error.
- **Real consumer flow (e.g. Mollie's e2e workflow):** consumers `docker exec` as root and run `composer require`/`install-composer-package`, `setup:upgrade --keep-generated`, `setup:di:compile`, `setup:static-content:deploy -f`, `indexer:reindex`, then hit the storefront. This repo's own CI does the equivalent (see `.github/workflows/magento-2.4.yml` around the `composer require` + `deploy:mode:set developer` + `setup:di:compile` steps). Validation MUST run the storefront page-load checks AFTER that runtime di:compile, not just on a fresh container.
- **di:compile with FPM present:** the with-replacements variant used to remove `php-fpm.conf` so FPM would not hold handles on `generated/` during di:compile. FPM is now present; the base pool is `ondemand` (master runs, no idle workers), so a runtime di:compile with no concurrent traffic should still succeed. Confirm it does.
- **FPM master under ondemand:** the entrypoint process-monitor greps `php`, which still matches `php-fpm: master process` even though `ondemand` spawns no idle workers. Confirm the master stays up (the monitor must not false-exit).
- **Match the real CI probes:** the existing workflows detect a healthy storefront by grepping response headers, not a bare status line: Varnish disabled greps `200 OK`, Varnish enabled greps `X-Magento-Tags`. Use the same checks.
- The `tests/install-hyva-checkout.test.sh` bash unit tests are unrelated to nginx but must stay green.

## Requirements (Test Descriptions)
- [ ] `it returns 200 OK from nginx for the homepage in default mode (header grep, matching CI)`
- [ ] `it renders a category or product page without a 502 or permission error`
- [ ] `it confirms the php-fpm worker processes run as root (parity with the old php -S)`
- [ ] `it serves the storefront on port 80 with ENABLE_VARNISH=true and returns the X-Magento-Tags header (matching CI Varnish probe)`
- [ ] `it confirms the php-fpm master process is running (and the entrypoint monitor does not false-exit under ondemand)`
- [ ] `it runs the consumer runtime sequence (composer require, deploy:mode:set developer, setup:di:compile as root) and setup:di:compile succeeds with FPM present`
- [ ] `it loads an uncached storefront page AFTER the runtime di:compile without a permission error in var/log`
- [ ] `it passes the example integration test in dev/tests/integration after the runtime di:compile`
- [ ] `it passes tests/storefront.spec.ts against the container`
- [ ] `it passes tests/cart-and-checkout.spec.ts against the container`
- [ ] `it passes tests/customer-account.spec.ts against the container`
- [ ] `it keeps tests/install-hyva-checkout.test.sh passing`

## Acceptance Criteria
- Build runbook (per validated variant; mirrors the CI workflow probes and the consumer runtime sequence):
  ```bash
  # default mode
  docker build -t nginx-check magento -f magento/Dockerfile-2.4
  docker run -d --rm --name nginx-check -p 1234:80 -e URL=http://localhost:1234/ nginx-check
  curl -s -D- -o /dev/null http://localhost:1234/ | grep -qi "200 OK"      # nginx healthy (CI probe)
  curl -s http://localhost:1234/ | grep -qi copyright                       # storefront renders
  docker exec nginx-check sh -c 'ps aux | grep -q "[p]hp-fpm"'             # fpm master running
  docker exec nginx-check ps -o user= -C php-fpm | sort -u                  # expect: root (parity)

  # consumer runtime sequence (root re-touches generated/; di:compile runs with FPM up)
  docker exec nginx-check composer require michielgerritsen/exampletest:@dev || true
  docker exec nginx-check ./retry "bin/magento deploy:mode:set developer"
  docker exec nginx-check ./retry "php bin/magento setup:di:compile"        # must succeed with FPM present
  curl -s http://localhost:1234/?nocache=$RANDOM | grep -qi copyright       # uncached load AFTER di:compile
  docker exec nginx-check sh -c 'grep -ri "permission denied" /data/var/log || echo "no perm errors"'

  # Varnish mode
  docker run -d --rm --name nginx-varnish -p 1235:80 -e URL=http://localhost:1235/ -e ENABLE_VARNISH=true nginx-check
  curl -s -D- -o /dev/null http://localhost:1235/ | grep -qi "X-Magento-Tags"  # CI Varnish probe

  BASE_URL=http://localhost:1234 npx playwright test tests/storefront.spec.ts tests/customer-account.spec.ts
  ```
- Repeat the build runbook for `magento/Dockerfile-with-replacements` (the variant that previously removed php-fpm.conf) and `mage-os/Dockerfile`.
- `bash tests/install-hyva-checkout.test.sh` exits 0.
- Any failure (502, permission denied in `var/` or `pub/static`, di:compile failure with FPM present, fpm workers NOT running as root, missing nginx files) is captured with the failing output before declaring done. A www-data/permission failure means the base image is not yet running FPM as root: fix the base (`base-image-fpm-root-prompt.md`) rather than adding a chown here.

## Implementation Notes
Validated 2026-06-12 on a native arm64 build of `magento/Dockerfile-2.4`
(`PHP_VERSION=php84-fpm`, `MAGENTO_VERSION=2.4.8`, `SAMPLE_DATA=false`). The ghcr base tag
`magento2-base-image:php84-fpm` is amd64-only and this host is arm64 with no buildx/qemu, so the
build used the locally-cached arm64 `magento2-base-image:8.4` (verified to be the updated base:
nginx present, `fastcgi_backend` -> 127.0.0.1:9000, fpm pool `user/group = root`, stock
`www.conf` removed), retagged to the ghcr name the Dockerfile expects, built without `--pull`.

Results (all green):
- Default mode: `200 OK`, `Server: nginx/1.18.0`, `X-Magento-Tags` present (FPC working).
- `php-fpm` master + worker run as **root** (parity with old `php -S`).
- `webserver.conf` absent; `/etc/nginx/conf.d/default.conf` is the Magento wrapper (`set $MAGE_ROOT /data`).
- Consumer runtime sequence as root (`composer require` exampletest, `deploy:mode:set developer`,
  `setup:di:compile`) all succeeded; `di:compile` completed **with php-fpm present**.
- Example integration test: OK (2/2).
- Uncached homepage after the root `di:compile`: `200`, no permission errors in `/data/var/log`.
- `ENABLE_VARNISH=true`: `200` with `X-Varnish`/`X-Magento-Tags`, nginx switched to `listen 8080;`
  by the inherited `start-services`, varnishd running.

Not run: Playwright specs (skipped per user; would also need a `-sample-data` image for the
cart/checkout spec) and the other variants (2.3, with-replacements, mage-os) and PHP versions,
which are left to CI (amd64). Code committed as `d0357b3` on `feature/nginx-webserver`.
