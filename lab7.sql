CREATE TABLE employees (
  emp_id INT PRIMARY KEY,
  emp_name VARCHAR(50),
  dept_id INT,
  salary DECIMAL(10,2)
);

CREATE TABLE departments (
  dept_id INT PRIMARY KEY,
  dept_name VARCHAR(50),
  location VARCHAR(50)
);

CREATE TABLE projects (
  project_id INT PRIMARY KEY,
  project_name VARCHAR(50),
  dept_id INT,
  budget DECIMAL(10,2)
);

-- Exercise 2.1
CREATE OR REPLACE VIEW employee_details AS
SELECT
  e.emp_id,
  e.emp_name,
  e.salary,
  e.dept_id,
  d.dept_name,
  d.location
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id;

-- Test
-- Tom Brown does not appear if he has no dept_id or unmatched department.

-- Exercise 2.2
CREATE OR REPLACE VIEW dept_statistics AS
SELECT
  d.dept_id,
  d.dept_name,
  COALESCE(COUNT(e.emp_id), 0) AS employee_count,
  ROUND(COALESCE(AVG(e.salary), 0)::numeric, 2) AS average_salary,
  COALESCE(MAX(e.salary), 0) AS max_salary,
  COALESCE(MIN(e.salary), 0) AS min_salary
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name;

-- Exercise 2.3
CREATE OR REPLACE VIEW project_overview AS
SELECT
  p.project_id,
  p.project_name,
  p.budget,
  p.dept_id,
  d.dept_name,
  d.location,
  COALESCE((SELECT COUNT(*) FROM employees e WHERE e.dept_id = d.dept_id), 0) AS team_size
FROM projects p
LEFT JOIN departments d ON p.dept_id = d.dept_id;

-- Exercise 2.4
CREATE OR REPLACE VIEW high_earners AS
SELECT
  e.emp_id,
  e.emp_name,
  e.salary,
  d.dept_name
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
WHERE e.salary > 55000;

-- Exercise 3.1
CREATE OR REPLACE VIEW employee_details AS
SELECT
  e.emp_id,
  e.emp_name,
  e.salary,
  e.dept_id,
  d.dept_name,
  d.location,
  CASE
    WHEN e.salary > 60000 THEN 'High'
    WHEN e.salary > 50000 THEN 'Medium'
    ELSE 'Standard'
  END AS salary_grade
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id;

-- Exercise 3.2
ALTER VIEW high_earners RENAME TO top_performers;

-- Exercise 3.3
CREATE TEMPORARY VIEW temp_view AS
SELECT emp_id, emp_name, salary
FROM employees
WHERE salary < 50000;

DROP VIEW IF EXISTS temp_view;

-- Exercise 4.1
CREATE OR REPLACE VIEW employee_salaries AS
SELECT emp_id, emp_name, dept_id, salary
FROM employees;

-- Exercise 4.2
UPDATE employee_salaries SET salary = 52000 WHERE emp_name = 'John Smith';
SELECT * FROM employees WHERE emp_name = 'John Smith';

-- Exercise 4.3
INSERT INTO employee_salaries (emp_id, emp_name, dept_id, salary)
VALUES (6, 'Alice Johnson', 102, 58000);
SELECT * FROM employees WHERE emp_id = 6;

-- Exercise 4.4
CREATE OR REPLACE VIEW it_employees AS
SELECT emp_id, emp_name, dept_id, salary
FROM employees
WHERE dept_id = 101
WITH LOCAL CHECK OPTION;

-- Exercise 5.1
DROP MATERIALIZED VIEW IF EXISTS dept_summary_mv;
CREATE MATERIALIZED VIEW dept_summary_mv
WITH DATA AS
SELECT
  d.dept_id,
  d.dept_name,
  COALESCE(e.emp_count, 0) AS total_employees,
  COALESCE(e.total_salaries, 0)::numeric(14,2) AS total_salaries,
  COALESCE(p.project_count, 0) AS total_projects,
  COALESCE(p.total_budget, 0)::numeric(14,2) AS total_project_budget
FROM departments d
LEFT JOIN (
  SELECT dept_id, COUNT(*) AS emp_count, SUM(salary) AS total_salaries
  FROM employees
  GROUP BY dept_id
) e ON e.dept_id = d.dept_id
LEFT JOIN (
  SELECT dept_id, COUNT(*) AS project_count, SUM(budget) AS total_budget
  FROM projects
  GROUP BY dept_id
) p ON p.dept_id = d.dept_id;

-- Exercise 5.2
INSERT INTO employees (emp_id, emp_name, dept_id, salary)
VALUES (8, 'Charlie Brown', 101, 54000);
REFRESH MATERIALIZED VIEW dept_summary_mv;

-- Exercise 5.3
CREATE UNIQUE INDEX IF NOT EXISTS idx_dept_summary_mv_dept_id
ON dept_summary_mv(dept_id);


-- Exercise 5.4
DROP MATERIALIZED VIEW IF EXISTS project_stats_mv;
CREATE MATERIALIZED VIEW project_stats_mv
WITH NO DATA AS
SELECT
  p.project_id,
  p.project_name,
  p.budget,
  d.dept_name,
  COALESCE(emp_cnt.emp_count, 0) AS assigned_employee_count
FROM projects p
LEFT JOIN departments d ON p.dept_id = d.dept_id
LEFT JOIN (
  SELECT dept_id, COUNT(*) AS emp_count FROM employees GROUP BY dept_id
) emp_cnt ON emp_cnt.dept_id = p.dept_id;

-- Exercise 6.1
CREATE ROLE analyst NOLOGIN;
CREATE ROLE data_viewer WITH LOGIN PASSWORD 'viewer123';
CREATE ROLE report_user WITH LOGIN PASSWORD 'report456';

-- Exercise 6.2
CREATE ROLE db_creator WITH LOGIN PASSWORD 'creator789' CREATEDB;
CREATE ROLE user_manager WITH LOGIN PASSWORD 'manager101' CREATEROLE;
CREATE ROLE admin_user WITH LOGIN PASSWORD 'admin999' SUPERUSER;

-- Exercise 6.3
GRANT SELECT ON employees, departments, projects TO analyst;
GRANT ALL PRIVILEGES ON TABLE employee_details TO data_viewer;
GRANT SELECT, INSERT ON employees TO report_user;

-- Exercise 6.4
CREATE ROLE hr_team NOLOGIN;
CREATE ROLE finance_team NOLOGIN;
CREATE ROLE it_team NOLOGIN;

CREATE ROLE hr_user1 WITH LOGIN PASSWORD 'hr001';
CREATE ROLE hr_user2 WITH LOGIN PASSWORD 'hr002';
CREATE ROLE finance_user1 WITH LOGIN PASSWORD 'fin001';

GRANT hr_team TO hr_user1;
GRANT hr_team TO hr_user2;
GRANT finance_team TO finance_user1;

GRANT SELECT, UPDATE ON employees TO hr_team;
GRANT SELECT ON dept_statistics TO finance_team;

-- Exercise 6.5
REVOKE UPDATE ON employees FROM hr_team;
REVOKE hr_team FROM hr_user2;
REVOKE ALL PRIVILEGES ON TABLE employee_details FROM data_viewer;

-- Exercise 6.6
ALTER ROLE analyst WITH LOGIN PASSWORD 'analyst123';
ALTER ROLE user_manager WITH SUPERUSER;
ALTER ROLE analyst WITH PASSWORD NULL;
ALTER ROLE data_viewer CONNECTION LIMIT 5;

-- Exercise 7.1
CREATE ROLE read_only NOLOGIN;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO read_only;

CREATE ROLE junior_analyst WITH LOGIN PASSWORD 'junior123';
CREATE ROLE senior_analyst WITH LOGIN PASSWORD 'senior123';

GRANT read_only TO junior_analyst;
GRANT read_only TO senior_analyst;
GRANT INSERT, UPDATE ON employees TO senior_analyst;

-- Exercise 7.2
CREATE ROLE project_manager WITH LOGIN PASSWORD 'pm123';
ALTER VIEW dept_statistics OWNER TO project_manager;
ALTER TABLE projects OWNER TO project_manager;

-- Exercise 7.3
CREATE ROLE temp_owner WITH LOGIN;
CREATE TABLE temp_table (id INT);
ALTER TABLE temp_table OWNER TO temp_owner;
REASSIGN OWNED BY temp_owner TO postgres;
DROP OWNED BY temp_owner;
DROP ROLE IF EXISTS temp_owner;

-- Exercise 7.4
CREATE OR REPLACE VIEW hr_employee_view AS
SELECT emp_id, emp_name, dept_id, salary
FROM employees
WHERE dept_id = 102;
GRANT SELECT ON hr_employee_view TO hr_team;

CREATE OR REPLACE VIEW finance_employee_view AS
SELECT emp_id, emp_name, salary
FROM employees;
GRANT SELECT ON finance_employee_view TO finance_team;

-- Exercise 8.1
CREATE OR REPLACE VIEW dept_dashboard AS
SELECT
  d.dept_id,
  d.dept_name,
  d.location,
  COALESCE(e.emp_count, 0) AS employee_count,
  ROUND(COALESCE(e.avg_salary, 0)::numeric, 2) AS average_salary,
  COALESCE(p.project_count, 0) AS active_projects,
  COALESCE(p.total_budget, 0)::numeric(14,2) AS total_project_budget,
  ROUND(
    CASE WHEN COALESCE(e.emp_count,0) > 0
         THEN COALESCE(p.total_budget,0) / COALESCE(e.emp_count,1)
         ELSE 0
    END::numeric, 2
  ) AS budget_per_employee
FROM departments d
LEFT JOIN (
  SELECT dept_id, COUNT(*) AS emp_count, AVG(salary) AS avg_salary
  FROM employees
  GROUP BY dept_id
) e ON e.dept_id = d.dept_id
LEFT JOIN (
  SELECT dept_id, COUNT(*) AS project_count, SUM(budget) AS total_budget
  FROM projects
  GROUP BY dept_id
) p ON p.dept_id = d.dept_id;

-- Exercise 8.2
ALTER TABLE projects
ADD COLUMN IF NOT EXISTS created_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;

CREATE OR REPLACE VIEW high_budget_projects AS
SELECT
  p.project_id,
  p.project_name,
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

-- Exercise 8.3
CREATE ROLE viewer_role NOLOGIN;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO viewer_role;

CREATE ROLE entry_role NOLOGIN;
GRANT viewer_role TO entry_role;
GRANT INSERT ON employees, projects TO entry_role;

CREATE ROLE analyst_role NOLOGIN;
GRANT entry_role TO analyst_role;
GRANT UPDATE ON employees, projects TO analyst_role;

CREATE ROLE manager_role NOLOGIN;
GRANT analyst_role TO manager_role;
GRANT DELETE ON employees, projects TO manager_role;

CREATE ROLE alice WITH LOGIN PASSWORD 'alice123';
CREATE ROLE bob WITH LOGIN PASSWORD 'bob123';
CREATE ROLE charlie WITH LOGIN PASSWORD 'charlie123';

GRANT viewer_role TO alice;
GRANT analyst_role TO bob;
GRANT manager_role TO charlie;
