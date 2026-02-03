#!/bin/bash

# ============================================================================
# deploy.sh
# Deploy Snowflake multi-tenant analytics system using Snow CLI
# 
# Usage:
#   ./deploy.sh                    # Uses default.conf
#   ./deploy.sh config.conf        # Uses custom config file
# ============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}ℹ ${NC}$1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_header() {
    echo ""
    echo -e "${BLUE}============================================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}============================================================================${NC}"
    echo ""
}

# Check if snow CLI is installed
print_info "Checking for Snow CLI..."
if ! command -v snow &> /dev/null; then
    print_error "Snow CLI is not installed!"
    echo ""
    echo "The Snow CLI is required to deploy this project."
    echo ""
    echo "Installation instructions:"
    echo "  1. Install via pip:"
    echo "     pip install snowflake-cli-labs"
    echo ""
    echo "  2. Or via pipx (recommended):"
    echo "     pipx install snowflake-cli-labs"
    echo ""
    echo "  3. Configure a connection:"
    echo "     snow connection add"
    echo ""
    echo "For more information, visit:"
    echo "  https://docs.snowflake.com/en/developer-guide/snowflake-cli/index"
    echo ""
    exit 1
fi

print_success "Snow CLI is installed ($(snow --version 2>&1 | head -n 1))"

# List available connections
print_info "Checking Snow CLI connections..."
if snow connection list > /dev/null 2>&1; then
    echo ""
    echo "Available Snowflake connections:"
    echo "────────────────────────────────────────────────────────────────"
    snow connection list
    echo "────────────────────────────────────────────────────────────────"
    echo ""
    print_info "Using default connection (or set with: snow connection set-default <name>)"
    echo ""
else
    print_warning "No connections configured!"
    echo ""
    echo "You need to configure a Snowflake connection first:"
    echo "  snow connection add"
    echo ""
    read -p "Would you like to configure a connection now? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        snow connection add
        echo ""
        print_success "Connection configured"
    else
        print_error "Cannot proceed without a configured connection"
        exit 1
    fi
fi

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Load configuration
CONFIG_FILE="${1:-$SCRIPT_DIR/default.conf}"

if [ ! -f "$CONFIG_FILE" ]; then
    print_error "Configuration file not found: $CONFIG_FILE"
    echo ""
    echo "Usage:"
    echo "  ./deploy.sh                    # Uses default.conf"
    echo "  ./deploy.sh config.conf        # Uses custom config file"
    exit 1
fi

print_info "Loading configuration from: $CONFIG_FILE"
source "$CONFIG_FILE"

# Validate required configuration
if [ -z "$DATABASE_NAME" ] || [ -z "$WAREHOUSE_NAME" ]; then
    print_error "DATABASE_NAME and WAREHOUSE_NAME must be set in config file"
    exit 1
fi

print_header "Snowflake Multi-Tenant Analytics Deployment"

echo "Configuration:"
echo "  Database:  $DATABASE_NAME"
echo "  Schema:    ${SCHEMA_NAME:-PUBLIC}"
echo "  Warehouse: $WAREHOUSE_NAME (${WAREHOUSE_SIZE:-XSMALL})"
echo ""

# Array of SQL scripts to execute in order
SQL_SCRIPTS=(
    "01_setup_and_data.sql"
    "02_create_policies.sql"
    "03_apply_policies.sql"
)

# Conditionally add tests
if [ "${RUN_TESTS:-TRUE}" = "TRUE" ]; then
    SQL_SCRIPTS+=("04_test_policies.sql")
fi

# Check if all SQL files exist
print_info "Checking SQL files..."
for script in "${SQL_SCRIPTS[@]}"; do
    if [ ! -f "$SCRIPT_DIR/$script" ]; then
        print_error "SQL file not found: $script"
        exit 1
    fi
done
print_success "All SQL files found"

# Test Snow CLI connection
print_info "Testing Snow CLI connection..."
if snow connection test > /dev/null 2>&1; then
    print_success "Snow CLI connection test successful"
else
    print_error "Snow CLI connection test failed!"
    echo ""
    echo "Please verify your connection configuration:"
    echo "  snow connection test"
    echo ""
    echo "Or configure a new connection:"
    echo "  snow connection add"
    echo ""
    exit 1
fi

# Ask for confirmation
echo ""
read -p "This will deploy the multi-tenant analytics system. Continue? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "Deployment cancelled"
    exit 0
fi

# Execute each SQL script
TOTAL_SCRIPTS=${#SQL_SCRIPTS[@]}
CURRENT=0

for script in "${SQL_SCRIPTS[@]}"; do
    CURRENT=$((CURRENT + 1))
    print_header "[$CURRENT/$TOTAL_SCRIPTS] Executing: $script"
    
    # Export config variables for SQL scripts to use
    export SNOWFLAKE_DATABASE="$DATABASE_NAME"
    export SNOWFLAKE_SCHEMA="${SCHEMA_NAME:-PUBLIC}"
    export SNOWFLAKE_WAREHOUSE="$WAREHOUSE_NAME"
    
    # Use snow sql with variable substitution
    if snow sql -f "$SCRIPT_DIR/$script" \
        -D database_name="$DATABASE_NAME" \
        -D schema_name="${SCHEMA_NAME:-PUBLIC}" \
        -D warehouse_name="$WAREHOUSE_NAME" \
        -D warehouse_size="${WAREHOUSE_SIZE:-XSMALL}" \
        -D auto_suspend="${WAREHOUSE_AUTO_SUSPEND:-60}" \
        -D auto_resume="${WAREHOUSE_AUTO_RESUME:-TRUE}" \
        -D auto_recluster="${AUTO_RECLUSTER_ENABLED:-FALSE}"; then
        print_success "Successfully executed: $script"
    else
        print_error "Failed to execute: $script"
        print_error "Deployment stopped. Please fix the error and try again."
        exit 1
    fi
    
    # Small delay between scripts
    sleep 1
done

# Deployment complete
print_header "Deployment Complete!"

echo ""
print_success "All scripts executed successfully"
echo ""
echo "Summary:"
echo "  ✓ Database, schema, and warehouse created"
echo "  ✓ 12 tables created with sample data"
echo "  ✓ 12 row access policies created and applied"
if [ "${RUN_TESTS:-TRUE}" = "TRUE" ]; then
    echo "  ✓ Policies tested with multiple users"
fi
echo ""
echo "Usage:"
echo "  1. Set session context before querying:"
echo "     SET current_org_id = 'org_123';"
echo "     SET current_app_ids = '[\"app_1\", \"app_2\"]';"
echo ""
echo "  2. All queries are automatically filtered:"
echo "     SELECT * FROM organizations;     -- Only sees org_123"
echo "     SELECT * FROM applications;      -- Only sees app_1, app_2"
echo "     SELECT * FROM analytics_events;  -- Only sees org_123 + allowed apps"
echo ""
