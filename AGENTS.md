# Agent notes

## Image names

Images are published to two registries. Only one is current:

| Status     | Image                                                                          |
|------------|--------------------------------------------------------------------------------|
| Use        | `ghcr.io/controlaltdelete-nl/magento2-in-a-box/magento-project-community-edition` |
| Use        | `ghcr.io/controlaltdelete-nl/magento2-in-a-box/mage-os-community-edition`         |
| Deprecated | `michielgerritsen/magento-project-community-edition` (Docker Hub)                 |
| Deprecated | `michielgerritsen/mage-os-community-edition` (Docker Hub)                         |

Tags are identical in both, e.g. `php84-fpm-mage-os2.3.0-sample-data`. The `latest`, `latest-sample-data` and short tags (`mage-os2.3.0`, `magento2.4.9`) only exist on ghcr.io.

- Always reference the ghcr.io names in docs, examples, answers and new code.
- The workflows still push to `michielgerritsen/` on Docker Hub for existing users, and use that local tag inside CI steps. Don't copy those names elsewhere.
- `michielgerritsen/exampletest` is a Composer package used by the CI smoke test, not an image. Leave it alone.

## Architecture

Read `docs/architecture.md` before changing Dockerfiles, scripts or workflows. It covers the build and publish flow and the gotchas (amd64-only base image, duplicated scripts per build context, what CI does not test).
