#!/usr/bin/env bash
set -euo pipefail

# Guards against a broken PHPStan ending up in a published image. PHPStan 2.2.10
# started serving cache entries from a shared memory arena, which makes the
# autoloaders of bitexpert/phpstan-magento require source code instead of a file
# and turns every run into "Internal error: Failed opening required '<?php ...'".
# See https://github.com/bitExpert/phpstan-magento/issues/356
#
# The generated Factory classes are only written to the cache on a cold run, so
# the analysis has to start with an empty tmpDir to hit the problem.

container="$1"
cache_dir=/tmp/phpstan-smoke-cache
config=/data/phpstan-smoke.neon

find_module_path() {
    for path in vendor/magento/module-cms vendor/mage-os/module-cms; do
        if docker exec "${container}" test -d "/data/${path}"; then
            echo "${path}"
            return 0
        fi
    done

    echo "Could not find a CMS module to analyse in ${container}." >&2
    return 1
}

if ! docker exec "${container}" test -x /data/vendor/bin/phpstan; then
    echo "PHPStan is not installed in ${container}."
    exit 1
fi

module_path="$(find_module_path)"

docker exec "${container}" bash -c "rm -rf ${cache_dir} && mkdir -p ${cache_dir} && cat > ${config} <<'NEON'
parameters:
    level: 2
    tmpDir: ${cache_dir}
    paths:
        - ${module_path}
NEON"

output="$(docker exec -w /data "${container}" vendor/bin/phpstan analyse -c "${config}" --no-progress 2>&1 || true)"

echo "${output}"

if grep -qiE "Internal error|Failed opening required" <<<"${output}"; then
    echo
    echo "PHPStan crashed while analysing ${module_path}, so this image is not usable for static analysis."
    exit 1
fi

if ! grep -qE "\[OK\]|Found [0-9]+ error" <<<"${output}"; then
    echo
    echo "PHPStan did not complete the analysis of ${module_path}."
    exit 1
fi

echo
echo "PHPStan analysed ${module_path} without internal errors."
