# Certbot Cloudflare DNS Setup Script

A comprehensive bash script that automates Let's Encrypt certificate generation using Cloudflare DNS validation for Ubuntu systems.

## Features

- ✅ **Multiple Domain Support**: Handle single or multiple domains in one command
- ✅ **Flexible Modes**: Certificate-only or automatic Nginx configuration
- ✅ **Security Focused**: Proper credential handling and validation
- ✅ **Comprehensive Logging**: Detailed logs with different severity levels
- ✅ **Error Handling**: Robust error checking and user-friendly messages
- ✅ **Testing Support**: Staging environment and verbose modes
- ✅ **Automation Ready**: Non-interactive mode for cron jobs and CI/CD

## Quick Start

1. **Make the script executable:**
   ```bash
   chmod +x certbot-setup.sh
   ```

2. **Run with basic parameters:**
   ```bash
   sudo ./certbot-setup.sh -e admin@example.com -d "example.com,www.example.com"
   ```

3. **For Nginx auto-configuration:**
   ```bash
   sudo ./certbot-setup.sh -e admin@example.com -d example.com -m nginx
   ```

## Prerequisites

### System Requirements
- Ubuntu server with sudo access
- Python 3 and pip installed
- Certbot and plugins installed (see installation guide below)

### Cloudflare Setup
- Domain managed through Cloudflare
- API token with `Zone:DNS:Edit` permissions
- DNS records pointing to your server

### Installation

Follow the detailed installation guide in `dns01-cerbot-renewal.txt` or run:

```bash
# Install system dependencies
sudo apt install python3 python3-dev python3-venv libaugeas-dev gcc

# Create virtual environment
sudo python3 -m venv /opt/certbot/

# Install Certbot and plugins
sudo /opt/certbot/bin/pip install --upgrade pip
sudo /opt/certbot/bin/pip install certbot certbot-nginx certbot-dns-cloudflare cryptography

# Create symbolic link
sudo ln -s /opt/certbot/bin/certbot /usr/bin/certbot
```

## Usage

### Basic Syntax
```bash
sudo ./certbot-setup.sh -e EMAIL -d DOMAINS [OPTIONS]
```

### Required Arguments
- `-e, --email EMAIL`: Email address for Let's Encrypt registration
- `-d, --domains DOMAINS`: Comma-separated list of domains

### Optional Arguments
- `-m, --mode MODE`: Mode - `certonly` (default) or `nginx`
- `-c, --credentials FILE`: Path to Cloudflare credentials file (default: `/etc/letsencrypt/cloudflare.ini`)
- `-p, --propagation SECONDS`: DNS propagation wait time (default: 20)
- `-s, --staging`: Use Let's Encrypt staging environment
- `-n, --non-interactive`: Run in non-interactive mode
- `-v, --verbose`: Enable verbose output
- `-h, --help`: Show help information

## Examples

### 1. Basic Certificate Generation
```bash
sudo ./certbot-setup.sh -e admin@example.com -d "example.com,www.example.com"
```

### 2. With Nginx Auto-Configuration
```bash
sudo ./certbot-setup.sh -e admin@example.com -d example.com -m nginx
```

### 3. Testing with Staging Environment
```bash
sudo ./certbot-setup.sh -e admin@example.com -d example.com -s
```

### 4. Non-Interactive Mode (Automation)
```bash
sudo ./certbot-setup.sh -e admin@example.com -d example.com -n
```

### 5. Custom Configuration
```bash
sudo ./certbot-setup.sh \
  -e admin@example.com \
  -d "example.com,www.example.com,api.example.com" \
  -m nginx \
  -c /path/to/cloudflare.ini \
  -p 30 \
  -n
```

## Configuration

### Cloudflare Credentials

The script will create a credentials file template if it doesn't exist:

```ini
# /etc/letsencrypt/cloudflare.ini
dns_cloudflare_api_token = YOUR_CLOUDFLARE_API_TOKEN_HERE
```

**Getting your API token:**
1. Log into [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. Go to "My Profile" → "API Tokens"
3. Create token with `Zone:DNS:Edit` permissions
4. Replace the placeholder in the credentials file

### File Permissions
```bash
sudo chmod 600 /etc/letsencrypt/cloudflare.ini
```

## Security Features

### Credential Protection
- Credentials file has 600 permissions (owner read/write only)
- Template creation with clear instructions
- Validation of credentials file format

### Input Validation
- Email format validation
- Domain format validation
- Required argument checking
- Dependency verification

### Error Handling
- Comprehensive error messages
- Graceful failure handling
- Detailed logging for troubleshooting

## Logging

All operations are logged to `/var/log/certbot-setup.log` with timestamps and severity levels:

- **INFO**: General information
- **SUCCESS**: Successful operations
- **WARNING**: Non-critical issues
- **ERROR**: Critical errors
- **DEBUG**: Detailed debugging (verbose mode only)

## Troubleshooting

### Common Issues

1. **"Missing required dependencies"**
   - Install certbot and required plugins
   - See installation section above

2. **"Credentials file not found"**
   - The script will create a template
   - Edit the file and add your API token

3. **"Invalid credentials file format"**
   - Ensure the file contains `dns_cloudflare_api_token = YOUR_TOKEN`
   - Check file permissions (should be 600)

4. **"Certificate generation failed"**
   - Check DNS propagation
   - Verify domain points to your server
   - Try with `-s` flag for staging environment
   - Use `-v` flag for verbose output

### Debugging Steps

1. **Check logs:**
   ```bash
   tail -f /var/log/certbot-setup.log
   ```

2. **Test with staging:**
   ```bash
   sudo ./certbot-setup.sh -e admin@example.com -d example.com -s -v
   ```

3. **Verify DNS:**
   ```bash
   dig TXT _acme-challenge.example.com
   ```

4. **Check permissions:**
   ```bash
   ls -la /etc/letsencrypt/cloudflare.ini
   ```

## Automation

### Cron Job Example
```bash
# Add to crontab for automatic renewal
0 2 * * * /path/to/certbot-setup.sh -e admin@example.com -d "example.com,www.example.com" -n >> /var/log/certbot-cron.log 2>&1
```

### Systemd Timer
Certbot automatically installs a systemd timer for renewal:
```bash
sudo systemctl status certbot.timer
sudo systemctl enable certbot.timer
```

## File Structure

```
/home/ubuntu/
├── certbot-setup.sh              # Main script
├── cloudflare.ini.template       # Credentials template
├── certbot-setup-examples.sh     # Usage examples
├── README-certbot-setup.md       # This documentation
└── dns01-cerbot-renewal.txt      # Detailed installation guide
```

## Certificate Locations

After successful generation:
- **Certificates**: `/etc/letsencrypt/live/domain.com/`
- **Private Keys**: `/etc/letsencrypt/live/domain.com/privkey.pem`
- **Certificate Chain**: `/etc/letsencrypt/live/domain.com/fullchain.pem`
- **Configuration**: `/etc/letsencrypt/`

## Best Practices

1. **Test First**: Always use `-s` flag for testing
2. **Monitor Expiration**: Set up alerts for certificate expiration
3. **Backup Certificates**: Include `/etc/letsencrypt/` in backup strategy
4. **Rotate API Tokens**: Regularly rotate Cloudflare API tokens
5. **Use Minimal Permissions**: API token should only have required permissions
6. **Monitor Logs**: Regularly check logs for issues

## Support

For issues and questions:
1. Check the logs: `/var/log/certbot-setup.log`
2. Review this documentation
3. See `dns01-cerbot-renewal.txt` for detailed installation guide
4. Check Let's Encrypt documentation: https://eff-certbot.readthedocs.io

## Version History

- **v1.0**: Initial release with full feature set
  - Multiple domain support
  - Nginx auto-configuration
  - Comprehensive error handling
  - Security features
  - Detailed logging
