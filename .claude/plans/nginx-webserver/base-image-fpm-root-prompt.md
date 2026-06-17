# Base image change: run PHP-FPM as root (parity with the old `php -S`)

> **STATUS: APPLIED & VERIFIED (2026-06-12).** The base image
> (`controlaltdelete-nl/magento2-docker-base-images`) now ships this change:
> `templates/php-fpm/zz-magento.conf` sets `user = root` / `group = root`; the stock Debian
> `pool.d/www.conf` is removed (`rm -f`), so there is no duplicate `[www]` pool; and php-fpm is
> started as root with the `-R` flag (`/usr/sbin/php-fpm$PHP_VERSION -F -R`), which is what lets
> the pool accept `user = root` without the "running as root" fatal. nginx (`default.conf`,
> `fastcgi_backend.conf`, `available/magento.conf`) is in place. No `chown`/`USER`, `/data` stays
> root-owned. The downstream `nginx-webserver` plan can now build against this base; the brief
> below is kept for reference.

Hand this to an AI (or do it yourself) working in the **magento2-docker-base-images** repo
(`controlaltdelete-nl/magento2-docker-base-images`, the image published as
`ghcr.io/controlaltdelete-nl/magento2-docker-base-images/magento2-base-image` and
`michielgerritsen/magento2-base-image`).

## Why

The base image now serves Magento through nginx + PHP-FPM. The FPM pool
(`templates/php-fpm/zz-magento.conf`, the `[www]` pool) sets no `user`/`group`, so workers
run as the Debian default **www-data**.

Downstream "in-a-box" images (and their real consumers, e.g. the Mollie extension's e2e
workflow) are built and used assuming **everything runs as root**:

- The image is built with `setup:install` as root, so `/data` is root-owned.
- Consumers `docker exec` into the running container and run, **as root**,
  `composer require` + `bin/magento setup:upgrade --keep-generated` + `setup:di:compile` +
  `setup:static-content:deploy` + `indexer:reindex`, which (re)create `/data/vendor`,
  `/data/generated`, `/data/pub/static` and write `/data/var` as **root-owned**.
- The storefront must then serve correctly.

Historically these images ran the PHP built-in server (`php -S`) as **root**, so there was
never a permission mismatch. Now that FPM serves as www-data, on the next request FPM cannot
write `var/cache`, `var/page_cache`, `var/session` (and, in developer mode, regenerate
`generated/` and `pub/static`), so the storefront 500s.

A build-time or entrypoint `chown` in the downstream image cannot fix this: the consumer's
root-run commands happen **after** the entrypoint, and there is no hook after them. The clean,
parity-preserving fix is to run the FPM pool as **root**, matching the old `php -S` exactly.

## Goal

Make the Magento FPM pool run its workers as **root**, so `/data` stays uniformly root-owned
and writable by the webserver, with no `chown` needed anywhere downstream. The FPM master
already runs as root under Supervisord, so this is purely a pool user/group change.

## What to change

In `templates/php-fpm/zz-magento.conf`, under the `[www]` pool, add:

```ini
user = root
group = root
```

Final file (order does not matter, but keep `[www]` first):

```ini
[www]
user = root
group = root
listen = 127.0.0.1:9000
pm = ondemand
pm.max_children = 4
pm.process_idle_timeout = 10s
pm.max_requests = 500
catch_workers_output = yes
```

## Watch out for

- **Duplicate `[www]` pool / stock `www.conf`.** Debian's php-fpm ships
  `/etc/php/${PHP_VERSION}/fpm/pool.d/www.conf` (also `[www]`, `user = www-data`). Two pools
  with the same name is a fatal php-fpm error, so the base must already be removing or
  overriding the stock `www.conf`. Confirm how that is handled. If the stock `www.conf` is
  still present, deleting it in the Dockerfile (`rm -f .../pool.d/www.conf`) is the right move
  so `zz-magento.conf` is the only `[www]` pool. If it is already removed, just add the two
  lines above.
- **FPM refuses to start with no user when run as root.** When the master runs as root, every
  pool MUST declare `user`/`group`. Adding `user = root`/`group = root` satisfies that. After
  the change, confirm php-fpm actually starts (check Supervisord logs for the pool, not just
  that the container is up).
- **`pm.max_children` override env var.** The downstream brief references a `PHP_FPM_MAX_CHILDREN`
  env override. If that is implemented elsewhere, this change does not touch it; leave it intact.
- **Security.** Running FPM as root is acceptable for these disposable test/CI images (it
  restores the exact privilege level of the previous `php -S`). Do NOT carry this pattern into
  a production-intended image.

## How to validate

1. Rebuild the base image.
2. Build a downstream image on it and run the container.
3. `docker exec` as root and run `bin/magento setup:di:compile` and
   `setup:static-content:deploy -f` (mimic the consumer flow), then:
   - `curl -I http://localhost/` returns 200 (not 502 / not 500).
   - Load an uncached category/product page; it renders with no permission error in
     `/data/var/log/` (`exception.log`, `system.log`).
   - `docker exec <container> ps -o user= -C php-fpm` shows the worker processes running as
     `root`.
4. Confirm php-fpm starts cleanly (Supervisord shows the pool running, no "please specify user
   and group" fatal).

## Coordination

The downstream change (this in-a-box repo, plan `nginx-webserver`) drops the PHP dev server and
activates `magento.conf`, and deliberately does NOT chown `/data`, relying on this base change
for the webserver to run as root. Build and publish the updated base (or build it locally and
point the downstream `FROM` at it) BEFORE validating the downstream images, or the storefront
will 500 on the first write.
