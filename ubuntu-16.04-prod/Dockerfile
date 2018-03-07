#
# Dockerfile for phalconphp/php-apache:ubuntu-16.04
#
# https://github.com/phalcon/dockerfiles
#

FROM webdevops/php-nginx:ubuntu-16.04

LABEL maintainer="Gamal Abdul Nasser <gamalanpro@gmail.com>"

COPY artifacts /artifacts

ENV PATH=/root/composer/vendor/bin:$PATH \
    COMPOSER_HOME=/root/composer \
    COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_HOME=/root/composer \
    APPLICATION_PATH="/project" \
    DEBIAN_FRONTEND=noninteractive

RUN mkdir -p $APPLICATION_PATH/public \
    && chown -R $APPLICATION_USER:$APPLICATION_GROUP $APPLICATION_PATH \
    && apt-add-repository ppa:ondrej/apache2 \
    && LANG=C.UTF-8 apt-add-repository -y ppa:ondrej/php \
    && echo "#!/bin/sh\nexit 0" > /usr/sbin/policy-rc.d \
    && chmod +x /usr/sbin/policy-rc.d \
    && apt-get update -y

RUN apt-get -o Dpkg::Options::="--force-confnew" install -y -f --no-install-recommends \
        php7.0-apcu \
        php-apcu-bc \
        php7.0-dev \
        php7.0-dba \
        php7.0-gmp \
        php-igbinary \
        php7.0-imagick \
        php7.0-imap \
        php-sodium \
        php-memcache \
        php7.0-mongodb \
        php7.0-msgpack \
        php-pear \
        php7.0-odbc \
        php7.0-pgsql \
        php7.0-pspell \
        php7.0-recode \
        php-ssh2 \
        php7.0-tidy \
        php-yaml \
        lsb-release \
        libssh2-1-dev \
        libyaml-dev \
        libssl-dev

RUN wget https://phar.io/releases/phive.phar \
    && wget https://phar.io/releases/phive.phar.asc \
    && gpg --keyserver hkps.pool.sks-keyservers.net --recv-keys 0x9B2D5D79 \
    && gpg --verify phive.phar.asc phive.phar \
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

RUN cp -R /artifacts/etc/php/7.0/mods-available/*.ini /etc/php/7.0/mods-available \
    && cp -R /artifacts/usr/lib/php/20151012/*.so /usr/lib/php/`php-config --phpapi` \
    && for f in `ls /artifacts/etc/php/7.0/mods-available`; \
        do \
            phpenmod -v 7.0 -s ALL `basename $f | cut -d '.' -f 1`; \
        done \
    && php -m

RUN TIMEZONE=`cat /etc/timezone`; sed -i "s|;date.timezone =.*|date.timezone = ${TIMEZONE}|" /etc/php/7.0/cli/php.ini \
    && TIMEZONE=`cat /etc/timezone`; sed -i "s|;date.timezone =.*|date.timezone = ${TIMEZONE}|" /etc/php/7.0/fpm/php.ini \
    && sed -i "s|memory_limit =.*|memory_limit = -1|" /etc/php/7.0/cli/php.ini \
    && sed -i 's|short_open_tag =.*|short_open_tag = On|' /etc/php/7.0/cli/php.ini \
    && sed -i 's|display_errors =.*|display_errors = Off|' /etc/php/7.0/cli/php.ini \
    && sed -i 's|display_startup_errors =.*|display_startup_errors = Off|' /etc/php/7.0/cli/php.ini \
    && sed -i -re 's|^(;?)(session.save_path) =.*|\2 = "/tmp"|g' /etc/php/7.0/cli/php.ini \
    && sed -i -re 's|^(;?)(phar.readonly) =.*|\2 = off|g' /etc/php/7.0/cli/php.ini \
    && echo "apc.enable_cli = 1" >> /etc/php/7.0/mods-available/apcu.ini

ENV PROVISION_CONTEXT "production"

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

RUN apt-get update && apt-get install nano vim htop telnet traceroute dnsutils iputils-ping bash-completion tmux -y && apt-get clean -y

RUN apt-get autoremove -y \
    && apt-get autoclean -y \
    && apt-get clean -y \
    && rm -rf \
        /var/lib/apt/lists/* \
        /tmp/* \
        /var/tmp/* \
        /artifacts \
        /opt/docker/etc/php/fpm/pool.d/www.conf

EXPOSE 80 443 9000
