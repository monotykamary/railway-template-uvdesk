## Supported runtime maintenance

PHP 8.2.35 keeps the supported 8.2 line and bundled IMAP extension. UVdesk remains 1.1.8; MariaDB remains exactly as published. The pinned archive checksum and upstream licensing are unchanged.

The product gate creates an additional validation account through UVdesk’s own console API only at boot, checks its password and identity through upgrade and redeploy, and rejects missing state. 120-second soaks and authenticated web checks are required. No live Railway validation or publication is claimed.
