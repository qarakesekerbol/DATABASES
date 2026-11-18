-- Laboratory Work 8: SQL Indexes
-- Full Name: Zheksembaev Erbol | Student ID: 25B031261

-- ============================================================
-- Part 1: Database Setup
-- ============================================================

CREATE TABLE departments (
    dept_id   INT PRIMARY KEY,
    dept_name VARCHAR(50),
    location  VARCHAR(50)
);
CREATE TABLE employees (
    emp_id   INT PRIMARY KEY,
    emp_name VARCHAR(100),
    dept_id  INT,
    salary   DECIMAL(10,2),
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);
CREATE TABLE projects (
    proj_id   INT PRIMARY KEY,
    proj_name VARCHAR(100),
    budget    DECIMAL(12,2),
    dept_id   INT,
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

INSERT INTO departments VALUES
    (101, 'IT', 'Building A'),
    (102, 'HR', 'Building B'),
    (103, 'Operations', 'Building C');
INSERT INTO employees VALUES
    (1, 'John Smith', 101, 50000),
    (2, 'Jane Doe', 101, 55000),
    (3, 'Mike Johnson', 102, 48000),
    (4, 'Sarah Williams', 102, 52000),
    (5, 'Tom Brown', 103, 60000);
INSERT INTO projects VALUES
    (201, 'Website Redesign', 75000, 101),
    (202, 'Database Migration', 120000, 101),
    (203, 'HR System Upgrade', 50000, 102);

-- ============================================================
-- PART 2: CREATING BASIC INDEXES
-- ============================================================

-- Exercise 2.1: Create a Simple B-tree Index
CREATE INDEX emp_salary_idx ON employees(salary);

-- List all indexes on employees table
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'employees';

-- Answer: Two indexes exist on the employees table: employees_pkey (created automatically
-- by the PRIMARY KEY) and emp_salary_idx (created manually).

-- Exercise 2.2: Create an Index on a Foreign Key
CREATE INDEX emp_dept_idx ON employees(dept_id);

-- This query should use the index
SELECT * FROM employees WHERE dept_id = 101;

-- Answer: PostgreSQL does not create an index on a foreign key column automatically. An
-- index on a foreign key makes JOINs on that column faster and makes lookups of child rows
-- fast (for example, finding all employees of a department). It also speeds up the checks
-- that PostgreSQL does on the child table when a row in the parent table is deleted or
-- updated; without the index it has to scan the whole child table.

-- Exercise 2.3: View Index Information
-- View all indexes in your database
SELECT tablename, indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- Answer: Indexes seen: departments_pkey, emp_dept_idx, emp_salary_idx, employees_pkey and
-- projects_pkey. The automatically created ones are departments_pkey, employees_pkey and
-- projects_pkey (from the PRIMARY KEY constraints). emp_dept_idx and emp_salary_idx were
-- created manually.

-- ============================================================
-- PART 3: MULTICOLUMN INDEXES
-- ============================================================

-- Exercise 3.1: Create a Multicolumn Index
CREATE INDEX emp_dept_salary_idx ON employees(dept_id, salary);

-- This query can use the multicolumn index
SELECT emp_name, salary
FROM employees
WHERE dept_id = 101 AND salary > 52000;

-- Answer: No, it would normally not be useful for a query that filters only by salary. A
-- multicolumn B-tree index is sorted by the first column (dept_id) and then by the second
-- (salary) inside each dept_id group. It works well when the query uses the leftmost
-- column(s). A filter only on salary cannot use that sort order efficiently, so a separate
-- index on salary is needed.

-- Exercise 3.2: Understanding Column Order
CREATE INDEX emp_salary_dept_idx ON employees(salary, dept_id);

-- Query 1: Filters by dept_id first
SELECT * FROM employees WHERE dept_id = 102 AND salary > 50000;

-- Query 2: Filters by salary first
SELECT * FROM employees WHERE salary > 50000 AND dept_id = 102;

-- Answer: Yes, the order of columns matters. The index (dept_id, salary) is best for
-- queries with an equality condition on dept_id and a range condition on salary, and it
-- can also serve queries that filter only by dept_id. The index (salary, dept_id) is best
-- when salary is the main filter (or sort column) and can serve queries that filter only
-- by salary. The order of the conditions inside WHERE does not matter: Query 1 and Query 2
-- are the same for the planner and return the same result.

-- ============================================================
-- PART 4: UNIQUE INDEXES
-- ============================================================

-- Exercise 4.1: Create a Unique Index
ALTER TABLE employees ADD COLUMN email VARCHAR(100);
UPDATE employees SET email = 'john.smith@company.com' WHERE emp_id = 1;
UPDATE employees SET email = 'jane.doe@company.com' WHERE emp_id = 2;
UPDATE employees SET email = 'mike.johnson@company.com' WHERE emp_id = 3;
UPDATE employees SET email = 'sarah.williams@company.com' WHERE emp_id = 4;
UPDATE employees SET email = 'tom.brown@company.com' WHERE emp_id = 5;

CREATE UNIQUE INDEX emp_email_unique_idx ON employees(email);

-- This should fail with a unique violation error
-- INSERT INTO employees (emp_id, emp_name, dept_id, salary, email)
-- VALUES (6, 'New Employee', 101, 55000, 'john.smith@company.com');

-- Answer: Error message: ERROR: duplicate key value violates unique constraint
-- "emp_email_unique_idx" (DETAIL: Key (email)=(john.smith@company.com) already exists.)

-- Exercise 4.2: Unique Index vs UNIQUE Constraint
-- Add a phone column with UNIQUE constraint
ALTER TABLE employees ADD COLUMN phone VARCHAR(20) UNIQUE;

SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'employees' AND indexname LIKE '%phone%';

-- Answer: Yes, PostgreSQL automatically created an index named employees_phone_key. It is
-- a UNIQUE B-tree index, because a UNIQUE constraint is implemented with a unique index.

-- ============================================================
-- PART 5: INDEXES AND SORTING
-- ============================================================

-- Exercise 5.1: Create an Index for Sorting
CREATE INDEX emp_salary_desc_idx ON employees(salary DESC);

SELECT emp_name, salary
FROM employees
ORDER BY salary DESC;

-- Answer: A B-tree index stores its entries already sorted. With an index on salary DESC,
-- PostgreSQL can read the rows in that order directly (index scan) and does not need a
-- separate sort step, which is faster on large tables.

-- Exercise 5.2: Index with NULL Handling
CREATE INDEX proj_budget_nulls_first_idx ON projects(budget NULLS FIRST);

SELECT proj_name, budget
FROM projects
ORDER BY budget NULLS FIRST;

-- Answer: By default, ascending order places NULL values last. This index stores NULLs
-- first, so it matches ORDER BY budget NULLS FIRST and PostgreSQL can return the rows in
-- order without sorting.

-- ============================================================
-- PART 6: INDEXES ON EXPRESSIONS
-- ============================================================

-- Exercise 6.1: Create a Function-Based Index
CREATE INDEX emp_name_lower_idx ON employees(LOWER(emp_name));

-- This query can use the expression index
SELECT * FROM employees WHERE LOWER(emp_name) = 'john smith';

-- Answer: Without the index, PostgreSQL scans the whole table (Seq Scan), applies
-- LOWER(emp_name) to every row and compares the result with 'john smith'. A normal index
-- on emp_name cannot be used for this condition because the query searches on the
-- expression LOWER(emp_name), not on the column itself.

-- Exercise 6.2: Index on Calculated Values
ALTER TABLE employees ADD COLUMN hire_date DATE;
UPDATE employees SET hire_date = '2020-01-15' WHERE emp_id = 1;
UPDATE employees SET hire_date = '2019-06-20' WHERE emp_id = 2;
UPDATE employees SET hire_date = '2021-03-10' WHERE emp_id = 3;
UPDATE employees SET hire_date = '2020-11-05' WHERE emp_id = 4;
UPDATE employees SET hire_date = '2018-08-25' WHERE emp_id = 5;

-- Create index on the year extracted from hire_date
CREATE INDEX emp_hire_year_idx ON employees(EXTRACT(YEAR FROM hire_date));

SELECT emp_name, hire_date
FROM employees
WHERE EXTRACT(YEAR FROM hire_date) = 2020;

-- ============================================================
-- PART 7: MANAGING INDEXES
-- ============================================================

-- Exercise 7.1: Rename an Index
ALTER INDEX emp_salary_idx RENAME TO employees_salary_index;

SELECT indexname FROM pg_indexes WHERE tablename = 'employees' ORDER BY indexname;

-- Exercise 7.2: Drop Unused Indexes
DROP INDEX emp_salary_dept_idx;

-- Answer: Reasons to drop an index: it is redundant or duplicates another index (here
-- (salary, dept_id) overlaps with the other salary indexes), it is rarely or never used,
-- it slows down INSERT/UPDATE/DELETE (every index must be updated), and it takes disk
-- space and maintenance time.

-- Exercise 7.3: Reindex
REINDEX INDEX employees_salary_index;

-- Answer: REINDEX rebuilds the index from scratch. It is useful after bulk INSERT
-- operations, when the index is bloated, and after significant data modifications.

-- ============================================================
-- PART 8: PRACTICAL SCENARIOS
-- ============================================================

-- Exercise 8.1: Optimize a Slow Query
-- Index for the WHERE clause
CREATE INDEX emp_salary_filter_idx ON employees(salary) WHERE salary > 50000;
-- Index for the JOIN: already created (emp_dept_idx)
-- Index for ORDER BY: already created (emp_salary_desc_idx)

SELECT e.emp_name, e.salary, d.dept_name
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
WHERE e.salary > 50000
ORDER BY e.salary DESC;

-- Answer: The three indexes cover the query: emp_salary_filter_idx for the WHERE condition
-- (salary > 50000), emp_dept_idx for the JOIN on dept_id and emp_salary_desc_idx for ORDER
-- BY salary DESC.

-- Exercise 8.2: Partial Index
CREATE INDEX proj_high_budget_idx ON projects(budget)
WHERE budget > 80000;

SELECT proj_name, budget
FROM projects
WHERE budget > 80000;

-- Answer: A partial index contains only the rows that satisfy its condition (budget >
-- 80000). It is smaller, uses less disk space, is faster to scan and cheaper to maintain,
-- because only the matching rows cause index updates on INSERT/UPDATE/DELETE.

-- Exercise 8.3: Analyze Index Usage
EXPLAIN SELECT * FROM employees WHERE salary > 52000;

-- Extra: the tables are tiny, so force the planner to show the index plan
SET enable_seqscan = off;
EXPLAIN SELECT * FROM employees WHERE salary > 52000;
RESET enable_seqscan;

-- Answer: The first plan shows a Seq Scan. The employees table has only 5 rows (one page),
-- so reading the whole table is cheaper than using an index, and the planner chooses the
-- plan with the lowest estimated cost. With enable_seqscan = off, the plan shows an Index
-- Scan using emp_salary_desc_idx, which proves that the index can be used. It means that
-- having an index does not guarantee its use: on small tables or when the query returns a
-- large part of the table, a sequential scan is chosen.

-- ============================================================
-- PART 9: INDEX TYPES COMPARISON
-- ============================================================

-- Exercise 9.1: Create a Hash Index
CREATE INDEX dept_name_hash_idx ON departments USING HASH (dept_name);

SELECT * FROM departments WHERE dept_name = 'IT';

-- Answer: Use a HASH index when you only need equality comparisons (=) on a column. A
-- B-tree index supports equality, range queries (<, >, BETWEEN), sorting and prefix
-- searches, so it is the better choice in most cases. Hash indexes cannot be used for
-- ranges or ORDER BY.

-- Exercise 9.2: Compare Index Types
-- B-tree index
CREATE INDEX proj_name_btree_idx ON projects(proj_name);
-- Hash index
CREATE INDEX proj_name_hash_idx ON projects USING HASH (proj_name);

-- Equality search (both can be used)
SELECT * FROM projects WHERE proj_name = 'Website Redesign';

-- Range search (only B-tree can be used)
SELECT * FROM projects WHERE proj_name > 'Database';

-- Answer: Equality search: both indexes can be used. Range search (proj_name >
-- 'Database'): only the B-tree index can be used, because a hash index supports only the =
-- operator. (Here the tiny table is scanned sequentially anyway.)

-- ============================================================
-- PART 10: CLEANUP AND BEST PRACTICES
-- ============================================================

-- Exercise 10.1: Review All Indexes
SELECT schemaname, tablename, indexname,
       pg_size_pretty(pg_relation_size(indexname::regclass)) AS index_size
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- Answer: The largest indexes are the two hash indexes, dept_name_hash_idx and
-- proj_name_hash_idx (32 kB each, while the B-tree indexes are 16 kB). A hash index
-- allocates a metapage, a bitmap page and bucket pages up front, so its minimum size is
-- larger than that of a small B-tree index. All tables here are tiny, so the sizes are
-- only the minimum sizes.

-- Exercise 10.2: Drop Unnecessary Indexes
-- Drop the duplicate index
DROP INDEX IF EXISTS proj_name_hash_idx;

-- Answer: proj_name_hash_idx duplicates proj_name_btree_idx (the B-tree index handles
-- equality and range searches), so it is dropped.

-- Exercise 10.3: Document Your Indexes
CREATE VIEW index_documentation AS
SELECT tablename,
       indexname,
       indexdef,
       'Improves salary-based queries' AS purpose
FROM pg_indexes
WHERE schemaname = 'public'
  AND indexname LIKE '%salary%';

SELECT * FROM index_documentation;

-- Answer: The view lists the custom indexes whose name contains 'salary'.

-- ============================================================
-- ADDITIONAL CHALLENGES (OPTIONAL)
-- ============================================================

-- Challenge 1: Index for finding employees hired in a specific month
CREATE INDEX emp_hire_month_idx ON employees(EXTRACT(MONTH FROM hire_date));

SELECT emp_name, hire_date
FROM employees
WHERE EXTRACT(MONTH FROM hire_date) = 6;

-- Answer: An expression index on EXTRACT(MONTH FROM hire_date) lets PostgreSQL find the
-- employees hired in a given month without scanning the whole table.

-- Challenge 2: Composite unique index on dept_id and email
CREATE UNIQUE INDEX emp_dept_email_unique_idx ON employees(dept_id, email);

-- Answer: The composite unique index guarantees that the same email cannot be used twice
-- inside the same department.

-- Challenge 3: EXPLAIN ANALYZE with and without an index (on a large test table)
CREATE TABLE big_employees AS
SELECT g AS emp_id,
       'Employee ' || g AS emp_name,
       (g % 3) + 101 AS dept_id,
       30000 + (g % 50000) AS salary
FROM generate_series(1, 500000) AS g;
ANALYZE big_employees;

-- Without an index
EXPLAIN ANALYZE SELECT * FROM big_employees WHERE emp_id = 345678;

CREATE INDEX big_emp_id_idx ON big_employees(emp_id);
ANALYZE big_employees;

-- With an index
EXPLAIN ANALYZE SELECT * FROM big_employees WHERE emp_id = 345678;

DROP TABLE big_employees;

-- Answer: On a test table with 500,000 rows, the query without an index used a Parallel
-- Seq Scan and took about 51.7 ms. After creating the index, it used an Index Scan and
-- took about 0.048 ms, which is more than 1000 times faster.

-- Challenge 4: Covering index
CREATE INDEX emp_covering_idx ON employees(dept_id) INCLUDE (emp_name, salary);

SET enable_seqscan = off;
EXPLAIN SELECT emp_name, salary FROM employees WHERE dept_id = 101;
RESET enable_seqscan;

-- Answer: A covering index stores the extra columns (emp_name, salary) with INCLUDE, so
-- the query can be answered from the index alone (Index Only Scan) without reading the
-- table.

-- ============================================================
-- SUMMARY QUESTIONS
-- ============================================================

-- 1. What is the default index type in PostgreSQL?
-- Answer: B-tree.

-- 2. Name three scenarios where you should create an index:
-- Answer: (a) Columns that are frequently used in WHERE conditions of queries on large
-- tables. (b) Foreign key columns and columns used in JOIN conditions. (c) Columns used in
-- ORDER BY (or GROUP BY), and columns that must be unique.

-- 3. Name two scenarios where you should NOT create an index:
-- Answer: (a) Small tables, where a sequential scan is as fast or faster. (b) Columns with
-- very few distinct values (for example, a boolean flag) or columns that are rarely
-- queried, especially in tables with heavy INSERT/UPDATE/DELETE activity.

-- 4. What happens to indexes when you INSERT, UPDATE, or DELETE data?
-- Answer: PostgreSQL updates every affected index automatically. This keeps the indexes
-- correct, but it makes write operations slower, and over time the indexes can become
-- bloated (which is why REINDEX or VACUUM may be needed).

-- 5. How can you check if a query is using an index?
-- Answer: Use EXPLAIN (or EXPLAIN ANALYZE) and look at the plan: Index Scan, Index Only
-- Scan or Bitmap Index Scan means an index is used, while Seq Scan means a full table
-- scan. The view pg_stat_user_indexes (column idx_scan) also shows how often each index
-- was used.

-- ============================================================
-- REFLECTION: WHEN TO USE INDEXES
-- ============================================================

-- Indexes are very useful for large tables when queries filter, join or sort on specific
-- columns: they can change a full table scan into a lookup that is thousands of times
-- faster (see Challenge 3). However, each index takes disk space and slows down INSERT,
-- UPDATE and DELETE, so indexes should be created only for columns that are queried often,
-- and unused or duplicate indexes should be removed. On very small tables the planner
-- prefers a sequential scan anyway, so an index gives no benefit. The best approach is to
-- check queries with EXPLAIN (ANALYZE) before and after creating an index.
