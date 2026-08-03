FROM docker.io/library/php:8.2.33-apache-bookworm@sha256:38e82cca3dcb2d93baec086db6d627f246402f99df8f2cf0bf9f3ebc859ff365 AS build
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl unzip libicu-dev libjpeg62-turbo-dev libpng-dev libfreetype6-dev libzip-dev libonig-dev libc-client2007e-dev libkrb5-dev && rm -rf /var/lib/apt/lists/* \
 && docker-php-ext-configure gd --with-freetype --with-jpeg \
 && docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
 && docker-php-ext-install -j2 pdo_mysql intl gd zip mbstring imap \
 && pecl install mailparse-3.1.8 && docker-php-ext-enable mailparse \
 && rm -f /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini
RUN curl -fsSL https://cdn.uvdesk.com/uvdesk/downloads/opensource/uvdesk-community-current-stable.zip -o /tmp/uvdesk.zip \
 && echo 'c6b9fe9c0e1d3fc0eab5645801e826958f182ff5f0c4568a0a5756c6ef19ad9d  /tmp/uvdesk.zip' | sha256sum -c - \
 && unzip -q /tmp/uvdesk.zip -d /opt \
 && mv /opt/uvdesk-community-v1.1.8 /opt/uvdesk \
 && rm -rf /opt/uvdesk/var/cache/* /opt/uvdesk/var/log/* \
 && chown -R www-data:www-data /opt/uvdesk
RUN a2enmod rewrite
FROM build
COPY --from=docker.io/library/caddy:2.10.2-alpine@sha256:d8c17a862962def15cde69863a3a463f25a2664942eafd7bdbf050e9c3116b83 /usr/bin/caddy /usr/bin/caddy
COPY Caddyfile /etc/caddy/Caddyfile
COPY entrypoint.sh /usr/local/bin/uvdesk-railway-entrypoint
RUN chmod +x /usr/local/bin/uvdesk-railway-entrypoint
EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/uvdesk-railway-entrypoint"]
