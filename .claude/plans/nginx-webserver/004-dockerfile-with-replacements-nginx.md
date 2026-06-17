# Task 004: Migrate magento/Dockerfile-with-replacements to nginx + PHP-FPM

**Status**: pending
**Depends on**: none
**Retry count**: 0

## Description
Switch the replacements image to nginx + PHP-FPM. This variant has an extra trap: it explicitly removes `php-fpm.conf` (because it used `php -S`). With nginx, PHP-FPM IS the backend, so that removal must be deleted or nginx returns 502. No `chown`: the base image runs FPM as root (see `base-image-fpm-root-prompt.md`).

## Context
- Related file: `magento/Dockerfile-with-replacements`
- Remove the line `COPY templates/supervisord-webserver.conf /etc/supervisor/conf.d/webserver.conf` (around line 69). Shared template deletion is task 006.
- **Remove the php-fpm disable block** (around lines 64-67): the comment `# Disable PHP-FPM: this image uses the PHP built-in web server, not FPM.` (and its two continuation lines) plus `RUN rm -f /etc/supervisor/conf.d/php-fpm.conf`. PHP-FPM must run at runtime for nginx to serve PHP.
- Add `RUN cp /etc/nginx/available/magento.conf /etc/nginx/conf.d/default.conf` after the install RUN block (ends in `./stop-services`). Keep `$MAGE_MODE` developer.
- Do NOT add a `chown` (root-parity FPM handles ownership).
- Background on the old php-fpm removal: the comment claimed FPM held file handles that blocked `di:compile` from cleaning `generated/`. That `rm` ran AFTER the install RUN finished, so it only ever affected runtime, not the build. Consumers DO run `setup:di:compile` as root at runtime (e.g. Mollie's e2e workflow), but the base FPM pool is `ondemand` (master runs, workers spawn only on a request), so during a runtime di:compile with no concurrent storefront traffic no worker holds handles on `generated/`. Removing the `rm` line is therefore safe; task 007 confirms di:compile still succeeds with FPM present.
- Do not change FROM, install commands, or EXPOSE.

## Requirements (Test Descriptions)
- [ ] `it no longer copies supervisord-webserver.conf into the image`
- [ ] `it no longer removes /etc/supervisor/conf.d/php-fpm.conf`
- [ ] `it removes the obsolete built-in-web-server php-fpm-disable comment`
- [ ] `it copies /etc/nginx/available/magento.conf over /etc/nginx/conf.d/default.conf`
- [ ] `it does not chown /data`
- [ ] `it keeps deploy:mode:set developer unchanged`

## Acceptance Criteria
- `grep -q "supervisord-webserver.conf" magento/Dockerfile-with-replacements` returns no match.
- `grep -q "php-fpm.conf" magento/Dockerfile-with-replacements` returns no match.
- `grep -qi "php-fpm\|built-in web server" magento/Dockerfile-with-replacements` returns no match (obsolete comment gone).
- `grep -q "cp /etc/nginx/available/magento.conf /etc/nginx/conf.d/default.conf" magento/Dockerfile-with-replacements` matches.
- `grep -q "chown" magento/Dockerfile-with-replacements` returns no match.
- Code follows code standards.

## Implementation Notes
(Left blank - filled in by programmer during implementation)
