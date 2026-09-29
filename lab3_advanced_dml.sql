-- =====================================================================
-- Laboratory Work #3 - Advanced DML Operations (PostgreSQL)
-- File: lab3_advanced_dml.sql
-- =====================================================================

-- =====================================================================
-- PART A: Database and Table Setup
-- =====================================================================

-- 1. Create database (run this line while connected to another DB, e.g. postgres)
CREATE DATABASE advanced_lab;
-- Switch to the new database (psql meta-command)
\c advanced_lab

-- employees: emp_id is SERIAL => auto increment primary key.
-- salary has NO default (so DEFAULT gives NULL); status defaults to 'Active'.
CREATE TABLE employees (
    emp_id     SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name  VARCHAR(50) NOT NULL,
    department VARCHAR(50),
    salary     INTEGER,
    hire_date  DATE,
    status     VARCHAR(20) DEFAULT 'Active'
);

CREATE TABLE departments (
    dept_id    SERIAL PRIMARY KEY,
    dept_name  VARCHAR(50) NOT NULL,
    budget     INTEGER,
    manager_id INTEGER
);

CREATE TABLE projects (
    project_id   SERIAL PRIMARY KEY,
    project_name VARCHAR(100) NOT NULL,
    dept_id      INTEGER,
    start_date   DATE,
    end_date     DATE,
    budget       INTEGER
);

-- =====================================================================
-- PART B: Advanced INSERT Operations
-- =====================================================================

-- 2. INSERT with column specification (only emp_id, first_name, last_name, department)
--    Other columns get their defaults (salary/hire_date = NULL, status = 'Active').
INSERT INTO employees (emp_id, first_name, last_name, department)
VALUES (1, 'Aidos', 'Zhaksylykov', 'IT'),
       (2, 'Aigul', 'Nurpeisova', 'Sales');

-- We inserted emp_id manually, so move the SERIAL sequence forward
-- to avoid duplicate-key errors on later inserts.
SELECT setval(pg_get_serial_sequence('employees', 'emp_id'),
              (SELECT MAX(emp_id) FROM employees));

-- 3. INSERT with DEFAULT values (salary -> NULL, status -> 'Active')
INSERT INTO employees (first_name, last_name, department, salary, status)
VALUES ('Serik', 'Amanov', 'IT', DEFAULT, DEFAULT);

-- 4. INSERT multiple rows in one statement
INSERT INTO departments (dept_name, budget, manager_id)
VALUES ('IT',    500000, 1),
       ('Sales', 300000, 2),
       ('HR',    150000, 3);

-- 5. INSERT with expressions: hire_date = current date, salary = 50000 * 1.1
--    (55000.0 is rounded/cast to INTEGER automatically)
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Kamila', 'Bekova', 'IT', 50000 * 1.1, CURRENT_DATE);

-- Extra sample data used to test the queries below
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Aruzhan', 'Iskakova',  'IT',      65000, '2018-04-12'),
       ('Dias',    'Serikov',   'IT',      85000, '2019-08-20'),
       ('Gulnara', 'Akhmetova', 'Sales',   58000, '2021-01-15'),
       ('Nurlan',  'Kenzhebek', 'HR',      42000, '2017-11-30'),
       ('Asel',    'Omarova',   'Finance', 30000, '2022-06-01');

INSERT INTO projects (project_name, dept_id, start_date, end_date, budget)
VALUES ('Website Redesign', 1, '2022-01-01', '2022-12-31', 120000),
       ('CRM Migration',    2, '2023-03-01', '2024-03-01',  80000),
       ('Old Audit',        3, '2021-01-01', '2021-12-31',  30000),
       ('Cloud Move',       1, '2024-01-01', '2025-06-30', 300000),
       ('Sales Portal',     2, '2024-02-01', '2025-01-31',  40000);

-- 6. INSERT from SELECT: temporary table + copy of IT employees
--    LIKE copies the column structure of employees.
CREATE TEMPORARY TABLE temp_employees (LIKE employees);

INSERT INTO temp_employees
SELECT * FROM employees WHERE department = 'IT';

SELECT * FROM temp_employees;

-- =====================================================================
-- PART C: Complex UPDATE Operations
-- =====================================================================

-- 7. UPDATE with arithmetic: +10% for everyone (NULL salary stays NULL)
UPDATE employees
SET salary = salary * 1.10;

-- 8. UPDATE with multiple conditions
UPDATE employees
SET status = 'Senior'
WHERE salary > 60000
  AND hire_date < '2020-01-01';

-- 9. UPDATE using CASE: department derived from salary
--    NULL salary falls into ELSE => 'Junior'
UPDATE employees
SET department = CASE
                     WHEN salary > 80000              THEN 'Management'
                     WHEN salary BETWEEN 50000 AND 80000 THEN 'Senior'
                     ELSE 'Junior'
                 END;

-- Test data refresh: step 9 overwrote all departments, so we add new rows
-- to keep testing IT / Sales / HR based queries.
INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES ('Bauyrzhan', 'Nurlan',   'IT',    55000, '2021-03-01', 'Active'),
       ('Saltanat',  'Yerkin',   'IT',    60000, '2022-05-05', 'Active'),
       ('Rustem',    'Zhumabek', 'IT',    72000, '2020-02-02', 'Active'),
       ('Dana',      'Omarova',  'Sales', 48000, '2018-07-15', 'Active'),
       ('Yerlan',    'Kassym',   'Sales', 52000, '2022-02-20', 'Active'),
       ('Madina',    'Tulegen',  'HR',    45000, '2020-09-09', 'Inactive'),
       ('Timur',     'Abenov',   'HR',    42000, '2017-11-30', 'Terminated'),
       ('Nurgul',    'Sarsen',   NULL,    35000, '2023-05-05', 'Active');

INSERT INTO departments (dept_name, budget, manager_id)
VALUES ('Legal', 80000, NULL);   -- department with no employees

-- 10. UPDATE with DEFAULT: department has no default value => becomes NULL
UPDATE employees
SET department = DEFAULT
WHERE status = 'Inactive';

-- 11. UPDATE with subquery: budget = 120% of the average salary of the department.
--     EXISTS guard prevents setting NULL for departments without employees.
UPDATE departments d
SET budget = (SELECT AVG(e.salary) * 1.2
              FROM employees e
              WHERE e.department = d.dept_name)
WHERE EXISTS (SELECT 1 FROM employees e WHERE e.department = d.dept_name);

-- 12. UPDATE multiple columns in a single statement
UPDATE employees
SET salary = salary * 1.15,
    status = 'Promoted'
WHERE department = 'Sales';

-- =====================================================================
-- PART D: Advanced DELETE Operations
-- =====================================================================

-- 13. DELETE with simple WHERE
DELETE FROM employees
WHERE status = 'Terminated';

-- 14. DELETE with complex WHERE (IS NULL, not "= NULL")
DELETE FROM employees
WHERE salary < 40000
  AND hire_date > '2023-01-01'
  AND department IS NULL;

-- 15. DELETE with subquery.
--     NOTE: dept_id is INTEGER and employees.department is a string, so they
--     cannot be compared directly. The link between the tables is the NAME,
--     so we compare dept_name with employees.department.
--     IS NOT NULL inside the subquery is essential: NOT IN with a NULL in
--     the list would return no rows at all.
DELETE FROM departments
WHERE dept_name NOT IN (SELECT DISTINCT department
                        FROM employees
                        WHERE department IS NOT NULL);

-- 16. DELETE with RETURNING: show all deleted projects
DELETE FROM projects
WHERE end_date < '2023-01-01'
RETURNING *;

-- =====================================================================
-- PART E: Operations with NULL Values
-- =====================================================================

-- 17. INSERT with NULL values
INSERT INTO employees (first_name, last_name, salary, department)
VALUES ('Ruslan', 'Test', NULL, NULL);

-- 18. UPDATE NULL handling
UPDATE employees
SET department = 'Unassigned'
WHERE department IS NULL;

-- 19. DELETE with NULL conditions
--     (department was filled in step 18, so mostly salary IS NULL matches)
DELETE FROM employees
WHERE salary IS NULL
   OR department IS NULL;

-- =====================================================================
-- PART F: RETURNING Clause Operations
-- =====================================================================

-- 20. INSERT with RETURNING: generated id + concatenated full name
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Ainur', 'Kenzhebek', 'IT', 61000, '2023-09-01')
RETURNING emp_id, first_name || ' ' || last_name AS full_name;

-- 21. UPDATE with RETURNING old and new salary.
--     RETURNING normally sees only NEW values, so we capture the old salary
--     in a CTE and join it in the UPDATE ... FROM.
WITH old AS (
    SELECT emp_id, salary AS old_salary
    FROM employees
    WHERE department = 'IT'
)
UPDATE employees e
SET salary = e.salary + 5000
FROM old
WHERE e.emp_id = old.emp_id
RETURNING e.emp_id, old.old_salary, e.salary AS new_salary;

-- 22. DELETE with RETURNING all columns
DELETE FROM employees
WHERE hire_date < '2020-01-01'
RETURNING *;

-- Test data refresh for Part G
INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES ('Marat', 'Kairat', 'Sales', 40000, '2021-04-04', 'Inactive'),
       ('Laura', 'Ospan',  'IT',    47000, '2022-08-08', 'Inactive');

-- Give IT a big budget so that both branches of task 24 are exercised
UPDATE departments SET budget = 200000 WHERE dept_name = 'IT';

-- =====================================================================
-- PART G: Advanced DML Patterns
-- =====================================================================

-- 23. Conditional INSERT with WHERE NOT EXISTS
--     (a) duplicate name => 0 rows inserted
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
SELECT 'Rustem', 'Zhumabek', 'IT', 70000, CURRENT_DATE
WHERE NOT EXISTS (SELECT 1 FROM employees
                  WHERE first_name = 'Rustem' AND last_name = 'Zhumabek');

--     (b) new name => 1 row inserted
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
SELECT 'Zhanna', 'Baurzhan', 'Sales', 50000, CURRENT_DATE
WHERE NOT EXISTS (SELECT 1 FROM employees
                  WHERE first_name = 'Zhanna' AND last_name = 'Baurzhan');

-- 24. UPDATE with "JOIN logic" via subquery:
--     dept budget > 100000 => +10%, otherwise +5%
UPDATE employees e
SET salary = salary * CASE
                          WHEN (SELECT d.budget FROM departments d
                                WHERE d.dept_name = e.department) > 100000
                          THEN 1.10
                          ELSE 1.05
                      END
WHERE EXISTS (SELECT 1 FROM departments d WHERE d.dept_name = e.department);

-- 25. Bulk operations
--     (a) insert 5 employees in one statement (marked with status 'Onboarding')
INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES ('Ali',    'Bulk1', 'IT',    50000, '2024-01-10', 'Onboarding'),
       ('Bota',   'Bulk2', 'IT',    52000, '2024-01-10', 'Onboarding'),
       ('Chingiz','Bulk3', 'IT',    54000, '2024-01-10', 'Onboarding'),
       ('Dilnaz', 'Bulk4', 'Sales', 48000, '2024-01-10', 'Onboarding'),
       ('Erlan',  'Bulk5', 'Sales', 46000, '2024-01-10', 'Onboarding');

--     (b) raise all of them by 10% in one UPDATE
UPDATE employees
SET salary = salary * 1.10
WHERE status = 'Onboarding';

-- 26. Data migration simulation: move Inactive employees to employee_archive
CREATE TABLE employee_archive (LIKE employees INCLUDING ALL);

BEGIN;  -- transaction: copy and delete succeed or fail together
    INSERT INTO employee_archive
    SELECT * FROM employees WHERE status = 'Inactive';

    DELETE FROM employees WHERE status = 'Inactive';
COMMIT;

-- 27. Complex business logic: +30 days for projects with budget > 50000
--     whose department has more than 3 employees.
--     Link: projects.dept_id -> departments.dept_name -> employees.department
UPDATE projects
SET end_date = end_date + 30
WHERE budget > 50000
  AND dept_id IN (SELECT d.dept_id
                  FROM departments d
                  WHERE (SELECT COUNT(*)
                         FROM employees e
                         WHERE e.department = d.dept_name) > 3);
