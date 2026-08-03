# Deploy and Host UVdesk on Railway

## About Hosting UVdesk

UVdesk Community Helpdesk is an open-source support platform with tickets, agents, groups, workflows, knowledge base content, saved replies, and customer portals. This template deploys stable 1.1.8 with generated credentials and private MariaDB.

Sign in at `/en/member/login` as `admin@example.com` with `UVDESK_ADMIN_PASSWORD`.

## Common Use Cases

- Customer support ticketing
- Internal service desks
- Knowledge base and agent workflows

## Dependencies for UVdesk Hosting

### Deployment Dependencies

UVdesk and private MariaDB services each use a daily-backed-up volume. Railway provides HTTPS. Outbound mail remains disabled until `MAILER_DSN` is configured.

### Implementation Details

The adapter creates the schema, loads UVdesk's supported fixtures, creates a generated super administrator, trusts only the loopback proxy, and persists configuration plus attachments. Use one application replica.

## Why Deploy UVdesk on Railway?

Railway provides generated credentials, private networking, HTTPS, persistent storage, backups, health checks, and Git-driven updates.
