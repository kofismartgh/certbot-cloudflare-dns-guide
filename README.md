# certbot-cloudflare-dns-guide
this repo contains documentation for setting up Certbot with Cloudflare DNS challenges no port 80
# Certbot with Cloudflare DNS Setup Guide

## Overview
This guide covers the installation and configuration of Certbot using the pip approach with Cloudflare DNS validation for SSL certificate management on Ubuntu systems.

**Why DNS-01 Challenge Method?**
This approach is specifically designed for environments where port 80 is not accessible from the internet, making the standard HTTP-01 challenge method impossible. The DNS-01 challenge method validates domain ownership through DNS TXT records, eliminating the need for inbound HTTP traffic on port 80.

Since our infrastructure uses Cloudflare for DNS management, we utilize the `certbot-dns-cloudflare` plugin. However, Certbot supports DNS plugins for various providers including AWS Route53, DigitalOcean, Google Cloud DNS, and many others.

**Reference Documentation:** This guide is based on the official Certbot documentation available at https://eff-certbot.readthedocs.io

## Prerequisites
- Ubuntu server with sudo access
- Domain managed through Cloudflare
- Cloudflare API token with Zone:DNS:Edit permissions

## Installation

### 1. Install System Dependencies
```bash
sudo apt install python3 python3-dev python3-venv libaugeas-dev gcc
```

### 2. Remove Existing APT-based Certbot (if present)
If you previously installed Certbot via apt, remove it first:
```bash
sudo apt-get remove certbot
```

### 3. Create Python Virtual Environment
```bash
python3 -m venv /opt/certbot/
```

### 4. Install Certbot and Plugins
```bash
# Upgrade pip first
sudo /opt/certbot/bin/pip install --upgrade pip

# Install Certbot with required plugins
sudo /opt/certbot/bin/pip install certbot certbot-nginx certbot-dns-cloudflare cryptography
```

**Plugins Installed:**
- `certbot` - Core Certbot functionality
- `certbot-nginx` - Nginx integration
- `certbot-dns-cloudflare` - Cloudflare DNS challenge support
- `cryptography` - Cryptographic operations support

**Note:** Other DNS plugins are available for different providers (AWS Route53, DigitalOcean, etc.)

### 5. Create Symbolic Link
```bash
sudo ln -s /opt/certbot/bin/certbot /usr/bin/certbot
```

## Cloudflare Configuration

### 1. Create Configuration Directory
```bash
sudo mkdir -p /etc/letsencrypt
```

### 2. Create Cloudflare Credentials File
```bash
sudo vim /etc/letsencrypt/cloudflare.ini
```

Add the following content:
```ini
# Cloudflare API token used by Certbot
dns_cloudflare_api_token = 0123456789abcdef0123456789abcdef01234567
```

**Getting Your API Token:**
1. Log into Cloudflare Dashboard
2. Go to "My Profile" → "API Tokens"
3. Create token with `Zone:DNS:Edit` permissions for your domain

### 3. Secure the Credentials File
```bash
sudo chmod 600 /etc/letsencrypt/cloudflare.ini
```

## Certificate Generation

### Option 1: Certificate Only (Manual Nginx Configuration)
Use this when you want to handle Nginx configuration manually:

```bash
sudo certbot certonly \
  --dns-cloudflare \
  --dns-cloudflare-propagation-seconds 10 \
  --dns-cloudflare-credentials /etc/letsencrypt/cloudflare.ini \
  --preferred-challenges dns-01 \
  --email your-email@example.com \
  --agree-tos \
  -d your-domain.com
```

### Option 2: Certificate + Automatic Nginx Configuration
Use this for automatic Nginx configuration:

```bash
sudo certbot run \
  --dns-cloudflare \
  --dns-cloudflare-propagation-seconds 20 \
  --dns-cloudflare-credentials /etc/letsencrypt/cloudflare.ini \
  --preferred-challenges dns-01 \
  --email your-email@example.com \
  --agree-tos \
  --installer nginx \
  -d your-domain.com
```

### Option 3: Automated/Non-Interactive Mode
For scripting and automation:

```bash
sudo certbot run \
  --dns-cloudflare \
  --dns-cloudflare-propagation-seconds 20 \
  --dns-cloudflare-credentials /etc/letsencrypt/cloudflare.ini \
  --preferred-challenges dns-01 \
  --non-interactive \
  --agree-tos \
  --email your-email@example.com \
  --installer nginx \
  -d your-domain.com
```

## Key Parameters Explained

| Parameter | Description |
|-----------|-------------|
| `--dns-cloudflare` | Use Cloudflare DNS plugin |
| `--dns-cloudflare-propagation-seconds` | Wait time for DNS propagation (10-60 seconds recommended) |
| `--dns-cloudflare-credentials` | Path to Cloudflare credentials file |
| `--preferred-challenges dns-01` | Use DNS challenge method |
| `--non-interactive` | Run without user interaction (for automation) |
| `--agree-tos` | Automatically agree to Terms of Service |
| `--installer nginx` | Automatically configure Nginx |
| `certonly` | Generate certificate only, don't install |
| `run` | Generate certificate AND install it |

## Verification and Renewal

### Check Certificate Expiration
```bash
openssl x509 -enddate -noout -in /etc/letsencrypt/live/your-domain.com/cert.pem
```

### Test Renewal Process
```bash
sudo certbot renew --dry-run
```

### Manual Renewal
```bash
sudo certbot renew
```

## Automatic Renewal Setup

Certbot automatically installs a systemd timer. Verify it's active:

```bash
sudo systemctl status certbot.timer
```

## Troubleshooting

### Common Issues
1. **DNS Propagation**: Increase `--dns-cloudflare-propagation-seconds` if challenges fail
2. **API Token**: Ensure token has correct permissions (Zone:DNS:Edit)
3. **Firewall**: Ensure ports 80/443 are accessible if using HTTP challenges
4. **File Permissions**: Verify cloudflare.ini has correct permissions (600)

### Log Locations
- Certbot logs: `/var/log/letsencrypt/letsencrypt.log`
- Nginx logs: `/var/log/nginx/error.log`

## Security Best Practices

1. **Credentials Security**: Always use `chmod 600` on credential files
2. **API Token Scope**: Use minimal required permissions (Zone:DNS:Edit only)
3. **Regular Updates**: Keep Certbot and plugins updated
4. **Monitoring**: Set up alerts for certificate expiration
5. **Backup**: Include `/etc/letsencrypt/` in your backup strategy

## File Locations

| Item | Location |
|------|----------|
| Certificates | `/etc/letsencrypt/live/domain.com/` |
| Private Keys | `/etc/letsencrypt/live/domain.com/privkey.pem` |
| Certificate Chain | `/etc/letsencrypt/live/domain.com/fullchain.pem` |
| Configuration | `/etc/letsencrypt/` |
| Logs | `/var/log/letsencrypt/` |

---

**Note**: Always test certificate generation in a staging environment first, and consider using Let's Encrypt's staging environment (`--staging` flag) to avoid rate limits during testing.
