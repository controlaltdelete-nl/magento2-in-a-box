<?php
/**
 * Copyright © Magento, Inc. All rights reserved.
 * See COPYING.txt for license details.
 */

// The integration test framework runs its own setup:install in a sandbox with
// no config.php, so every module defaults to enabled (createModulesConfig in
// Magento\Setup\Model\Installer). To stay consistent with the image's
// build-time module state — in particular the 2FA disable — mirror whatever
// is marked disabled in app/etc/config.php into --disable-modules.
$appConfigFile = __DIR__ . '/../../../../app/etc/config.php';
$modules = [];
if (is_file($appConfigFile)) {
    $loaded = include $appConfigFile;
    if (is_array($loaded) && isset($loaded['modules']) && is_array($loaded['modules'])) {
        $modules = $loaded['modules'];
    }
}

$disableCandidates = ['Magento_TwoFactorAuth', 'Magento_AdminAdobeImsTwoFactorAuth'];
$toDisable = array_values(array_filter(
    $disableCandidates,
    static fn(string $name): bool => isset($modules[$name]) && !$modules[$name]
));

// Sample data modules are irrelevant for integration tests and pull in extra
// data fixtures that slow the sandbox install down.
foreach ($modules as $name => $_enabled) {
    if (substr($name, -10) === 'SampleData') {
        $toDisable[] = $name;
    }
}

$params = [
    'db-host' => '127.0.0.1',
    'db-user' => 'magento-test',
    'db-password' => 'password',
    'db-name' => 'magento-test',
    'db-prefix' => '',
    'backend-frontname' => 'backend',
    'admin-user' => \Magento\TestFramework\Bootstrap::ADMIN_NAME,
    'admin-password' => \Magento\TestFramework\Bootstrap::ADMIN_PASSWORD,
    'admin-email' => \Magento\TestFramework\Bootstrap::ADMIN_EMAIL,
    'admin-firstname' => \Magento\TestFramework\Bootstrap::ADMIN_FIRSTNAME,
    'admin-lastname' => \Magento\TestFramework\Bootstrap::ADMIN_LASTNAME,
];

if ($toDisable) {
    $params['disable-modules'] = implode(',', $toDisable);
}

return $params;
