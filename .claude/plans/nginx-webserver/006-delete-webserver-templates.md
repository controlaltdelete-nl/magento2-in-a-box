# Task 006: Delete the supervisord-webserver.conf templates

**Status**: pending
**Depends on**: 002, 003, 004, 005
**Retry count**: 0

## Description
Now that no Dockerfile COPYs them, delete the two `php -S` supervisord program templates. Done last among the file removals so no Dockerfile build references a missing COPY source in between.

## Context
- Related files: `magento/templates/supervisord-webserver.conf`, `mage-os/templates/supervisord-webserver.conf` (both identical: the `[program:webserver] command=/usr/bin/php -S 0.0.0.0:80 ...` entry).
- Depends on tasks 002-005 having removed every `COPY templates/supervisord-webserver.conf ...` line first.
- Leave all other files in `templates/` untouched (install-config-mysql.php, post-install-setup-command-config.php, memory-limit-php.ini).

## Requirements (Test Descriptions)
- [ ] `it deletes magento/templates/supervisord-webserver.conf`
- [ ] `it deletes mage-os/templates/supervisord-webserver.conf`
- [ ] `it leaves no remaining reference to supervisord-webserver.conf anywhere in the repo`
- [ ] `it keeps the other template files in place`

## Acceptance Criteria
- Neither `magento/templates/supervisord-webserver.conf` nor `mage-os/templates/supervisord-webserver.conf` exists.
- `grep -rn "supervisord-webserver.conf" magento mage-os` returns no matches.
- `magento/templates/install-config-mysql.php` and `mage-os/templates/memory-limit-php.ini` still exist.

## Implementation Notes
(Left blank - filled in by programmer during implementation)
