#!/bin/bash
set -euo pipefail
: "${UVDESK_DB_HOST:?UVDESK_DB_HOST is required}" "${UVDESK_DB_PASSWORD:?UVDESK_DB_PASSWORD is required}" "${UVDESK_ADMIN_PASSWORD:?UVDESK_ADMIN_PASSWORD is required}" "${UVDESK_APP_SECRET:?UVDESK_APP_SECRET is required}" "${UVDESK_PUBLIC_HOST:?UVDESK_PUBLIC_HOST is required}"
if [ ! -f /var/www/uvdesk/bin/console ]; then
  mkdir -p /var/www/uvdesk
  cp -a /opt/uvdesk/. /var/www/uvdesk/
fi
cd /var/www/uvdesk
cat >.env.local <<EOF
APP_ENV=prod
APP_DEBUG=0
APP_SECRET=${UVDESK_APP_SECRET}
DATABASE_URL="mysql://${UVDESK_DB_USER:-uvdesk}:${UVDESK_DB_PASSWORD}@${UVDESK_DB_HOST}:${UVDESK_DB_PORT:-3306}/${UVDESK_DB_NAME:-uvdesk}?serverVersion=mariadb-11.8.3&charset=utf8mb4"
MAILER_DSN=${MAILER_DSN:-null://null}
EOF
sed -i "s|^[[:space:]]*site_url:.*|    site_url: '${UVDESK_PUBLIC_HOST}'|" config/packages/uvdesk.yaml
if ! grep -q 'setTrustedProxies' public/index.php; then
  sed -i '/use App\\Kernel;/a use Symfony\\Component\\HttpFoundation\\Request;' public/index.php
  sed -i '/return function (array $context) {/a\\    Request::setTrustedProxies(["127.0.0.1"], Request::HEADER_X_FORWARDED_FOR | Request::HEADER_X_FORWARDED_HOST | Request::HEADER_X_FORWARDED_PORT | Request::HEADER_X_FORWARDED_PROTO);' public/index.php
fi
mkdir -p var/cache var/log public/attachment public/uvdesk
chown -R www-data:www-data /var/www/uvdesk
for i in $(seq 1 120); do
  if runuser -u www-data -- php -r '$p=new PDO("mysql:host=".getenv("UVDESK_DB_HOST").";port=".(getenv("UVDESK_DB_PORT")?:"3306").";dbname=".(getenv("UVDESK_DB_NAME")?:"uvdesk"),getenv("UVDESK_DB_USER")?:"uvdesk",getenv("UVDESK_DB_PASSWORD"));' >/dev/null 2>&1; then break; fi
  sleep 2
done
db_scalar() {
  runuser -u www-data -- php -r '$p=new PDO("mysql:host=".getenv("UVDESK_DB_HOST").";port=".(getenv("UVDESK_DB_PORT")?:"3306").";dbname=".(getenv("UVDESK_DB_NAME")?:"uvdesk"),getenv("UVDESK_DB_USER")?:"uvdesk",getenv("UVDESK_DB_PASSWORD"));exit((int)$p->query($argv[1])->fetchColumn()>0?0:1);' "$1"
}
if ! db_scalar "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=DATABASE() AND table_name='uv_user'"; then
  runuser -u www-data -- php bin/console doctrine:schema:create --no-interaction
fi
if ! db_scalar 'SELECT COUNT(*) FROM uv_support_role'; then
  runuser -u www-data -- env APP_ENV=dev APP_DEBUG=0 php bin/console doctrine:fixtures:load --append --no-interaction
fi
runuser -u www-data -- php bin/console doctrine:migrations:version --add --all --no-interaction || true
if ! db_scalar "SELECT COUNT(*) FROM uv_user_instance i JOIN uv_support_role r ON r.id=i.supportRole_id WHERE r.code='ROLE_SUPER_ADMIN'"; then
  runuser -u www-data -- php bin/console uvdesk_wizard:defaults:create-user ROLE_SUPER_ADMIN 'Railway Admin' "${UVDESK_ADMIN_EMAIL:-admin@example.com}" "${UVDESK_ADMIN_PASSWORD}" --no-interaction
fi
runuser -u www-data -- php bin/console cache:clear --env=prod --no-debug
chown -R www-data:www-data /var/www/uvdesk
sed -ri 's/Listen 80/Listen 8000/' /etc/apache2/ports.conf
cat >/etc/apache2/sites-available/000-default.conf <<'EOF'
<VirtualHost *:8000>
  DocumentRoot /var/www/uvdesk/public
  <Directory /var/www/uvdesk/public>
    AllowOverride All
    Require all granted
    FallbackResource /index.php
  </Directory>
  ErrorLog /proc/self/fd/2
  CustomLog /proc/self/fd/1 combined
</VirtualHost>
EOF
rm -f /etc/apache2/mods-enabled/mpm_event.load /etc/apache2/mods-enabled/mpm_event.conf /etc/apache2/mods-enabled/mpm_worker.load /etc/apache2/mods-enabled/mpm_worker.conf /etc/apache2/mods-enabled/mpm_prefork.load /etc/apache2/mods-enabled/mpm_prefork.conf
a2enmod mpm_prefork >/dev/null
apache2-foreground &
app=$!
caddy run --config /etc/caddy/Caddyfile --adapter caddyfile &
proxy=$!
trap 'kill -TERM "$app" "$proxy" 2>/dev/null || true; wait' TERM INT
wait -n "$app" "$proxy"
status=$?
kill -TERM "$app" "$proxy" 2>/dev/null || true
wait || true
exit "$status"
