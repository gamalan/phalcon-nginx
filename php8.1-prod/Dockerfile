#
# Dockerfile for phalconphp/php-apache:ubuntu-16.04
#
# https://github.com/phalcon/dockerfiles
#

FROM webdevops/php-nginx:8.1

LABEL maintainer="Gamal Abdul Nasser <gamalanpro@gmail.com>"

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
    && apt-get install -y libpq-dev libpq5 libpspell-dev librecode-dev libtidy-dev libssh2-1-dev libyaml-dev libopendkim-dev \
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
    && docker-php-ext-configure tidy \
    && docker-php-ext-install tidy 

RUN pecl install igbinary \
    && echo "extension=igbinary.so" > /usr/local/etc/php/conf.d/igbinary.ini \
    && pecl install mcrypt-1.0.6 \
    && echo "extension=mcrypt.so" > /usr/local/etc/php/conf.d/mcrypt.ini \
    && pecl install msgpack \
    && echo "extension=msgpack.so" > /usr/local/etc/php/conf.d/msgpack.ini \
    && pecl install yaml \
    && echo "extension=yaml.so" > /usr/local/etc/php/conf.d/yaml.ini

RUN pear channel-update pear.php.net \
    && pear install Net_SMTP Net_Socket Mail_MIME Net_Sieve Auth_SASL Crypt_GPG Net_LDAP2 \
    && pear install channel://pear.php.net/Net_IDNA2-0.2.0

RUN apt-get update \ 
    && apt-get install -y dirmngr --install-recommends \
    && wget https://phar.io/releases/phive.phar \
    && wget https://phar.io/releases/phive.phar.asc \
    && chmod +x phive.phar \
    && mv phive.phar /usr/bin/phive 

RUN curl -sOL https://squizlabs.github.io/PHP_CodeSniffer/phpcs.phar \
    && chmod +x phpcs.phar \
    && mv phpcs.phar /usr/local/bin/phpcs \ 
    && curl -sOL https://squizlabs.github.io/PHP_CodeSniffer/phpcbf.phar \
    && chmod +x phpcbf.phar \
    && mv phpcbf.phar /usr/local/bin/phpcbf \ 
    && curl -sOL https://github.com/phpmd/phpmd/releases/download/2.6.1/phpmd.phar \
    && chmod +x phpmd.phar \
    && mv phpmd.phar /usr/local/bin/phpmd \ 
    && curl -sOL http://www.phing.info/get/phing-latest.phar \
    && chmod +x phing-latest.phar \
    && mv phing-latest.phar /usr/local/bin/phing \
    && mkdir $COMPOSER_HOME \
    && curl -sSL https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && chmod +x /usr/local/bin/composer

RUN php -m \
    && echo "apc.enable_cli = 1" >> /usr/local/etc/php/conf.d/apcu.ini \
    && sed -ri 's/DEFAULT@SECLEVEL=2/DEFAULT@SECLEVEL=1/g' /etc/ssl/openssl.cnf 

ENV PROVISION_CONTEXT "production"

# Deploy scripts/configurations
COPY bin/*.sh /opt/docker/provision/entrypoint.d/

RUN mkdir -p /vendor \
    && composer --working-dir=/vendor require robmorgan/phinx:0.12.12  \
    && ln -s /vendor/vendor/robmorgan/phinx/bin/phinx /usr/local/bin/phinx \
    && chmod ugo+x /usr/local/bin/phinx \
    && composer --working-dir=/vendor require symfony/yaml  \
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
    /opt/ssh2.tgz \
    /opt/docker/etc/php/fpm/pool.d/www.conf

USER application

RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.39.7/install.sh | bash \
    && export NVM_DIR="$HOME/.nvm" \
    && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" \
    && [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" \
    && nvm install stable

USER root

EXPOSE 80 443 9000
