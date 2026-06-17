# Task 001: Remove php -S port-switch from both entrypoints

**Status**: pending
**Depends on**: none
**Retry count**: 0

## Description
The inherited `./start-services` now performs the ENABLE_VARNISH nginx port switch itself. Remove the now-redundant block in both entrypoints that rewrote the (about-to-be-deleted) `webserver.conf` to listen on 8080. Both entrypoint files are byte-identical and must stay that way.

## Context
- Related files: `magento/entrypoint.sh`, `mage-os/entrypoint.sh` (currently identical)
- The block to remove is the FIRST `if [ "$ENABLE_VARNISH" = "true" ]` guard at the top of the file, including its two comment lines and the `sed -i 's/0.0.0.0:80/0.0.0.0:8080/' /etc/supervisor/conf.d/webserver.conf` line.
- Leave every other `ENABLE_VARNISH` block intact (the `core_config_data` caching_application write, the varnishd process-monitor check). Leave the `#!/bin/bash` shebang and all later logic untouched.
- After editing, `diff magento/entrypoint.sh mage-os/entrypoint.sh` must report no differences.

## Requirements (Test Descriptions)
- [ ] `it removes the listen-80-to-8080 sed block from magento entrypoint`
- [ ] `it removes the listen-80-to-8080 sed block from mage-os entrypoint`
- [ ] `it no longer references /etc/supervisor/conf.d/webserver.conf in either entrypoint`
- [ ] `it keeps the ENABLE_VARNISH caching_application core_config_data write intact`
- [ ] `it keeps the varnishd process-monitor check intact`
- [ ] `it leaves both entrypoint files byte-identical to each other`

## Acceptance Criteria
- `grep -c webserver.conf magento/entrypoint.sh mage-os/entrypoint.sh` returns 0 for both.
- `diff magento/entrypoint.sh mage-os/entrypoint.sh` exits 0 (no output).
- `grep -q "caching_application" magento/entrypoint.sh` still matches.
- Code follows code standards (bash: keep existing style, quoting, comments only where already present).

## Implementation Notes
(Left blank - filled in by programmer during implementation)
