-- ============================================================================
-- rollback.sql
-- Rollback/cleanup script to remove all deployed objects
-- 
-- Variables: <% database_name %>, <% schema_name %>, <% warehouse_name %>
-- ============================================================================

-- WARNING: This script will delete ALL data and objects created by the deployment
-- Use with caution!

USE DATABASE <% database_name %>;
USE SCHEMA <% schema_name %>;
USE WAREHOUSE <% warehouse_name %>;

SELECT '============================================================================' as separator;
SELECT 'ROLLBACK: Removing all deployed objects' as title;
SELECT '============================================================================' as separator;

-- ============================================================================
-- STEP 1: Remove row access policies from tables
-- ============================================================================

SELECT '--- Removing row access policies from tables ---' as step;

-- Remove policies from org_id only tables
ALTER TABLE IF EXISTS organizations DROP ROW ACCESS POLICY policy_organizations;
ALTER TABLE IF EXISTS organization_settings DROP ROW ACCESS POLICY policy_organization_settings;
ALTER TABLE IF EXISTS organization_billing DROP ROW ACCESS POLICY policy_organization_billing;
ALTER TABLE IF EXISTS organization_users DROP ROW ACCESS POLICY policy_organization_users;

-- Remove policies from app_id only tables
ALTER TABLE IF EXISTS applications DROP ROW ACCESS POLICY policy_applications;
ALTER TABLE IF EXISTS app_configuration DROP ROW ACCESS POLICY policy_app_configuration;
ALTER TABLE IF EXISTS app_performance_metrics DROP ROW ACCESS POLICY policy_app_performance_metrics;

-- Remove policies from both org_id and app_id tables
ALTER TABLE IF EXISTS user_app_access DROP ROW ACCESS POLICY policy_user_app_access;
ALTER TABLE IF EXISTS analytics_events DROP ROW ACCESS POLICY policy_analytics_events;
ALTER TABLE IF EXISTS revenue_data DROP ROW ACCESS POLICY policy_revenue_data;
ALTER TABLE IF EXISTS session_data DROP ROW ACCESS POLICY policy_session_data;
ALTER TABLE IF EXISTS daily_aggregates DROP ROW ACCESS POLICY policy_daily_aggregates;

SELECT '✓ Row access policies removed from tables' as status;

-- ============================================================================
-- STEP 2: Drop row access policies
-- ============================================================================

SELECT '--- Dropping row access policies ---' as step;

DROP ROW ACCESS POLICY IF EXISTS policy_organizations;
DROP ROW ACCESS POLICY IF EXISTS policy_organization_settings;
DROP ROW ACCESS POLICY IF EXISTS policy_organization_billing;
DROP ROW ACCESS POLICY IF EXISTS policy_organization_users;
DROP ROW ACCESS POLICY IF EXISTS policy_applications;
DROP ROW ACCESS POLICY IF EXISTS policy_app_configuration;
DROP ROW ACCESS POLICY IF EXISTS policy_app_performance_metrics;
DROP ROW ACCESS POLICY IF EXISTS policy_user_app_access;
DROP ROW ACCESS POLICY IF EXISTS policy_analytics_events;
DROP ROW ACCESS POLICY IF EXISTS policy_revenue_data;
DROP ROW ACCESS POLICY IF EXISTS policy_session_data;
DROP ROW ACCESS POLICY IF EXISTS policy_daily_aggregates;

SELECT '✓ Row access policies dropped' as status;

-- ============================================================================
-- STEP 3: Drop views
-- ============================================================================

SELECT '--- Dropping views ---' as step;

DROP VIEW IF EXISTS v_user_access_summary;
DROP VIEW IF EXISTS v_org_app_analytics;
DROP VIEW IF EXISTS v_recent_events_summary;
DROP VIEW IF EXISTS v_revenue_summary;
DROP VIEW IF EXISTS v_app_performance_overview;

SELECT '✓ Views dropped' as status;

-- ============================================================================
-- STEP 4: Drop procedures
-- ============================================================================

SELECT '--- Dropping procedures ---' as step;

DROP PROCEDURE IF EXISTS set_user_session_context(VARCHAR, VARCHAR, ARRAY);
DROP PROCEDURE IF EXISTS get_user_context(VARCHAR);
DROP PROCEDURE IF EXISTS authenticate_and_setup_context(VARCHAR);

SELECT '✓ Procedures dropped' as status;

-- ============================================================================
-- STEP 5: Drop functions
-- ============================================================================

SELECT '--- Dropping functions ---' as step;

DROP FUNCTION IF EXISTS CURRENT_USER_ID();
DROP FUNCTION IF EXISTS CURRENT_ORG_ID();
DROP FUNCTION IF EXISTS CURRENT_APP_IDS();

SELECT '✓ Functions dropped' as status;

-- ============================================================================
-- STEP 6: Drop tables (in reverse dependency order)
-- ============================================================================

SELECT '--- Dropping tables ---' as step;

-- Drop tables with foreign keys first
DROP TABLE IF EXISTS daily_aggregates;
DROP TABLE IF EXISTS session_data;
DROP TABLE IF EXISTS revenue_data;
DROP TABLE IF EXISTS analytics_events;
DROP TABLE IF EXISTS user_app_access;
DROP TABLE IF EXISTS app_performance_metrics;
DROP TABLE IF EXISTS app_configuration;
DROP TABLE IF EXISTS organization_billing;
DROP TABLE IF EXISTS organization_settings;
DROP TABLE IF EXISTS organization_users;

-- Drop reference tables
DROP TABLE IF EXISTS applications;
DROP TABLE IF EXISTS organizations;

SELECT '✓ Tables dropped' as status;

-- ============================================================================
-- STEP 7: Drop schema and database (optional)
-- ============================================================================

SELECT '--- Dropping schema and database (commented out for safety) ---' as step;

-- Uncomment the following lines to completely remove the database
-- USE DATABASE SNOWFLAKE;
-- DROP SCHEMA IF EXISTS <% database_name %>.<% schema_name %> CASCADE;
-- DROP DATABASE IF EXISTS <% database_name %> CASCADE;
-- DROP WAREHOUSE IF EXISTS <% warehouse_name %>;

SELECT '✓ Schema and database NOT dropped (uncomment to remove)' as status;

-- ============================================================================
-- SUMMARY
-- ============================================================================

SELECT '============================================================================' as separator;
SELECT 'ROLLBACK COMPLETE' as status;
SELECT '============================================================================' as separator;

SELECT '
Removed:
✓ 12 row access policies (removed from tables and dropped)
✓ 5 views
✓ 3 stored procedures
✓ 3 functions
✓ 12 tables with all data
✓ All indexes (dropped with tables)

NOT Removed (for safety):
- Schema
- Database
- Warehouse

To completely remove the database, uncomment the DROP DATABASE command in this script.

To redeploy, run: ./deploy.sh
' as summary;
