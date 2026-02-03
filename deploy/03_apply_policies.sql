-- ============================================================================
-- 03_apply_policies.sql
-- Apply row access policies to tables
-- 
-- Variables: <% database_name %>, <% schema_name %>, <% warehouse_name %>
-- ============================================================================

USE DATABASE <% database_name %>;
USE SCHEMA <% schema_name %>;
USE WAREHOUSE <% warehouse_name %>;

-- Initialize session variables (required for policy application)
SET current_user_id = NULL;
SET current_org_id = NULL;
SET current_app_ids = '[]';

-- ============================================================================
-- APPLY POLICIES TO ORG_ID ONLY TABLES
-- ============================================================================

-- Apply policy to organizations table
ALTER TABLE organizations 
    ADD ROW ACCESS POLICY policy_organizations 
    ON (org_id);

SELECT '✓ Applied policy to organizations' as status;

-- Apply policy to organization_settings table
ALTER TABLE organization_settings 
    ADD ROW ACCESS POLICY policy_organization_settings 
    ON (org_id);

SELECT '✓ Applied policy to organization_settings' as status;

-- Apply policy to organization_billing table
ALTER TABLE organization_billing 
    ADD ROW ACCESS POLICY policy_organization_billing 
    ON (org_id);

SELECT '✓ Applied policy to organization_billing' as status;

-- Apply policy to organization_users table
ALTER TABLE organization_users 
    ADD ROW ACCESS POLICY policy_organization_users 
    ON (org_id);

SELECT '✓ Applied policy to organization_users' as status;

-- ============================================================================
-- APPLY POLICIES TO APP_ID ONLY TABLES
-- ============================================================================

-- Apply policy to applications table
ALTER TABLE applications 
    ADD ROW ACCESS POLICY policy_applications 
    ON (app_id);

SELECT '✓ Applied policy to applications' as status;

-- Apply policy to app_configuration table
ALTER TABLE app_configuration 
    ADD ROW ACCESS POLICY policy_app_configuration 
    ON (app_id);

SELECT '✓ Applied policy to app_configuration' as status;

-- Apply policy to app_performance_metrics table
ALTER TABLE app_performance_metrics 
    ADD ROW ACCESS POLICY policy_app_performance_metrics 
    ON (app_id);

SELECT '✓ Applied policy to app_performance_metrics' as status;

-- ============================================================================
-- APPLY POLICIES TO BOTH ORG_ID AND APP_ID TABLES
-- ============================================================================

-- Apply policy to user_app_access table
ALTER TABLE user_app_access 
    ADD ROW ACCESS POLICY policy_user_app_access 
    ON (org_id, app_id);

SELECT '✓ Applied policy to user_app_access' as status;

-- Apply policy to analytics_events table
ALTER TABLE analytics_events 
    ADD ROW ACCESS POLICY policy_analytics_events 
    ON (org_id, app_id);

SELECT '✓ Applied policy to analytics_events' as status;

-- Apply policy to revenue_data table
ALTER TABLE revenue_data 
    ADD ROW ACCESS POLICY policy_revenue_data 
    ON (org_id, app_id);

SELECT '✓ Applied policy to revenue_data' as status;

-- Apply policy to session_data table
ALTER TABLE session_data 
    ADD ROW ACCESS POLICY policy_session_data 
    ON (org_id, app_id);

SELECT '✓ Applied policy to session_data' as status;

-- Apply policy to daily_aggregates table
ALTER TABLE daily_aggregates 
    ADD ROW ACCESS POLICY policy_daily_aggregates 
    ON (org_id, app_id);

SELECT '✓ Applied policy to daily_aggregates' as status;

-- ============================================================================
-- VERIFY POLICY APPLICATION
-- ============================================================================

-- Show all row access policies
SHOW ROW ACCESS POLICIES;

SELECT '✓ All row access policies applied successfully' as status;
