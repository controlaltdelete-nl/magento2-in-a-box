# Task 003: Migrate magento/Dockerfile-2.4 to nginx + PHP-FPM

**Status**: pending
**Depends on**: none
**Retry count**: 0

## Description
Switch the Magento 2.4 image from the `php -S` supervisord program to the base image's nginx + PHP-FPM. Remove the webserver COPY and activate the Magento nginx wrapper as the default site. No `chown`: the base image runs FPM as root (see `base-image-fpm-root-prompt.md`), matching the old root `php -S`.

## Context
- Related file: `magento/Dockerfile-2.4`
- Remove the line `COPY templates/supervisord-webserver.conf /etc/supervisor/conf.d/webserver.conf` (around line 82). Do NOT delete the shared template file (task 006).
- Add `RUN cp /etc/nginx/available/magento.conf /etc/nginx/conf.d/default.conf` after the install RUN block (ends in `./stop-services`). Keep `$MAGE_MODE` developer.
- Do NOT add a `chown` (root-parity FPM handles ownership).
- Do not change FROM, install commands, or EXPOSE.
- Mirror the exact placement/wording chosen in task 002 for consistency across variants.

## Requirements (Test Descriptions)
- [ ] `it no longer copies supervisord-webserver.conf into the image`
- [ ] `it copies /etc/nginx/available/magento.conf over /etc/nginx/conf.d/default.conf`
- [ ] `it does not chown /data`
- [ ] `it keeps deploy:mode:set developer unchanged`
- [ ] `it leaves the FROM base-image tag and EXPOSE unchanged`

## Acceptance Criteria
- `grep -q "supervisord-webserver.conf" magento/Dockerfile-2.4` returns no match.
- `grep -q "cp /etc/nginx/available/magento.conf /etc/nginx/conf.d/default.conf" magento/Dockerfile-2.4` matches.
- `grep -q "chown" magento/Dockerfile-2.4` returns no match.
- Code follows code standards.

## Implementation Notes
(Left blank - filled in by programmer during implementation)
