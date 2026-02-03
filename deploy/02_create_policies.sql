-- ============================================================================
-- 02_create_policies.sql
-- Create row access policies (but don't apply them yet)
-- 
-- Variables: <% database_name %>, <% schema_name %>, <% warehouse_name %>
-- ============================================================================
--
-- CRITICAL SECURITY REQUIREMENT:
-- All policies require session context to be set BEFORE querying data.
-- If org_id or app_ids are not set, NO ROWS will be returned.
-- 
-- This is by design to ensure:
-- 1. Multi-tenant isolation is always enforced
-- 2. No accidental data leakage if context is missing
-- 3. Explicit authentication required for all queries
--
-- To set context, use:
--   SET current_user_id = 'user_1';
--   SET current_org_id = 'org_123';
--   SET current_app_ids = '["app_1", "app_2", "app_3"]';
--
-- ============================================================================

USE DATABASE <% database_name %>;
USE SCHEMA <% schema_name %>;
USE WAREHOUSE <% warehouse_name %>;

-- Initialize session variables (required for policy compilation)
SET current_user_id = NULL;
SET current_org_id = NULL;
SET current_app_ids = '[]';

-- ============================================================================
-- ROW ACCESS POLICIES FOR ORG_ID ONLY TABLES
-- ============================================================================
-- IMPORTANT: org_id must be set in session context, otherwise no rows are returned

-- Policy for organizations table  
CREATE ROW ACCESS POLICY policy_organizations
AS (org_id VARCHAR) RETURNS BOOLEAN ->
    org_id = $current_org_id
COMMENT = 'Filter organizations by current user org_id - requires org_id in session';

-- Policy for organization_settings table
CREATE ROW ACCESS POLICY policy_organization_settings
AS (org_id VARCHAR) RETURNS BOOLEAN ->
    org_id = $current_org_id
COMMENT = 'Filter organization settings by current user org_id - requires org_id in session';

-- Policy for organization_billing table
CREATE ROW ACCESS POLICY policy_organization_billing
AS (org_id VARCHAR) RETURNS BOOLEAN ->
    org_id = $current_org_id
COMMENT = 'Filter billing records by current user org_id - requires org_id in session';

-- Policy for organization_users table
CREATE ROW ACCESS POLICY policy_organization_users
AS (org_id VARCHAR) RETURNS BOOLEAN ->
    org_id = $current_org_id
COMMENT = 'Filter users by current user org_id - requires org_id in session';

-- ============================================================================
-- ROW ACCESS POLICIES FOR APP_ID ONLY TABLES
-- ============================================================================
-- IMPORTANT: app_ids must be set in session context, otherwise no rows are returned

-- Policy for applications table
CREATE ROW ACCESS POLICY policy_applications
AS (app_id VARCHAR) RETURNS BOOLEAN ->
    ARRAY_CONTAINS(app_id::VARIANT, PARSE_JSON($current_app_ids))
COMMENT = 'Filter applications by current user accessible app_ids - requires app_ids in session';

-- Policy for app_configuration table
CREATE ROW ACCESS POLICY policy_app_configuration
AS (app_id VARCHAR) RETURNS BOOLEAN ->
    ARRAY_CONTAINS(app_id::VARIANT, PARSE_JSON($current_app_ids))
COMMENT = 'Filter app configuration by current user accessible app_ids - requires app_ids in session';

-- Policy for app_performance_metrics table
CREATE ROW ACCESS POLICY policy_app_performance_metrics
AS (app_id VARCHAR) RETURNS BOOLEAN ->
    ARRAY_CONTAINS(app_id::VARIANT, PARSE_JSON($current_app_ids))
COMMENT = 'Filter app metrics by current user accessible app_ids - requires app_ids in session';

-- ============================================================================
-- ROW ACCESS POLICIES FOR BOTH ORG_ID AND APP_ID TABLES
-- ============================================================================
-- CRITICAL: Both org_id AND app_ids must be set, otherwise NO rows are returned
-- This ensures multi-tenant isolation is always enforced

-- Policy for user_app_access table
CREATE ROW ACCESS POLICY policy_user_app_access
AS (org_id VARCHAR, app_id VARCHAR) RETURNS BOOLEAN ->
    org_id = $current_org_id
    AND ARRAY_CONTAINS(app_id::VARIANT, PARSE_JSON($current_app_ids))
COMMENT = 'Filter user app access by org_id and app_ids - requires both in session';

-- Policy for analytics_events table
CREATE ROW ACCESS POLICY policy_analytics_events
AS (org_id VARCHAR, app_id VARCHAR) RETURNS BOOLEAN ->
    org_id = $current_org_id
    AND ARRAY_CONTAINS(app_id::VARIANT, PARSE_JSON($current_app_ids))
COMMENT = 'Filter analytics events by org_id and app_ids - requires both in session';

-- Policy for revenue_data table
CREATE ROW ACCESS POLICY policy_revenue_data
AS (org_id VARCHAR, app_id VARCHAR) RETURNS BOOLEAN ->
    org_id = $current_org_id
    AND ARRAY_CONTAINS(app_id::VARIANT, PARSE_JSON($current_app_ids))
COMMENT = 'Filter revenue data by org_id and app_ids - requires both in session';

-- Policy for session_data table
CREATE ROW ACCESS POLICY policy_session_data
AS (org_id VARCHAR, app_id VARCHAR) RETURNS BOOLEAN ->
    org_id = $current_org_id
    AND ARRAY_CONTAINS(app_id::VARIANT, PARSE_JSON($current_app_ids))
COMMENT = 'Filter session data by org_id and app_ids - requires both in session';

-- Policy for daily_aggregates table
CREATE ROW ACCESS POLICY policy_daily_aggregates
AS (org_id VARCHAR, app_id VARCHAR) RETURNS BOOLEAN ->
    org_id = $current_org_id
    AND ARRAY_CONTAINS(app_id::VARIANT, PARSE_JSON($current_app_ids))
COMMENT = 'Filter daily aggregates by org_id and app_ids - requires both in session';

-- Display created policies
SHOW ROW ACCESS POLICIES;

SELECT '✓ Row access policies created successfully' as status;
SELECT '  Note: Policies are created but not yet applied to tables' as note;
