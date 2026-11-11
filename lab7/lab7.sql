-- Laboratory Work 7: SQL Views and Roles
-- Full Name: Zheksembaev Erbol | Student ID: 25B031261

-- ============================================================
-- PART 2: Creating Basic Views
-- ============================================================

-- Exercise 2.1: Simple View Creation
CREATE VIEW employee_details AS
SELECT e.emp_name, e.salary, d.dept_name, d.location
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id;

SELECT * FROM employee_details;

-- Exercise 2.2: View with Aggregation
CREATE VIEW dept_statistics AS
SELECT d.dept_name,
       COUNT(e.emp_id)           AS employee_count,
       ROUND(AVG(e.salary), 2)   AS avg_salary,
       MAX(e.salary)             AS max_salary,
       MIN(e.salary)             AS min_salary
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name;

SELECT * FROM dept_statistics
ORDER BY employee_count DESC;

-- Exercise 2.3: View with Multiple Joins
CREATE VIEW project_overview AS
SELECT p.project_name,
       p.budget,
       d.dept_name,
       d.location,
       (SELECT COUNT(*)
        FROM employees e
        WHERE e.dept_id = p.dept_id) AS team_size
FROM projects p
LEFT JOIN departments d ON p.dept_id = d.dept_id;

SELECT * FROM project_overview;

-- Exercise 2.4: View with Filtering
CREATE VIEW high_earners AS
SELECT e.emp_name, e.salary, d.dept_name
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
WHERE e.salary > 55000;

SELECT * FROM high_earners;

-- ============================================================
-- PART 3: Modifying and Managing Views
-- ============================================================

-- Exercise 3.1: Replace a View
CREATE OR REPLACE VIEW employee_details AS
SELECT e.emp_name, e.salary, d.dept_name, d.location,
       CASE
           WHEN e.salary > 60000 THEN 'High'
           WHEN e.salary > 50000 THEN 'Medium'
           ELSE 'Standard'
       END AS salary_grade
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id;

SELECT * FROM employee_details;

-- Exercise 3.2: Rename a View
ALTER VIEW high_earners RENAME TO top_performers;

SELECT * FROM top_performers;

-- Exercise 3.3: Drop a View
CREATE VIEW temp_view AS
SELECT emp_name, salary
FROM employees
WHERE salary < 50000;

SELECT * FROM temp_view;

DROP VIEW temp_view;

-- ============================================================
-- PART 4: Updatable Views
-- ============================================================

-- Exercise 4.1: Create an Updatable View
CREATE VIEW employee_salaries AS
SELECT emp_id, emp_name, dept_id, salary
FROM employees;

SELECT * FROM employee_salaries ORDER BY emp_id;

-- Exercise 4.2: Update Through a View
UPDATE employee_salaries
SET salary = 52000
WHERE emp_name = 'John Smith';

SELECT * FROM employees WHERE emp_name = 'John Smith';

-- Exercise 4.3: Insert Through a View
INSERT INTO employee_salaries (emp_id, emp_name, dept_id, salary)
VALUES (6, 'Alice Johnson', 102, 58000);

SELECT * FROM employees ORDER BY emp_id;

-- Exercise 4.4: View with CHECK OPTION
CREATE VIEW it_employees AS
SELECT emp_id, emp_name, dept_id, salary
FROM employees
WHERE dept_id = 101
WITH LOCAL CHECK OPTION;

-- This should fail with: new row violates check option for view "it_employees"
-- INSERT INTO it_employees (emp_id, emp_name, dept_id, salary)
-- VALUES (7, 'Bob Wilson', 103, 60000);

-- ============================================================
-- PART 5: Materialized Views
-- ============================================================

-- Exercise 5.1: Create a Materialized View
CREATE MATERIALIZED VIEW dept_summary_mv AS
SELECT d.dept_id,
       d.dept_name,
       (SELECT COUNT(*) FROM employees e
         WHERE e.dept_id = d.dept_id)                      AS total_employees,
       COALESCE((SELECT SUM(e.salary) FROM employees e
         WHERE e.dept_id = d.dept_id), 0)                  AS total_salaries,
       (SELECT COUNT(*) FROM projects p
         WHERE p.dept_id = d.dept_id)                      AS total_projects,
       COALESCE((SELECT SUM(p.budget) FROM projects p
         WHERE p.dept_id = d.dept_id), 0)                  AS total_project_budget
FROM departments d
WITH DATA;

SELECT * FROM dept_summary_mv ORDER BY total_employees DESC;

-- Exercise 5.2: Refresh Materialized View
INSERT INTO employees (emp_id, emp_name, dept_id, salary)
VALUES (8, 'Charlie Brown', 101, 54000);

-- Before refresh
SELECT * FROM dept_summary_mv ORDER BY total_employees DESC;

REFRESH MATERIALIZED VIEW dept_summary_mv;

-- After refresh
SELECT * FROM dept_summary_mv ORDER BY total_employees DESC;

-- Exercise 5.3: Concurrent Refresh
CREATE UNIQUE INDEX idx_dept_summary_mv_dept_id
ON dept_summary_mv (dept_id);

REFRESH MATERIALIZED VIEW CONCURRENTLY dept_summary_mv;

SELECT * FROM dept_summary_mv ORDER BY dept_id;

-- Exercise 5.4: Materialized View with NO DATA
CREATE MATERIALIZED VIEW project_stats_mv AS
SELECT p.project_name,
       p.budget,
       d.dept_name,
       (SELECT COUNT(*) FROM employees e
         WHERE e.dept_id = p.dept_id) AS assigned_employees
FROM projects p
LEFT JOIN departments d ON p.dept_id = d.dept_id
WITH NO DATA;

-- Fails with: materialized view "project_stats_mv" has not been populated
-- SELECT * FROM project_stats_mv;

-- Fix: populate the materialized view
REFRESH MATERIALIZED VIEW project_stats_mv;

SELECT * FROM project_stats_mv;

-- ============================================================
-- PART 6: Database Roles
-- ============================================================

-- Exercise 6.1: Create Basic Roles
CREATE ROLE analyst NOLOGIN;
CREATE ROLE data_viewer LOGIN PASSWORD 'viewer123';
CREATE USER report_user PASSWORD 'report456';

SELECT rolname FROM pg_roles WHERE rolname NOT LIKE 'pg_%';

-- Exercise 6.2: Role with Specific Attributes
CREATE ROLE db_creator CREATEDB LOGIN PASSWORD 'creator789';
CREATE ROLE user_manager CREATEROLE LOGIN PASSWORD 'manager101';
CREATE ROLE admin_user SUPERUSER LOGIN PASSWORD 'admin999';

SELECT rolname, rolcanlogin, rolcreatedb, rolcreaterole, rolsuper
FROM pg_roles
WHERE rolname IN ('db_creator', 'user_manager', 'admin_user')
ORDER BY rolname;

-- Exercise 6.3: Grant Privileges to Roles
GRANT SELECT ON employees, departments, projects TO analyst;
GRANT ALL PRIVILEGES ON employee_details TO data_viewer;
GRANT SELECT, INSERT ON employees TO report_user;

SELECT grantee, table_name, privilege_type
FROM information_schema.role_table_grants
WHERE grantee IN ('analyst', 'data_viewer', 'report_user')
ORDER BY grantee, table_name, privilege_type;

-- Exercise 6.4: Create Group Roles
-- 1. Group roles
CREATE ROLE hr_team;
CREATE ROLE finance_team;
CREATE ROLE it_team;

-- 2. Individual users
CREATE USER hr_user1 PASSWORD 'hr001';
CREATE USER hr_user2 PASSWORD 'hr002';
CREATE USER finance_user1 PASSWORD 'fin001';

-- 3. and 4. Assign members to groups
GRANT hr_team TO hr_user1;
GRANT hr_team TO hr_user2;
GRANT finance_team TO finance_user1;

-- 5. Privileges for hr_team
GRANT SELECT, UPDATE ON employees TO hr_team;

-- 6. Privileges for finance_team
GRANT SELECT ON dept_statistics TO finance_team;

-- Verification: group memberships
SELECT r.rolname AS group_role, m.rolname AS member
FROM pg_auth_members am
JOIN pg_roles r ON r.oid = am.roleid
JOIN pg_roles m ON m.oid = am.member
WHERE r.rolname IN ('hr_team', 'finance_team')
ORDER BY group_role, member;

-- Exercise 6.5: Revoke Privileges
REVOKE UPDATE ON employees FROM hr_team;
REVOKE hr_team FROM hr_user2;
REVOKE ALL PRIVILEGES ON employee_details FROM data_viewer;

-- Verification
SELECT r.rolname AS group_role, m.rolname AS member
FROM pg_auth_members am
JOIN pg_roles r ON r.oid = am.roleid
JOIN pg_roles m ON m.oid = am.member
WHERE r.rolname = 'hr_team';

SELECT grantee, table_name, privilege_type
FROM information_schema.role_table_grants
WHERE grantee IN ('hr_team', 'data_viewer')
ORDER BY grantee, privilege_type;

-- Exercise 6.6: Modify Role Attributes
ALTER ROLE analyst WITH LOGIN PASSWORD 'analyst123';
ALTER ROLE user_manager WITH SUPERUSER;
ALTER ROLE analyst WITH PASSWORD NULL;
ALTER ROLE data_viewer WITH CONNECTION LIMIT 5;

-- Verification
SELECT rolname, rolcanlogin, rolsuper, rolconnlimit
FROM pg_roles
WHERE rolname IN ('analyst', 'user_manager', 'data_viewer')
ORDER BY rolname;

-- ============================================================
-- PART 7: Advanced Role Management
-- ============================================================

-- Exercise 7.1: Role Hierarchies
-- 1. Parent role
CREATE ROLE read_only;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO read_only;

-- 2. Child roles
CREATE ROLE junior_analyst LOGIN PASSWORD 'junior123';
CREATE ROLE senior_analyst LOGIN PASSWORD 'senior123';

-- 3. Membership
GRANT read_only TO junior_analyst;
GRANT read_only TO senior_analyst;

-- 4. Additional privileges for senior_analyst only
GRANT INSERT, UPDATE ON employees TO senior_analyst;

-- Verification
SELECT r.rolname AS parent_role, m.rolname AS member
FROM pg_auth_members am
JOIN pg_roles r ON r.oid = am.roleid
JOIN pg_roles m ON m.oid = am.member
WHERE r.rolname = 'read_only'
ORDER BY member;

SELECT grantee, privilege_type
FROM information_schema.role_table_grants
WHERE table_name = 'employees'
  AND grantee IN ('read_only', 'senior_analyst', 'junior_analyst')
ORDER BY grantee, privilege_type;

-- Exercise 7.2: Object Ownership
CREATE ROLE project_manager LOGIN PASSWORD 'pm123';

ALTER VIEW dept_statistics OWNER TO project_manager;
ALTER TABLE projects OWNER TO project_manager;

-- Check ownership of tables
SELECT tablename, tableowner
FROM pg_tables
WHERE schemaname = 'public';

-- Check ownership of the view
SELECT viewname, viewowner
FROM pg_views
WHERE schemaname = 'public' AND viewname = 'dept_statistics';

-- Exercise 7.3: Reassign and Drop Roles
-- 1. Create the role
CREATE ROLE temp_owner LOGIN;

-- 2. Create the table
CREATE TABLE temp_table (id INT);

-- 3. Transfer ownership to temp_owner
ALTER TABLE temp_table OWNER TO temp_owner;

SELECT tablename, tableowner FROM pg_tables WHERE tablename = 'temp_table';

-- 4. Reassign all objects owned by temp_owner to postgres
REASSIGN OWNED BY temp_owner TO postgres;

SELECT tablename, tableowner FROM pg_tables WHERE tablename = 'temp_table';

-- 5. Drop all objects owned by temp_owner
DROP OWNED BY temp_owner;

-- 6. Drop the role
DROP ROLE temp_owner;

SELECT rolname FROM pg_roles WHERE rolname = 'temp_owner';

-- Exercise 7.4: Row-Level Security with Views
-- 1. HR view (HR department only)
CREATE VIEW hr_employee_view AS
SELECT *
FROM employees
WHERE dept_id = 102;

-- 2. Grant to hr_team
GRANT SELECT ON hr_employee_view TO hr_team;

-- 3. Finance view (limited columns, all employees)
CREATE VIEW finance_employee_view AS
SELECT emp_id, emp_name, salary
FROM employees;

-- 4. Grant to finance_team
GRANT SELECT ON finance_employee_view TO finance_team;

SELECT * FROM hr_employee_view;
SELECT * FROM finance_employee_view ORDER BY emp_id;

-- ============================================================
-- PART 8: Practical Scenarios
-- ============================================================

-- Exercise 8.1: Department Dashboard View
CREATE VIEW dept_dashboard AS
SELECT d.dept_name,
       d.location,
       COALESCE(e.emp_count, 0)            AS employee_count,
       COALESCE(ROUND(e.avg_salary, 2), 0) AS avg_salary,
       COALESCE(p.project_count, 0)        AS active_projects,
       COALESCE(p.total_budget, 0)         AS total_project_budget,
       CASE
           WHEN COALESCE(e.emp_count, 0) = 0 THEN 0
           ELSE ROUND(COALESCE(p.total_budget, 0) / e.emp_count, 2)
       END                                 AS budget_per_employee
FROM departments d
LEFT JOIN (SELECT dept_id,
                  COUNT(*)    AS emp_count,
                  AVG(salary) AS avg_salary
           FROM employees
           GROUP BY dept_id) e ON d.dept_id = e.dept_id
LEFT JOIN (SELECT dept_id,
                  COUNT(*)    AS project_count,
                  SUM(budget) AS total_budget
           FROM projects
           GROUP BY dept_id) p ON d.dept_id = p.dept_id;

SELECT * FROM dept_dashboard ORDER BY dept_name;

-- Exercise 8.2: Audit View
-- 1. Add created_date column
ALTER TABLE projects
ADD COLUMN created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

-- 2-4. Audit view
CREATE VIEW high_budget_projects AS
SELECT p.project_name,
       p.budget,
       d.dept_name,
       p.created_date,
       CASE
           WHEN p.budget > 150000 THEN 'Critical Review Required'
           WHEN p.budget > 100000 THEN 'Management Approval Needed'
           ELSE 'Standard Process'
       END AS approval_status
FROM projects p
LEFT JOIN departments d ON p.dept_id = d.dept_id
WHERE p.budget > 75000;

SELECT project_name, budget, dept_name, approval_status
FROM high_budget_projects;

-- Exercise 8.3: Create Access Control System
-- Level 1 - Viewer
CREATE ROLE viewer_role;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO viewer_role;

-- Level 2 - Entry
CREATE ROLE entry_role;
GRANT viewer_role TO entry_role;
GRANT INSERT ON employees, projects TO entry_role;

-- Level 3 - Analyst
CREATE ROLE analyst_role;
GRANT entry_role TO analyst_role;
GRANT UPDATE ON employees, projects TO analyst_role;

-- Level 4 - Manager
CREATE ROLE manager_role;
GRANT analyst_role TO manager_role;
GRANT DELETE ON employees, projects TO manager_role;

-- Users
CREATE USER alice PASSWORD 'alice123';
CREATE USER bob PASSWORD 'bob123';
CREATE USER charlie PASSWORD 'charlie123';

GRANT viewer_role TO alice;
GRANT analyst_role TO bob;
GRANT manager_role TO charlie;

-- Verification: role hierarchy
SELECT r.rolname AS role, m.rolname AS member
FROM pg_auth_members am
JOIN pg_roles r ON r.oid = am.roleid
JOIN pg_roles m ON m.oid = am.member
WHERE r.rolname LIKE '%\_role' OR m.rolname IN ('alice', 'bob', 'charlie')
ORDER BY role, member;
