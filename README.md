# UVdesk on Railway

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/uvdesk?referralCode=ZqgrJ0)

Deploy UVdesk Community Helpdesk 1.1.8 with a generated administrator password, private MariaDB, persistent configuration and attachments, and daily backups.

Sign in at `/en/member/login` as `admin@example.com` with `UVDESK_ADMIN_PASSWORD`. Configure `MAILER_DSN` before enabling outbound email. Use one application replica because attachments use an attached volume.

Upstream: https://github.com/uvdesk/community-skeleton/tree/v1.1.8 (MIT skeleton; bundled UVdesk packages are OSL-3.0). Not affiliated with Railway.
