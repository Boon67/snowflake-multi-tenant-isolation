-- ============================================================================
-- 01_setup_and_data.sql
-- Complete setup: database, tables, and sample data
-- 
-- Variables (passed via Snow CLI -D flag):
--   <% database_name %>   - Database name (default: ANALYTICS_DB)
--   <% schema_name %>     - Schema name (default: PUBLIC)
--   <% warehouse_name %>  - Warehouse name (default: COMPUTE_WH)
--   <% warehouse_size %>  - Warehouse size (default: XSMALL)
--   <% auto_suspend %>    - Auto suspend time in seconds (default: 60)
--   <% auto_resume %>     - Auto resume (default: TRUE)
-- ============================================================================

-- ============================================================================
-- SETUP DATABASE, SCHEMA, AND WAREHOUSE
-- ============================================================================

-- Drop database if it exists (CASCADE will drop all schemas and objects)
DROP DATABASE IF EXISTS <% database_name %> CASCADE;
SELECT '✓ Dropped existing database (if any)' as status;

-- Create database
CREATE DATABASE <% database_name %>
    COMMENT = 'Multi-tenant analytics database with row access policies';

USE DATABASE <% database_name %>;

-- Create schema (IF NOT EXISTS in case it's PUBLIC which is auto-created)
CREATE SCHEMA IF NOT EXISTS <% schema_name %>
    COMMENT = 'Main schema for analytics tables';

USE SCHEMA <% schema_name %>;

-- Create warehouse if it doesn't exist
CREATE WAREHOUSE IF NOT EXISTS <% warehouse_name %>
    WITH
    WAREHOUSE_SIZE = '<% warehouse_size %>'
    AUTO_SUSPEND = <% auto_suspend %>
    AUTO_RESUME = <% auto_resume %>
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'Compute warehouse for analytics queries';

USE WAREHOUSE <% warehouse_name %>;

-- Grant usage on database and schema
GRANT USAGE ON DATABASE <% database_name %> TO ROLE SYSADMIN;
GRANT USAGE ON SCHEMA <% database_name %>.<% schema_name %> TO ROLE SYSADMIN;
GRANT USAGE ON WAREHOUSE <% warehouse_name %> TO ROLE SYSADMIN;

SELECT '✓ Database, schema, and warehouse setup complete' as status;

-- ============================================================================
-- CREATE TABLES
-- ============================================================================

-- Organizations table
CREATE TABLE organizations (
    org_id VARCHAR(50) PRIMARY KEY,
    org_name VARCHAR(200) NOT NULL,
    industry VARCHAR(100),
    tier VARCHAR(50) NOT NULL,
    created_at TIMESTAMP NOT NULL,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    country VARCHAR(50),
    employee_count INTEGER
) COMMENT = 'Organization master table - tier should be one of: free, pro, enterprise';

-- Organization settings table
CREATE TABLE organization_settings (
    setting_id VARCHAR(50) PRIMARY KEY,
    org_id VARCHAR(50) NOT NULL,
    setting_key VARCHAR(100) NOT NULL,
    setting_value VARCHAR(500),
    updated_at TIMESTAMP NOT NULL,
    updated_by VARCHAR(100) NOT NULL,
    CONSTRAINT fk_org_settings FOREIGN KEY (org_id) REFERENCES organizations(org_id)
) COMMENT = 'Organization-specific settings';

-- Organization billing table
CREATE TABLE organization_billing (
    billing_id VARCHAR(50) PRIMARY KEY,
    org_id VARCHAR(50) NOT NULL,
    billing_period VARCHAR(20) NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(10) NOT NULL,
    payment_status VARCHAR(50) NOT NULL,
    payment_date TIMESTAMP,
    invoice_url VARCHAR(500),
    CONSTRAINT fk_org_billing FOREIGN KEY (org_id) REFERENCES organizations(org_id)
) COMMENT = 'Organization billing records - payment_status should be one of: pending, paid, failed, refunded';

-- Organization users table
CREATE TABLE organization_users (
    user_id VARCHAR(50) PRIMARY KEY,
    org_id VARCHAR(50) NOT NULL,
    email VARCHAR(200) NOT NULL UNIQUE,
    full_name VARCHAR(200) NOT NULL,
    role VARCHAR(50) NOT NULL,
    created_at TIMESTAMP NOT NULL,
    last_login TIMESTAMP,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT fk_org_users FOREIGN KEY (org_id) REFERENCES organizations(org_id)
) COMMENT = 'Users belonging to organizations - role should be one of: admin, developer, analyst, viewer';

-- Applications table
CREATE TABLE applications (
    app_id VARCHAR(50) PRIMARY KEY,
    app_name VARCHAR(200) NOT NULL,
    app_type VARCHAR(100) NOT NULL,
    platform VARCHAR(50) NOT NULL,
    created_at TIMESTAMP NOT NULL,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    version VARCHAR(50)
) COMMENT = 'Application catalog - app_type should be one of: web, mobile_ios, mobile_android, api, desktop';

-- App configuration table
CREATE TABLE app_configuration (
    config_id VARCHAR(50) PRIMARY KEY,
    app_id VARCHAR(50) NOT NULL,
    config_key VARCHAR(100) NOT NULL,
    config_value VARCHAR(500),
    environment VARCHAR(50) NOT NULL,
    updated_at TIMESTAMP NOT NULL,
    CONSTRAINT fk_app_config FOREIGN KEY (app_id) REFERENCES applications(app_id)
) COMMENT = 'Application configuration settings - environment should be one of: production, staging, development';

-- App performance metrics table
CREATE TABLE app_performance_metrics (
    metric_id VARCHAR(50) PRIMARY KEY,
    app_id VARCHAR(50) NOT NULL,
    metric_date DATE NOT NULL,
    avg_response_time_ms INTEGER,
    error_rate DECIMAL(5,2),
    uptime_percentage DECIMAL(5,2),
    total_requests INTEGER,
    CONSTRAINT fk_app_metrics FOREIGN KEY (app_id) REFERENCES applications(app_id)
) COMMENT = 'Application performance metrics';

-- User app access junction table
CREATE TABLE user_app_access (
    access_id VARCHAR(50) PRIMARY KEY,
    user_id VARCHAR(50) NOT NULL,
    org_id VARCHAR(50) NOT NULL,
    app_id VARCHAR(50) NOT NULL,
    granted_at TIMESTAMP NOT NULL,
    granted_by VARCHAR(100) NOT NULL,
    access_level VARCHAR(50) NOT NULL,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT fk_user_access_user FOREIGN KEY (user_id) REFERENCES organization_users(user_id),
    CONSTRAINT fk_user_access_org FOREIGN KEY (org_id) REFERENCES organizations(org_id),
    CONSTRAINT fk_user_access_app FOREIGN KEY (app_id) REFERENCES applications(app_id)
) COMMENT = 'User access to applications - access_level should be one of: read, write, admin';

-- Analytics events table
CREATE TABLE analytics_events (
    event_id VARCHAR(50) PRIMARY KEY,
    org_id VARCHAR(50) NOT NULL,
    app_id VARCHAR(50) NOT NULL,
    event_name VARCHAR(100) NOT NULL,
    event_timestamp TIMESTAMP NOT NULL,
    user_id VARCHAR(50),
    session_id VARCHAR(100),
    device_type VARCHAR(50),
    country VARCHAR(50),
    properties VARIANT,
    CONSTRAINT fk_events_org FOREIGN KEY (org_id) REFERENCES organizations(org_id),
    CONSTRAINT fk_events_app FOREIGN KEY (app_id) REFERENCES applications(app_id)
) COMMENT = 'Analytics events fact table';

-- Revenue data table
CREATE TABLE revenue_data (
    revenue_id VARCHAR(50) PRIMARY KEY,
    org_id VARCHAR(50) NOT NULL,
    app_id VARCHAR(50) NOT NULL,
    transaction_date TIMESTAMP NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(10) NOT NULL,
    payment_method VARCHAR(50),
    customer_id VARCHAR(50),
    product_id VARCHAR(50),
    quantity INTEGER,
    CONSTRAINT fk_revenue_org FOREIGN KEY (org_id) REFERENCES organizations(org_id),
    CONSTRAINT fk_revenue_app FOREIGN KEY (app_id) REFERENCES applications(app_id)
) COMMENT = 'Revenue and transaction data';

-- Session data table
CREATE TABLE session_data (
    session_id VARCHAR(100) PRIMARY KEY,
    org_id VARCHAR(50) NOT NULL,
    app_id VARCHAR(50) NOT NULL,
    user_id VARCHAR(50),
    session_start TIMESTAMP NOT NULL,
    session_end TIMESTAMP,
    duration_seconds INTEGER,
    page_views INTEGER,
    events_count INTEGER,
    device_type VARCHAR(50),
    browser VARCHAR(50),
    ip_address VARCHAR(50),
    CONSTRAINT fk_session_org FOREIGN KEY (org_id) REFERENCES organizations(org_id),
    CONSTRAINT fk_session_app FOREIGN KEY (app_id) REFERENCES applications(app_id)
) COMMENT = 'User session data';

-- Daily aggregates table
CREATE TABLE daily_aggregates (
    aggregate_id VARCHAR(50) PRIMARY KEY,
    org_id VARCHAR(50) NOT NULL,
    app_id VARCHAR(50) NOT NULL,
    date DATE NOT NULL,
    total_users INTEGER,
    total_sessions INTEGER,
    total_events INTEGER,
    total_revenue DECIMAL(10,2),
    avg_session_duration_seconds INTEGER,
    CONSTRAINT fk_aggregates_org FOREIGN KEY (org_id) REFERENCES organizations(org_id),
    CONSTRAINT fk_aggregates_app FOREIGN KEY (app_id) REFERENCES applications(app_id),
    CONSTRAINT uk_aggregates UNIQUE (org_id, app_id, date)
) COMMENT = 'Daily aggregated metrics';

SELECT '✓ All tables created successfully' as status;

-- ============================================================================
-- INSERT SAMPLE DATA
-- ============================================================================

INSERT INTO organizations (org_id, org_name, industry, tier, created_at, active, country, employee_count)
VALUES
    ('org_123', 'Acme Corporation', 'Technology', 'enterprise', '2023-01-15 10:00:00', TRUE, 'USA', 500),
    ('org_456', 'Global Retail Inc', 'Retail', 'pro', '2023-02-20 14:30:00', TRUE, 'UK', 1200),
    ('org_789', 'FinTech Solutions', 'Finance', 'enterprise', '2023-03-10 09:15:00', TRUE, 'USA', 250),
    ('org_101', 'HealthCare Plus', 'Healthcare', 'pro', '2023-04-05 11:45:00', TRUE, 'Canada', 800),
    ('org_202', 'EduTech Systems', 'Education', 'free', '2023-05-12 16:20:00', TRUE, 'Australia', 50);

INSERT INTO organization_settings (setting_id, org_id, setting_key, setting_value, updated_at, updated_by)
VALUES
    ('set_1', 'org_123', 'data_retention_days', '365', '2024-01-01 10:00:00', 'admin@acme.com'),
    ('set_2', 'org_123', 'timezone', 'America/New_York', '2024-01-01 10:00:00', 'admin@acme.com'),
    ('set_3', 'org_456', 'data_retention_days', '180', '2024-01-02 11:00:00', 'admin@retail.com'),
    ('set_4', 'org_456', 'timezone', 'Europe/London', '2024-01-02 11:00:00', 'admin@retail.com'),
    ('set_5', 'org_789', 'data_retention_days', '730', '2024-01-03 12:00:00', 'admin@fintech.com'),
    ('set_6', 'org_789', 'timezone', 'America/Los_Angeles', '2024-01-03 12:00:00', 'admin@fintech.com');

INSERT INTO organization_billing (billing_id, org_id, billing_period, total_amount, currency, payment_status, payment_date, invoice_url)
VALUES
    ('bill_1', 'org_123', '2024-01', 5000.00, 'USD', 'paid', '2024-01-05 10:00:00', 'https://invoices.com/bill_1'),
    ('bill_2', 'org_456', '2024-01', 2500.00, 'GBP', 'paid', '2024-01-06 11:00:00', 'https://invoices.com/bill_2'),
    ('bill_3', 'org_789', '2024-01', 4500.00, 'USD', 'paid', '2024-01-07 12:00:00', 'https://invoices.com/bill_3'),
    ('bill_4', 'org_123', '2024-02', 5200.00, 'USD', 'pending', NULL, NULL),
    ('bill_5', 'org_456', '2024-02', 2600.00, 'GBP', 'pending', NULL, NULL);

INSERT INTO organization_users (user_id, org_id, email, full_name, role, created_at, last_login, active)
VALUES
    ('user_1', 'org_123', 'john.doe@acme.com', 'John Doe', 'admin', '2023-01-16 10:00:00', '2024-02-01 09:30:00', TRUE),
    ('user_2', 'org_123', 'jane.smith@acme.com', 'Jane Smith', 'developer', '2023-01-17 11:00:00', '2024-02-01 14:20:00', TRUE),
    ('user_3', 'org_123', 'bob.wilson@acme.com', 'Bob Wilson', 'analyst', '2023-01-18 12:00:00', '2024-01-31 16:45:00', TRUE),
    ('user_4', 'org_456', 'alice.brown@retail.com', 'Alice Brown', 'admin', '2023-02-21 10:00:00', '2024-02-01 08:15:00', TRUE),
    ('user_5', 'org_456', 'charlie.davis@retail.com', 'Charlie Davis', 'analyst', '2023-02-22 11:00:00', '2024-01-30 17:30:00', TRUE),
    ('user_6', 'org_789', 'david.lee@fintech.com', 'David Lee', 'admin', '2023-03-11 10:00:00', '2024-02-01 10:00:00', TRUE),
    ('user_7', 'org_101', 'emma.white@healthcare.com', 'Emma White', 'admin', '2023-04-06 10:00:00', '2024-01-29 11:20:00', TRUE),
    ('user_8', 'org_202', 'frank.green@edutech.com', 'Frank Green', 'admin', '2023-05-13 10:00:00', '2024-01-28 15:40:00', TRUE);

INSERT INTO applications (app_id, app_name, app_type, platform, created_at, active, version)
VALUES
    ('app_1', 'E-Commerce Web', 'web', 'web', '2023-01-20 10:00:00', TRUE, '2.5.1'),
    ('app_2', 'Mobile Shopping iOS', 'mobile_ios', 'ios', '2023-01-25 11:00:00', TRUE, '3.2.0'),
    ('app_3', 'Mobile Shopping Android', 'mobile_android', 'android', '2023-01-25 11:30:00', TRUE, '3.1.8'),
    ('app_4', 'Admin Dashboard', 'web', 'web', '2023-02-01 12:00:00', TRUE, '1.8.5'),
    ('app_5', 'Analytics API', 'api', 'api', '2023-02-10 13:00:00', TRUE, '4.0.2'),
    ('app_6', 'Customer Portal', 'web', 'web', '2023-03-01 14:00:00', TRUE, '2.1.0'),
    ('app_7', 'Internal Tools', 'web', 'web', '2023-03-15 15:00:00', TRUE, '1.0.5');

INSERT INTO app_configuration (config_id, app_id, config_key, config_value, environment, updated_at)
VALUES
    ('cfg_1', 'app_1', 'api_endpoint', 'https://api.acme.com/v1', 'production', '2024-01-01 10:00:00'),
    ('cfg_2', 'app_1', 'max_session_timeout', '3600', 'production', '2024-01-01 10:00:00'),
    ('cfg_3', 'app_2', 'api_endpoint', 'https://api.acme.com/mobile/v2', 'production', '2024-01-02 11:00:00'),
    ('cfg_4', 'app_2', 'push_notifications_enabled', 'true', 'production', '2024-01-02 11:00:00'),
    ('cfg_5', 'app_3', 'api_endpoint', 'https://api.acme.com/mobile/v2', 'production', '2024-01-03 12:00:00'),
    ('cfg_6', 'app_4', 'theme', 'dark', 'production', '2024-01-04 13:00:00'),
    ('cfg_7', 'app_5', 'rate_limit_per_minute', '1000', 'production', '2024-01-05 14:00:00');

INSERT INTO app_performance_metrics (metric_id, app_id, metric_date, avg_response_time_ms, error_rate, uptime_percentage, total_requests)
VALUES
    ('met_1', 'app_1', '2024-01-31', 125, 0.15, 99.95, 1500000),
    ('met_2', 'app_2', '2024-01-31', 180, 0.25, 99.90, 850000),
    ('met_3', 'app_3', '2024-01-31', 175, 0.30, 99.88, 920000),
    ('met_4', 'app_4', '2024-01-31', 95, 0.10, 99.99, 250000),
    ('met_5', 'app_5', '2024-01-31', 45, 0.05, 99.99, 5000000),
    ('met_6', 'app_1', '2024-02-01', 130, 0.18, 99.93, 1520000),
    ('met_7', 'app_2', '2024-02-01', 185, 0.28, 99.87, 865000);

INSERT INTO user_app_access (access_id, user_id, org_id, app_id, granted_at, granted_by, access_level, active)
VALUES
    ('acc_1', 'user_1', 'org_123', 'app_1', '2023-01-16 10:00:00', 'system', 'admin', TRUE),
    ('acc_2', 'user_1', 'org_123', 'app_2', '2023-01-16 10:00:00', 'system', 'admin', TRUE),
    ('acc_3', 'user_1', 'org_123', 'app_3', '2023-01-16 10:00:00', 'system', 'admin', TRUE),
    ('acc_4', 'user_1', 'org_123', 'app_4', '2023-01-16 10:00:00', 'system', 'admin', TRUE),
    ('acc_5', 'user_2', 'org_123', 'app_1', '2023-01-17 11:00:00', 'user_1', 'write', TRUE),
    ('acc_6', 'user_2', 'org_123', 'app_2', '2023-01-17 11:00:00', 'user_1', 'write', TRUE),
    ('acc_7', 'user_3', 'org_123', 'app_1', '2023-01-18 12:00:00', 'user_1', 'read', TRUE),
    ('acc_8', 'user_3', 'org_123', 'app_4', '2023-01-18 12:00:00', 'user_1', 'read', TRUE),
    ('acc_9', 'user_4', 'org_456', 'app_1', '2023-02-21 10:00:00', 'system', 'admin', TRUE),
    ('acc_10', 'user_4', 'org_456', 'app_2', '2023-02-21 10:00:00', 'system', 'admin', TRUE),
    ('acc_11', 'user_4', 'org_456', 'app_6', '2023-02-21 10:00:00', 'system', 'admin', TRUE),
    ('acc_12', 'user_5', 'org_456', 'app_1', '2023-02-22 11:00:00', 'user_4', 'read', TRUE),
    ('acc_13', 'user_6', 'org_789', 'app_1', '2023-03-11 10:00:00', 'system', 'admin', TRUE),
    ('acc_14', 'user_6', 'org_789', 'app_5', '2023-03-11 10:00:00', 'system', 'admin', TRUE),
    ('acc_15', 'user_6', 'org_789', 'app_6', '2023-03-11 10:00:00', 'system', 'admin', TRUE);

INSERT INTO analytics_events (event_id, org_id, app_id, event_name, event_timestamp, user_id, session_id, device_type, country, properties)
SELECT 
    column1 as event_id,
    column2 as org_id,
    column3 as app_id,
    column4 as event_name,
    column5::TIMESTAMP as event_timestamp,
    column6 as user_id,
    column7 as session_id,
    column8 as device_type,
    column9 as country,
    PARSE_JSON(column10) as properties
FROM VALUES
    ('evt_1', 'org_123', 'app_1', 'page_view', '2024-01-31 10:00:00', 'user_1', 'sess_001', 'desktop', 'USA', '{"page": "/home", "duration": 45}'),
    ('evt_2', 'org_123', 'app_1', 'button_click', '2024-01-31 10:05:00', 'user_1', 'sess_001', 'desktop', 'USA', '{"button": "checkout", "position": "header"}'),
    ('evt_3', 'org_123', 'app_2', 'app_open', '2024-01-31 11:00:00', 'user_2', 'sess_002', 'mobile', 'USA', '{"version": "3.2.0", "os": "iOS 17"}'),
    ('evt_4', 'org_123', 'app_2', 'purchase', '2024-01-31 11:15:00', 'user_2', 'sess_002', 'mobile', 'USA', '{"amount": 99.99, "currency": "USD", "items": 3}'),
    ('evt_5', 'org_123', 'app_3', 'app_open', '2024-01-31 12:00:00', 'user_3', 'sess_003', 'mobile', 'USA', '{"version": "3.1.8", "os": "Android 14"}'),
    ('evt_6', 'org_456', 'app_1', 'page_view', '2024-01-31 13:00:00', 'user_4', 'sess_004', 'desktop', 'UK', '{"page": "/products", "duration": 120}'),
    ('evt_7', 'org_456', 'app_1', 'search', '2024-01-31 13:05:00', 'user_4', 'sess_004', 'desktop', 'UK', '{"query": "winter jackets", "results": 45}'),
    ('evt_8', 'org_456', 'app_2', 'app_open', '2024-01-31 14:00:00', 'user_5', 'sess_005', 'mobile', 'UK', '{"version": "3.2.0", "os": "iOS 16"}'),
    ('evt_9', 'org_789', 'app_1', 'page_view', '2024-01-31 15:00:00', 'user_6', 'sess_006', 'desktop', 'USA', '{"page": "/dashboard", "duration": 300}'),
    ('evt_10', 'org_789', 'app_5', 'api_call', '2024-01-31 15:30:00', 'user_6', 'sess_007', 'api', 'USA', '{"endpoint": "/v1/analytics", "method": "GET", "status": 200}');

INSERT INTO revenue_data (revenue_id, org_id, app_id, transaction_date, amount, currency, payment_method, customer_id, product_id, quantity)
VALUES
    ('rev_1', 'org_123', 'app_1', '2024-01-31 10:30:00', 149.99, 'USD', 'credit_card', 'cust_001', 'prod_101', 1),
    ('rev_2', 'org_123', 'app_1', '2024-01-31 11:45:00', 299.99, 'USD', 'paypal', 'cust_002', 'prod_102', 2),
    ('rev_3', 'org_123', 'app_2', '2024-01-31 12:15:00', 99.99, 'USD', 'apple_pay', 'cust_003', 'prod_103', 1),
    ('rev_4', 'org_123', 'app_2', '2024-01-31 13:20:00', 199.99, 'USD', 'credit_card', 'cust_004', 'prod_104', 1),
    ('rev_5', 'org_123', 'app_3', '2024-01-31 14:30:00', 79.99, 'USD', 'google_pay', 'cust_005', 'prod_105', 3),
    ('rev_6', 'org_456', 'app_1', '2024-01-31 15:00:00', 249.99, 'GBP', 'credit_card', 'cust_006', 'prod_201', 1),
    ('rev_7', 'org_456', 'app_2', '2024-01-31 16:15:00', 349.99, 'GBP', 'paypal', 'cust_007', 'prod_202', 1),
    ('rev_8', 'org_789', 'app_1', '2024-01-31 17:00:00', 499.99, 'USD', 'credit_card', 'cust_008', 'prod_301', 2),
    ('rev_9', 'org_789', 'app_6', '2024-01-31 18:30:00', 599.99, 'USD', 'wire_transfer', 'cust_009', 'prod_302', 1);

INSERT INTO session_data (session_id, org_id, app_id, user_id, session_start, session_end, duration_seconds, page_views, events_count, device_type, browser, ip_address)
VALUES
    ('sess_001', 'org_123', 'app_1', 'user_1', '2024-01-31 10:00:00', '2024-01-31 10:45:00', 2700, 15, 42, 'desktop', 'Chrome', '192.168.1.1'),
    ('sess_002', 'org_123', 'app_2', 'user_2', '2024-01-31 11:00:00', '2024-01-31 11:30:00', 1800, 8, 25, 'mobile', 'Safari', '192.168.1.2'),
    ('sess_003', 'org_123', 'app_3', 'user_3', '2024-01-31 12:00:00', '2024-01-31 12:20:00', 1200, 5, 18, 'mobile', 'Chrome', '192.168.1.3'),
    ('sess_004', 'org_456', 'app_1', 'user_4', '2024-01-31 13:00:00', '2024-01-31 14:00:00', 3600, 25, 68, 'desktop', 'Firefox', '192.168.2.1'),
    ('sess_005', 'org_456', 'app_2', 'user_5', '2024-01-31 14:00:00', '2024-01-31 14:15:00', 900, 4, 12, 'mobile', 'Safari', '192.168.2.2'),
    ('sess_006', 'org_789', 'app_1', 'user_6', '2024-01-31 15:00:00', '2024-01-31 16:30:00', 5400, 35, 95, 'desktop', 'Chrome', '192.168.3.1'),
    ('sess_007', 'org_789', 'app_5', 'user_6', '2024-01-31 15:30:00', '2024-01-31 15:35:00', 300, 0, 150, 'api', 'N/A', '192.168.3.1');

INSERT INTO daily_aggregates (aggregate_id, org_id, app_id, date, total_users, total_sessions, total_events, total_revenue, avg_session_duration_seconds)
VALUES
    ('agg_1', 'org_123', 'app_1', '2024-01-31', 150, 320, 4500, 2450.75, 1850),
    ('agg_2', 'org_123', 'app_2', '2024-01-31', 200, 450, 6200, 3890.50, 1200),
    ('agg_3', 'org_123', 'app_3', '2024-01-31', 180, 380, 5100, 1250.25, 1100),
    ('agg_4', 'org_456', 'app_1', '2024-01-31', 300, 680, 9500, 5670.80, 2100),
    ('agg_5', 'org_456', 'app_2', '2024-01-31', 250, 520, 7200, 4230.90, 1450),
    ('agg_6', 'org_789', 'app_1', '2024-01-31', 120, 280, 3800, 3450.60, 2400),
    ('agg_7', 'org_789', 'app_5', '2024-01-31', 80, 1500, 25000, 0.00, 180);

SELECT '✓ Sample data inserted successfully' as status;
SELECT '✓ Setup complete - database, tables, and data ready' as status;
