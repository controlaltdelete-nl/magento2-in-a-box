# Task 002: Migrate magento/Dockerfile-2.3 to nginx + PHP-FPM

**Status**: pending
**Depends on**: none
**Retry count**: 0

## Description
Switch the Magento 2.3 image from the `php -S` supervisord program to the base image's nginx + PHP-FPM. Remove the webserver COPY and activate the Magento nginx wrapper as the default site. No `chown` is needed: the base image is being changed to run FPM as root (see `base-image-fpm-root-prompt.md`), giving exact parity with the old root `php -S`, so `/data` stays uniformly root-owned and writable by the webserver.

## Context
- Related file: `magento/Dockerfile-2.3`
- Remove the line `COPY templates/supervisord-webserver.conf /etc/supervisor/conf.d/webserver.conf` (around line 81). Do NOT delete the template file itself here (shared with other variants; handled in task 006).
- Add `RUN cp /etc/nginx/available/magento.conf /etc/nginx/conf.d/default.conf` to activate Magento routing (serves `/data/pub` via `/data/nginx.conf.sample` through `upstream fastcgi_backend`). Keep `$MAGE_MODE` as developer (the image runs `deploy:mode:set developer`).
- Place the `cp` RUN after the big install RUN block (the one ending in `./stop-services`). It is fine anywhere after FROM since `/data/nginx.conf.sample` is only needed at runtime, but keep it after the install block for consistency across variants.
- Do NOT add a `chown`. Root-parity FPM (base image change) makes it unnecessary, and any build-time chown would be undone by consumers' root-run runtime commands anyway (see Risks in `_plan.md`).
- Do not change the FROM tag, the install commands, or EXPOSE.

## Requirements (Test Descriptions)
- [ ] `it no longer copies supervisord-webserver.conf into the image`
- [ ] `it copies /etc/nginx/available/magento.conf over /etc/nginx/conf.d/default.conf`
- [ ] `it does not chown /data`
- [ ] `it keeps deploy:mode:set developer unchanged`
- [ ] `it leaves the FROM base-image tag and EXPOSE unchanged`

## Acceptance Criteria
- `grep -q "supervisord-webserver.conf" magento/Dockerfile-2.3` returns no match.
- `grep -q "cp /etc/nginx/available/magento.conf /etc/nginx/conf.d/default.conf" magento/Dockerfile-2.3` matches.
- `grep -q "chown" magento/Dockerfile-2.3` returns no match.
- Code follows code standards.

## Implementation Notes
(Left blank - filled in by programmer during implementation)
