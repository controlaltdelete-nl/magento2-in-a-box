<?php
declare(strict_types=1);

const SUITES = [
    [
        'source' => 'dev/tests/integration/phpunit.xml.dist',
        'target' => 'dev/tests/integration/phpunit.xml',
        'name'   => 'Magento Integration Tests',
        'dir'    => '/data/extensions/**/Test/Integration',
    ],
    [
        'source' => 'dev/tests/unit/phpunit.xml.dist',
        'target' => 'dev/tests/unit/phpunit.xml',
        'name'   => 'Magento Unit Tests',
        'dir'    => '/data/extensions/**/Test/Unit',
    ],
];

foreach (SUITES as $suite) {
    patchPhpunitXml($suite['source'], $suite['target'], $suite['name'], $suite['dir']);
}

function patchPhpunitXml(string $source, string $target, string $suiteName, string $testDirectory): void
{
    if (!file_exists($source)) {
        echo "Skipping {$source} (not present)" . PHP_EOL;
        return;
    }

    $dom = new DOMDocument();
    $dom->preserveWhiteSpace = false;
    $dom->formatOutput = true;
    $dom->load($source);

    $xpath = new DOMXPath($dom);

    replaceTestsuites($dom, $xpath, $suiteName, $testDirectory);
    removeAllure($xpath);
    removeEmptyContainers($xpath);

    $dom->save($target);

    echo "Patched {$target}" . PHP_EOL;
}

function replaceTestsuites(DOMDocument $dom, DOMXPath $xpath, string $suiteName, string $testDirectory): void
{
    foreach ($xpath->query('//testsuites') as $node) {
        $node->parentNode->removeChild($node);
    }

    $directory = $dom->createElement('directory', $testDirectory);
    $directory->setAttribute('suffix', 'Test.php');

    $testsuite = $dom->createElement('testsuite');
    $testsuite->setAttribute('name', $suiteName);
    $testsuite->appendChild($directory);

    $testsuites = $dom->createElement('testsuites');
    $testsuites->appendChild($testsuite);

    $dom->documentElement->appendChild($testsuites);
}

function removeAllure(DOMXPath $xpath): void
{
    foreach ($xpath->query('//listener[contains(@class, "Allure")]|//extension[contains(@class, "Allure")]|//bootstrap[contains(@class, "Allure")]') as $node) {
        $node->parentNode->removeChild($node);
    }
}

function removeEmptyContainers(DOMXPath $xpath): void
{
    foreach ($xpath->query('//listeners[not(*)]|//extensions[not(*)]') as $node) {
        $node->parentNode->removeChild($node);
    }
}
