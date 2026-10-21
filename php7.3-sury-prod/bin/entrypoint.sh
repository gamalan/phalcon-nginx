#!/usr/bin/env bash
set -euo pipefail

# Parity with old image: php-fpm pool + nginx workers run as `application`.
# Override at runtime for host-volume ownership, e.g.
#   -e APPLICATION_UID=$(id -u) -e APPLICATION_GID=$(id -g)
APP_USER="${APPLICATION_USER:-application}"
APP_UID="${APPLICATION_UID:-1000}"
APP_GID="${APPLICATION_GID:-1000}"
APP_PATH="${APPLICATION_PATH:-/app}"

if [ "$(id -u "$APP_USER")" != "$APP_UID" ]; then
  usermod -u "$APP_UID" "$APP_USER"
fi
if [ "$(id -g "$APP_USER")" != "$APP_GID" ]; then
  groupmod -g "$APP_GID" "$APP_USER"
fi

sed -ri "s/^(user|group) = .*/\1 = $APP_USER/" /etc/php/7.3/fpm/pool.d/www.conf
sed -ri "s/^user .*/user $APP_USER;/" /etc/nginx/nginx.conf

mkdir -p "$APP_PATH"
chown "$APP_USER:$APP_USER" "$APP_PATH" /run/php 2>/dev/null || true

php -v
if php --ri phalcon > /dev/null 2>&1; then
  php --ri phalcon 2>/dev/null | head -n 6 || true
else
  echo "WARNING: phalcon extension not loaded"
fi

exec "$@"
