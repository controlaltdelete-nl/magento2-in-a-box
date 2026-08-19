#!/usr/bin/env bash
set -euo pipefail

download_browser() {
    for attempt in 1 2 3; do
        if npx playwright install chromium; then
            return 0
        fi

        echo "Downloading Chromium failed (attempt ${attempt}/3), retrying in 15 seconds..."
        sleep 15
    done

    return 1
}

can_launch_browser() {
    node -e "require('@playwright/test').chromium.launch().then(browser => browser.close())"
}

install_system_dependencies() {
    echo 'Acquire::Retries "3"; Acquire::http::Timeout "30"; Acquire::https::Timeout "30";' \
        | sudo tee /etc/apt/apt.conf.d/99-playwright-timeouts > /dev/null
    npx playwright install-deps chromium
}

download_browser

if can_launch_browser; then
    echo "Chromium launches with the libraries already present on the runner."
    exit 0
fi

echo "Chromium could not launch, falling back to installing system dependencies..."
install_system_dependencies
can_launch_browser
