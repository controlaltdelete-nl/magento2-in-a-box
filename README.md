# Magento 2 in-a-box

Do you quickly need a up & running Magento environment for testing? That is exactly what this repository is about. Run a full pre-installed Magento 2/Mage-OS environment with a single command:

**Magento 2:**
```
docker run -d --rm \
    --name=magento \
    -p 1234:80 \
    -e URL=http://localhost:1234/ \
    michielgerritsen/magento-project-community-edition:php84-fpm-magento2.4.8
```

**Mage-OS:**
```
docker run -d --rm \
    --name=mage-os \
    -p 1234:80 \
    -e URL=http://localhost:1234/ \
    michielgerritsen/mage-os-community-edition:php84-fpm-mage-os2.0.0
```

Run the command, wait a moment, and then you can access Magento/Mage-OS on this URL:

```
http://localhost:1234/
http://localhost:1234/admin

Username: exampleuser
Password: examplepassword123
```

Two-factor authentication is disabled by default. You can choose between a bunch of PHP and Magento versions. The the [version matrix](#version-matrix) for all options. Each combination is built with and without Sample Data. Add `-sample-data` to the tag to include it.

## Usage

### Docker CLI

**Magento 2**
```
docker run -d --rm \
    --name=magento \
    -p 1234:80 \
    -e URL=http://localhost:1234/ \
    michielgerritsen/magento-project-community-edition:php84-fpm-magento2.4.8
```

**Mage-OS**
```
docker run -d --rm \
    --name=mage-os \
    -p 1234:80 \
    -e URL=http://localhost:1234/ \
    michielgerritsen/mage-os-community-edition:php84-fpm-mage-os2.0.0
```

### Docker Compose

**Magento 2**
```
version: '3'
services:
  magento:
    container_name: magento
    image: michielgerritsen/magento-project-community-edition:php83-fpm-magento2.4.7-p4
    ports:
      - 1234:80
    environment:
      - URL=http://localhost:1234/
```

**Mage-OS**
```
version: '3'
services:
  mage-os:
    container_name: mage-os
    image: michielgerritsen/mage-os-community-edition:php84-fpm-mage-os2.0.0
    ports:
      - 1234:80
    environment:
      - URL=http://localhost:1234/
```

## Parameters

These are all optional and only required when you want to run the container to access the web interface.

| Parameter | Info  |
| --- | --- |
| `-p 1234:80` | Make the webserver available at port 1234. Optional if you do not need to visit Magento in the browser. |
| `-p 3307:3306` | Make the MySQL database available at port 3307. Optional if you do not need to access the database. |
| `-e URL=http://localhost:1234/` | Should match the port mapped to port 80 |
| `-e FLAT_TABLES=false` | Enable the flat tables on startup? |
| `-e ENABLE_VARNISH=false` | Enable Varnish full page cache on startup? When enabled, Varnish listens on port 80 and the PHP server moves to port 8080. |

## Commands

There are a few special command that you can run. 

> Note: you need to have the container started before running any of these commands.

| Info                              | Magento 2 Command                                           | Mage-OS Command                                             |
|-----------------------------------|-------------------------------------------------------------|-------------------------------------------------------------|
| bin/magento                       | `docker exec magento bin/magento <your:command:is:my:wish>` | `docker exec mage-os bin/magento <your:command:is:my:wish>` |
| magerun2                          | `docker exec magento magerun2 <your:command:is:my:wish>`    | `docker exec mage-os magerun2 <your:command:is:my:wish>`    |
| Change the base URL               | `docker exec magento ./change-base-url <domain-name>`       | `docker exec mage-os ./change-base-url <domain-name>`       | 
| Disable two-factor authentication | `docker exec magento ./disable-2fa`                         | `docker exec mage-os ./disable-2fa`                         | 

### GitHub Actions

In the examples folder you can find 2 examples for integration and unit tests. View the [`readme.md`](examples/github) to see how you can start with this in your own project (hint: copy 2 files, add the composer name of your package, and you are good to go).

## Image tags

Every build is published under a fully qualified tag, for example `php85-fpm-magento2.4.9` or `php85-fpm-mage-os3.4.0-sample-data`. On top of that there are two floating tags that always point at the newest tested release on the default PHP version:

| Tag                  | Points at                       |
|----------------------|---------------------------------|
| `latest`             | Newest release, no sample data  |
| `latest-sample-data` | Newest release, with sample data |

```bash
docker pull ghcr.io/controlaltdelete-nl/magento2-in-a-box/magento-project-community-edition:latest
docker pull ghcr.io/controlaltdelete-nl/magento2-in-a-box/mage-os-community-edition:latest
```

Pin a specific tag if you need a reproducible build; `latest` moves when a new Magento or Mage-OS release is added. The `latest` tags are only published to GitHub Container Registry, not to the deprecated Docker Hub images.

## Version matrix

View [Mage-OS versions](#mage-os-versions) below.

| Magento version | PHP 8.4 | PHP 8.3 | PHP 8.2 | PHP 8.1 | PHP 7.4 | PHP 7.3 | PHP 7.2 |
|-----------------|---------|---------|---------|---------|---------|---------|---------|
| 2.4.8-p4        | x       | x       | -       | -       | -       | -       | -       |
| 2.4.8-p3        | x       | x       | -       | -       | -       | -       | -       |
| 2.4.8-p2        | x       | x       | -       | -       | -       | -       | -       |
| 2.4.8-p1        | x       | x       | -       | -       | -       | -       | -       |
| 2.4.8           | x       | x       | -       | -       | -       | -       | -       |
| 2.4.7-p9        | -       | x       | x       | -       | -       | -       | -       |
| 2.4.7-p8        | -       | x       | x       | -       | -       | -       | -       |
| 2.4.7-p7        | -       | x       | x       | -       | -       | -       | -       |
| 2.4.7-p6        | -       | x       | x       | -       | -       | -       | -       |
| 2.4.7-p5        | -       | x       | x       | -       | -       | -       | -       |
| 2.4.7-p4        | -       | x       | x       | -       | -       | -       | -       |
| 2.4.7-p3        | -       | x       | x       | -       | -       | -       | -       |
| 2.4.7-p2        | -       | x       | x       | -       | -       | -       | -       |
| 2.4.7-p1        | -       | x       | x       | -       | -       | -       | -       |
| 2.4.7           | -       | x       | x       | -       | -       | -       | -       |
| 2.4.6-p14       | -       | -       | x       | x       | -       | -       | -       |
| 2.4.6-p13       | -       | -       | x       | x       | -       | -       | -       |
| 2.4.6-p12       | -       | -       | x       | x       | -       | -       | -       |
| 2.4.6-p11       | -       | -       | x       | x       | -       | -       | -       |
| 2.4.6-p10       | -       | -       | x       | x       | -       | -       | -       |
| 2.4.6-p9        | -       | -       | x       | x       | -       | -       | -       |
| 2.4.6-p8        | -       | -       | x       | x       | -       | -       | -       |
| 2.4.6-p7        | -       | -       | x       | x       | -       | -       | -       |
| 2.4.6-p6        | -       | -       | x       | x       | -       | -       | -       |
| 2.4.6-p5        | -       | -       | x       | x       | -       | -       | -       |
| 2.4.6-p4        | -       | -       | x       | x       | -       | -       | -       |
| 2.4.6-p3        | -       | -       | x       | x       | -       | -       | -       |
| 2.4.6-p2        | -       | -       | -       | -       | -       | -       | -       |
| 2.4.6-p1        | -       | -       | x       | x       | -       | -       | -       |
| 2.4.6           | -       | -       | x       | x       | -       | -       | -       |
| 2.4.5-p14       | -       | -       | -       | x       | -       | -       | -       |
| 2.4.5-p13       | -       | -       | -       | x       | -       | -       | -       |
| 2.4.5-p12       | -       | -       | -       | x       | -       | -       | -       |
| 2.4.5-p11       | -       | -       | -       | x       | -       | -       | -       |
| 2.4.5-p10       | -       | -       | -       | x       | -       | -       | -       |
| 2.4.5-p9        | -       | -       | -       | x       | -       | -       | -       |
| 2.4.5-p8        | -       | -       | -       | x       | -       | -       | -       |
| 2.4.5-p7        | -       | -       | -       | x       | -       | -       | -       |
| 2.4.5-p6        | -       | -       | -       | x       | -       | -       | -       |
| 2.4.5-p5        | -       | -       | -       | x       | -       | -       | -       |
| 2.4.5-p4        | -       | -       | -       | x       | -       | -       | -       |
| 2.4.5-p3        | -       | -       | -       | x       | -       | -       | -       |
| 2.4.5-p2        | -       | -       | -       | x       | -       | -       | -       |
| 2.4.5-p1        | -       | -       | -       | x       | -       | -       | -       |
| 2.4.5           | -       | -       | -       | x       | -       | -       | -       |
| 2.4.4-p13       | -       | -       | -       | -       | x       | -       | -       |
| 2.4.4-p12       | -       | -       | -       | -       | x       | -       | -       |
| 2.4.4-p11       | -       | -       | -       | -       | x       | -       | -       |
| 2.4.4-p10       | -       | -       | -       | -       | x       | -       | -       |
| 2.4.4-p9        | -       | -       | -       | -       | x       | -       | -       |
| 2.4.4-p8        | -       | -       | -       | -       | x       | -       | -       |
| 2.4.4-p7        | -       | -       | -       | -       | x       | -       | -       |
| 2.4.4-p6        | -       | -       | -       | -       | x       | -       | -       |
| 2.4.4-p5        | -       | -       | -       | -       | x       | -       | -       |
| 2.4.4-p4        | -       | -       | -       | -       | x       | -       | -       |
| 2.4.4-p3        | -       | -       | -       | -       | x       | -       | -       |
| 2.4.4-p2        | -       | -       | -       | -       | x       | -       | -       |
| 2.4.4-p1        | -       | -       | -       | -       | x       | -       | -       |
| 2.4.4           | -       | -       | -       | -       | x       | -       | -       |
| 2.4.3-p2        | -       | -       | -       | -       | x       | -       | -       |
| 2.4.3-p1        | -       | -       | -       | -       | x       | x       | -       |
| 2.4.3           | -       | -       | -       | -       | x       | x       | -       |
| 2.4.2-p2        | -       | -       | -       | -       | x       | x       | -       |
| 2.4.2-p1        | -       | -       | -       | -       | x       | x       | -       |
| 2.4.2           | -       | -       | -       | -       | x       | x       | -       |
| 2.4.1-p1        | -       | -       | -       | -       | x       | x       | -       |
| 2.4.1           | -       | -       | -       | -       | x       | x       | -       |
| 2.4.0-p1        | -       | -       | -       | -       | x       | x       | -       |
| 2.4.0           | -       | -       | -       | -       | x       | x       | -       |
| 2.3.7-p4        | -       | -       | -       | -       | x       | x       | -       |
| 2.3.7-p3        | -       | -       | -       | -       | x       | x       | -       |
| 2.3.7-p2        | -       | -       | -       | -       | x       | x       | -       |
| 2.3.7-p1        | -       | -       | -       | -       | x       | x       | -       |
| 2.3.7           | -       | -       | -       | -       | x       | x       | -       |
| 2.3.6-p1        | -       | -       | -       | -       | -       | x       | x       |
| 2.3.6           | -       | -       | -       | -       | -       | x       | x       |
| 2.3.5-p2        | -       | -       | -       | -       | -       | x       | x       |
| 2.3.5-p1        | -       | -       | -       | -       | -       | x       | x       |
| 2.3.4           | -       | -       | -       | -       | -       | x       | x       |
| 2.3.3           | -       | -       | -       | -       | -       | x       | x       |
| 2.3.2           | -       | -       | -       | -       | -       | -       | x       |
| 2.3.1           | -       | -       | -       | -       | -       | -       | x       |
| 2.3.0           | -       | -       | -       | -       | -       | -       | x       |


# Mage-OS Versions
| Mage-OS Version | PHP 8.5 | PHP 8.4 | PHP 8.3 | PHP 8.2 |
|-----------------|---------|---------|---------|---------|
| 3.4.0           | x       | x       | -       | -       |
| 3.3.0           | x       | x       | -       | -       |
| 3.2.0           | x       | x       | -       | -       |
| 3.1.0           | x       | x       | -       | -       |
| 3.0.0           | x       | x       | -       | -       |
| 2.3.0           | -       | x       | x       | -       |
| 2.2.2           | -       | x       | x       | -       |
| 2.2.1           | -       | x       | x       | -       |
| 2.2.0           | -       | x       | x       | -       |
| 2.1.0           | -       | x       | x       | -       |
| 2.0.0           | -       | x       | x       | -       |
| 1.3.1           | -       | -       | x       | -       |
| 1.3.0           | -       | -       | x       | -       |
| 1.2.0           | -       | -       | x       | -       |
| 1.1.1           | -       | -       | x       | -       |
| 1.1.0           | -       | -       | x       | -       |
| 1.0.6           | -       | -       | x       | -       |
| 1.0.5           | -       | -       | x       | -       |
| 1.0.4           | -       | -       | x       | -       |
| 1.0.3           | -       | -       | x       | -       |
| 1.0.2           | -       | -       | x       | -       |
| 1.0.1           | -       | -       | -       | x       |
| 1.0.0           | -       | -       | -       | x       |
