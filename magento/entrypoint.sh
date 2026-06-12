#!/bin/bash

# Comes from the parent image, starts supervisord (mysql, elasticsearch, php-fpm,
# nginx, and optionally varnish when ENABLE_VARNISH=true). When ENABLE_VARNISH=true
# the parent image's start-services switches nginx from port 80 to 8080 so Varnish
# can front it on 80.
./start-services

# Config changes are written straight to core_config_data so we only pay the
# Magento bootstrap cost once (a single cache:flush at the end).
need_flush=0
need_reindex=0

if [ "$ENABLE_VARNISH" = "true" ]; then
  mysql -u root magento -e "\
INSERT INTO core_config_data (scope, scope_id, path, value) VALUES \
  ('default', 0, 'system/full_page_cache/caching_application', '2') \
ON DUPLICATE KEY UPDATE value = VALUES(value);"
  need_flush=1
fi

if [ -n "$URL" ]; then
  url_sql="${URL//\'/\'\'}"
  mysql -u root magento -e "\
INSERT INTO core_config_data (scope, scope_id, path, value) VALUES \
  ('default', 0, 'web/unsecure/base_url',      '$url_sql'), \
  ('default', 0, 'web/secure/base_url',        '$url_sql'), \
  ('default', 0, 'web/unsecure/base_link_url', '$url_sql'), \
  ('default', 0, 'web/secure/base_link_url',   '$url_sql') \
ON DUPLICATE KEY UPDATE value = VALUES(value);"
  need_flush=1
fi

# Allow to set the commands in an environment variable
if [[ ! -z "${CUSTOM_ENTRYPOINT_COMMAND}" ]]; then
  echo "${CUSTOM_ENTRYPOINT_COMMAND}" > custom-entrypoint.sh
fi

if [ -f custom-entrypoint.sh ]; then
  bash ./custom-entrypoint.sh
fi

if [ "$FLAT_TABLES" = "true" ]; then
  echo "Enabling Flat Tables"
  mysql -u root magento -e "\
INSERT INTO core_config_data (scope, scope_id, path, value) VALUES \
  ('default', 0, 'catalog/frontend/flat_catalog_category', '1'), \
  ('default', 0, 'catalog/frontend/flat_catalog_product',  '1') \
ON DUPLICATE KEY UPDATE value = VALUES(value);"
  need_flush=1
  need_reindex=1
fi

# Matches only the enabled state so the disable is skipped when it was already
# applied at build time.
if [ "$DISABLE_2FA" = "true" ] && grep -q "'Magento_TwoFactorAuth' => 1" "app/etc/config.php"; then
  echo "Disabling Two Factor Authentication"
  php bin/magento module:disable Magento_TwoFactorAuth -f
fi

if [ "$need_flush" = "1" ]; then
  php bin/magento cache:flush
fi

if [ "$need_reindex" = "1" ]; then
  php bin/magento indexer:reindex
fi

while sleep 5; do
  ps aux |grep elasticsearch |grep -q -v grep
  ELASTICSEARCH_STATUS=$?
  ps aux |grep mysqld_safe |grep -q -v grep
  MYSQL_STATUS=$?
  ps aux |grep php |grep -q -v grep
  PHP_STATUS=$?

  if [ $ELASTICSEARCH_STATUS -ne 0 -o $MYSQL_STATUS -ne 0 -o $PHP_STATUS -ne 0 ]; then
    echo "One of the processes has already exited."
    exit 1
  fi

  if [ "$ENABLE_VARNISH" = "true" ]; then
    ps aux |grep varnishd |grep -q -v grep
    VARNISH_STATUS=$?
    if [ $VARNISH_STATUS -ne 0 ]; then
      echo "Varnish has exited."
      exit 1
    fi
  fi
done
