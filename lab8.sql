BEGIN;

DROP VIEW IF EXISTS index_documentation;
DROP TABLE IF EXISTS projects;
DROP TABLE IF EXISTS employees;
DROP TABLE IF EXISTS departments;

CREATE TABLE departments (
  dept_id INT PRIMARY KEY,
  dept_name VARCHAR(50),
  location VARCHAR(50)
);

CREATE TABLE employees (
  emp_id INT PRIMARY KEY,
  emp_name VARCHAR(100),
  dept_id INT,
  salary DECIMAL(10,2),
  CONSTRAINT fk_emp_dept FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

CREATE TABLE projects (
  proj_id INT PRIMARY KEY,
  proj_name VARCHAR(100),
  budget DECIMAL(12,2),
  dept_id INT,
  CONSTRAINT fk_proj_dept FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

INSERT INTO departments (dept_id, dept_name, location) VALUES
  (101, 'IT', 'Building A'),
  (102, 'HR', 'Building B'),
  (103, 'Operations', 'Building C')
ON CONFLICT (dept_id) DO NOTHING;

INSERT INTO employees (emp_id, emp_name, dept_id, salary) VALUES
  (1, 'John Smith', 101, 50000),
  (2, 'Jane Doe', 101, 55000),
  (3, 'Mike Johnson', 102, 48000),
  (4, 'Sarah Williams', 102, 52000),
  (5, 'Tom Brown', 103, 60000)
ON CONFLICT (emp_id) DO NOTHING;

INSERT INTO projects (proj_id, proj_name, budget, dept_id) VALUES
  (201, 'Website Redesign', 75000, 101),
  (202, 'Database Migration', 120000, 101),
  (203, 'HR System Upgrade', 50000, 102)
ON CONFLICT (proj_id) DO NOTHING;

-- Part 2
DROP INDEX IF EXISTS emp_salary_idx;
DROP INDEX IF EXISTS emp_dept_idx;

CREATE INDEX IF NOT EXISTS emp_salary_idx ON employees (salary);
CREATE INDEX IF NOT EXISTS emp_dept_idx ON employees (dept_id);

-- Part 3
DROP INDEX IF EXISTS emp_dept_salary_idx;
DROP INDEX IF EXISTS emp_salary_dept_idx;

CREATE INDEX IF NOT EXISTS emp_dept_salary_idx ON employees (dept_id, salary);
CREATE INDEX IF NOT EXISTS emp_salary_dept_idx ON employees (salary, dept_id);

-- Part 4
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_name='employees' AND column_name='email') THEN
    ALTER TABLE employees ADD COLUMN email VARCHAR(100);
  END IF;
END$$;

UPDATE employees SET email = CASE emp_id
  WHEN 1 THEN COALESCE(email, 'john.smith@company.com')
  WHEN 2 THEN COALESCE(email, 'jane.doe@company.com')
  WHEN 3 THEN COALESCE(email, 'mike.johnson@company.com')
  WHEN 4 THEN COALESCE(email, 'sarah.williams@company.com')
  WHEN 5 THEN COALESCE(email, 'tom.brown@company.com')
  ELSE email END;

DROP INDEX IF EXISTS emp_email_unique_idx;
CREATE UNIQUE INDEX IF NOT EXISTS emp_email_unique_idx ON employees (email);

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_name='employees' AND column_name='phone') THEN
    ALTER TABLE employees ADD COLUMN phone VARCHAR(20) UNIQUE;
  ELSE
    BEGIN
      ALTER TABLE employees ADD CONSTRAINT employees_phone_key UNIQUE (phone);
    EXCEPTION WHEN duplicate_table THEN
      NULL;
    EXCEPTION WHEN unique_violation THEN
      RAISE NOTICE 'Cannot add UNIQUE constraint on phone because duplicates exist.';
    END;
  END IF;
END$$;

-- Part 5
DROP INDEX IF EXISTS emp_salary_desc_idx;
CREATE INDEX IF NOT EXISTS emp_salary_desc_idx ON employees (salary DESC);

DROP INDEX IF EXISTS proj_budget_nulls_first_idx;
CREATE INDEX IF NOT EXISTS proj_budget_nulls_first_idx ON projects (budget NULLS FIRST);

-- Part 6
DROP INDEX IF EXISTS emp_name_lower_idx;
CREATE INDEX IF NOT EXISTS emp_name_lower_idx ON employees (LOWER(emp_name));

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_name='employees' AND column_name='hire_date') THEN
    ALTER TABLE employees ADD COLUMN hire_date DATE;
  END IF;
END$$;

UPDATE employees SET hire_date = CASE emp_id
  WHEN 1 THEN COALESCE(hire_date, '2020-01-15')
  WHEN 2 THEN COALESCE(hire_date, '2019-06-20')
  WHEN 3 THEN COALESCE(hire_date, '2021-03-10')
  WHEN 4 THEN COALESCE(hire_date, '2020-11-05')
  WHEN 5 THEN COALESCE(hire_date, '2018-08-25')
  ELSE hire_date END;

DROP INDEX IF EXISTS emp_hire_year_idx;
CREATE INDEX IF NOT EXISTS emp_hire_year_idx ON employees (EXTRACT(YEAR FROM hire_date));

-- Part 7
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_class WHERE relname = 'emp_salary_idx') THEN
    ALTER INDEX emp_salary_idx RENAME TO employees_salary_index;
  END IF;
END$$;

DROP INDEX IF EXISTS emp_salary_dept_idx;

-- REINDEX INDEX employees_salary_index;

-- Part 8
DROP INDEX IF EXISTS emp_salary_filter_idx;
CREATE INDEX IF NOT EXISTS emp_salary_filter_idx ON employees (salary) WHERE salary > 50000;

DROP INDEX IF EXISTS proj_high_budget_idx;
CREATE INDEX IF NOT EXISTS proj_high_budget_idx ON projects (budget) WHERE budget > 80000;

-- Part 9
DROP INDEX IF EXISTS dept_name_hash_idx;
CREATE INDEX IF NOT EXISTS dept_name_hash_idx ON departments USING HASH (dept_name);

DROP INDEX IF EXISTS proj_name_btree_idx;
DROP INDEX IF EXISTS proj_name_hash_idx;

CREATE INDEX IF NOT EXISTS proj_name_btree_idx ON projects (proj_name);
CREATE INDEX IF NOT EXISTS proj_name_hash_idx ON projects USING HASH (proj_name);

-- Part 10
CREATE OR REPLACE VIEW index_documentation AS
SELECT tablename, indexname, indexdef,
  CASE
    WHEN indexname ILIKE '%salary%' THEN 'Improves salary-based queries'
    ELSE NULL
  END AS purpose
FROM pg_indexes
WHERE schemaname = 'public' AND indexname ILIKE '%salary%';

COMMIT;
