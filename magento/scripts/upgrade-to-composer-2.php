<?php

$version = getenv('MAGENTO_VERSION');
$is240 = substr($version, 0, 5) == '2.4.0';
$is241 = substr($version, 0, 5) == '2.4.1';

if ($is240 || $is241) {
    run('composer require laminas/laminas-dependency-plugin:"2.1.2 as 1.0.4" --no-update');
    run('composer require magento/inventory-composer-installer:"1.2.0 as 1.1.0" --no-update');
    run('composer require --dev dealerdirect/phpcodesniffer-composer-installer:^0.7.0 --no-update');
    return;
}

function run(string $command) {
    echo 'Running command ' . $command . PHP_EOL;

    $output = null;
    $code = null;
    exec($command, $output, $code);

    if ($code !== 0) {
        echo 'Error while running "' . $command . '"' . PHP_EOL;
        die($code);
    }
}
