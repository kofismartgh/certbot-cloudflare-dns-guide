#!/bin/bash

# ================================
# Certbot Setup Script - Usage Examples
# ================================
# This file contains practical examples of how to use certbot-setup.sh
# Copy and modify these examples for your specific use cases
# ================================

echo "Certbot Setup Script - Usage Examples"
echo "====================================="
echo

# Make sure the script is executable
chmod +x ./certbot-setup.sh

echo "1. Basic Usage - Single Domain"
echo "=============================="
echo "Command:"
echo "sudo ./certbot-setup.sh -e admin@example.com -d example.com"
echo
echo "This will:"
echo "- Generate a certificate for example.com"
echo "- Use certonly mode (certificate only, no web server config)"
echo "- Use default credentials file: /etc/letsencrypt/cloudflare.ini"
echo "- Use default propagation time: 20 seconds"
echo

echo "2. Multiple Domains"
echo "==================="
echo "Command:"
echo "sudo ./certbot-setup.sh -e admin@example.com -d \"example.com,www.example.com,api.example.com\""
echo
echo "This will:"
echo "- Generate certificates for all three domains"
echo "- Create a single certificate covering all domains (SAN certificate)"
echo

echo "3. With Nginx Auto-Configuration"
echo "================================"
echo "Command:"
echo "sudo ./certbot-setup.sh -e admin@example.com -d example.com -m nginx"
echo
echo "This will:"
echo "- Generate certificate AND configure Nginx automatically"
echo "- Update Nginx configuration to use SSL"
echo "- Enable HTTPS redirect"
echo

echo "4. Using Staging Environment (Testing)"
echo "======================================"
echo "Command:"
echo "sudo ./certbot-setup.sh -e admin@example.com -d example.com -s"
echo
echo "This will:"
echo "- Use Let's Encrypt staging environment"
echo "- Generate test certificates (not trusted by browsers)"
echo "- Avoid rate limits during testing"
echo

echo "5. Non-Interactive Mode (Automation)"
echo "===================================="
echo "Command:"
echo "sudo ./certbot-setup.sh -e admin@example.com -d example.com -n"
echo
echo "This will:"
echo "- Run without user interaction"
echo "- Perfect for cron jobs and automation"
echo "- Use default values for all prompts"
echo

echo "6. Custom Credentials File"
echo "=========================="
echo "Command:"
echo "sudo ./certbot-setup.sh -e admin@example.com -d example.com -c /path/to/custom-cloudflare.ini"
echo
echo "This will:"
echo "- Use a custom Cloudflare credentials file"
echo "- Useful for different environments or accounts"
echo

echo "7. Custom DNS Propagation Time"
echo "=============================="
echo "Command:"
echo "sudo ./certbot-setup.sh -e admin@example.com -d example.com -p 60"
echo
echo "This will:"
echo "- Wait 60 seconds for DNS propagation"
echo "- Useful for slow DNS environments"
echo

echo "8. Verbose Output (Debugging)"
echo "============================="
echo "Command:"
echo "sudo ./certbot-setup.sh -e admin@example.com -d example.com -v"
echo
echo "This will:"
echo "- Show detailed debug information"
echo "- Help troubleshoot issues"
echo

echo "9. Complete Example (Production)"
echo "==============================="
echo "Command:"
echo "sudo ./certbot-setup.sh \\"
echo "  -e admin@example.com \\"
echo "  -d \"example.com,www.example.com,api.example.com\" \\"
echo "  -m nginx \\"
echo "  -c /etc/letsencrypt/cloudflare.ini \\"
echo "  -p 30 \\"
echo "  -n"
echo
echo "This will:"
echo "- Generate certificates for multiple domains"
echo "- Configure Nginx automatically"
echo "- Use custom credentials file"
echo "- Wait 30 seconds for DNS propagation"
echo "- Run non-interactively"
echo

echo "10. Help and Usage Information"
echo "============================="
echo "Command:"
echo "sudo ./certbot-setup.sh --help"
echo
echo "This will:"
echo "- Display complete help information"
echo "- Show all available options"
echo "- Provide usage examples"
echo

echo "Prerequisites Checklist"
echo "======================="
echo "Before running the script, ensure:"
echo "1. You have sudo/root access"
echo "2. Certbot is installed (see dns01-cerbot-renewal.txt)"
echo "3. Cloudflare API token is configured"
echo "4. Domains point to your server"
echo "5. Firewall allows ports 80 and 443"
echo

echo "Troubleshooting Tips"
echo "===================="
echo "1. Check logs: tail -f /var/log/certbot-setup.log"
echo "2. Test with staging: add -s flag"
echo "3. Verify DNS: dig TXT _acme-challenge.example.com"
echo "4. Check permissions: ls -la /etc/letsencrypt/cloudflare.ini"
echo "5. Validate domains: nslookup example.com"
echo

echo "Security Best Practices"
echo "======================="
echo "1. Use minimal Cloudflare API token permissions"
echo "2. Rotate API tokens regularly"
echo "3. Monitor certificate expiration"
echo "4. Set up automatic renewal"
echo "5. Backup certificate files"
echo "6. Use staging environment for testing"
echo

echo "For more information, see: dns01-cerbot-renewal.txt"
