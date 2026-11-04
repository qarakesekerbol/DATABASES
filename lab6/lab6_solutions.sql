-- =====================================================================
-- Laboratory Work 6: SQL JOINs  (PostgreSQL syntax)
-- =====================================================================

-- =====================================================================
-- PART 1: DATABASE SETUP
-- =====================================================================
CREATE TABLE employees (
    emp_id    INT PRIMARY KEY,
    emp_name  VARCHAR(50),
    dept_id   INT,
    salary    DECIMAL(10, 2)
);

CREATE TABLE departments (
    dept_id   INT PRIMARY KEY,
    dept_name VARCHAR(50),
    location  VARCHAR(50)
);

CREATE TABLE projects (
    project_id   INT PRIMARY KEY,
    project_name VARCHAR(50),
    dept_id      INT,
    budget       DECIMAL(10, 2)
);

INSERT INTO employees (emp_id, emp_name, dept_id, salary) VALUES
(1, 'John Smith',     101,  50000),
(2, 'Jane Doe',       102,  60000),
(3, 'Mike Johnson',   101,  55000),
(4, 'Sarah Williams', 103,  65000),
(5, 'Tom Brown',      NULL, 45000);

INSERT INTO departments (dept_id, dept_name, location) VALUES
(101, 'IT',        'Building A'),
(102, 'HR',        'Building B'),
(103, 'Finance',   'Building C'),
(104, 'Marketing', 'Building D');

INSERT INTO projects (project_id, project_name, dept_id, budget) VALUES
(1, 'Website Redesign',   101, 100000),
(2, 'Employee Training',  102,  50000),
(3, 'Budget Analysis',    103,  75000),
(4, 'Cloud Migration',    101, 150000),
(5, 'AI Research',        NULL, 200000);


-- =====================================================================
-- PART 2: CROSS JOIN
-- =====================================================================

-- Exercise 2.1: Basic CROSS JOIN
SELECT e.emp_name, d.dept_name
FROM employees e CROSS JOIN departments d;
-- Answer: 20 rows. N x M = 5 employees x 4 departments = 20.

-- Exercise 2.2: Alternative syntax
-- a) Comma notation
SELECT e.emp_name, d.dept_name
FROM employees e, departments d;

-- b) INNER JOIN with TRUE condition
SELECT e.emp_name, d.dept_name
FROM employees e
INNER JOIN departments d ON TRUE;

-- Exercise 2.3: Practical CROSS JOIN (employee x project availability matrix)
SELECT e.emp_name, p.project_name
FROM employees e
CROSS JOIN projects p
ORDER BY e.emp_name, p.project_name;
-- 5 employees x 5 projects = 25 rows.


-- =====================================================================
-- PART 3: INNER JOIN
-- =====================================================================

-- Exercise 3.1: INNER JOIN with ON
SELECT e.emp_name, d.dept_name, d.location
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id;
-- Answer: 4 rows. Tom Brown is excluded because his dept_id is NULL,
-- and NULL = anything is never TRUE, so he has no matching department.

-- Exercise 3.2: INNER JOIN with USING
SELECT emp_name, dept_name, location
FROM employees
INNER JOIN departments USING (dept_id);
-- Answer: With the selected columns the output is identical. The difference
-- shows up with SELECT *: USING returns the join column dept_id only ONCE,
-- while ON returns both e.dept_id and d.dept_id. With USING the join column
-- also cannot be qualified with a table alias.

-- Exercise 3.3: NATURAL INNER JOIN
SELECT emp_name, dept_name, location
FROM employees
NATURAL INNER JOIN departments;
-- Joins automatically on the only common column name: dept_id.

-- Exercise 3.4: Multi-table INNER JOIN
SELECT e.emp_name, d.dept_name, p.project_name
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id
INNER JOIN projects p    ON d.dept_id = p.dept_id;
-- Answer: 6 rows (John and Mike each pair with 2 IT projects,
-- Jane with 1 HR project, Sarah with 1 Finance project).


-- =====================================================================
-- PART 4: LEFT JOIN
-- =====================================================================

-- Exercise 4.1: Basic LEFT JOIN
SELECT e.emp_name, e.dept_id AS emp_dept, d.dept_id AS dept_dept, d.dept_name
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id;
-- Answer: Tom Brown appears with emp_dept = NULL, dept_dept = NULL
-- and dept_name = NULL (no matching department).

-- Exercise 4.2: LEFT JOIN with USING
SELECT emp_name, dept_id, dept_name
FROM employees
LEFT JOIN departments USING (dept_id);

-- Exercise 4.3: Find unmatched records
SELECT e.emp_name, e.dept_id
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
WHERE d.dept_id IS NULL;
-- Result: Tom Brown.

-- Exercise 4.4: LEFT JOIN with aggregation
SELECT d.dept_name, COUNT(e.emp_id) AS employee_count
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name
ORDER BY employee_count DESC;
-- Result: IT = 2, HR = 1, Finance = 1, Marketing = 0.
-- COUNT(e.emp_id) (not COUNT(*)) so departments with no employees give 0.


-- =====================================================================
-- PART 5: RIGHT JOIN
-- =====================================================================

-- Exercise 5.1: Basic RIGHT JOIN
SELECT e.emp_name, d.dept_name
FROM employees e
RIGHT JOIN departments d ON e.dept_id = d.dept_id;
-- 5 rows: 4 matched employees + Marketing with NULL employee.

-- Exercise 5.2: Convert to LEFT JOIN (reverse table order)
SELECT e.emp_name, d.dept_name
FROM departments d
LEFT JOIN employees e ON e.dept_id = d.dept_id;

-- Exercise 5.3: Departments without employees
SELECT d.dept_name, d.location
FROM employees e
RIGHT JOIN departments d ON e.dept_id = d.dept_id
WHERE e.emp_id IS NULL;
-- Result: Marketing, Building D.


-- =====================================================================
-- PART 6: FULL JOIN
-- =====================================================================

-- Exercise 6.1: Basic FULL JOIN
SELECT e.emp_name, e.dept_id AS emp_dept, d.dept_id AS dept_dept, d.dept_name
FROM employees e
FULL JOIN departments d ON e.dept_id = d.dept_id;
-- Answer (6 rows):
--   NULLs on the LEFT (employee) side:  Marketing department (no employees).
--   NULLs on the RIGHT (department) side: Tom Brown (no department).

-- Exercise 6.2: FULL JOIN with projects
SELECT d.dept_name, p.project_name, p.budget
FROM departments d
FULL JOIN projects p ON d.dept_id = p.dept_id;
-- 6 rows: IT (2 projects), HR, Finance, Marketing (no project -> NULLs),
-- and 'AI Research' (no department -> dept_name NULL).

-- Exercise 6.3: Orphaned records
SELECT
    CASE
        WHEN e.emp_id IS NULL THEN 'Department without employees'
        WHEN d.dept_id IS NULL THEN 'Employee without department'
        ELSE 'Matched'
    END AS record_status,
    e.emp_name,
    d.dept_name
FROM employees e
FULL JOIN departments d ON e.dept_id = d.dept_id
WHERE e.emp_id IS NULL OR d.dept_id IS NULL;
-- Result: 'Employee without department' -> Tom Brown;
--         'Department without employees' -> Marketing.


-- =====================================================================
-- PART 7: ON vs WHERE
-- =====================================================================

-- Exercise 7.1: Filter in ON (LEFT JOIN)
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
LEFT JOIN departments d
       ON e.dept_id = d.dept_id AND d.location = 'Building A';
-- Result: all 5 employees. John and Mike show 'IT'; the other three have
-- dept_name = NULL.

-- Exercise 7.2: Filter in WHERE (LEFT JOIN)
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
WHERE d.location = 'Building A';
-- Result: only John and Mike (2 rows).
-- Explanation: In Query 1 the condition is part of the matching rule, so
-- employees without a match are still kept (with NULLs) because it is a
-- LEFT JOIN. In Query 2 the WHERE filter runs AFTER the join and removes
-- every row whose d.location is not 'Building A' (including the NULL rows),
-- which effectively turns the LEFT JOIN into an INNER JOIN.

-- Exercise 7.3: Same with INNER JOIN
-- ON version
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
INNER JOIN departments d
        ON e.dept_id = d.dept_id AND d.location = 'Building A';

-- WHERE version
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id
WHERE d.location = 'Building A';
-- Answer: No difference - both return John and Mike. An INNER JOIN only keeps
-- rows that satisfy all conditions, so it does not matter whether the filter
-- is applied during the join (ON) or after it (WHERE).


-- =====================================================================
-- PART 8: COMPLEX JOIN SCENARIOS
-- =====================================================================

-- Exercise 8.1: Multiple joins with different types
SELECT
    d.dept_name,
    e.emp_name,
    e.salary,
    p.project_name,
    p.budget
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
LEFT JOIN projects  p ON d.dept_id = p.dept_id
ORDER BY d.dept_name, e.emp_name;
-- 8 rows: Finance (1), HR (1), IT (4 = 2 employees x 2 projects),
-- Marketing (1 row of NULLs).

-- Exercise 8.2: Self join
ALTER TABLE employees ADD COLUMN manager_id INT;

UPDATE employees SET manager_id = 3    WHERE emp_id = 1;
UPDATE employees SET manager_id = 3    WHERE emp_id = 2;
UPDATE employees SET manager_id = NULL WHERE emp_id = 3;
UPDATE employees SET manager_id = 3    WHERE emp_id = 4;
UPDATE employees SET manager_id = 3    WHERE emp_id = 5;

SELECT
    e.emp_name AS employee,
    m.emp_name AS manager
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.emp_id;
-- Everyone reports to Mike Johnson; Mike has no manager (NULL).

-- Exercise 8.3: Departments with average salary above 50,000
SELECT d.dept_name, AVG(e.salary) AS avg_salary
FROM departments d
INNER JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name
HAVING AVG(e.salary) > 50000;
-- Result: IT (52500), HR (60000), Finance (65000).


-- =====================================================================
-- LAB QUESTIONS (answers)
-- =====================================================================
-- 1. INNER JOIN returns only rows with a match in both tables. LEFT JOIN
--    returns ALL rows of the left table plus matching rows of the right
--    table; where there is no match, right-side columns are NULL.
--
-- 2. CROSS JOIN is useful for generating all combinations: e.g. an
--    availability matrix (employees x projects), product x size x color
--    variants, calendar/date x store reports, test-data generation.
--
-- 3. In an INNER JOIN, non-matching rows are discarded anyway, so a filter
--    in ON or WHERE gives the same result. In an OUTER JOIN, ON decides which
--    rows MATCH (unmatched preserved rows are kept with NULLs), whereas WHERE
--    filters the final result and removes the NULL-extended rows, changing
--    the meaning of the query.
--
-- 4. 5 x 10 = 50 rows, so COUNT(*) returns 50.
--
-- 5. NATURAL JOIN automatically joins on ALL columns that have the same name
--    in both tables (and outputs each such column once).
--
-- 6. Risks: (a) joins on unintended columns that merely share a name;
--    (b) silently changes behavior if columns are added/renamed later;
--    (c) if no common columns exist it becomes a CROSS JOIN; (d) less
--    readable and harder to maintain/debug.
--
-- 7. SELECT * FROM B RIGHT JOIN A ON A.id = B.id;
--    (same rows; column order becomes B's columns first, then A's)
--
-- 8. Use FULL OUTER JOIN when you need all rows from both tables whether or
--    not they match: data reconciliation/comparison between two sources,
--    finding orphaned records on either side, merging two datasets.


-- =====================================================================
-- ADDITIONAL CHALLENGES (optional)
-- =====================================================================

-- Challenge 1: Simulate FULL OUTER JOIN with UNION of LEFT and RIGHT joins
SELECT e.emp_name, d.dept_name
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
UNION
SELECT e.emp_name, d.dept_name
FROM employees e
RIGHT JOIN departments d ON e.dept_id = d.dept_id;

-- Challenge 2: Employees in departments with more than one project
SELECT e.emp_name, d.dept_name
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id
WHERE d.dept_id IN (
    SELECT dept_id
    FROM projects
    WHERE dept_id IS NOT NULL
    GROUP BY dept_id
    HAVING COUNT(*) > 1
);
-- Result: John Smith, Mike Johnson (IT has 2 projects).

-- Challenge 3: Hierarchy via self-joins (employee -> manager -> manager's manager)
SELECT
    e.emp_name  AS employee,
    m1.emp_name AS manager,
    m2.emp_name AS managers_manager
FROM employees e
LEFT JOIN employees m1 ON e.manager_id  = m1.emp_id
LEFT JOIN employees m2 ON m1.manager_id = m2.emp_id;

-- Challenge 3 (alternative, any depth): recursive CTE
WITH RECURSIVE org AS (
    SELECT emp_id, emp_name, manager_id, 1 AS level,
           emp_name::TEXT AS path
    FROM employees
    WHERE manager_id IS NULL
    UNION ALL
    SELECT e.emp_id, e.emp_name, e.manager_id, o.level + 1,
           o.path || ' -> ' || e.emp_name
    FROM employees e
    JOIN org o ON e.manager_id = o.emp_id
)
SELECT * FROM org ORDER BY level, emp_name;

-- Challenge 4: All pairs of employees in the same department
SELECT
    e1.emp_name AS employee_1,
    e2.emp_name AS employee_2,
    d.dept_name
FROM employees e1
INNER JOIN employees e2
        ON e1.dept_id = e2.dept_id
       AND e1.emp_id < e2.emp_id      -- avoids self-pairs and duplicate pairs
INNER JOIN departments d ON e1.dept_id = d.dept_id;
-- Result: John Smith & Mike Johnson (IT).
