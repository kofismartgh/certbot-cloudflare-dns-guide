#!/bin/bash

# ================================
# Certbot Cloudflare DNS Setup Script
# ================================
# Automates Let's Encrypt certificate generation with Cloudflare DNS validation
# Supports multiple domains and various configuration options
#
# Author: SRE Team
# Version: 1.0
# ================================

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Script configuration
SCRIPT_NAME="certbot-setup.sh"
VERSION="1.0"
LOG_FILE="/var/log/certbot-setup.log"

# Default values
DEFAULT_CREDENTIALS_FILE="/etc/letsencrypt/cloudflare.ini"
DEFAULT_PROPAGATION_SECONDS=20
DEFAULT_MODE="certonly"

# Global variables
EMAIL=""
DOMAINS=""
MODE="$DEFAULT_MODE"
CREDENTIALS_FILE="$DEFAULT_CREDENTIALS_FILE"
PROPAGATION_SECONDS="$DEFAULT_PROPAGATION_SECONDS"
STAGING=false
NON_INTERACTIVE=false
VERBOSE=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ================================
# Helper Functions
# ================================

# Enhanced logging function
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "INFO")
            echo -e "${BLUE}[INFO]${NC} $message"
            ;;
        "SUCCESS")
            echo -e "${GREEN}[SUCCESS]${NC} $message"
            ;;
        "WARNING")
            echo -e "${YELLOW}[WARNING]${NC} $message"
            ;;
        "ERROR")
            echo -e "${RED}[ERROR]${NC} $message"
            ;;
        "DEBUG")
            if [ "$VERBOSE" = true ]; then
                echo -e "${BLUE}[DEBUG]${NC} $message"
            fi
            ;;
    esac
    
    # Always log to file
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# Error handling function
error_exit() {
    log "ERROR" "$1"
    exit 1
}

# Check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        error_exit "This script must be run as root (use sudo)"
    fi
}

# Check if required commands exist
check_dependencies() {
    local missing_deps=()
    
    # Check for required commands
    for cmd in certbot openssl curl; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        error_exit "Missing required dependencies: ${missing_deps[*]}. Please install them first."
    fi
    
    log "INFO" "All required dependencies found"
}

# Validate email format
validate_email() {
    local email="$1"
    if [[ ! "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        error_exit "Invalid email format: $email"
    fi
}

# Validate domain format
validate_domain() {
    local domain="$1"
    if [[ ! "$domain" =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
        error_exit "Invalid domain format: $domain"
    fi
}

# Parse domains from comma-separated string
parse_domains() {
    local domains_string="$1"
    IFS=',' read -ra DOMAIN_ARRAY <<< "$domains_string"
    
    # Trim whitespace and validate each domain
    for domain in "${DOMAIN_ARRAY[@]}"; do
        domain=$(echo "$domain" | xargs)  # Trim whitespace
        validate_domain "$domain"
        log "DEBUG" "Validated domain: $domain"
    done
    
    log "INFO" "Parsed ${#DOMAIN_ARRAY[@]} domain(s): ${DOMAIN_ARRAY[*]}"
}

# Check if credentials file exists and is readable
check_credentials() {
    if [ ! -f "$CREDENTIALS_FILE" ]; then
        error_exit "Credentials file not found: $CREDENTIALS_FILE"
    fi
    
    if [ ! -r "$CREDENTIALS_FILE" ]; then
        error_exit "Cannot read credentials file: $CREDENTIALS_FILE"
    fi
    
    # Check if file contains API token
    if ! grep -q "dns_cloudflare_api_token" "$CREDENTIALS_FILE"; then
        error_exit "Invalid credentials file format. Missing 'dns_cloudflare_api_token' in $CREDENTIALS_FILE"
    fi
    
    log "INFO" "Credentials file validated: $CREDENTIALS_FILE"
}

# Create credentials file template if it doesn't exist
create_credentials_template() {
    if [ ! -f "$CREDENTIALS_FILE" ]; then
        log "INFO" "Creating credentials file template: $CREDENTIALS_FILE"
        cat > "$CREDENTIALS_FILE" << EOF
# Cloudflare API token used by Certbot
# Replace the token below with your actual Cloudflare API token
dns_cloudflare_api_token = YOUR_CLOUDFLARE_API_TOKEN_HERE
EOF
        chmod 600 "$CREDENTIALS_FILE"
        log "WARNING" "Please edit $CREDENTIALS_FILE and add your Cloudflare API token"
        log "INFO" "You can get your API token from: https://dash.cloudflare.com/profile/api-tokens"
        return 1
    fi
    return 0
}

# Build certbot command
build_certbot_command() {
    local cmd="certbot"
    local domain_args=""
    
    # Add staging flag if requested
    if [ "$STAGING" = true ]; then
        cmd="$cmd --staging"
        log "INFO" "Using Let's Encrypt staging environment"
    fi
    
    # Add non-interactive flag if requested
    if [ "$NON_INTERACTIVE" = true ]; then
        cmd="$cmd --non-interactive"
    fi
    
    # Add email and agreement
    cmd="$cmd --email $EMAIL --agree-tos"
    
    # Add mode-specific arguments
    if [ "$MODE" = "nginx" ]; then
        cmd="$cmd run --installer nginx"
    else
        cmd="$cmd certonly"
    fi
    
    # Add Cloudflare DNS arguments
    cmd="$cmd --dns-cloudflare"
    cmd="$cmd --dns-cloudflare-credentials $CREDENTIALS_FILE"
    cmd="$cmd --dns-cloudflare-propagation-seconds $PROPAGATION_SECONDS"
    cmd="$cmd --preferred-challenges dns-01"
    
    # Add domain arguments
    for domain in "${DOMAIN_ARRAY[@]}"; do
        domain_args="$domain_args -d $domain"
    done
    
    cmd="$cmd $domain_args"
    
    echo "$cmd"
}

# Execute certbot command
execute_certbot() {
    local cmd="$1"
    
    log "INFO" "Executing certbot command..."
    log "DEBUG" "Command: $cmd"
    
    if eval "$cmd"; then
        log "SUCCESS" "Certificate generation completed successfully"
        return 0
    else
        log "ERROR" "Certificate generation failed"
        return 1
    fi
}

# Verify generated certificates
verify_certificates() {
    log "INFO" "Verifying generated certificates..."
    
    local all_valid=true
    
    for domain in "${DOMAIN_ARRAY[@]}"; do
        local cert_file="/etc/letsencrypt/live/$domain/fullchain.pem"
        
        if [ -f "$cert_file" ]; then
            local expiry_date=$(openssl x509 -enddate -noout -in "$cert_file" | cut -d= -f2)
            local expiry_epoch=$(date -d "$expiry_date" +%s)
            local now_epoch=$(date +%s)
            local days_left=$(( (expiry_epoch - now_epoch) / 86400 ))
            
            log "SUCCESS" "Certificate for $domain: Valid until $expiry_date ($days_left days)"
        else
            log "ERROR" "Certificate file not found for $domain: $cert_file"
            all_valid=false
        fi
    done
    
    if [ "$all_valid" = true ]; then
        log "SUCCESS" "All certificates verified successfully"
        return 0
    else
        log "ERROR" "Some certificates failed verification"
        return 1
    fi
}

# Display help information
show_help() {
    cat << EOF
$SCRIPT_NAME - Certbot Cloudflare DNS Setup Script v$VERSION

USAGE:
    $SCRIPT_NAME -e EMAIL -d DOMAINS [OPTIONS]

REQUIRED ARGUMENTS:
    -e, --email EMAIL           Email address for Let's Encrypt registration
    -d, --domains DOMAINS       Comma-separated list of domains (e.g., "example.com,www.example.com")

OPTIONAL ARGUMENTS:
    -m, --mode MODE             Mode: 'certonly' (default) or 'nginx'
    -c, --credentials FILE      Path to Cloudflare credentials file (default: $DEFAULT_CREDENTIALS_FILE)
    -p, --propagation SECONDS   DNS propagation wait time (default: $DEFAULT_PROPAGATION_SECONDS)
    -s, --staging              Use Let's Encrypt staging environment
    -n, --non-interactive      Run in non-interactive mode
    -v, --verbose              Enable verbose output
    -h, --help                 Show this help message

EXAMPLES:
    # Basic certificate generation
    $SCRIPT_NAME -e admin@example.com -d "example.com,www.example.com"
    
    # With Nginx auto-configuration
    $SCRIPT_NAME -e admin@example.com -d "example.com" -m nginx
    
    # Using staging environment
    $SCRIPT_NAME -e admin@example.com -d "example.com" -s
    
    # Custom credentials file
    $SCRIPT_NAME -e admin@example.com -d "example.com" -c /path/to/cloudflare.ini
    
    # Non-interactive mode with custom propagation time
    $SCRIPT_NAME -e admin@example.com -d "example.com" -n -p 30

NOTES:
    - This script must be run as root (use sudo)
    - Ensure your Cloudflare API token has Zone:DNS:Edit permissions
    - The script will create a credentials file template if it doesn't exist
    - All operations are logged to $LOG_FILE

EOF
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -e|--email)
                EMAIL="$2"
                shift 2
                ;;
            -d|--domains)
                DOMAINS="$2"
                shift 2
                ;;
            -m|--mode)
                MODE="$2"
                if [[ "$MODE" != "certonly" && "$MODE" != "nginx" ]]; then
                    error_exit "Invalid mode: $MODE. Must be 'certonly' or 'nginx'"
                fi
                shift 2
                ;;
            -c|--credentials)
                CREDENTIALS_FILE="$2"
                shift 2
                ;;
            -p|--propagation)
                PROPAGATION_SECONDS="$2"
                if ! [[ "$PROPAGATION_SECONDS" =~ ^[0-9]+$ ]]; then
                    error_exit "Propagation seconds must be a number: $PROPAGATION_SECONDS"
                fi
                shift 2
                ;;
            -s|--staging)
                STAGING=true
                shift
                ;;
            -n|--non-interactive)
                NON_INTERACTIVE=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                error_exit "Unknown option: $1. Use --help for usage information."
                ;;
        esac
    done
    
    # Validate required arguments
    if [ -z "$EMAIL" ]; then
        error_exit "Email is required. Use -e or --email"
    fi
    
    if [ -z "$DOMAINS" ]; then
        error_exit "Domains are required. Use -d or --domains"
    fi
}

# Main function
main() {
    log "INFO" "Starting $SCRIPT_NAME v$VERSION"
    
    # Parse command line arguments
    parse_arguments "$@"
    
    # Validate inputs
    validate_email "$EMAIL"
    parse_domains "$DOMAINS"
    
    # System checks
    check_root
    check_dependencies
    
    # Handle credentials
    if ! create_credentials_template; then
        error_exit "Please configure your Cloudflare API token in $CREDENTIALS_FILE and run the script again"
    fi
    check_credentials
    
    # Build and execute certbot command
    local certbot_cmd
    certbot_cmd=$(build_certbot_command)
    
    if execute_certbot "$certbot_cmd"; then
        verify_certificates
        log "SUCCESS" "Certificate setup completed successfully for domains: ${DOMAIN_ARRAY[*]}"
        
        # Display next steps
        echo
        log "INFO" "Next steps:"
        log "INFO" "1. Configure your web server to use the certificates"
        log "INFO" "2. Set up automatic renewal (certbot.timer should be active)"
        log "INFO" "3. Test your SSL configuration"
        
        if [ "$MODE" = "nginx" ]; then
            log "INFO" "4. Restart Nginx: systemctl restart nginx"
        fi
        
        echo
        log "INFO" "Certificate files location: /etc/letsencrypt/live/"
    else
        error_exit "Certificate setup failed. Check the logs for details."
    fi
}

# Run main function with all arguments
main "$@"
