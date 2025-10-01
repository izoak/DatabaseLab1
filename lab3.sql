DROP DATABASE IF EXISTS advanced_lab;
CREATE DATABASE advanced_lab;
DROP TABLE IF EXISTS employee_archive CASCADE;
DROP TABLE IF EXISTS temp_employees CASCADE;
DROP TABLE IF EXISTS projects CASCADE;
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS departments CASCADE;

CREATE TABLE departments (
    dept_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    dept_name VARCHAR(100) NOT NULL UNIQUE,
    budget INTEGER DEFAULT 0,
    manager_id BIGINT
);

CREATE TABLE employees (
    emp_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    dept_id BIGINT REFERENCES departments(dept_id),
    salary INTEGER DEFAULT 30000,
    hire_date DATE NOT NULL DEFAULT CURRENT_DATE,
    status VARCHAR(20) DEFAULT 'Active',
    CONSTRAINT uniq_emp_name UNIQUE (first_name, last_name)
);

ALTER TABLE departments
ADD CONSTRAINT fk_manager FOREIGN KEY (manager_id) REFERENCES employees(emp_id) ON DELETE SET NULL;

CREATE TABLE projects (
    project_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    project_name VARCHAR(200) NOT NULL,
    dept_id BIGINT REFERENCES departments(dept_id) ON DELETE SET NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    budget INTEGER DEFAULT 0
);

INSERT INTO departments (dept_name, budget) VALUES
  ('IT', 120000),
  ('HR', 40000),
  ('Sales', 90000),
  ('Finance', 300000),
  ('Management', 200000),
  ('Senior', 50000),
  ('Junior', 10000),
  ('Unassigned', 0),
  ('Engineering', 150000);

INSERT INTO employees (first_name, last_name, dept_id, salary, hire_date, status) VALUES
  ('Ivan', 'Petrov', (SELECT dept_id FROM departments WHERE dept_name='IT' LIMIT 1), 60000, DATE '2018-03-15', 'Active'),
  ('Anna', 'Sidorova', (SELECT dept_id FROM departments WHERE dept_name='HR' LIMIT 1), 45000, DATE '2021-06-10', 'Active'),
  ('Olga', 'Kuznetsova', (SELECT dept_id FROM departments WHERE dept_name='Finance' LIMIT 1), 70000, DATE '2019-09-01', 'Active'),
  ('Pavel', 'Smirnov', (SELECT dept_id FROM departments WHERE dept_name='Sales' LIMIT 1), 45000, DATE '2019-06-01', 'Active'),
  ('Marina', 'Volkova', (SELECT dept_id FROM departments WHERE dept_name='Sales' LIMIT 1), 52000, DATE '2021-02-15', 'Active'),
  ('Sergey', 'Belov', (SELECT dept_id FROM departments WHERE dept_name='IT' LIMIT 1), 75000, DATE '2018-11-10', 'Active'),
  ('Elena', 'Novikova', (SELECT dept_id FROM departments WHERE dept_name='HR' LIMIT 1), 38000, DATE '2024-03-20', 'Active'),
  ('Nikolay', 'Orlov', NULL, NULL, DATE '2024-09-01', 'Inactive');

INSERT INTO employees (first_name, last_name, dept_id, hire_date)
VALUES ('Default', 'User', (SELECT dept_id FROM departments WHERE dept_name='Engineering' LIMIT 1), CURRENT_DATE);

INSERT INTO employees (first_name, last_name, dept_id, hire_date, salary)
VALUES ('Dmitry', 'Ivanov', (SELECT dept_id FROM departments WHERE dept_name='IT' LIMIT 1), CURRENT_DATE, CAST(50000 * 1.1 AS INTEGER));

CREATE TEMP TABLE temp_employees AS
SELECT * FROM employees
WHERE dept_id = (SELECT dept_id FROM departments WHERE dept_name='IT' LIMIT 1);

INSERT INTO projects (project_name, dept_id, start_date, end_date, budget) VALUES
  ('Legacy Cleanup', (SELECT dept_id FROM departments WHERE dept_name='IT' LIMIT 1), DATE '2020-01-01', DATE '2022-06-01', 20000),
  ('Old Research', (SELECT dept_id FROM departments WHERE dept_name='HR' LIMIT 1), DATE '2019-05-01', DATE '2022-12-31', 15000),
  ('Active Expansion', (SELECT dept_id FROM departments WHERE dept_name='Sales' LIMIT 1), DATE '2024-01-01', DATE '2025-12-31', 75000),
  ('Big Initiative', (SELECT dept_id FROM departments WHERE dept_name='Engineering' LIMIT 1), DATE '2023-01-01', DATE '2024-12-31', 60000);

UPDATE employees
SET salary = CAST(ROUND(salary * 1.10) AS INTEGER)
WHERE salary IS NOT NULL;

UPDATE employees
SET status = 'Senior'
WHERE salary > 60000
  AND hire_date < DATE '2020-01-01';

UPDATE employees
SET dept_id = CASE
    WHEN salary > 80000 THEN (SELECT dept_id FROM departments WHERE dept_name = 'Management' LIMIT 1)
    WHEN salary BETWEEN 50000 AND 80000 THEN (SELECT dept_id FROM departments WHERE dept_name = 'Senior' LIMIT 1)
    ELSE (SELECT dept_id FROM departments WHERE dept_name = 'Junior' LIMIT 1)
END
WHERE salary IS NOT NULL;

UPDATE employees
SET dept_id = DEFAULT
WHERE status = 'Inactive';

UPDATE departments d
SET budget = CAST(ROUND(budget + 0.20 * COALESCE(sub.avg_sal, 0)) AS INTEGER)
FROM (
    SELECT dept_id, AVG(salary) AS avg_sal
    FROM employees
    WHERE dept_id IS NOT NULL
    GROUP BY dept_id
) AS sub
WHERE d.dept_id = sub.dept_id;

UPDATE employees
SET salary = CAST(ROUND(salary * 1.15) AS INTEGER),
    status = 'Promoted'
WHERE dept_id = (SELECT dept_id FROM departments WHERE dept_name = 'Sales' LIMIT 1)
  AND salary IS NOT NULL;

DELETE FROM employees
WHERE status = 'Terminated';

DELETE FROM employees
WHERE salary < 40000
  AND hire_date > DATE '2023-01-01'
  AND dept_id IS NULL;

DELETE FROM departments
WHERE dept_id NOT IN (
    SELECT DISTINCT dept_id FROM employees WHERE dept_id IS NOT NULL
);

DELETE FROM projects
WHERE end_date < DATE '2023-01-01'
RETURNING *;

INSERT INTO employees (first_name, last_name, dept_id, salary, hire_date, status)
VALUES ('Null', 'Employee', NULL, NULL, CURRENT_DATE, 'Active');

UPDATE employees
SET dept_id = (SELECT dept_id FROM departments WHERE dept_name = 'Unassigned' LIMIT 1)
WHERE dept_id IS NULL;

DELETE FROM employees
WHERE salary IS NULL OR dept_id IS NULL
RETURNING emp_id, first_name, last_name, salary, dept_id;

INSERT INTO employees (first_name, last_name, dept_id, salary, hire_date)
VALUES ('Igor', 'Kovalenko', (SELECT dept_id FROM departments WHERE dept_name='IT' LIMIT 1), 68000, CURRENT_DATE)
RETURNING emp_id, (first_name || ' ' || last_name) AS full_name;

WITH old AS (
    SELECT emp_id, salary AS old_salary
    FROM employees
    WHERE dept_id = (SELECT dept_id FROM departments WHERE dept_name='IT' LIMIT 1)
)
UPDATE employees e
SET salary = e.salary + 5000
FROM old
WHERE e.emp_id = old.emp_id
RETURNING e.emp_id, old.old_salary, e.salary AS new_salary;

DELETE FROM employees
WHERE hire_date < DATE '2020-01-01'
RETURNING *;

INSERT INTO employees (first_name, last_name, dept_id, salary, hire_date)
SELECT 'Viktor', 'Zaitsev', (SELECT dept_id FROM departments WHERE dept_name='Engineering' LIMIT 1), 55000, CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 FROM employees e WHERE e.first_name = 'Viktor' AND e.last_name = 'Zaitsev'
);

UPDATE employees e
SET salary = CAST(ROUND(
    CASE
        WHEN d.budget > 100000 THEN e.salary * 1.10
        ELSE e.salary * 1.05
    END
) AS INTEGER)
FROM departments d
WHERE e.dept_id = d.dept_id
  AND e.salary IS NOT NULL;

INSERT INTO employees (first_name, last_name, dept_id, salary, hire_date)
VALUES
  ('Ashot', 'Kara', (SELECT dept_id FROM departments WHERE dept_name='HR' LIMIT 1), 32000, CURRENT_DATE),
  ('Lilia', 'Gromova', (SELECT dept_id FROM departments WHERE dept_name='Finance' LIMIT 1), 41000, CURRENT_DATE),
  ('Yuri', 'Klein', (SELECT dept_id FROM departments WHERE dept_name='Sales' LIMIT 1), 46000, CURRENT_DATE),
  ('Sofia', 'Mikhailova', (SELECT dept_id FROM departments WHERE dept_name='IT' LIMIT 1), 54000, CURRENT_DATE),
  ('Anton', 'Zhukov', (SELECT dept_id FROM departments WHERE dept_name='Sales' LIMIT 1), 47000, CURRENT_DATE);

UPDATE employees
SET salary = CAST(ROUND(salary * 1.10) AS INTEGER)
WHERE hire_date = CURRENT_DATE
  AND first_name IN ('Ashot', 'Lilia', 'Yuri', 'Sofia', 'Anton')
  AND salary IS NOT NULL;

CREATE TABLE employee_archive AS
SELECT * FROM employees WHERE 1=0;

INSERT INTO employee_archive
SELECT * FROM employees
WHERE status = 'Inactive';

DELETE FROM employees
WHERE status = 'Inactive';

UPDATE projects p
SET end_date = p.end_date + INTERVAL '30 days'
FROM (
    SELECT d.dept_id
    FROM departments d
    JOIN employees e ON e.dept_id = d.dept_id
    GROUP BY d.dept_id
    HAVING COUNT(e.emp_id) > 3
) AS rich_depts
WHERE p.dept_id = rich_depts.dept_id
  AND p.budget > 50000
  AND p.end_date IS NOT NULL;

SELECT * FROM employees ORDER BY emp_id;
SELECT * FROM departments ORDER BY dept_id;
SELECT * FROM projects ORDER BY project_id;
SELECT * FROM temp_employees;
SELECT * FROM employee_archive;
