#!/usr/bin/env bash
set -euo pipefail

push_image() {
    for attempt in 1 2 3; do
        if docker push "$1"; then
            return 0
        fi

        echo "Pushing $1 failed (attempt ${attempt}/3), retrying in 15 seconds..."
        sleep 15
    done

    return 1
}

for image in "$@"; do
    push_image "${image}"
done
