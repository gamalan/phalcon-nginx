# PHP 7.3 (Sury) + Phalcon 3.4 + nginx on Debian Bookworm
#
# Rebuild of gamalan/phalcon-nginx:php7.3-prod-phalcon34 (Debian 10/Buster,
# PHP 7.3.33 built Mar 2022, nginx 1.22, Phalcon 3.4.5) using the still-maintained
# Ondrej Sury packages (packages.sury.org/php), which as of 2026-10-21 publish
# PHP 7.3.33-35 for debian11/bullseye, debian12/bookworm and debian13/trixie.
#
# Why bookworm and not bullseye/buster?
#   - Buster (the old image's base) is EOL and was removed from Sury (403).
#   - Bullseye left LTS in Aug 2026, so its security mirror 404s on fresh builds.
#   - Bookworm is stable until ~2028 and Sury still publishes php7.3 here
#     (7.3.33-35+0~20261021.144+debian12, seen 2026-10-21).
#   - Sury's php7.3 builds are patched for OpenSSL 3; Phalcon 3.4.5 itself
#     only uses PHP-level crypto APIs, so it compiles cleanly.

FROM debian:bookworm-slim

LABEL maintainer="Gamal Abdul Nasser <gamalanpro@gmail.com>"
LABEL php.version="7.3" \
      php.origin="deb.sury.org" \
      phalcon.version="3.4.5" \
      base="debian:bookworm-slim"

ENV DEBIAN_FRONTEND=noninteractive \
    APPLICATION_PATH="/app" \
    COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_HOME=/root/composer \
    PATH=/root/composer/vendor/bin:$PATH

# ---------------------------------------------------------------- Sury repo --
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates curl wget gnupg lsb-release apt-transport-https; \
    curl -fsSL https://packages.sury.org/php/apt.gpg -o /usr/share/keyrings/deb-sury-php.gpg; \
    echo "deb [signed-by=/usr/share/keyrings/deb-sury-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" \
        > /etc/apt/sources.list.d/php-sury.list; \
    apt-get update; \
    rm -rf /var/lib/apt/lists/*

# ------------------------------------------------- PHP 7.3 + nginx + tools --
# Extension mapping vs. old image (php -m):
#   covered by apt below: apcu bcmath bz2 calendar ctype curl date dom exif
#     fileinfo filter ftp gd gettext gmp hash iconv igbinary imagick imap intl
#     json ldap libxml mbstring mcrypt memcached mongodb msgpack mysqli mysqlnd
#     odbc openssl pcntl pcre PDO pdo_mysql pdo_pgsql pdo_sqlite pgsql phar
#     posix readline session shmop SimpleXML soap sockets SPL sqlite3
#     standard sysvmsg sysvsem sysvshm tidy tokenizer xml xmlreader xmlwriter
#     xsl yaml Zend OPcache zip zlib
#   compiled from source below: phalcon 3.4.5 + zephir_parser (1.7.0) +
#     phpredis 5.3.7 (pecl redis-5.3.7; Sury only ships 6.0.2 for php7.3)
#   verified against kirimemail-appmain (2026-10-21), intentionally dropped:
#     xmlrpc (0 usages — NOT required), aerospike (0 usages), handlersocketi,
#     pinba, weakref, vips, ionCube Loader, ssh2, recode/wddx (removed upstream),
#     sodium (Sury ships no php7.3-sodium for bookworm; 0 usages in app).
#   dba kept (harmless; app hits are dbAdapter false positives, no dba_* calls).
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        nginx \
        supervisor \
        php7.3-fpm php7.3-cli php7.3-common \
        php7.3-apcu php7.3-bcmath php7.3-bz2 php7.3-curl php7.3-dba \
        php7.3-gd php7.3-gettext php7.3-gmp php7.3-igbinary \
        php7.3-imagick php7.3-imap php7.3-intl php7.3-json \
        php7.3-ldap php7.3-mbstring php7.3-mcrypt php7.3-memcached \
        php7.3-mongodb php7.3-msgpack php7.3-mysql php7.3-odbc \
        php7.3-opcache php7.3-pgsql php7.3-pspell php7.3-readline \
        php7.3-soap php7.3-sqlite3 php7.3-tidy \
        php7.3-xml php7.3-xsl php7.3-yaml php7.3-zip \
        php7.3-dev php-pear pkg-config git unzip zip nano vim htop \
        libpcre3-dev re2c autoconf automake libtool make g++ \
        libssl-dev zlib1g-dev libmemcached-dev; \
    rm -rf /var/lib/apt/lists/*; \
    php -v; \
    php -m | sort

# ------------------------------------------------------- Zephir parser 1.7.0 --
# Phalcon 3.4 requires the zephir_parser extension at runtime.
# v1.7.0 (2022) is the last 1.x line supporting PHP 7.2-8.1.
RUN set -eux; \
    git clone --depth 1 --branch v1.7.0 \
        https://github.com/phalcon/php-zephir-parser.git /tmp/zephir-parser; \
    cd /tmp/zephir-parser; \
    phpize7.3; \
    ./configure --with-php-config=/usr/bin/php-config7.3; \
    make -j"$(nproc)"; \
    make install; \
    printf 'extension=zephir_parser.so\n' > /etc/php/7.3/mods-available/zephir_parser.ini; \
    for sapi in cli fpm; do \
        ln -sf ../../mods-available/zephir_parser.ini "/etc/php/7.3/$sapi/conf.d/15-zephir_parser.ini"; \
    done; \
    php -m | grep -i zephir; \
    rm -rf /tmp/zephir-parser

# -------------------------------------------------------------- Phalcon 3.4.5 --
# Upstream tag v3.4.5 (Nov 2019) — same version as the old image.
# Build layout for v3: cphalcon/build/php7/64bits.
RUN set -eux; \
    git clone --depth 1 --branch v3.4.5 \
        https://github.com/phalcon/cphalcon.git /tmp/cphalcon; \
    cd /tmp/cphalcon/build/php7/64bits; \
    phpize7.3; \
    ./configure --with-php-config=/usr/bin/php-config7.3; \
    make -j"$(nproc)"; \
    make install; \
    printf 'extension=phalcon.so\n' > /etc/php/7.3/mods-available/phalcon.ini; \
    # Load order matters: zephir_parser (15) BEFORE phalcon (25).
    # phpenmod would give both priority 20 (phalcon first alphabetically),
    # so link into each SAPI explicitly with ordered prefixes.
    for sapi in cli fpm; do \
        ln -sf ../../mods-available/zephir_parser.ini "/etc/php/7.3/$sapi/conf.d/15-zephir_parser.ini"; \
        ln -sf ../../mods-available/phalcon.ini "/etc/php/7.3/$sapi/conf.d/25-phalcon.ini"; \
    done; \
    php --ri phalcon | head -n 12; \
    rm -rf /tmp/cphalcon

# ------------------------------------------------- application user (parity) --
# Old image ran php-fpm + nginx workers as `application` (1000:1000).
# FPM listens on TCP 127.0.0.1:9000 to match nginx fastcgi_pass (no-502 default,
# same as old image; avoids unix-socket owner/mode mismatches entirely).
RUN set -eux; \
    groupadd -g 1000 application; \
    useradd -u 1000 -g 1000 -m -s /bin/bash application; \
    sed -ri 's/^(user|group) = .*/\1 = application/' /etc/php/7.3/fpm/pool.d/www.conf; \
    sed -ri 's|^listen = .*|listen = 127.0.0.1:9000|' /etc/php/7.3/fpm/pool.d/www.conf; \
    sed -ri 's/^user .*/user application;/' /etc/nginx/nginx.conf; \
    grep -E '^(user|group|listen)' /etc/php/7.3/fpm/pool.d/www.conf; \
    grep '^user' /etc/nginx/nginx.conf

# ---------------------------------------------------------- phpredis 5.3.7 --
# Pinned to the 5.3.7 release tarball (Sury only publishes 6.0.2 for php7.3).
# NOTE: not via `pecl install` — pecl.php.net channel metadata is flaky
# ("No releases available" despite successful channel-update). Same bits,
# zero channel dependency. Defaults (no igbinary/lzf) match Phalcon's
# default PHP serializer.
RUN set -eux; \
    curl -fsSL https://github.com/phpredis/phpredis/archive/5.3.7.tar.gz -o /tmp/phpredis.tar.gz; \
    mkdir -p /tmp/phpredis && tar -xzf /tmp/phpredis.tar.gz -C /tmp/phpredis --strip-components=1; \
    cd /tmp/phpredis; \
    phpize7.3; \
    ./configure --with-php-config=/usr/bin/php-config7.3; \
    make -j"$(nproc)"; \
    make install; \
    printf 'extension=redis.so\n' > /etc/php/7.3/mods-available/redis.ini; \
    for sapi in cli fpm; do \
        ln -sf ../../mods-available/redis.ini "/etc/php/7.3/$sapi/conf.d/20-redis.ini"; \
    done; \
    test "$(php -r 'echo phpversion("redis");')" = 5.3.7; \
    php --ri redis | head -n 5

# ------------------------------------------------------------------ Composer --
RUN set -eux; \
    mkdir -p "$COMPOSER_HOME"; \
    curl -sSL https://getcomposer.org/installer -o /tmp/composer-setup.php; \
    php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer; \
    rm -f /tmp/composer-setup.php; \
    composer --version

# -------------------------------------------------------------------- Config --
COPY nginx/default.conf /etc/nginx/sites-available/default
COPY nginx/conf.d/ /etc/nginx/conf.d/
COPY nginx/app.d/ /etc/nginx/app.d/
COPY php/opcache.ini /etc/php/7.3/mods-available/opcache-custom.ini
COPY php/extra/ /tmp/php-extra/
COPY supervisord.conf /etc/supervisor/supervisord.conf
COPY bin/entrypoint.sh /usr/local/bin/entrypoint.sh

RUN set -eux; \
    chmod +x /usr/local/bin/entrypoint.sh; \
    phpenmod -v 7.3 opcache-custom || true; \
    if ls /tmp/php-extra/*.ini >/dev/null 2>&1; then \
        for sapi in cli fpm; do cp /tmp/php-extra/*.ini /etc/php/7.3/$sapi/conf.d/; done; \
    fi; \
    # nginx runs in foreground under supervisord; php-fpm likewise
    mkdir -p /run/php /var/log/supervisor /var/cache/nginx /var/log/nginx "$APPLICATION_PATH"; \
    chown -R application:application "$APPLICATION_PATH" /var/cache/nginx /var/log/nginx /run/php; \
    php -v; \
    php -m | sort; \
    nginx -v; \
    nginx -t; \
    # drop build-only packages, keep runtime libs
    apt-get update; \
    apt-get purge -y php7.3-dev php-pear pkg-config git autoconf automake \
        libtool make g++ re2c libpcre3-dev libssl-dev zlib1g-dev libmemcached-dev; \
    apt-get autoremove -y; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /app

EXPOSE 80 443

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
