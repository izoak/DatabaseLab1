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

INSERT INTO employees (emp_id, emp_name, dept_id, salary) VALUES
(1, 'John Smith', 101, 50000),
(2, 'Jane Doe', 102, 60000),
(3, 'Mike Johnson', 101, 55000),
(4, 'Sarah Williams', 103, 65000),
(5, 'Tom Brown', NULL, 45000);

INSERT INTO departments (dept_id, dept_name, location) VALUES
(101, 'IT', 'Building A'),
(102, 'HR', 'Building B'),
(103, 'Finance', 'Building C'),
(104, 'Marketing', 'Building D');

INSERT INTO projects (project_id, project_name, dept_id, budget) VALUES
(1, 'Website Redesign', 101, 100000),
(2, 'Employee Training', 102, 50000),
(3, 'Budget Analysis', 103, 75000),
(4, 'Cloud Migration', 101, 150000),
(5, 'AI Research', NULL, 200000);

-- Exercise 2.1
SELECT e.emp_name, d.dept_name
FROM employees e CROSS JOIN departments d;


-- Exercise 2.2
SELECT e.emp_name, d.dept_name FROM employees e, departments d;

SELECT e.emp_name, d.dept_name FROM employees e INNER JOIN departments d ON TRUE;


-- Exercise 2.3
SELECT e.emp_name, p.project_name
FROM employees e CROSS JOIN projects p;

-- Exercise 3.1
SELECT e.emp_name, d.dept_name, d.location
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id;

-- Exercise 3.2
SELECT emp_name, dept_name, location
FROM employees
INNER JOIN departments USING (dept_id);

-- Exercise 3.3
SELECT emp_name, dept_name, location
FROM employees
NATURAL INNER JOIN departments;

-- Exercise 3.4
SELECT e.emp_name, d.dept_name, p.project_name
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id
INNER JOIN projects p ON d.dept_id = p.dept_id;

-- Exercise 4.1
SELECT e.emp_name, e.dept_id AS emp_dept, d.dept_id AS dept_dept, d.dept_name
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id;

-- Exercise 4.2
SELECT emp_name, dept_name, location
FROM employees
LEFT JOIN departments USING (dept_id);

-- Exercise 4.3
SELECT e.emp_name, e.dept_id
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
WHERE d.dept_id IS NULL;

-- Exercise 4.4
SELECT d.dept_name, COUNT(e.emp_id) AS employee_count
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name
ORDER BY employee_count DESC;


-- Exercise 5.1
SELECT e.emp_name, d.dept_name
FROM employees e
RIGHT JOIN departments d ON e.dept_id = d.dept_id;

-- Exercise 5.2
SELECT e.emp_name, d.dept_name
FROM departments d
LEFT JOIN employees e ON e.dept_id = d.dept_id;

-- Exercise 5.3
SELECT d.dept_name, d.location
FROM employees e
RIGHT JOIN departments d ON e.dept_id = d.dept_id
WHERE e.emp_id IS NULL;



-- Exercise 6.1
SELECT e.emp_name, e.dept_id AS emp_dept, d.dept_id AS dept_dept, d.dept_name
FROM employees e
FULL JOIN departments d ON e.dept_id = d.dept_id;


-- Exercise 6.2
SELECT d.dept_name, p.project_name, p.budget
FROM departments d
FULL JOIN projects p ON d.dept_id = p.dept_id;

-- Exercise 6.3
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

-- Exercise 7.1
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id AND d.location = 'Building A';

-- Exercise 7.2
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
WHERE d.location = 'Building A';


-- Exercise 7.3
SELECT e.emp_name, d.dept_name FROM employees e INNER JOIN departments d ON e.dept_id = d.dept_id AND d.location = 'Building A';

SELECT e.emp_name, d.dept_name FROM employees e INNER JOIN departments d ON e.dept_id = d.dept_id WHERE d.location = 'Building A';


-- Exercise 8.1
SELECT
  d.dept_name,
  e.emp_name,
  e.salary,
  p.project_name,
  p.budget
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
LEFT JOIN projects p ON d.dept_id = p.dept_id
ORDER BY d.dept_name, e.emp_name;


-- Exercise 8.2
ALTER TABLE employees ADD COLUMN manager_id INT;


UPDATE employees SET manager_id = 3 WHERE emp_id = 1;
UPDATE employees SET manager_id = 3 WHERE emp_id = 2;
UPDATE employees SET manager_id = NULL WHERE emp_id = 3;
UPDATE employees SET manager_id = 3 WHERE emp_id = 4;
UPDATE employees SET manager_id = 3 WHERE emp_id = 5;


SELECT e.emp_name AS employee, m.emp_name AS manager
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.emp_id;


-- Exercise 8.3:
SELECT d.dept_name, AVG(e.salary) AS avg_salary
FROM departments d
INNER JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name
HAVING AVG(e.salary) > 50000;


-- Lab Questions: Answer

-- 1) What is the difference between INNER JOIN and LEFT JOIN?
-- Answer: INNER JOIN returns only rows that have matching keys in both tables. LEFT JOIN
-- returns all rows from the left table and matching rows from the right table; when there is no match,
-- the right-side columns are NULL.

-- 2) When would you use CROSS JOIN in a practical scenario?
-- Answer: Use CROSS JOIN to produce combinational pairs, for example building an availability matrix,
-- generating test data, creating combinations of parameters for simulations, or creating calendar entries
-- for every user and date.

-- 3) Explain why the position of a filter condition (ON vs WHERE) matters for outer joins but not for inner joins.
-- Answer: In outer joins the ON clause controls which rows are considered matches (non-matching side becomes NULL),
-- while WHERE filters are applied after joining and can eliminate rows produced by the outer join (turning it effectively
-- into an inner join in some cases). For inner joins both are applied to matched rows, so results are equivalent.

-- 4) What is the result of: SELECT COUNT(*) FROM table1 CROSS JOIN table2 if table1 has 5 rows and table2 has 10 rows?
-- Answer: 5 * 10 = 50 rows.

-- 5) How does NATURAL JOIN determine which columns to join on?
-- Answer: NATURAL JOIN automatically finds columns with the same name in both tables and joins on all of those columns.

-- 6) What are the potential risks of using NATURAL JOIN?
-- Answer: It can silently join on unexpected columns (especially after schema changes), causing incorrect results. It's implicit and less readable.

-- 7) Convert this LEFT JOIN to a RIGHT JOIN:
-- Original: SELECT * FROM A LEFT JOIN B ON A.id = B.id;
-- Converted: SELECT * FROM B RIGHT JOIN A ON A.id = B.id;
-- (Or rewrite using LEFT JOIN by swapping table order:
--  SELECT * FROM A RIGHT JOIN B ON A.id = B.id;)

-- 8) When should you use FULL OUTER JOIN instead of other join types?
-- Answer: Use FULL OUTER JOIN when you need rows from both tables regardless of matches and you want to see unmatched rows from either side in a single result set. Useful for reconciliation tasks.


SELECT e.emp_id, e.emp_name, e.dept_id, d.dept_name
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
UNION
SELECT e.emp_id, e.emp_name, e.dept_id, d.dept_name
FROM employees e
RIGHT JOIN departments d ON e.dept_id = d.dept_id;

WITH multi_proj_depts AS (
  SELECT dept_id FROM projects WHERE dept_id IS NOT NULL GROUP BY dept_id HAVING COUNT(*) > 1
)
SELECT e.emp_name, e.emp_id, e.dept_id
FROM employees e
JOIN multi_proj_depts m ON e.dept_id = m.dept_id;

WITH RECURSIVE hierarchy AS (
  SELECT emp_id, emp_name, manager_id, emp_name AS path, 1 AS level
  FROM employees WHERE manager_id IS NULL 
  UNION ALL
  SELECT e.emp_id, e.emp_name, e.manager_id, h.path || ' -> ' || e.emp_name, h.level + 1
  FROM employees e
  JOIN hierarchy h ON e.manager_id = h.emp_id
)
SELECT * FROM hierarchy ORDER BY level, emp_name;


SELECT e1.emp_id AS emp1_id, e1.emp_name AS emp1, e2.emp_id AS emp2_id, e2.emp_name AS emp2
FROM employees e1
JOIN employees e2 ON e1.dept_id = e2.dept_id AND e1.emp_id < e2.emp_id
WHERE e1.dept_id IS NOT NULL;


