-- =============================================================================
-- Database Constraints - Laboratory Work (PostgreSQL)
--
-- Name:        <Zheksembaev Erbol>
-- Student ID:  <25B031261>
--
-- Tested on PostgreSQL 16 with:  psql -v ON_ERROR_STOP=1 -f lab5_constraints.sql
--
-- HOW THIS FILE IS ORGANISED
--   * Every statement that is NOT commented out runs successfully, so the whole
--     file can be executed from top to bottom without errors.
--   * Every statement that is EXPECTED TO FAIL is written as a comment
--     (-- INSERT ...). Directly below it, the constraint that is violated and the
--     real error message returned by PostgreSQL are documented
--     ("-- TEST RESULT: ...").
--   * To see a failure yourself, remove the leading "-- " from that one statement
--     and run it on its own.
--   * Task 6.1 (e-commerce) uses its own schema "ecommerce", because the table
--     names customers / products / orders were already used by earlier tasks.
-- =============================================================================

-- =============================================================================
-- CLEAN-UP (makes the script re-runnable)
-- =============================================================================
DROP TABLE IF EXISTS order_items, orders, products_fk, categories,
                     books, publishers, authors, employees_dept,
                     student_courses, departments, course_enrollments, users,
                     inventory, customers, bookings, products_catalog, employees CASCADE;

DROP SCHEMA IF EXISTS ecommerce CASCADE;


-- =============================================================================
-- PART 1: CHECK CONSTRAINTS
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Task 1.1: Basic CHECK constraint (employees)
-- -----------------------------------------------------------------------------
-- A CHECK constraint is a boolean condition that every row must satisfy. The row is rejected
-- only when the condition evaluates to FALSE (if it evaluates to NULL/unknown the row is accepted).
--   * age    must be between 18 and 65 (inclusive)  -> auto-named employees_age_check
--   * salary must be greater than 0                 -> auto-named employees_salary_check
CREATE TABLE employees (
    employee_id integer,
    first_name  text,
    last_name   text,
    age         integer CHECK (age BETWEEN 18 AND 65),
    salary      numeric CHECK (salary > 0)
);

-- -----------------------------------------------------------------------------
-- Task 1.2: Named CHECK constraint (products_catalog)
-- -----------------------------------------------------------------------------
-- valid_discount is a named table-level constraint combining three rules:
-- regular_price > 0, discount_price > 0 and discount_price < regular_price.
-- (If discount_price is NULL the condition is unknown, so the row is accepted - "no discount".)
CREATE TABLE products_catalog (
    product_id     integer,
    product_name   text,
    regular_price  numeric,
    discount_price numeric,
    CONSTRAINT valid_discount CHECK (
        regular_price > 0
        AND discount_price > 0
        AND discount_price < regular_price
    )
);

-- -----------------------------------------------------------------------------
-- Task 1.3: Multiple column CHECK (bookings)
-- -----------------------------------------------------------------------------
-- valid_guest_count : num_guests BETWEEN 1 AND 10.
-- valid_dates       : compares two columns of the same row (check_out_date > check_in_date).
CREATE TABLE bookings (
    booking_id     integer,
    check_in_date  date,
    check_out_date date,
    num_guests     integer,
    CONSTRAINT valid_guest_count CHECK (num_guests BETWEEN 1 AND 10),
    CONSTRAINT valid_dates       CHECK (check_out_date > check_in_date)
);

-- -----------------------------------------------------------------------------
-- Task 1.4: Testing CHECK constraints
-- -----------------------------------------------------------------------------
-- Valid data: employees (includes the boundary ages 18 and 65, which are allowed).
INSERT INTO employees (employee_id, first_name, last_name, age, salary) VALUES
    (1, 'Aigerim', 'Sadykova', 28, 450000),
    (2, 'Daniyar', 'Omarov',   45, 620000.50),
    (3, 'Madina',  'Bekova',   18, 300000),
    (4, 'Timur',   'Nurzhanov', 65, 700000);

-- INSERT INTO employees VALUES (5, 'Too', 'Young', 17, 250000);
-- Violated: employees_age_check - age 17 is below the minimum of 18.
-- TEST RESULT: ERROR [SQLSTATE 23514]: new row for relation "employees" violates check constraint "employees_age_check"
--                 DETAIL: Failing row contains (5, Too, Young, 17, 250000).

-- INSERT INTO employees VALUES (6, 'Too', 'Old', 66, 250000);
-- Violated: employees_age_check - age 66 is above the maximum of 65.
-- TEST RESULT: ERROR [SQLSTATE 23514]: new row for relation "employees" violates check constraint "employees_age_check"
--                 DETAIL: Failing row contains (6, Too, Old, 66, 250000).

-- INSERT INTO employees VALUES (7, 'Zero', 'Salary', 30, 0);
-- Violated: employees_salary_check - salary must be strictly greater than 0 (0 is not allowed).
-- TEST RESULT: ERROR [SQLSTATE 23514]: new row for relation "employees" violates check constraint "employees_salary_check"
--                 DETAIL: Failing row contains (7, Zero, Salary, 30, 0).

-- INSERT INTO employees VALUES (8, 'Negative', 'Salary', 30, -500);
-- Violated: employees_salary_check - a negative salary is not allowed.
-- TEST RESULT: ERROR [SQLSTATE 23514]: new row for relation "employees" violates check constraint "employees_salary_check"
--                 DETAIL: Failing row contains (8, Negative, Salary, 30, -500).

-- Only the 4 valid rows are stored:
SELECT employee_id, first_name, age, salary FROM employees ORDER BY employee_id;
-- TEST RESULT:
--  employee_id | first_name | age | salary
-- -------------+------------+-----+-----------
--  1           | Aigerim    | 28  | 450000
--  2           | Daniyar    | 45  | 620000.50
--  3           | Madina     | 18  | 300000
--  4           | Timur      | 65  | 700000
--  (4 rows)

-- Valid data: products_catalog.
INSERT INTO products_catalog (product_id, product_name, regular_price, discount_price) VALUES
    (1, 'Laptop',     500000, 450000),
    (2, 'Headphones',  30000,  25000),
    (3, 'Keyboard',    15000,   NULL);

-- INSERT INTO products_catalog VALUES (4, 'Mouse', 10000, 12000);
-- Violated: valid_discount - discount_price (12000) is greater than regular_price (10000).
-- TEST RESULT: ERROR [SQLSTATE 23514]: new row for relation "products_catalog" violates check constraint "valid_discount"
--                 DETAIL: Failing row contains (4, Mouse, 10000, 12000).

-- INSERT INTO products_catalog VALUES (5, 'Cable', 5000, 5000);
-- Violated: valid_discount - discount_price must be strictly LESS than regular_price (equal is not
-- allowed).
-- TEST RESULT: ERROR [SQLSTATE 23514]: new row for relation "products_catalog" violates check constraint "valid_discount"
--                 DETAIL: Failing row contains (5, Cable, 5000, 5000).

-- INSERT INTO products_catalog VALUES (6, 'Tablet', -100, -200);
-- Violated: valid_discount - regular_price must be greater than 0 (and discount_price too).
-- TEST RESULT: ERROR [SQLSTATE 23514]: new row for relation "products_catalog" violates check constraint "valid_discount"
--                 DETAIL: Failing row contains (6, Tablet, -100, -200).

-- INSERT INTO products_catalog VALUES (7, 'Case', 2000, 0);
-- Violated: valid_discount - discount_price must be greater than 0.
-- TEST RESULT: ERROR [SQLSTATE 23514]: new row for relation "products_catalog" violates check constraint "valid_discount"
--                 DETAIL: Failing row contains (7, Case, 2000, 0).

-- Only the 3 valid rows are stored:
SELECT * FROM products_catalog ORDER BY product_id;
-- TEST RESULT:
--  product_id | product_name | regular_price | discount_price
-- ------------+--------------+---------------+----------------
--  1          | Laptop       | 500000        | 450000
--  2          | Headphones   | 30000         | 25000
--  3          | Keyboard     | 15000         | NULL
--  (3 rows)

-- Valid data: bookings (booking 2 uses the maximum of 10 guests).
INSERT INTO bookings (booking_id, check_in_date, check_out_date, num_guests) VALUES
    (1, '2026-11-01', '2026-11-05', 2),
    (2, '2026-12-20', '2026-12-27', 10),
    (3, '2027-01-10', '2027-01-11', 1);

-- INSERT INTO bookings VALUES (4, '2026-11-01', '2026-11-05', 0);
-- Violated: valid_guest_count - num_guests must be at least 1.
-- TEST RESULT: ERROR [SQLSTATE 23514]: new row for relation "bookings" violates check constraint "valid_guest_count"
--                 DETAIL: Failing row contains (4, 2026-11-01, 2026-11-05, 0).

-- INSERT INTO bookings VALUES (5, '2026-11-01', '2026-11-05', 11);
-- Violated: valid_guest_count - num_guests must be at most 10.
-- TEST RESULT: ERROR [SQLSTATE 23514]: new row for relation "bookings" violates check constraint "valid_guest_count"
--                 DETAIL: Failing row contains (5, 2026-11-01, 2026-11-05, 11).

-- INSERT INTO bookings VALUES (6, '2026-11-05', '2026-11-05', 2);
-- Violated: valid_dates - check_out_date must be AFTER check_in_date (same day is not allowed).
-- TEST RESULT: ERROR [SQLSTATE 23514]: new row for relation "bookings" violates check constraint "valid_dates"
--                 DETAIL: Failing row contains (6, 2026-11-05, 2026-11-05, 2).

-- INSERT INTO bookings VALUES (7, '2026-11-05', '2026-11-01', 2);
-- Violated: valid_dates - check_out_date (Nov 1) is before check_in_date (Nov 5).
-- TEST RESULT: ERROR [SQLSTATE 23514]: new row for relation "bookings" violates check constraint "valid_dates"
--                 DETAIL: Failing row contains (7, 2026-11-05, 2026-11-01, 2).

-- Only the 3 valid rows are stored:
SELECT * FROM bookings ORDER BY booking_id;
-- TEST RESULT:
--  booking_id | check_in_date | check_out_date | num_guests
-- ------------+---------------+----------------+------------
--  1          | 2026-11-01    | 2026-11-05     | 2
--  2          | 2026-12-20    | 2026-12-27     | 10
--  3          | 2027-01-10    | 2027-01-11     | 1
--  (3 rows)

-- =============================================================================
-- PART 2: NOT NULL CONSTRAINTS
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Task 2.1: NOT NULL implementation (customers)
-- -----------------------------------------------------------------------------
-- NOT NULL forbids missing values. phone has no constraint, so it may be NULL.
CREATE TABLE customers (
    customer_id       integer NOT NULL,
    email             text    NOT NULL,
    phone             text,
    registration_date date    NOT NULL
);

-- -----------------------------------------------------------------------------
-- Task 2.2: Combining constraints (inventory)
-- -----------------------------------------------------------------------------
-- NOT NULL and CHECK can be combined on one column. NOT NULL rejects NULL; CHECK rejects wrong non-
-- NULL values (a CHECK alone would let NULL through).
CREATE TABLE inventory (
    item_id      integer   NOT NULL,
    item_name    text      NOT NULL,
    quantity     integer   NOT NULL CHECK (quantity >= 0),
    unit_price   numeric   NOT NULL CHECK (unit_price > 0),
    last_updated timestamp NOT NULL
);

-- -----------------------------------------------------------------------------
-- Task 2.3: Testing NOT NULL
-- -----------------------------------------------------------------------------
-- 1) Complete records succeed.
INSERT INTO customers (customer_id, email, phone, registration_date) VALUES
    (1, 'aigerim@example.kz', '+7 701 111 2233', '2026-01-15'),
    (2, 'daniyar@example.kz', '+7 702 222 3344', '2026-02-20');
INSERT INTO inventory (item_id, item_name, quantity, unit_price, last_updated) VALUES
    (1, 'Notebook', 100, 1500.00, '2026-10-14 09:00:00'),
    (2, 'Pen',      500,  200.50, '2026-10-14 09:05:00'),
    (3, 'Stapler',    0, 3200.00, '2026-10-14 09:10:00');

-- 2) NULL in NOT NULL columns is rejected.
-- INSERT INTO customers VALUES (NULL, 'nullid@example.kz', '+7 703 000 0000', '2026-03-01');
-- Violated: NOT NULL on customers.customer_id.
-- TEST RESULT: ERROR [SQLSTATE 23502]: null value in column "customer_id" of relation "customers" violates not-null constraint
--                 DETAIL: Failing row contains (null, nullid@example.kz, +7 703 000 0000, 2026-03-01).

-- INSERT INTO customers VALUES (3, NULL, '+7 703 000 0000', '2026-03-01');
-- Violated: NOT NULL on customers.email.
-- TEST RESULT: ERROR [SQLSTATE 23502]: null value in column "email" of relation "customers" violates not-null constraint
--                 DETAIL: Failing row contains (3, null, +7 703 000 0000, 2026-03-01).

-- INSERT INTO customers VALUES (3, 'nodate@example.kz', '+7 703 000 0000', NULL);
-- Violated: NOT NULL on customers.registration_date.
-- TEST RESULT: ERROR [SQLSTATE 23502]: null value in column "registration_date" of relation "customers" violates not-null constraint
--                 DETAIL: Failing row contains (3, nodate@example.kz, +7 703 000 0000, null).

-- INSERT INTO inventory VALUES (4, NULL, 10, 100, '2026-10-14 10:00:00');
-- Violated: NOT NULL on inventory.item_name.
-- TEST RESULT: ERROR [SQLSTATE 23502]: null value in column "item_name" of relation "inventory" violates not-null constraint
--                 DETAIL: Failing row contains (4, null, 10, 100, 2026-10-14 10:00:00).

-- INSERT INTO inventory VALUES (4, 'Ruler', NULL, 100, '2026-10-14 10:00:00');
-- Violated: NOT NULL on inventory.quantity (a plain CHECK would NOT have stopped this NULL).
-- TEST RESULT: ERROR [SQLSTATE 23502]: null value in column "quantity" of relation "inventory" violates not-null constraint
--                 DETAIL: Failing row contains (4, Ruler, null, 100, 2026-10-14 10:00:00).

-- INSERT INTO inventory VALUES (4, 'Ruler', 10, NULL, '2026-10-14 10:00:00');
-- Violated: NOT NULL on inventory.unit_price.
-- TEST RESULT: ERROR [SQLSTATE 23502]: null value in column "unit_price" of relation "inventory" violates not-null constraint
--                 DETAIL: Failing row contains (4, Ruler, 10, null, 2026-10-14 10:00:00).

-- INSERT INTO inventory VALUES (4, 'Ruler', 10, 100, NULL);
-- Violated: NOT NULL on inventory.last_updated.
-- TEST RESULT: ERROR [SQLSTATE 23502]: null value in column "last_updated" of relation "inventory" violates not-null constraint
--                 DETAIL: Failing row contains (4, Ruler, 10, 100, null).

-- The CHECK parts of inventory (combined with NOT NULL):
-- INSERT INTO inventory VALUES (5, 'Eraser', -5, 100, '2026-10-14 10:00:00');
-- Violated: inventory_quantity_check - quantity must be >= 0.
-- TEST RESULT: ERROR [SQLSTATE 23514]: new row for relation "inventory" violates check constraint "inventory_quantity_check"
--                 DETAIL: Failing row contains (5, Eraser, -5, 100, 2026-10-14 10:00:00).

-- INSERT INTO inventory VALUES (5, 'Eraser', 5, 0, '2026-10-14 10:00:00');
-- Violated: inventory_unit_price_check - unit_price must be > 0.
-- TEST RESULT: ERROR [SQLSTATE 23514]: new row for relation "inventory" violates check constraint "inventory_unit_price_check"
--                 DETAIL: Failing row contains (5, Eraser, 5, 0, 2026-10-14 10:00:00).

-- 3) NULL in a nullable column (phone) is accepted - explicitly, and by omitting the column.
INSERT INTO customers (customer_id, email, phone, registration_date)
VALUES (3, 'madina@example.kz', NULL, '2026-03-02');
INSERT INTO customers (customer_id, email, registration_date)
VALUES (4, 'timur@example.kz', '2026-03-10');

-- Customers 3 and 4 have phone = NULL:
SELECT * FROM customers ORDER BY customer_id;
-- TEST RESULT:
--  customer_id | email              | phone           | registration_date
-- -------------+--------------------+-----------------+-------------------
--  1           | aigerim@example.kz | +7 701 111 2233 | 2026-01-15
--  2           | daniyar@example.kz | +7 702 222 3344 | 2026-02-20
--  3           | madina@example.kz  | NULL            | 2026-03-02
--  4           | timur@example.kz   | NULL            | 2026-03-10
--  (4 rows)

-- =============================================================================
-- PART 3: UNIQUE CONSTRAINTS
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Task 3.1: Single column UNIQUE (users)
-- -----------------------------------------------------------------------------
-- UNIQUE on username and on email. PostgreSQL auto-names them users_username_key and
-- users_email_key (they are renamed in Task 3.3).
CREATE TABLE users (
    user_id    integer,
    username   text UNIQUE,
    email      text UNIQUE,
    created_at timestamp
);

INSERT INTO users (user_id, username, email, created_at) VALUES
    (1, 'aigerim', 'aigerim@example.kz', '2026-09-01 10:00:00'),
    (2, 'daniyar', 'daniyar@example.kz', '2026-09-02 11:30:00');

-- -----------------------------------------------------------------------------
-- Task 3.2: Multi-column UNIQUE (course_enrollments)
-- -----------------------------------------------------------------------------
-- The UNIQUE constraint covers the COMBINATION (student_id, course_code, semester): a student
-- cannot enroll in the same course twice in the same semester, but may repeat the course in another
-- semester, and different students may take the same course.
CREATE TABLE course_enrollments (
    enrollment_id integer,
    student_id    integer,
    course_code   text,
    semester      text,
    UNIQUE (student_id, course_code, semester)
);

INSERT INTO course_enrollments (enrollment_id, student_id, course_code, semester) VALUES
    (1, 101, 'CS101',   'Fall 2026'),
    (2, 101, 'MATH201', 'Fall 2026'),
    (3, 102, 'CS101',   'Fall 2026'),
    (4, 101, 'CS101',   'Spring 2027');

-- INSERT INTO course_enrollments VALUES (5, 101, 'CS101', 'Fall 2026');
-- Violated: course_enrollments_student_id_course_code_semester_key - the combination (101, 'CS101',
-- 'Fall 2026') already exists (row 1).
-- TEST RESULT: ERROR [SQLSTATE 23505]: duplicate key value violates unique constraint "course_enrollments_student_id_course_code_semester_key"
--                 DETAIL: Key (student_id, course_code, semester)=(101, CS101, Fall 2026) already exists.

-- Rows 1, 3 and 4 share individual values, but no full combination is repeated:
SELECT * FROM course_enrollments ORDER BY enrollment_id;
-- TEST RESULT:
--  enrollment_id | student_id | course_code | semester
-- ---------------+------------+-------------+-------------
--  1             | 101        | CS101       | Fall 2026
--  2             | 101        | MATH201     | Fall 2026
--  3             | 102        | CS101       | Fall 2026
--  4             | 101        | CS101       | Spring 2027
--  (4 rows)

-- -----------------------------------------------------------------------------
-- Task 3.3: Named UNIQUE constraints (modify users)
-- -----------------------------------------------------------------------------
-- The auto-named constraints are dropped and replaced by explicitly named ones, so that error
-- messages are readable and the constraints can be managed by name. (Keeping both would create
-- duplicate indexes.)
ALTER TABLE users
    DROP CONSTRAINT users_username_key,
    DROP CONSTRAINT users_email_key,
    ADD CONSTRAINT unique_username UNIQUE (username),
    ADD CONSTRAINT unique_email    UNIQUE (email);

-- The table now has exactly the two named UNIQUE ('u') constraints:
SELECT conname, contype
FROM pg_constraint
WHERE conrelid = 'users'::regclass
ORDER BY conname;
-- TEST RESULT:
--  conname         | contype
-- -----------------+---------
--  unique_email    | u
--  unique_username | u
--  (2 rows)

INSERT INTO users (user_id, username, email, created_at)
VALUES (3, 'madina', 'madina@example.kz', '2026-09-03 09:15:00');

-- Duplicate tests:
-- INSERT INTO users VALUES (4, 'aigerim', 'other@example.kz', '2026-09-04 12:00:00');
-- Violated: unique_username - the username 'aigerim' is already taken.
-- TEST RESULT: ERROR [SQLSTATE 23505]: duplicate key value violates unique constraint "unique_username"
--                 DETAIL: Key (username)=(aigerim) already exists.

-- INSERT INTO users VALUES (5, 'newuser', 'daniyar@example.kz', '2026-09-05 12:00:00');
-- Violated: unique_email - the email 'daniyar@example.kz' is already registered.
-- TEST RESULT: ERROR [SQLSTATE 23505]: duplicate key value violates unique constraint "unique_email"
--                 DETAIL: Key (email)=(daniyar@example.kz) already exists.

-- UNIQUE allows several NULLs (NULL is 'unknown', so two NULLs are not considered equal):
INSERT INTO users (user_id, username, email, created_at) VALUES
    (6, NULL, 'anon1@example.kz', '2026-09-06 08:00:00'),
    (7, NULL, 'anon2@example.kz', '2026-09-06 08:05:00');

-- Final content of users:
SELECT user_id, username, email FROM users ORDER BY user_id;
-- TEST RESULT:
--  user_id | username | email
-- ---------+----------+--------------------
--  1       | aigerim  | aigerim@example.kz
--  2       | daniyar  | daniyar@example.kz
--  3       | madina   | madina@example.kz
--  6       | NULL     | anon1@example.kz
--  7       | NULL     | anon2@example.kz
--  (5 rows)

-- =============================================================================
-- PART 4: PRIMARY KEY CONSTRAINTS
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Task 4.1: Single column PRIMARY KEY (departments)
-- -----------------------------------------------------------------------------
-- PRIMARY KEY = UNIQUE + NOT NULL. The constraint is auto-named departments_pkey.
CREATE TABLE departments (
    dept_id   integer PRIMARY KEY,
    dept_name text NOT NULL,
    location  text
);

INSERT INTO departments (dept_id, dept_name, location) VALUES
    (1, 'Engineering', 'Almaty'),
    (2, 'Finance',     'Astana'),
    (3, 'Marketing',   'Almaty'),
    (4, 'HR',          NULL);

-- INSERT INTO departments VALUES (2, 'Legal', 'Shymkent');
-- Violated: departments_pkey - dept_id 2 already exists (a primary key must be unique).
-- TEST RESULT: ERROR [SQLSTATE 23505]: duplicate key value violates unique constraint "departments_pkey"
--                 DETAIL: Key (dept_id)=(2) already exists.

-- INSERT INTO departments VALUES (NULL, 'Legal', 'Shymkent');
-- Violated: PRIMARY KEY implies NOT NULL - dept_id cannot be NULL.
-- TEST RESULT: ERROR [SQLSTATE 23502]: null value in column "dept_id" of relation "departments" violates not-null constraint
--                 DETAIL: Failing row contains (null, Legal, Shymkent).

-- INSERT INTO departments VALUES (5, NULL, 'Shymkent');
-- Violated: NOT NULL on dept_name.
-- TEST RESULT: ERROR [SQLSTATE 23502]: null value in column "dept_name" of relation "departments" violates not-null constraint
--                 DETAIL: Failing row contains (5, null, Shymkent).

-- -----------------------------------------------------------------------------
-- Task 4.2: Composite PRIMARY KEY (student_courses)
-- -----------------------------------------------------------------------------
-- The pair (student_id, course_id) identifies a row. Each column may repeat on its own, but the
-- pair may not; neither column may be NULL.
CREATE TABLE student_courses (
    student_id      integer,
    course_id       integer,
    enrollment_date date,
    grade           text,
    PRIMARY KEY (student_id, course_id)
);

INSERT INTO student_courses (student_id, course_id, enrollment_date, grade) VALUES
    (1, 101, '2026-09-01', 'A'),
    (1, 102, '2026-09-01', 'B+'),
    (2, 101, '2026-09-02', 'A-');

-- INSERT INTO student_courses VALUES (1, 101, '2026-09-10', 'C');
-- Violated: student_courses_pkey - the pair (1, 101) already exists.
-- TEST RESULT: ERROR [SQLSTATE 23505]: duplicate key value violates unique constraint "student_courses_pkey"
--                 DETAIL: Key (student_id, course_id)=(1, 101) already exists.

-- INSERT INTO student_courses VALUES (NULL, 103, '2026-09-10', 'C');
-- Violated: PRIMARY KEY implies NOT NULL - student_id is part of the key and cannot be NULL.
-- TEST RESULT: ERROR [SQLSTATE 23502]: null value in column "student_id" of relation "student_courses" violates not-null constraint
--                 DETAIL: Failing row contains (null, 103, 2026-09-10, C).

-- Student 1 appears twice and course 101 appears twice, but every PAIR is unique:
SELECT * FROM student_courses ORDER BY student_id, course_id;
-- TEST RESULT:
--  student_id | course_id | enrollment_date | grade
-- ------------+-----------+-----------------+-------
--  1          | 101       | 2026-09-01      | A
--  1          | 102       | 2026-09-01      | B+
--  2          | 101       | 2026-09-02      | A-
--  (3 rows)

-- -----------------------------------------------------------------------------
-- Task 4.3: Comparison exercise (written explanation)
-- -----------------------------------------------------------------------------
-- 1. DIFFERENCE BETWEEN UNIQUE AND PRIMARY KEY
--    * Both guarantee that values (or combinations of values) are not duplicated, and both are
--      implemented with a unique index.
--    * PRIMARY KEY also forces every key column to be NOT NULL. UNIQUE allows NULLs (and in
--      PostgreSQL several rows may contain NULL in a UNIQUE column, because NULL = NULL is
-- unknown).
--    * PRIMARY KEY states the row's identity: it is the default target of FOREIGN KEY references
--      and the column(s) used to find exactly one row. UNIQUE columns are "alternative keys"
--      (e.g. email or ISBN), which can also be referenced but express a business rule.
--    * A table may have only one PRIMARY KEY but any number of UNIQUE constraints.
--
-- 2. SINGLE-COLUMN VS COMPOSITE PRIMARY KEY
--    * Use a SINGLE-column key when one value identifies the row on its own: a surrogate id such
--      as dept_id, customer_id or order_id. It is short, simple to reference from other tables,
--      and stays stable when business data changes.
--    * Use a COMPOSITE key when no single column identifies a row but a combination does,
--      typically in link (many-to-many) tables such as student_courses (student_id, course_id)
--      or order lines (order_id, product_id). It prevents duplicate pairs naturally, but every
--      table that references it must carry all key columns, so keep composite keys short.
--
-- 3. WHY ONLY ONE PRIMARY KEY BUT MANY UNIQUE CONSTRAINTS
--    * The primary key is the single, official identifier of a row: it defines which columns
--      are the "main" identity, which are NOT NULL, and what a bare "REFERENCES table" points to.
--      Two primary keys would make that identity ambiguous.
--    * UNIQUE constraints only add extra rules ("no two users share an email AND no two users
--      share a username"). Such rules are independent of each other, so a table can have as many
--      as the business needs (a person can be identified by id, passport number, and email, all
--      different, but only one of them is chosen as the primary key).
-- =============================================================================
-- PART 5: FOREIGN KEY CONSTRAINTS
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Task 5.1: Basic FOREIGN KEY (employees_dept -> departments)
-- -----------------------------------------------------------------------------
-- REFERENCES departments (without a column list) points to the primary key of departments. Without
-- an ON DELETE clause the default is NO ACTION (deleting a referenced parent fails).
CREATE TABLE employees_dept (
    emp_id    integer PRIMARY KEY,
    emp_name  text NOT NULL,
    dept_id   integer REFERENCES departments,
    hire_date date
);

INSERT INTO employees_dept (emp_id, emp_name, dept_id, hire_date) VALUES
    (1, 'Aigerim Sadykova', 1, '2024-03-01'),
    (2, 'Daniyar Omarov',   2, '2023-07-15'),
    (3, 'Madina Bekova',    1, '2025-01-20'),
    (4, 'Timur Nurzhanov',  NULL, '2026-02-01');

-- Row 4 has dept_id = NULL: a NULL foreign key is allowed (employee not yet assigned).
-- INSERT INTO employees_dept VALUES (5, 'Ghost Worker', 99, '2026-05-01');
-- Violated: employees_dept_dept_id_fkey - department 99 does not exist in departments.
-- TEST RESULT: ERROR [SQLSTATE 23503]: insert or update on table "employees_dept" violates foreign key constraint "employees_dept_dept_id_fkey"
--                 DETAIL: Key (dept_id)=(99) is not present in table "departments".

-- DELETE FROM departments WHERE dept_id = 1;
-- Violated: employees_dept_dept_id_fkey - department 1 is still referenced by employees (default NO
-- ACTION).
-- TEST RESULT: ERROR [SQLSTATE 23503]: update or delete on table "departments" violates foreign key constraint "employees_dept_dept_id_fkey" on table "employees_dept"
--                 DETAIL: Key (dept_id)=(1) is still referenced from table "employees_dept".

-- Only valid references were stored:
SELECT e.emp_id, e.emp_name, d.dept_name
FROM employees_dept e LEFT JOIN departments d ON d.dept_id = e.dept_id
ORDER BY e.emp_id;
-- TEST RESULT:
--  emp_id | emp_name         | dept_name
-- --------+------------------+-------------
--  1      | Aigerim Sadykova | Engineering
--  2      | Daniyar Omarov   | Finance
--  3      | Madina Bekova    | Engineering
--  4      | Timur Nurzhanov  | NULL
--  (4 rows)

-- -----------------------------------------------------------------------------
-- Task 5.2: Multiple FOREIGN KEYS (library system)
-- -----------------------------------------------------------------------------
CREATE TABLE authors (
    author_id   integer PRIMARY KEY,
    author_name text NOT NULL,
    country     text
);

CREATE TABLE publishers (
    publisher_id   integer PRIMARY KEY,
    publisher_name text NOT NULL,
    city           text
);

-- books references both parents; isbn is UNIQUE (an alternative key).
CREATE TABLE books (
    book_id          integer PRIMARY KEY,
    title            text NOT NULL,
    author_id        integer REFERENCES authors,
    publisher_id     integer REFERENCES publishers,
    publication_year integer,
    isbn             text UNIQUE
);

INSERT INTO authors (author_id, author_name, country) VALUES
    (1, 'Mukhtar Auezov', 'Kazakhstan'),
    (2, 'Leo Tolstoy',    'Russia'),
    (3, 'George Orwell',  'United Kingdom'),
    (4, 'Abai Kunanbayuly', 'Kazakhstan');
INSERT INTO publishers (publisher_id, publisher_name, city) VALUES
    (1, 'Zhazushy',      'Almaty'),
    (2, 'Penguin Books', 'London'),
    (3, 'Eksmo',         'Moscow');
INSERT INTO books (book_id, title, author_id, publisher_id, publication_year, isbn) VALUES
    (1, 'Abai Zholy',     1, 1, 1942, '978-0-00-000001-1'),
    (2, 'War and Peace',  2, 3, 1869, '978-0-00-000002-2'),
    (3, 'Anna Karenina',  2, 3, 1878, '978-0-00-000003-3'),
    (4, 'Nineteen Eighty-Four', 3, 2, 1949, '978-0-00-000004-4'),
    (5, 'Animal Farm',    3, 2, 1945, '978-0-00-000005-5');

-- INSERT INTO books VALUES (6, 'Copy Cat', 3, 2, 2000, '978-0-00-000005-5');
-- Violated: books_isbn_key - the ISBN 978-0-00-000005-5 already belongs to 'Animal Farm'.
-- TEST RESULT: ERROR [SQLSTATE 23505]: duplicate key value violates unique constraint "books_isbn_key"
--                 DETAIL: Key (isbn)=(978-0-00-000005-5) already exists.

-- INSERT INTO books VALUES (6, 'Orphan Book', 99, 2, 2000, '978-0-00-000006-6');
-- Violated: books_author_id_fkey - author 99 does not exist.
-- TEST RESULT: ERROR [SQLSTATE 23503]: insert or update on table "books" violates foreign key constraint "books_author_id_fkey"
--                 DETAIL: Key (author_id)=(99) is not present in table "authors".

-- INSERT INTO books VALUES (6, 'Orphan Book', 3, 99, 2000, '978-0-00-000006-6');
-- Violated: books_publisher_id_fkey - publisher 99 does not exist.
-- TEST RESULT: ERROR [SQLSTATE 23503]: insert or update on table "books" violates foreign key constraint "books_publisher_id_fkey"
--                 DETAIL: Key (publisher_id)=(99) is not present in table "publishers".

-- Joining the three tables works because every reference is valid:
SELECT b.book_id, b.title, a.author_name, p.publisher_name, b.publication_year
FROM books b
JOIN authors    a ON a.author_id    = b.author_id
JOIN publishers p ON p.publisher_id = b.publisher_id
ORDER BY b.book_id;
-- TEST RESULT:
--  book_id | title                | author_name    | publisher_name | publication_year
-- ---------+----------------------+----------------+----------------+------------------
--  1       | Abai Zholy           | Mukhtar Auezov | Zhazushy       | 1942
--  2       | War and Peace        | Leo Tolstoy    | Eksmo          | 1869
--  3       | Anna Karenina        | Leo Tolstoy    | Eksmo          | 1878
--  4       | Nineteen Eighty-Four | George Orwell  | Penguin Books  | 1949
--  5       | Animal Farm          | George Orwell  | Penguin Books  | 1945
--  (5 rows)

-- -----------------------------------------------------------------------------
-- Task 5.3: ON DELETE options
-- -----------------------------------------------------------------------------
-- ON DELETE RESTRICT : products_fk.category_id -> a category that still has products cannot be
-- deleted.
-- ON DELETE CASCADE  : order_items.order_id    -> deleting an order deletes its order_items
-- automatically.
-- (default NO ACTION): order_items.product_id  -> a product that appears in order_items cannot be
-- deleted.
-- RESTRICT and NO ACTION both reject the delete; the only difference is that NO ACTION may be
-- deferred to the end of a transaction, RESTRICT is checked immediately.
CREATE TABLE categories (
    category_id   integer PRIMARY KEY,
    category_name text NOT NULL
);

CREATE TABLE products_fk (
    product_id   integer PRIMARY KEY,
    product_name text NOT NULL,
    category_id  integer REFERENCES categories ON DELETE RESTRICT
);

CREATE TABLE orders (
    order_id   integer PRIMARY KEY,
    order_date date NOT NULL
);

CREATE TABLE order_items (
    item_id    integer PRIMARY KEY,
    order_id   integer REFERENCES orders ON DELETE CASCADE,
    product_id integer REFERENCES products_fk,
    quantity   integer CHECK (quantity > 0)
);

INSERT INTO categories (category_id, category_name) VALUES
    (1, 'Electronics'), (2, 'Books'), (3, 'Toys');
INSERT INTO products_fk (product_id, product_name, category_id) VALUES
    (1, 'Laptop', 1), (2, 'Smartphone', 1), (3, 'Novel', 2);
INSERT INTO orders (order_id, order_date) VALUES
    (1, '2026-10-01'), (2, '2026-10-05');
INSERT INTO order_items (item_id, order_id, product_id, quantity) VALUES
    (1, 1, 1, 1),
    (2, 1, 3, 2),
    (3, 2, 2, 1),
    (4, 2, 3, 3);

-- --- Scenario 1: ON DELETE RESTRICT ---
-- DELETE FROM categories WHERE category_id = 1;
-- Violated: products_fk_category_id_fkey (ON DELETE RESTRICT) - category 1 'Electronics' still has
-- products, so it cannot be deleted. Nothing is changed.
-- TEST RESULT: ERROR [SQLSTATE 23503]: update or delete on table "categories" violates foreign key constraint "products_fk_category_id_fkey" on table "products_fk"
--                 DETAIL: Key (category_id)=(1) is still referenced from table "products_fk".

-- Category 3 'Toys' has no products, so RESTRICT does not block its deletion:
DELETE FROM categories WHERE category_id = 3;

-- Result: 'Electronics' and 'Books' remain, only the unreferenced 'Toys' was deleted:
SELECT * FROM categories ORDER BY category_id;
-- TEST RESULT:
--  category_id | category_name
-- -------------+---------------
--  1           | Electronics
--  2           | Books
--  (2 rows)

-- --- Scenario 2: ON DELETE CASCADE ---
-- BEFORE deleting order 1 - order_items holds 4 rows (2 of them belong to order 1):
SELECT item_id, order_id, product_id, quantity FROM order_items ORDER BY item_id;
-- TEST RESULT:
--  item_id | order_id | product_id | quantity
-- ---------+----------+------------+----------
--  1       | 1        | 1          | 1
--  2       | 1        | 3          | 2
--  3       | 2        | 2          | 1
--  4       | 2        | 3          | 3
--  (4 rows)

DELETE FROM orders WHERE order_id = 1;

-- AFTER deleting order 1 - items 1 and 2 were removed automatically by CASCADE; order 2's items are
-- untouched:
SELECT item_id, order_id, product_id, quantity FROM order_items ORDER BY item_id;
-- TEST RESULT:
--  item_id | order_id | product_id | quantity
-- ---------+----------+------------+----------
--  3       | 2        | 2          | 1
--  4       | 2        | 3          | 3
--  (2 rows)

-- CASCADE only affects the child rows: the products themselves are still there:
SELECT product_id, product_name FROM products_fk ORDER BY product_id;
-- TEST RESULT:
--  product_id | product_name
-- ------------+--------------
--  1          | Laptop
--  2          | Smartphone
--  3          | Novel
--  (3 rows)

-- --- Extra checks on order_items ---
-- DELETE FROM products_fk WHERE product_id = 3;
-- Violated: order_items_product_id_fkey (default NO ACTION) - product 3 'Novel' is still used by
-- order item 4.
-- TEST RESULT: ERROR [SQLSTATE 23503]: update or delete on table "products_fk" violates foreign key constraint "order_items_product_id_fkey" on table "order_items"
--                 DETAIL: Key (product_id)=(3) is still referenced from table "order_items".

-- INSERT INTO order_items VALUES (5, 2, 1, 0);
-- Violated: order_items_quantity_check - quantity must be greater than 0.
-- TEST RESULT: ERROR [SQLSTATE 23514]: new row for relation "order_items" violates check constraint "order_items_quantity_check"
--                 DETAIL: Failing row contains (5, 2, 1, 0).

-- INSERT INTO order_items VALUES (5, 99, 1, 1);
-- Violated: order_items_order_id_fkey - order 99 does not exist.
-- TEST RESULT: ERROR [SQLSTATE 23503]: insert or update on table "order_items" violates foreign key constraint "order_items_order_id_fkey"
--                 DETAIL: Key (order_id)=(99) is not present in table "orders".

-- --- Scenario 3: documentation of what happened ---
-- * DELETE category 1 (RESTRICT): FAILED with a foreign-key violation, no rows changed, because
--   products_fk still references it. A parent row cannot disappear while children depend on it.
-- * DELETE category 3 (RESTRICT, no children): succeeded - RESTRICT only blocks deletes that
--   would leave orphans.
-- * DELETE order 1 (CASCADE): succeeded, and PostgreSQL also deleted the order_items rows that
--   referenced it (items 1 and 2). The child rows had no meaning without their parent order.
-- * DELETE product 3 (NO ACTION): FAILED because order item 4 still references it.
-- =============================================================================
-- PART 6: PRACTICAL APPLICATION
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Task 6.1: E-commerce database
-- -----------------------------------------------------------------------------
-- All tables are created in the schema "ecommerce" (earlier tasks already used the table names
-- customers / products / orders in the default schema).
--
-- Design decisions (ON DELETE behaviours):
--   * orders.customer_id        -> ON DELETE RESTRICT : a customer with orders cannot be deleted,
--                                  so the order history / financial records are never lost.
--   * order_details.order_id    -> ON DELETE CASCADE  : the lines of an order are part of the
-- order;
--                                  deleting the order deletes its lines.
--   * order_details.product_id  -> ON DELETE RESTRICT : a product that was sold cannot be deleted,
--                                  so old orders stay readable.
CREATE SCHEMA ecommerce;

SET search_path TO ecommerce;

-- customers: PRIMARY KEY on customer_id; email is UNIQUE and NOT NULL (one account per email).
CREATE TABLE customers (
    customer_id       integer PRIMARY KEY,
    name              text    NOT NULL,
    email             text    NOT NULL UNIQUE,
    phone             text,                                   -- optional
    registration_date date    NOT NULL DEFAULT CURRENT_DATE
);

-- products: price and stock_quantity can never be negative (CHECK >= 0).
CREATE TABLE products (
    product_id     integer       PRIMARY KEY,
    name           text          NOT NULL,
    description    text,                                      -- optional
    price          numeric(10,2) NOT NULL CHECK (price >= 0),
    stock_quantity integer       NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0)
);

-- orders: status is limited to five allowed values; total_amount cannot be negative.
CREATE TABLE orders (
    order_id     integer       PRIMARY KEY,
    customer_id  integer       NOT NULL REFERENCES customers ON DELETE RESTRICT,
    order_date   date          NOT NULL DEFAULT CURRENT_DATE,
    total_amount numeric(12,2) NOT NULL DEFAULT 0 CHECK (total_amount >= 0),
    status       text          NOT NULL DEFAULT 'pending'
                 CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled'))
);

-- order_details: quantity must be positive; unit_price is the price at the time of the order (a
-- copy, so later price changes do not rewrite history).
CREATE TABLE order_details (
    order_detail_id integer       PRIMARY KEY,
    order_id        integer       NOT NULL REFERENCES orders   ON DELETE CASCADE,
    product_id      integer       NOT NULL REFERENCES products ON DELETE RESTRICT,
    quantity        integer       NOT NULL CHECK (quantity > 0),
    unit_price      numeric(10,2) NOT NULL CHECK (unit_price >= 0)
);

-- Sample data (5 customers, 5 products, 5 orders, 8 order lines). Prices are in tenge.
INSERT INTO customers (customer_id, name, email, phone, registration_date) VALUES
    (1, 'Aigerim Sadykova',  'aigerim@example.kz', '+7 701 111 2233', '2026-01-15'),
    (2, 'Daniyar Omarov',    'daniyar@example.kz', '+7 702 222 3344', '2026-02-20'),
    (3, 'Madina Bekova',     'madina@example.kz',  NULL,              '2026-03-02'),
    (4, 'Timur Nurzhanov',   'timur@example.kz',   '+7 705 444 5566', '2026-03-10'),
    (5, 'Aliya Kassymova',   'aliya@example.kz',   '+7 707 555 6677', '2026-04-05');

INSERT INTO products (product_id, name, description, price, stock_quantity) VALUES
    (1, 'Laptop',     '15-inch laptop, 16 GB RAM',   450000.00,  15),
    (2, 'Smartphone', '6.5-inch display, 128 GB',    250000.00,  40),
    (3, 'Headphones', 'Wireless over-ear headphones', 25000.00, 100),
    (4, 'Keyboard',   'Mechanical keyboard',          15000.00,  60),
    (5, 'Monitor',    '27-inch 4K monitor',          120000.00,  25);

INSERT INTO orders (order_id, customer_id, order_date, total_amount, status) VALUES
    (1, 1, '2026-09-01', 500000.00, 'delivered'),
    (2, 2, '2026-09-05', 250000.00, 'shipped'),
    (3, 3, '2026-09-10', 150000.00, 'processing'),
    (4, 4, '2026-09-15',  40000.00, 'pending'),
    (5, 5, '2026-09-20', 240000.00, 'cancelled');

INSERT INTO order_details (order_detail_id, order_id, product_id, quantity, unit_price) VALUES
    (1, 1, 1, 1, 450000.00),
    (2, 1, 3, 2,  25000.00),
    (3, 2, 2, 1, 250000.00),
    (4, 3, 4, 2,  15000.00),
    (5, 3, 5, 1, 120000.00),
    (6, 4, 3, 1,  25000.00),
    (7, 4, 4, 1,  15000.00),
    (8, 5, 5, 2, 120000.00);

-- TEST QUERIES - all constraints in the e-commerce schema
-- Test A: row counts (every table has at least 5 rows).
SELECT 'customers' AS table_name, count(*) AS rows FROM customers
UNION ALL SELECT 'products',      count(*) FROM products
UNION ALL SELECT 'orders',        count(*) FROM orders
UNION ALL SELECT 'order_details', count(*) FROM order_details;
-- TEST RESULT:
--  table_name    | rows
-- ---------------+------
--  customers     | 5
--  products      | 5
--  orders        | 5
--  order_details | 8
--  (4 rows)

-- Test B: data consistency - total_amount equals the sum of its order lines (all 'ok').
SELECT o.order_id, o.total_amount, sum(d.quantity * d.unit_price) AS lines_total,
       CASE WHEN o.total_amount = sum(d.quantity * d.unit_price) THEN 'ok' ELSE 'MISMATCH' END AS check
FROM orders o JOIN order_details d ON d.order_id = o.order_id
GROUP BY o.order_id, o.total_amount
ORDER BY o.order_id;
-- TEST RESULT:
--  order_id | total_amount | lines_total | check
-- ----------+--------------+-------------+-------
--  1        | 500000.00    | 500000.00   | ok
--  2        | 250000.00    | 250000.00   | ok
--  3        | 150000.00    | 150000.00   | ok
--  4        | 40000.00     | 40000.00    | ok
--  5        | 240000.00    | 240000.00   | ok
--  (5 rows)

-- Test C: PRIMARY KEY constraints.
-- INSERT INTO customers (customer_id, name, email) VALUES (1, 'Duplicate Id', 'dup.id@example.kz');
-- Violated: customers_pkey - customer_id 1 already exists.
-- TEST RESULT: ERROR [SQLSTATE 23505]: duplicate key value violates unique constraint "customers_pkey"
--                 DETAIL: Key (customer_id)=(1) already exists.

-- INSERT INTO products (product_id, name, price) VALUES (NULL, 'No Id', 10);
-- Violated: PRIMARY KEY implies NOT NULL - product_id cannot be NULL.
-- TEST RESULT: ERROR [SQLSTATE 23502]: null value in column "product_id" of relation "products" violates not-null constraint
--                 DETAIL: Failing row contains (null, No Id, null, 10.00, 0).

-- Test D: UNIQUE constraint on customer email.
-- INSERT INTO customers (customer_id, name, email) VALUES (6, 'Second Aigerim', 'aigerim@example.kz');
-- Violated: customers_email_key - the email 'aigerim@example.kz' is already registered.
-- TEST RESULT: ERROR [SQLSTATE 23505]: duplicate key value violates unique constraint "customers_email_key"
--                 DETAIL: Key (email)=(aigerim@example.kz) already exists.

-- Test E: NOT NULL constraints.
-- INSERT INTO customers (customer_id, name, email) VALUES (6, NULL, 'noname@example.kz');
-- Violated: NOT NULL on customers.name.
-- TEST RESULT: ERROR [SQLSTATE 23502]: null value in column "name" of relation "customers" violates not-null constraint
--                 DETAIL: Failing row contains (6, null, noname@example.kz, null, 2026-10-14).

-- INSERT INTO customers (customer_id, name, email) VALUES (6, 'No Email', NULL);
-- Violated: NOT NULL on customers.email.
-- TEST RESULT: ERROR [SQLSTATE 23502]: null value in column "email" of relation "customers" violates not-null constraint
--                 DETAIL: Failing row contains (6, No Email, null, null, 2026-10-14).

-- INSERT INTO orders (order_id, customer_id, order_date) VALUES (6, NULL, '2026-10-01');
-- Violated: NOT NULL on orders.customer_id (an order must belong to a customer).
-- TEST RESULT: ERROR [SQLSTATE 23502]: null value in column "customer_id" of relation "orders" violates not-null constraint
--                 DETAIL: Failing row contains (6, null, 2026-10-01, 0.00, pending).

-- INSERT INTO order_details VALUES (9, 1, 1, NULL, 100);
-- Violated: NOT NULL on order_details.quantity.
-- TEST RESULT: ERROR [SQLSTATE 23502]: null value in column "quantity" of relation "order_details" violates not-null constraint
--                 DETAIL: Failing row contains (9, 1, 1, null, 100.00).

-- Test F: CHECK - price and stock_quantity must be non-negative.
-- INSERT INTO products (product_id, name, price, stock_quantity) VALUES (6, 'Bad Price', -1, 10);
-- Violated: products_price_check - price cannot be negative.
-- TEST RESULT: ERROR [SQLSTATE 23514]: new row for relation "products" violates check constraint "products_price_check"
--                 DETAIL: Failing row contains (6, Bad Price, null, -1.00, 10).

-- INSERT INTO products (product_id, name, price, stock_quantity) VALUES (6, 'Bad Stock', 100, -5);
-- Violated: products_stock_quantity_check - stock_quantity cannot be negative.
-- TEST RESULT: ERROR [SQLSTATE 23514]: new row for relation "products" violates check constraint "products_stock_quantity_check"
--                 DETAIL: Failing row contains (6, Bad Stock, null, 100.00, -5).

-- UPDATE products SET stock_quantity = stock_quantity - 20 WHERE product_id = 1;
-- Violated: products_stock_quantity_check - UPDATE is checked too: selling 20 laptops when only 15
-- are in stock would give -5.
-- TEST RESULT: ERROR [SQLSTATE 23514]: new row for relation "products" violates check constraint "products_stock_quantity_check"
--                 DETAIL: Failing row contains (1, Laptop, 15-inch laptop, 16 GB RAM, 450000.00, -5).

-- A zero price / zero stock is allowed (constraint is >= 0):
INSERT INTO products (product_id, name, description, price, stock_quantity)
VALUES (99, 'Free Sample', 'Promotional item', 0, 0);

DELETE FROM products WHERE product_id = 99;

-- Test G: CHECK - order status must be one of the 5 allowed values.
-- INSERT INTO orders (order_id, customer_id, status) VALUES (6, 1, 'returned');
-- Violated: orders_status_check - 'returned' is not in
-- ('pending','processing','shipped','delivered','cancelled').
-- TEST RESULT: ERROR [SQLSTATE 23514]: new row for relation "orders" violates check constraint "orders_status_check"
--                 DETAIL: Failing row contains (6, 1, 2026-10-14, 0.00, returned).

-- UPDATE orders SET status = 'lost' WHERE order_id = 4;
-- Violated: orders_status_check - UPDATE to an invalid status is rejected.
-- TEST RESULT: ERROR [SQLSTATE 23514]: new row for relation "orders" violates check constraint "orders_status_check"
--                 DETAIL: Failing row contains (4, 4, 2026-09-15, 40000.00, lost).

-- INSERT INTO orders (order_id, customer_id, total_amount) VALUES (6, 1, -10);
-- Violated: orders_total_amount_check - total_amount cannot be negative.
-- TEST RESULT: ERROR [SQLSTATE 23514]: new row for relation "orders" violates check constraint "orders_total_amount_check"
--                 DETAIL: Failing row contains (6, 1, 2026-10-14, -10.00, pending).

-- A valid status change works, and a missing status uses the DEFAULT 'pending':
UPDATE orders SET status = 'shipped' WHERE order_id = 4;

INSERT INTO orders (order_id, customer_id) VALUES (6, 1);

SELECT order_id, status, total_amount, order_date = CURRENT_DATE AS date_defaulted FROM orders WHERE order_id IN (4, 6) ORDER BY order_id;
-- TEST RESULT:
--  order_id | status  | total_amount | date_defaulted
-- ----------+---------+--------------+----------------
--  4        | shipped | 40000.00     | False
--  6        | pending | 0.00         | True
--  (2 rows)

-- Test H: CHECK - quantity in order_details must be positive.
-- INSERT INTO order_details VALUES (9, 6, 1, 0, 450000);
-- Violated: order_details_quantity_check - quantity 0 is not positive.
-- TEST RESULT: ERROR [SQLSTATE 23514]: new row for relation "order_details" violates check constraint "order_details_quantity_check"
--                 DETAIL: Failing row contains (9, 6, 1, 0, 450000.00).

-- INSERT INTO order_details VALUES (9, 6, 1, -3, 450000);
-- Violated: order_details_quantity_check - quantity -3 is not positive.
-- TEST RESULT: ERROR [SQLSTATE 23514]: new row for relation "order_details" violates check constraint "order_details_quantity_check"
--                 DETAIL: Failing row contains (9, 6, 1, -3, 450000.00).

-- INSERT INTO order_details VALUES (9, 6, 1, 1, -450000);
-- Violated: order_details_unit_price_check - unit_price cannot be negative.
-- TEST RESULT: ERROR [SQLSTATE 23514]: new row for relation "order_details" violates check constraint "order_details_unit_price_check"
--                 DETAIL: Failing row contains (9, 6, 1, 1, -450000.00).

-- Test I: FOREIGN KEY constraints.
-- INSERT INTO orders (order_id, customer_id) VALUES (7, 999);
-- Violated: orders_customer_id_fkey - customer 999 does not exist.
-- TEST RESULT: ERROR [SQLSTATE 23503]: insert or update on table "orders" violates foreign key constraint "orders_customer_id_fkey"
--                 DETAIL: Key (customer_id)=(999) is not present in table "customers".

-- INSERT INTO order_details VALUES (9, 999, 1, 1, 100);
-- Violated: order_details_order_id_fkey - order 999 does not exist.
-- TEST RESULT: ERROR [SQLSTATE 23503]: insert or update on table "order_details" violates foreign key constraint "order_details_order_id_fkey"
--                 DETAIL: Key (order_id)=(999) is not present in table "orders".

-- INSERT INTO order_details VALUES (9, 6, 999, 1, 100);
-- Violated: order_details_product_id_fkey - product 999 does not exist.
-- TEST RESULT: ERROR [SQLSTATE 23503]: insert or update on table "order_details" violates foreign key constraint "order_details_product_id_fkey"
--                 DETAIL: Key (product_id)=(999) is not present in table "products".

-- Test J: ON DELETE RESTRICT - customers with orders and products that were sold cannot be deleted.
-- DELETE FROM customers WHERE customer_id = 1;
-- Violated: orders_customer_id_fkey (ON DELETE RESTRICT) - customer 1 still has orders.
-- TEST RESULT: ERROR [SQLSTATE 23503]: update or delete on table "customers" violates foreign key constraint "orders_customer_id_fkey" on table "orders"
--                 DETAIL: Key (customer_id)=(1) is still referenced from table "orders".

-- DELETE FROM products WHERE product_id = 1;
-- Violated: order_details_product_id_fkey (ON DELETE RESTRICT) - product 1 appears in
-- order_details.
-- TEST RESULT: ERROR [SQLSTATE 23503]: update or delete on table "products" violates foreign key constraint "order_details_product_id_fkey" on table "order_details"
--                 DETAIL: Key (product_id)=(1) is still referenced from table "order_details".

-- A customer WITHOUT orders can be deleted (temporary customer 100):
INSERT INTO customers (customer_id, name, email) VALUES (100, 'Temporary Customer', 'temp@example.kz');

DELETE FROM customers WHERE customer_id = 100;

-- Test K: ON DELETE CASCADE - deleting an order deletes its order lines. Order 6 is given two
-- lines, then deleted.
INSERT INTO order_details (order_detail_id, order_id, product_id, quantity, unit_price) VALUES
    (9,  6, 3, 1, 25000.00),
    (10, 6, 4, 2, 15000.00);

-- Before:
SELECT count(*) AS lines_of_order_6 FROM order_details WHERE order_id = 6;
-- TEST RESULT:
--  lines_of_order_6
-- ------------------
--  2
--  (1 row)

DELETE FROM orders WHERE order_id = 6;

-- After deleting order 6 - its two lines were removed automatically (CASCADE):
SELECT count(*) AS lines_of_order_6 FROM order_details WHERE order_id = 6;
-- TEST RESULT:
--  lines_of_order_6
-- ------------------
--  0
--  (1 row)

-- The original 5 sample orders are untouched:
SELECT count(*) AS orders_left FROM orders;
-- TEST RESULT:
--  orders_left
-- -------------
--  5
--  (1 row)

-- Test L: list of all constraints that were created in the schema (p = primary key, f = foreign
-- key, u = unique, c = check).
SELECT conrelid::regclass AS table_name, conname, contype
FROM pg_constraint
WHERE connamespace = 'ecommerce'::regnamespace AND contype IN ('p', 'f', 'u', 'c')
ORDER BY conrelid::regclass::text, contype, conname;
-- TEST RESULT:
--  table_name    | conname                        | contype
-- ---------------+--------------------------------+---------
--  customers     | customers_pkey                 | p
--  customers     | customers_email_key            | u
--  order_details | order_details_quantity_check   | c
--  order_details | order_details_unit_price_check | c
--  order_details | order_details_order_id_fkey    | f
--  order_details | order_details_product_id_fkey  | f
--  order_details | order_details_pkey             | p
--  orders        | orders_status_check            | c
--  orders        | orders_total_amount_check      | c
--  orders        | orders_customer_id_fkey        | f
--  orders        | orders_pkey                    | p
--  products      | products_price_check           | c
--  products      | products_stock_quantity_check  | c
--  products      | products_pkey                  | p
--  (14 rows)

RESET search_path;

-- =============================== END OF FILE ===============================
