CREATE DATABASE advanced_lab5;

-- Task 1.1
CREATE TABLE employees (
    employee_id INTEGER PRIMARY KEY,
    first_name TEXT,
    last_name TEXT,
    age INTEGER CHECK (age BETWEEN 18 AND 65),
    salary NUMERIC CHECK (salary > 0)
);

INSERT INTO employees (employee_id, first_name, last_name, age, salary) VALUES
(1, 'Alice', 'Morris', 30, 55000.00),
(2, 'Bob', 'Chen', 45, 72000.00);

-- Task 1.2
CREATE TABLE products_catalog (
    product_id INTEGER PRIMARY KEY,
    product_name TEXT,
    regular_price NUMERIC,
    discount_price NUMERIC,
    CONSTRAINT valid_discount CHECK (
        regular_price > 0
        AND discount_price > 0
        AND discount_price < regular_price
    )
);

INSERT INTO products_catalog (product_id, product_name, regular_price, discount_price) VALUES
(1, 'Wireless Mouse', 25.00, 19.99),
(2, 'Mechanical Keyboard', 120.00, 99.99);

-- Task 1.3
CREATE TABLE bookings (
    booking_id INTEGER PRIMARY KEY,
    check_in_date DATE,
    check_out_date DATE,
    num_guests INTEGER,
    CHECK (num_guests BETWEEN 1 AND 10),
    CHECK (check_out_date > check_in_date)
);

INSERT INTO bookings (booking_id, check_in_date, check_out_date, num_guests) VALUES
(1, '2025-12-01', '2025-12-05', 2),
(2, '2026-01-15', '2026-01-16', 1);

-- Task 2.1
CREATE TABLE customers (
    customer_id INTEGER NOT NULL PRIMARY KEY,
    email TEXT NOT NULL,
    phone TEXT,
    registration_date DATE NOT NULL
);

INSERT INTO customers (customer_id, email, phone, registration_date) VALUES
(100, 'jane.doe@example.com', '555-0100', '2024-06-01'),
(101, 'mark.river@example.com', NULL, '2025-01-10');

-- Task 2.2
CREATE TABLE inventory (
    item_id INTEGER NOT NULL PRIMARY KEY,
    item_name TEXT NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity >= 0),
    unit_price NUMERIC NOT NULL CHECK (unit_price > 0),
    last_updated TIMESTAMP NOT NULL
);

INSERT INTO inventory (item_id, item_name, quantity, unit_price, last_updated) VALUES
(1, 'Laptop', 10, 950.00, CURRENT_TIMESTAMP),
(2, 'Monitor', 25, 180.50, CURRENT_TIMESTAMP);

-- Task 3.1
CREATE TABLE users (
    user_id INTEGER PRIMARY KEY,
    username TEXT UNIQUE,
    email TEXT UNIQUE,
    created_at TIMESTAMP
);

INSERT INTO users (user_id, username, email, created_at) VALUES
(1, 'user1', 'user1@mail.com', CURRENT_TIMESTAMP),
(2, 'user2', 'user2@mail.com', CURRENT_TIMESTAMP);

-- Task 3.2
CREATE TABLE course_enrollments (
    enrollment_id INTEGER PRIMARY KEY,
    student_id INTEGER,
    course_code TEXT,
    semester TEXT,
    UNIQUE (student_id, course_code, semester)
);

INSERT INTO course_enrollments (enrollment_id, student_id, course_code, semester) VALUES
(1, 101, 'CS101', 'Fall2025'),
(2, 102, 'CS101', 'Fall2025');

-- Task 3.3
ALTER TABLE users ADD CONSTRAINT unique_username UNIQUE (username);
ALTER TABLE users ADD CONSTRAINT unique_email UNIQUE (email);

-- Task 4.1
CREATE TABLE departments (
    dept_id INTEGER PRIMARY KEY,
    dept_name TEXT NOT NULL,
    location TEXT
);

INSERT INTO departments VALUES
(1, 'HR', 'New York'),
(2, 'Finance', 'Chicago'),
(3, 'Engineering', 'San Francisco');

-- Task 4.2
CREATE TABLE student_courses (
    student_id INTEGER,
    course_id INTEGER,
    enrollment_date DATE,
    grade TEXT,
    PRIMARY KEY (student_id, course_id)
);

INSERT INTO student_courses VALUES
(201, 501, '2025-09-01', 'A'),
(202, 502, '2025-09-01', 'B');

-- Task 5.1
CREATE TABLE employees_dept (
    emp_id INTEGER PRIMARY KEY,
    emp_name TEXT NOT NULL,
    dept_id INTEGER REFERENCES departments(dept_id),
    hire_date DATE
);

INSERT INTO employees_dept VALUES
(1, 'Alice', 1, '2024-01-01'),
(2, 'Bob', 3, '2024-03-15');

-- Task 5.2
CREATE TABLE authors (
    author_id INTEGER PRIMARY KEY,
    author_name TEXT NOT NULL,
    country TEXT
);

CREATE TABLE publishers (
    publisher_id INTEGER PRIMARY KEY,
    publisher_name TEXT NOT NULL,
    city TEXT
);

CREATE TABLE books (
    book_id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    author_id INTEGER REFERENCES authors(author_id),
    publisher_id INTEGER REFERENCES publishers(publisher_id),
    publication_year INTEGER,
    isbn TEXT UNIQUE
);

INSERT INTO authors VALUES
(1, 'George Orwell', 'UK'),
(2, 'Haruki Murakami', 'Japan');

INSERT INTO publishers VALUES
(1, 'Penguin Books', 'London'),
(2, 'Vintage', 'Tokyo');

INSERT INTO books VALUES
(1, '1984', 1, 1, 1949, '9780451524935'),
(2, 'Kafka on the Shore', 2, 2, 2002, '9781400079278');

-- Task 5.3
CREATE TABLE categories (
    category_id INTEGER PRIMARY KEY,
    category_name TEXT NOT NULL
);

CREATE TABLE products_fk (
    product_id INTEGER PRIMARY KEY,
    product_name TEXT NOT NULL,
    category_id INTEGER REFERENCES categories(category_id) ON DELETE RESTRICT
);

CREATE TABLE orders (
    order_id INTEGER PRIMARY KEY,
    order_date DATE NOT NULL
);

CREATE TABLE order_items (
    item_id INTEGER PRIMARY KEY,
    order_id INTEGER REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES products_fk(product_id),
    quantity INTEGER CHECK (quantity > 0)
);

INSERT INTO categories VALUES (1, 'Electronics'), (2, 'Books');
INSERT INTO products_fk VALUES (1, 'Headphones', 1), (2, 'Novel', 2);
INSERT INTO orders VALUES (1, '2025-10-15');
INSERT INTO order_items VALUES (1, 1, 1, 2), (2, 1, 2, 1);

-- Task 6.1
CREATE TABLE ecommerce_customers (
    customer_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    phone TEXT,
    registration_date DATE NOT NULL
);

CREATE TABLE ecommerce_products (
    product_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    price NUMERIC CHECK (price >= 0),
    stock_quantity INTEGER CHECK (stock_quantity >= 0)
);

CREATE TABLE ecommerce_orders (
    order_id INTEGER PRIMARY KEY,
    customer_id INTEGER REFERENCES ecommerce_customers(customer_id) ON DELETE CASCADE,
    order_date DATE NOT NULL,
    total_amount NUMERIC,
    status TEXT CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled'))
);

CREATE TABLE ecommerce_order_details (
    order_detail_id INTEGER PRIMARY KEY,
    order_id INTEGER REFERENCES ecommerce_orders(order_id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES ecommerce_products(product_id),
    quantity INTEGER CHECK (quantity > 0),
    unit_price NUMERIC CHECK (unit_price >= 0)
);

INSERT INTO ecommerce_customers VALUES
(1, 'Jane Doe', 'jane@example.com', '555-1111', '2025-01-01'),
(2, 'John Smith', 'john@example.com', '555-2222', '2025-02-15'),
(3, 'Sara Lee', 'sara@example.com', '555-3333', '2025-03-10'),
(4, 'Michael Kim', 'michael@example.com', '555-4444', '2025-04-05'),
(5, 'Emma Jones', 'emma@example.com', '555-5555', '2025-05-20');

INSERT INTO ecommerce_products VALUES
(1, 'Laptop', '15-inch laptop', 1200.00, 20),
(2, 'Phone', '5G smartphone', 800.00, 50),
(3, 'Headphones', 'Noise cancelling', 150.00, 100),
(4, 'Keyboard', 'Mechanical keyboard', 90.00, 30),
(5, 'Monitor', '27-inch display', 300.00, 25);

INSERT INTO ecommerce_orders VALUES
(1, 1, '2025-06-01', 1350.00, 'delivered'),
(2, 2, '2025-06-05', 800.00, 'shipped'),
(3, 3, '2025-06-10', 240.00, 'processing'),
(4, 4, '2025-06-15', 180.00, 'pending'),
(5, 5, '2025-06-20', 600.00, 'cancelled');

INSERT INTO ecommerce_order_details VALUES
(1, 1, 1, 1, 1200.00),
(2, 1, 3, 1, 150.00),
(3, 2, 2, 1, 800.00),
(4, 3, 4, 2, 90.00),
(5, 4, 3, 1, 180.00);
