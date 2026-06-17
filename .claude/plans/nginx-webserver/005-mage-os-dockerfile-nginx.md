# Task 005: Migrate mage-os/Dockerfile to nginx + PHP-FPM

**Status**: pending
**Depends on**: none
**Retry count**: 0

## Description
Switch the Mage-OS image from the `php -S` supervisord program to the base image's nginx + PHP-FPM. Remove the webserver COPY and activate the Magento nginx wrapper as the default site. No `chown`: the base image runs FPM as root (see `base-image-fpm-root-prompt.md`).

## Context
- Related file: `mage-os/Dockerfile`
- Remove the line `COPY templates/supervisord-webserver.conf /etc/supervisor/conf.d/webserver.conf` (around line 59). The shared template (`mage-os/templates/supervisord-webserver.conf`) is deleted in task 006.
- Add `RUN cp /etc/nginx/available/magento.conf /etc/nginx/conf.d/default.conf` after the install RUN block (ends in `./stop-services`). Mage-OS ships `nginx.conf.sample` in `/data` just like Magento, so the wrapper's `include /data/nginx.conf.sample;` resolves. Keep `$MAGE_MODE` developer.
- Do NOT add a `chown` (root-parity FPM handles ownership).
- Note `mage-os/Dockerfile` uses `FROM michielgerritsen/magento2-base-image:${PHP_VERSION}` (Docker Hub) while the magento variants use the ghcr base. BOTH must be the nginx-capable base build that also runs FPM as root (verified in task 007). Do not change the FROM here.
- Do not change install commands or EXPOSE.

## Requirements (Test Descriptions)
- [ ] `it no longer copies supervisord-webserver.conf into the image`
- [ ] `it copies /etc/nginx/available/magento.conf over /etc/nginx/conf.d/default.conf`
- [ ] `it does not chown /data`
- [ ] `it keeps deploy:mode:set developer unchanged`
- [ ] `it leaves the FROM base-image tag and EXPOSE unchanged`

## Acceptance Criteria
- `grep -q "supervisord-webserver.conf" mage-os/Dockerfile` returns no match.
- `grep -q "cp /etc/nginx/available/magento.conf /etc/nginx/conf.d/default.conf" mage-os/Dockerfile` matches.
- `grep -q "chown" mage-os/Dockerfile` returns no match.
- Code follows code standards.

## Implementation Notes
(Left blank - filled in by programmer during implementation)
