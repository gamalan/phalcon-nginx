#
# Dockerfile for phalconphp/php-apache:ubuntu-16.04
#
# https://github.com/phalcon/dockerfiles
#

FROM webdevops/php-nginx:7.2

LABEL maintainer="Gamal Abdul Nasser <gamalanpro@gmail.com>"

COPY artifacts /artifacts

ENV PATH=/root/composer/vendor/bin:$PATH \
    COMPOSER_HOME=/root/composer \
    COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_HOME=/root/composer \
    APPLICATION_PATH="/project" \
    DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y apt-utils \
    && apt-get install -y unixodbc unixodbc-dev libicu-dev libgmp-dev libc-client-dev libkrb5-dev libldap2-dev libldb-dev \
    && apt-get install -y libgraphicsmagick1-dev libmagickcore-dev libmagickwand-dev libmcrypt-dev libmemcached-dev \
    && apt-get install -y libpq-dev libpq5 libpspell-dev librecode-dev libtidy-dev libssh2-1-dev libyaml-dev \
    && apt-get install -y nano vim htop telnet traceroute dnsutils iputils-ping bash-completion tmux \
    && rm -r /var/lib/apt/lists/*

RUN set -x \
    && docker-php-source extract \
    && cd /usr/src/php/ext/odbc \
    && phpize \
    && sed -ri 's@^ *test +"\$PHP_.*" *= *"no" *&& *PHP_.*=yes *$@#&@g' configure \
    && ./configure --with-unixODBC=shared,/usr \
    && docker-php-ext-install odbc

RUN docker-php-ext-configure gmp \
    && docker-php-ext-configure intl \
    && docker-php-ext-install gmp \
    && docker-php-ext-install intl \
    && docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
    && docker-php-ext-install imap \
    && docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu \
    && docker-php-ext-install ldap \
    && docker-php-ext-configure pdo_odbc --with-pdo-odbc=unixODBC,/usr \
    && docker-php-ext-install pdo_odbc \
    && docker-php-ext-configure pgsql \
    && docker-php-ext-install pgsql \ 
    && docker-php-ext-configure pdo_pgsql \
    && docker-php-ext-install pdo_pgsql \
    && docker-php-ext-configure pspell \
    && docker-php-ext-install pspell \
    && docker-php-ext-configure recode \
    && docker-php-ext-install recode \
    && docker-php-ext-configure tidy \
    && docker-php-ext-install tidy \
    && docker-php-ext-configure wddx \
    && docker-php-ext-install wddx \
    && docker-php-ext-configure xmlrpc \
    && docker-php-ext-install xmlrpc \
    && pecl install ssh2-alpha \
    && echo "extension=ssh2.so" > /usr/local/etc/php/conf.d/ssh2.ini \
    && pecl install igbinary \
    && echo "extension=igbinary.so" > /usr/local/etc/php/conf.d/igbinary.ini \
    && pecl install imagick \
    && echo "extension=imagick.so" > /usr/local/etc/php/conf.d/imagick.ini \
    && pecl install mcrypt-1.0.1 \
    && echo "extension=mcrypt.so" > /usr/local/etc/php/conf.d/mcrypt.ini \
    && pecl install memcached \
    && echo "extension=memcached.so" > /usr/local/etc/php/conf.d/memcached.ini \
    && pecl install mongodb \ 
    && echo "extension=mongodb.so" > /usr/local/etc/php/conf.d/mongodb.ini \
    && pecl install msgpack \
    && echo "extension=msgpack.so" > /usr/local/etc/php/conf.d/msgpack.ini \
    && pecl install yaml \
    && echo "extension=yaml.so" > /usr/local/etc/php/conf.d/yaml.ini \
    && pecl install apcu \
    && echo "extension=apcu.so" > /usr/local/etc/php/conf.d/apcu.ini 

RUN pecl install xdebug \
    && echo "zend_extension=/usr/local/lib/php/extensions/no-debug-non-zts-20170718/xdebug.so" > /usr/local/etc/php/conf.d/xdebug.ini

RUN apt-get update \ 
    && apt-get install dirmngr --install-recommends \
    && wget https://phar.io/releases/phive.phar \
    && wget https://phar.io/releases/phive.phar.asc \
    && chmod +x phive.phar \
    && mv phive.phar /usr/bin/phive \
    && pecl channel-update pecl.php.net \
    && curl -sOL https://squizlabs.github.io/PHP_CodeSniffer/phpcs.phar \
    && chmod +x phpcs.phar \
    && mv phpcs.phar /usr/local/bin/phpcs \
    && curl -sOL https://squizlabs.github.io/PHP_CodeSniffer/phpcbf.phar \
    && chmod +x phpcbf.phar \
    && mv phpcbf.phar /usr/local/bin/phpcbf \
    && curl -sOL http://static.phpmd.org/php/latest/phpmd.phar \
    && chmod +x phpmd.phar \
    && mv phpmd.phar /usr/local/bin/phpmd \
    && curl -sOL http://www.phing.info/get/phing-latest.phar \
    && chmod +x phing-latest.phar \
    && mv phing-latest.phar /usr/local/bin/phing \
    && mkdir $COMPOSER_HOME \
    && curl -sSL https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && chmod +x /usr/local/bin/composer

RUN cp -R /artifacts/etc/php/7.2/mods-available/*.ini /usr/local/etc/php/conf.d \
    && cp -R /artifacts/usr/lib/php/20170718/*.so `php-config --extension-dir` \
    && php -m \
    && echo "apc.enable_cli = 1" >> /usr/local/etc/php/conf.d/apcu.ini

ENV PROVISION_CONTEXT "development"

# Deploy scripts/configurations
COPY bin/*.sh /opt/docker/provision/entrypoint.d/

RUN mkdir -p /vendor \
    && composer --working-dir=/vendor require phalcon/devtools \
    && ln -s /vendor/vendor/phalcon/devtools/phalcon.php /usr/local/bin/phalcon \
    && chmod ugo+x /usr/local/bin/phalcon \
    && composer --working-dir=/vendor require robmorgan/phinx  \
    && ln -s /vendor/vendor/robmorgan/phinx/bin/phinx /usr/local/bin/phinx \
    && chmod ugo+x /usr/local/bin/phinx \
    # Custom provisions
    && chmod +x /opt/docker/provision/entrypoint.d/*.sh

RUN apt-get autoremove -y \
    && apt-get autoclean -y \
    && apt-get clean -y \
    && docker-php-source delete \
    && rm -rf \
    /var/lib/apt/lists/* \
    /tmp/* \
    /var/tmp/* \
    /artifacts \
    /opt/docker/etc/php/fpm/pool.d/www.conf

EXPOSE 80 443 9000
