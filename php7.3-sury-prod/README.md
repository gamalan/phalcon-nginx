# php7.3-sury-prod — PHP 7.3 (Sury, latest patched) + Phalcon 3.4 + nginx

Rebuild of `gamalan/phalcon-nginx:php7.3-prod-phalcon34` on a maintained base.

## 1. What the old image contains (audited 2026-10-21)

Pulled `gamalan/phalcon-nginx:php7.3-prod-phalcon34` and inspected it:

| Layer            | Old image value |
|------------------|-----------------|
| OS               | Debian 10 (buster) — **EOL**, removed from Sury (403) |
| PHP              | **7.3.33** (cli, NTS, built Mar 18 2022) |
| PHP SAPI         | source-compiled (`/usr/local/bin/php`, no `php7.3-*` deb packages) |
| nginx            | 1.22.0, vhosts in `/opt/docker/etc/nginx/`, web root `/app` |
| Phalcon          | **3.4.5** (Nov 2019) + Zephir Parser, `phalcon.so` in `/usr/local/lib/php/extensions/no-debug-non-zts-20180731/` |
| Process model    | webdevops base: supervisord-style entrypoint scripts in `/opt/docker/provision/entrypoint.d/` |
| Composer         | 2.4.4 |
| OpenSSL          | 1.1.1n (binary) / 1.1.1d (php bindings) |
| `php -m` (~80)   | aerospike amqp apcu bcmath bz2 calendar ctype curl date dom exif fileinfo filter ftp gd gettext gmp handlersocketi igbinary imagick imap intl ionCube json ldap libxml mbstring mcrypt memcached mongodb msgpack mysqli mysqlnd odbc openssl pcntl pcre PDO pdo_mysql PDO_ODBC pdo_pgsql pdo_sqlite pgsql phalcon Phar pinba posix pspell readline recode redis session shmop SimpleXML soap sockets sodium SPL sqlite3 ssh2 standard sysvmsg sysvsem sysvshm tidy tokenizer vips wddx Weakref xml xmlreader xmlrpc xmlwriter xsl yaml OPcache Zephir Parser zip zlib |

## 2. What this image does differently

| Layer            | New image |
|------------------|-----------|
| OS               | `debian:bookworm-slim` (stable until ~2028; Sury still publishes `7.3.33-35` for bookworm as of **2026-10-21**) |
| PHP              | **7.3.33-35** from `packages.sury.org/php` (`php7.3-fpm`, `php7.3-cli`, …) — `apt-get upgrade` picks up future Sury rebuilds |
| nginx            | stock Debian nginx, vhost in `nginx/default.conf`, Phalcon rewrite included. Custom conf via drop-ins — see §6 |
| Phalcon          | **3.4.5** compiled from `phalcon/cphalcon` tag `v3.4.5` |
| Zephir parser    | **1.7.0** compiled from `phalcon/php-zephir-parser` (last 1.x supporting PHP 7.x) |
| Process model    | `supervisord`: php-fpm 7.3 + nginx, both workers as **`application` (1000:1000)** — same as old image |

## 5. Parity notes — audit of kirimemail-appmain (2026-10-21)

Composer requires: `php>=7.2` + `ext-curl, ext-mbstring, ext-iconv, ext-json,
 ext-phalcon ^3.0, ext-yaml` — all present. Grep over `app/`, `bootstrap/`,
 `config/`, `library/`:

| Extension | Verdict |
|-----------|---------|
| **xmlrpc** | **NOT required** — 0 usages. Dropped (was only a suspicion). |
| **aerospike** | **Removed** — 0 usages, as agreed. |
| ssh2, vips, pinba, weakref, handlersocketi, recode, wddx, ioncube, pspell-direct | 0 usages. Dropped. |
| **sodium** | 0 usages. Sury ships **no** `php7.3-sodium` for bookworm and it is not in `php7.3-common` either, so it is unavailable — safe to live without. |
| calendar | No direct calls, but ships inside `php7.3-common` — present. |
| dba | No `dba_*()` calls (33 hits are all `dbAdapter` false positives). Package kept — harmless. |
| apcu | No direct `apc_*()` calls, but `config/cache.php` + `config/metadata.php` offer an `Apc` driver. `php7.3-apcu` installed for parity. |
| imap | Real usage (`EmailParser.php`, `php-imap/php-imap` lib). Installed. |
| tidy | Real usage (`HtmlPurifyPlugin.php`). Installed. |
| redis / memcached | Sessions (`SESSION_DRIVER=redis` default), cache drivers, rate limits. phpredis **pinned to 5.3.7** compiled from the release tarball (Sury only ships 6.0.2 for php7.3; pecl channel proved flaky). |
| soap, xsl | No `SoapClient` / `XSLTProcessor` calls (string matches only). Installed anyway — cheap. |
| mcrypt, ldap, odbc, pgsql, pspell | Kept from old image — cheap, avoids surprises in vendor libs. |
| Web root         | `/app` (`/app/public` as docroot, same Phalcon layout as before) |

Dropped vs. old image (dead/EOL upstream, add back only if you truly need them):
`aerospike`, `handlersocketi`, `pinba`, `weakref`, `vips`, `ionCube Loader`,
`ssh2`, `recode` (removed upstream), `wddx` (removed), `xmlrpc` (now PECL).

## 3. Build & run

```bash
cd php7.3-sury-prod
make build
docker run --rm -p 8080:80 -v ./sample:/app/public gamalan/phalcon-nginx:php7.3-sury-prod-phalcon34
php -v        # 7.3.33-35…
php --ri phalcon   # 3.4.5
```

## 6. Custom config drop-ins (no need to edit base files)

| What | Repo location | Lands in image | Scope |
|------|---------------|----------------|-------|
| nginx http-level (`gzip`, rate limits, log formats) | `nginx/conf.d/*.conf` | `/etc/nginx/conf.d/` | whole `http {}` (stock Debian include) |
| nginx server-level (extra `location`, auth, headers) | `nginx/app.d/*.conf` | `/etc/nginx/app.d/`, included at end of `server {}` in `nginx/default.conf` | this vhost only |
| PHP settings (`upload_max_filesize`, `memory_limit`, …) | `php/extra/*.ini` | `/etc/php/7.3/{cli,fpm}/conf.d/` | CLI and FPM |
| Full vhost replacement | `nginx/default.conf` | `/etc/nginx/sites-available/default` | this vhost |
| PHP extension toggles | Sury `php7.3-*` packages / `mods-available` + `phpenmod` | — | image build |

Conventions: files load alphabetically — prefix with `NN-` (`10-…`, `30-…`).
`*.example` files are documentation; copy to the real name to enable.
Build validates with `nginx -t`; active PHP inis are listed via `php --ini`.

Runtime alternative (no rebuild): volume-mount over `/etc/nginx/conf.d/`,
`/etc/nginx/app.d/`, or `/etc/php/7.3/{fpm,cli}/conf.d/` and reload
(`nginx -s reload`; FPM picks up inis on restart).

FPM + docroot defaults (no-502 out of the box):
- PHP-FPM pool `[www]` listens on TCP `127.0.0.1:9000`, matching nginx
  `fastcgi_pass` (same as old image; no socket owner/mode to mismatch).
- Docroot follows `$APPLICATION_PATH` (default `/app`): `<path>/public` when
  it contains `index.php` (kirimemail-appmain layout), else `<path>` itself.
  `fastcgi_param APPLICATION_PATH` is rewritten to the same path.
- Different mount, no config overrides needed: `-e APPLICATION_PATH=/project`
  → docroot `/project/public` (or `/project` if it holds `index.php`).
- Explicit web root (e.g. tracking domain): `-e WEB_ROOT=/project/track_public`
  bypasses the derivation and uses that dir verbatim.

Security defaults shipped in this image:
- nginx server block: `X-Content-Type-Options nosniff`,
  `Referrer-Policy no-referrer-when-downgrade`, `X-XSS-Protection 1; mode=block`,
  `Permissions-Policy` (camera/mic/geolocation off) — all with `always`.
  No `X-Frame-Options` by default (framing policy varies per deployment —
  set it via `nginx/app.d/` when decided).
- `server_tokens off` (`nginx/conf.d/00-security.conf`) and `expose_php = Off`
  (`php/extra/10-security.ini`) hide version banners.
- No default `Content-Security-Policy`: the app ships inline scripts a strict CSP
  would break — scope it per-route via `nginx/app.d/` (see `10-extra.conf.example`).

```
php7.3-sury-prod/
├── Dockerfile          # sury php7.3 + nginx + phalcon 3.4.5 build
├── Makefile            # build / run / shell / push
├── docker-compose.yml  # local run example
├── nginx/
│   ├── default.conf      # vhost with Phalcon rewrite + app.d include
│   ├── conf.d/           # http-level snippets → /etc/nginx/conf.d/
│   └── app.d/            # server-level drop-ins → included in server {}
├── php/
│   ├── opcache.ini       # sane prod opcache defaults (via phpenmod)
│   └── extra/            # *.ini → /etc/php/7.3/{cli,fpm}/conf.d/
├── supervisord.conf    # php-fpm + nginx
└── bin/entrypoint.sh   # prints versions, execs supervisord
```
