#!/usr/bin/env php
<?php
$version = getenv('MAGENTO_VERSION');
$is240 = substr($version, 0, 5) == '2.4.0';
$is241 = substr($version, 0, 5) == '2.4.1';
$is242 = substr($version, 0, 5) == '2.4.2';
$is243 = substr($version, 0, 5) == '2.4.3';
$is244 = substr($version, 0, 5) == '2.4.4';
$is245 = substr($version, 0, 5) == '2.4.5';
$is246 = substr($version, 0, 5) == '2.4.6';
$is247 = substr($version, 0, 5) == '2.4.7';
$is248 = substr($version, 0, 5) == '2.4.8';
$isP1 = substr($version, 6, 8) == 'p1';
$isP2 = substr($version, 6, 8) == 'p2';

function apply($patch) {
    echo 'Applying ' . $patch . PHP_EOL;

    $path = realpath(__DIR__ . '/../patches/' . $patch);
    if (!$path) {
        die('Path for ' . $patch . ' not found');
    }

    $output = null;
    $code = null;
    exec('git apply ' . $path, $output, $code);

    if ($code !== 0) {
        echo 'Unable to apply patch ' . $patch . PHP_EOL;
        die($code);
    }
}

function output($message) {
    echo $message . PHP_EOL;
}

function fixNginxFastcgiPass() {
    $sample = __DIR__ . '/../nginx.conf.sample';
    if (!file_exists($sample)) {
        return;
    }

    $contents = file_get_contents($sample);
    $fixed = str_replace('php-fpm:9000', 'fastcgi_backend', $contents);
    if ($fixed === $contents) {
        return;
    }

    file_put_contents($sample, $fixed);
    output('Rewrote nginx.conf.sample fastcgi_pass from php-fpm:9000 to fastcgi_backend');
}

if ($is240 || $is241 || $is242) {
    output('Found version 2.4.0 or 2.4.1 or 2.4.2');
    apply('APSB22-12/MDVA-43395_EE_2.4.3-p1_COMPOSER_v1.patch');
    apply('APSB22-12/MDVA-43443_EE_2.4.2-p2_COMPOSER_v1.patch');
}

if ($is243 && !$isP2) {
    echo 'Found version 2.4.3 and is not P2' . PHP_EOL;
    apply('APSB22-12/MDVA-43395_EE_2.4.3-p1_COMPOSER_v1.patch');
    apply('APSB22-12/MDVA-43443_EE_2.4.3-p1_COMPOSER_v1.patch');
}

if ($is243) {
    apply('33803/github-pr-33803-243.patch');
}

if ($is244) {
    apply('33803/github-pr-33803-244.patch');
}

if ($is245) {
    apply('33803/github-pr-33803-245.patch');
}

if ($is240 && !$isP1 && !$isP2) {
    apply('bundle-2684_dotmailer_integration_tests-2020-08-04-04-31-22.patch');
}

if ($is246 || $is247 || $is248) {
    exec('composer require "webonyx/graphql-php:^15.0 <15.31.0"');
}

fixNginxFastcgiPass();
