ARG PHP_VERSION=php74-fpm
FROM michielgerritsen/magento2-base-image:${PHP_VERSION}

ARG MAGEOS_VERSION=1.0.0
ARG MAGEOS_TYPE=project-community-edition
ARG SAMPLE_DATA=false
ARG DISABLE_2FA=true

ENV CI=true
ENV URL=http://localhost/
ENV FLAT_TABLES=false
ENV COMPOSER_ALLOW_SUPERUSER=1

COPY scripts/retry retry
COPY scripts/allow-composer-plugins.php scripts/allow-composer-plugins.php
COPY templates/memory-limit-php.ini /usr/local/etc/php/conf.d/memory-limit-php.ini

RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs

RUN set -e; \
    ./start-services && \
    composer self-update --2 && \
    echo "[cad] Composer version:" && \
    composer --version && \
    echo "[cad] Downloading & unzipping Magento" && \
    composer create-project --repository-url=https://repo.mage-os.org/ mage-os/project-community-edition:"$MAGEOS_VERSION" /tmp/mage-os --no-install && \
    (cd /tmp/mage-os && COMPOSER_NO_SECURITY_BLOCKING=1 composer update --no-security-blocking) && \
    rsync -a /tmp/mage-os/ /data/ && \
    echo "[cad] Allowing composer plugins" && \
    php scripts/allow-composer-plugins.php && \
    rm scripts/allow-composer-plugins.php && \
    echo "[cad] Updating XML" && \
    if [ -f "/data/vendor/magento/module-inventory-catalog/etc/communication.xml" ]; then sed -i 's/is_synchronous="false"//g' /data/vendor/magento/module-inventory-catalog/etc/communication.xml; fi && \
    if [ -f "/data/vendor/magento/module-inventory-sales/etc/communication.xml" ]; then sed -i 's/is_synchronous="false"//g' /data/vendor/magento/module-inventory-sales/etc/communication.xml; fi && \
    if [ -f "/data/vendor/magento/module-inventory-indexer/etc/communication.xml" ]; then sed -i 's/is_synchronous="false"//g' /data/vendor/magento/module-inventory-indexer/etc/communication.xml; fi && \
    composer dump-autoload && \
    echo "[cad] Running Magento setup:install" && \
    php bin/magento setup:install --backend-frontname=admin --session-save=db --db-host=127.0.0.1 --db-name=magento --db-user=magento --db-password=password --base-url=http://localhost --timezone=Europe/Amsterdam --currency=EUR --admin-user=exampleuser --admin-password=examplepassword123 --admin-email=user@example.com --admin-firstname=Example --admin-lastname=Example --use-rewrites=1 --use-sample-data && \
    echo "[cad] Setting developer mode" && \
    php bin/magento deploy:mode:set developer && \
    if [ "${SAMPLE_DATA}" = "true" ] && [ "$MAGEOS_VERSION" != "alpha2" ]; then echo "[cad] Running php bin/magento sampledata:deploy"; php bin/magento sampledata:deploy; fi && \
    if [ "${SAMPLE_DATA}" = "true" ] && [ "$MAGEOS_VERSION" = "alpha2" ]; then echo "[cad] Installing sampledata"; composer require mage-os/module-bundle-sample-data mage-os/module-catalog-sample-data mage-os/module-sales-sample-data mage-os/module-customer-sample-data mage-os/module-cms-sample-data mage-os/module-widget-sample-data mage-os/module-theme-sample-data mage-os/module-downloadable-sample-data mage-os/module-wishlist-sample-data mage-os/module-review-sample-data mage-os/module-tax-sample-data mage-os/module-catalog-rule-sample-data mage-os/module-configurable-sample-data mage-os/module-product-links-sample-data mage-os/module-sales-rule-sample-data mage-os/module-msrp-sample-data mage-os/module-grouped-product-sample-data mage-os/module-swatches-sample-data mage-os/module-offline-shipping-sample-data magento/sample-data-media --ignore-platform-reqs; fi && \
    if [ "${SAMPLE_DATA}" = "true" ]; then echo "[cad] Running setup:upgrade" && ./retry "php bin/magento setup:upgrade"; fi && \
    php bin/magento setup:static-content:deploy en_US -f -j 12 && \
    php bin/magento setup:di:compile && \
    php bin/magento indexer:reindex && \
    mkdir -p extensions && \
    composer config repositories.dev-extensions path extensions/* && \
    composer require --dev phpstan/phpstan bitexpert/phpstan-magento phpstan/extension-installer && \
    ./stop-services

COPY templates/supervisord-webserver.conf /etc/supervisor/conf.d/webserver.conf
COPY templates/install-config-mysql.php dev/tests/integration/etc/
COPY templates/post-install-setup-command-config.php dev/tests/integration/etc/
COPY entrypoint.sh entrypoint.sh

COPY scripts/change-base-url change-base-url
COPY scripts/install-composer-package install-composer-package
COPY scripts/disable-2fa disable-2fa

RUN chmod +x change-base-url

ENTRYPOINT ["/bin/bash", "entrypoint.sh"]

EXPOSE 80 3306
