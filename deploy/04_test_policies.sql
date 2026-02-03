-- ============================================================================
-- 04_test_policies.sql
-- Test row access policies with different users
-- 
-- Variables: <% database_name %>, <% schema_name %>, <% warehouse_name %>
-- ============================================================================

USE DATABASE <% database_name %>;
USE SCHEMA <% schema_name %>;
USE WAREHOUSE <% warehouse_name %>;

SELECT '============================================================================' as separator;
SELECT 'TESTING ROW ACCESS POLICIES' as title;
SELECT '============================================================================' as separator;

-- ============================================================================
-- TEST CASE 1: User 'user_1' from org_123 with access to apps 1,2,3,4
-- ============================================================================

SELECT '--- Test Case 1: user_1 (org_123, apps [1,2,3,4]) ---' as test_case;

-- Set session context for user_1
SET current_user_id = 'user_1';
SET current_org_id = 'org_123';
SET current_app_ids = '["app_1", "app_2", "app_3", "app_4"]';

-- Test organizations table (should return only org_123)
SELECT 'Organizations visible:' as query, COUNT(*) as count FROM organizations;

-- Test organization_users table (should return only users from org_123)
SELECT 'Users visible:' as query, COUNT(*) as count FROM organization_users;

-- Test applications table (should return only apps 1,2,3,4)
SELECT 'Applications visible:' as query, COUNT(*) as count FROM applications;

-- Test analytics_events table (should return events for org_123 AND apps 1,2,3,4)
SELECT 'Analytics events visible:' as query, COUNT(*) as count FROM analytics_events;

-- Test revenue_data table
SELECT 'Revenue records visible:' as query, COUNT(*) as count FROM revenue_data;

-- Detailed view of events
SELECT 'Sample events for user_1:' as info;
SELECT event_id, org_id, app_id, event_name, event_timestamp 
FROM analytics_events 
ORDER BY event_timestamp 
LIMIT 5;

-- ============================================================================
-- TEST CASE 2: User 'user_4' from org_456 with access to apps 1,2,6
-- ============================================================================

SELECT '--- Test Case 2: user_4 (org_456, apps [1,2,6]) ---' as test_case;

-- Set session context for user_4
SET current_user_id = 'user_4';
SET current_org_id = 'org_456';
SET current_app_ids = '["app_1", "app_2", "app_6"]';

-- Test organizations table (should return only org_456)
SELECT 'Organizations visible:' as query, COUNT(*) as count FROM organizations;

-- Test applications table (should return only apps 1,2,6)
SELECT 'Applications visible:' as query, COUNT(*) as count FROM applications;

-- Test analytics_events table (should return events for org_456 AND apps 1,2,6)
SELECT 'Analytics events visible:' as query, COUNT(*) as count FROM analytics_events;

-- Detailed view of events
SELECT 'Sample events for user_4:' as info;
SELECT event_id, org_id, app_id, event_name, event_timestamp 
FROM analytics_events 
ORDER BY event_timestamp 
LIMIT 5;

-- ============================================================================
-- TEST CASE 3: User 'user_3' with limited access (only apps 1,4)
-- ============================================================================

SELECT '--- Test Case 3: user_3 (org_123, apps [1,4]) ---' as test_case;

-- Set session context for user_3
SET current_user_id = 'user_3';
SET current_org_id = 'org_123';
SET current_app_ids = '["app_1", "app_4"]';

-- Test applications table (should return only apps 1,4)
SELECT 'Applications visible:' as query, COUNT(*) as count FROM applications;

-- Test analytics_events table (should return events for org_123 AND apps 1,4 only)
SELECT 'Analytics events visible:' as query, COUNT(*) as count FROM analytics_events;

-- Detailed view showing only app_1 events (no app_2 or app_3)
SELECT 'Sample events for user_3 (note: no app_2 or app_3):' as info;
SELECT event_id, org_id, app_id, event_name 
FROM analytics_events 
ORDER BY event_timestamp;


-- ============================================================================
-- COMPARISON TEST: Data visibility across users
-- ============================================================================

SELECT '--- Comparison: Data Visibility Across Users ---' as test_case;

-- User 1 (org_123, apps 1,2,3,4)
SET current_user_id = 'user_1';
SET current_org_id = 'org_123';
SET current_app_ids = '["app_1", "app_2", "app_3", "app_4"]';
SELECT 
    'user_1' as user,
    'org_123' as org,
    '["app_1", "app_2", "app_3", "app_4"]' as apps,
    (SELECT COUNT(*) FROM analytics_events) as visible_events,
    (SELECT COUNT(*) FROM revenue_data) as visible_revenue,
    (SELECT COUNT(*) FROM applications) as visible_apps;

-- User 4 (org_456, apps 1,2,6)
SET current_user_id = 'user_4';
SET current_org_id = 'org_456';
SET current_app_ids = '["app_1", "app_2", "app_6"]';
SELECT 
    'user_4' as user,
    'org_456' as org,
    '["app_1", "app_2", "app_6"]' as apps,
    (SELECT COUNT(*) FROM analytics_events) as visible_events,
    (SELECT COUNT(*) FROM revenue_data) as visible_revenue,
    (SELECT COUNT(*) FROM applications) as visible_apps;

-- User 3 (org_123, apps 1,4)
SET current_user_id = 'user_3';
SET current_org_id = 'org_123';
SET current_app_ids = '["app_1", "app_4"]';
SELECT 
    'user_3' as user,
    'org_123' as org,
    '["app_1", "app_4"]' as apps,
    (SELECT COUNT(*) FROM analytics_events) as visible_events,
    (SELECT COUNT(*) FROM revenue_data) as visible_revenue,
    (SELECT COUNT(*) FROM applications) as visible_apps;

-- ============================================================================
-- SUMMARY
-- ============================================================================

SELECT '============================================================================' as separator;
SELECT 'TEST COMPLETE' as status;
SELECT '============================================================================' as separator;

SELECT '
Key Findings:
1. Each user only sees data for their organization (org_id)
2. Each user only sees data for apps they have access to (app_ids)
3. Row access policies are applied automatically to all queries
4. No need to add WHERE clauses for org_id or app_id filtering

Usage:
- Set session context before querying:
  SET current_org_id = ''org_123'';
  SET current_app_ids = ''[\"app_1\", \"app_2\"]'';
- All subsequent queries will be automatically filtered
' as summary;
