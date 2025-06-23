-- Task 1 
CREATE DATABASE IF NOT EXISTS school;
USE school;

CREATE TABLE Projects (
    Task_ID INT,
    Start_Date DATE,
    End_Date DATE
);
INSERT INTO Projects (Task_ID, Start_Date, End_Date) VALUES
(1, '2015-10-01', '2015-10-02'),
(2, '2015-10-02', '2015-10-03'),
(3, '2015-10-03', '2015-10-04'),
(4, '2015-10-13', '2015-10-14'),
(5, '2015-10-14', '2015-10-15'),
(6, '2015-10-28', '2015-10-29'),
(7, '2015-10-30', '2015-10-31');
WITH ProjectStarts AS (
    SELECT 
        Task_ID,
        Start_Date,
        End_Date,
        CASE 
            WHEN NOT EXISTS (
                SELECT 1 
                FROM Projects p2 
                WHERE p2.End_Date = p1.Start_Date
            ) THEN 1 
            ELSE 0 
        END AS is_start
    FROM Projects p1
),
ProjectGroups AS (
    SELECT 
        Task_ID,
        Start_Date,
        End_Date,
        SUM(is_start) OVER (ORDER BY Start_Date) AS group_id
    FROM ProjectStarts
)
SELECT 
    MIN(Start_Date) AS Start_Date,
    MAX(End_Date) AS End_Date
FROM ProjectGroups
GROUP BY group_id
ORDER BY 
    (MAX(End_Date) - MIN(Start_Date)) ASC,
    MIN(Start_Date) ASC;
    
-- task 2 
-- Create database (use 'projects' or change to your preferred name)
CREATE DATABASE IF NOT EXISTS projects;
USE projects;

-- Create tables
CREATE TABLE Students (
    ID INT PRIMARY KEY,
    Name VARCHAR(50)
);

CREATE TABLE Friends (
    ID INT,
    Friend_ID INT,
    PRIMARY KEY (ID)
);

CREATE TABLE Packages (
    ID INT PRIMARY KEY,
    Salary FLOAT
);

-- Insert sample data
INSERT INTO Students (ID, Name) VALUES
(1, 'Ashley'),
(2, 'Samantha'),
(3, 'Julia'),
(4, 'Scarlet');

INSERT INTO Friends (ID, Friend_ID) VALUES
(1, 2),
(2, 3),
(3, 4),
(4, 1);

INSERT INTO Packages (ID, Salary) VALUES
(1, 15.20),
(2, 10.06),
(3, 11.55),
(4, 12.12);
SELECT s.Name
FROM Students s
JOIN Friends f ON s.ID = f.ID
JOIN Packages p1 ON s.ID = p1.ID
JOIN Packages p2 ON f.Friend_ID = p2.ID
WHERE p2.Salary > p1.Salary
ORDER BY p2.Salary;

-- task 3 
-- Create database (use 'projects' or change to your preferred name)
CREATE DATABASE IF NOT EXISTS projects;
USE projects;

-- Create Functions table
CREATE TABLE Functions (
    X INT,
    Y INT
);

-- Insert sample data
INSERT INTO Functions (X, Y) VALUES
(20, 20),
(20, 20),
(20, 21),
(23, 22),
(22, 23),
(21, 20);
 SELECT f1.X, f1.Y
FROM Functions f1
JOIN Functions f2 ON f1.X = f2.Y AND f1.Y = f2.X
WHERE f1.X <= f1.Y
ORDER BY f1.X;


-- task 4 
CREATE DATABASE IF NOT EXISTS projects;
USE projects;

CREATE TABLE Contests (
    contest_id INT PRIMARY KEY, 
    hacker_id INT,
    name VARCHAR(50)
);
CREATE TABLE Colleges (
    college_id INT PRIMARY KEY,
    contest_id INT
);
CREATE TABLE Challenges (
    challenge_id INT PRIMARY KEY,
    college_id INT
);
CREATE TABLE View_Stats (
    id INT AUTO_INCREMENT PRIMARY KEY,
    challenge_id INT,
    total_views INT,
    total_unique_views INT
);
CREATE TABLE Submission_Stats (
    id INT AUTO_INCREMENT PRIMARY KEY,
    challenge_id INT,
    total_submissions INT,
    total_accepted_submissions INT
);

-- Insert sample data from PDF (Contests example for brevity)
INSERT INTO Contests VALUES
(66406, 17973, 'Rose'),
(66556, 79153, 'Julia'),
(94828, 80275, 'Frank');
-- Insert Colleges, Challenges, View_Stats, Submission_Stats similarly
-- (Omitted for brevity; use the sample input tables above)
SELECT 
    c.contest_id,
    c.hacker_id,
    c.name,
    COALESCE(SUM(ss.total_submissions), 0) AS total_submissions,
    COALESCE(SUM(ss.total_accepted_submissions), 0) AS total_accepted_submissions,
    COALESCE(SUM(vs.total_views), 0) AS total_views,
    COALESCE(SUM(vs.total_unique_views), 0) AS total_unique_views
FROM 
    Contests c
    LEFT JOIN Colleges col ON c.contest_id = col.contest_id
    LEFT JOIN Challenges ch ON col.college_id = ch.college_id
    LEFT JOIN View_Stats vs ON ch.challenge_id = vs.challenge_id
    LEFT JOIN Submission_Stats ss ON ch.challenge_id = ss.challenge_id
GROUP BY 
    c.contest_id, c.hacker_id, c.name
HAVING 
    total_submissions > 0 OR 
    total_accepted_submissions > 0 OR 
    total_views > 0 OR 
    total_unique_views > 0
ORDER BY 
    c.contest_id; 
    
-- task 5 
CREATE TABLE Hackers (
    hacker_id INT PRIMARY KEY,
    name VARCHAR(50)
);
CREATE TABLE Submissions (
    submission_date DATE,
    submission_id INT PRIMARY KEY,
    hacker_id INT,
    score INT
);

WITH DailySubmissions AS (
    SELECT 
        s.submission_date,
        s.hacker_id,
        h.name,
        COUNT(*) AS submission_count,
        ROW_NUMBER() OVER (PARTITION BY s.submission_date ORDER BY COUNT(*) DESC, s.hacker_id ASC) AS rn
    FROM Submissions s
    JOIN Hackers h ON s.hacker_id = h.hacker_id
    WHERE s.submission_date BETWEEN '2016-03-01' AND '2016-03-15'
    GROUP BY s.submission_date, s.hacker_id, h.name
),
UniqueHackers AS (
    SELECT 
        submission_date,
        COUNT(DISTINCT hacker_id) AS unique_hackers
    FROM Submissions
    WHERE submission_date BETWEEN '2016-03-01' AND '2016-03-15'
    GROUP BY submission_date
),
CumulativeUnique AS (
    SELECT 
        d1.submission_date,
        COUNT(DISTINCT s.hacker_id) AS cumulative_unique
    FROM (SELECT DISTINCT submission_date FROM Submissions) d1
    LEFT JOIN Submissions s ON s.submission_date <= d1.submission_date
    WHERE s.submission_date BETWEEN '2016-03-01' AND '2016-03-15'
    GROUP BY d1.submission_date
)
SELECT 
    ds.submission_date,
    cu.cumulative_unique,
    ds.hacker_id,
    ds.name
FROM DailySubmissions ds
JOIN CumulativeUnique cu ON ds.submission_date = cu.submission_date
WHERE ds.rn = 1
ORDER BY ds.submission_date;

-- task 6
CREATE TABLE STATION (
    ID INT PRIMARY KEY,
    CITY VARCHAR(21),
    STATE VARCHAR(2),
    LAT_N FLOAT,
    LONG_W FLOAT
);

SELECT 
    ROUND(
        (ABS(MIN(LAT_N) - MAX(LAT_N)) + ABS(MIN(LONG_W) - MAX(LONG_W))),
        4
    ) AS manhattan_distance
FROM STATION;

-- task 7 
-- Create a temporary numbers table
CREATE TEMPORARY TABLE Numbers (n INT);
INSERT INTO Numbers
SELECT a.N + b.N * 10 + c.N * 100 + 2
FROM (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) a
CROSS JOIN (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) b
CROSS JOIN (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) c
WHERE a.N + b.N * 10 + c.N * 100 + 2 <= 1000;

SELECT GROUP_CONCAT(n SEPARATOR '&') AS prime_numbers
FROM Numbers
WHERE n > 1
AND NOT EXISTS (
    SELECT 1
    FROM Numbers d
    WHERE d <= SQRT(n)
    AND d > 1
    AND n % d = 0
);

-- task 8 
WITH RankedOccupations AS (
    SELECT 
        Name,
        Occupation,
        ROW_NUMBER() OVER (PARTITION BY Occupation ORDER BY Name) AS rn
    FROM OCCUPATIONS
)
SELECT 
    MAX(CASE WHEN Occupation = 'Doctor' THEN Name END) AS Doctor,
    MAX(CASE WHEN Occupation = 'Professor' THEN Name END) AS Professor,
    MAX(CASE WHEN Occupation = 'Singer' THEN Name END) AS Singer,
    MAX(CASE WHEN Occupation = 'Actor' THEN Name END) AS Actor
FROM RankedOccupations
GROUP BY rn
ORDER BY rn;

-- task 9 
-- Create database if needed (using 'school' as in previous tasks)
CREATE DATABASE IF NOT EXISTS school;
USE school;

-- Create BST table
CREATE TABLE BST (
    N INT,
    P INT
);

-- Insert sample data
INSERT INTO BST (N, P) VALUES
(1, 2),
(3, 2),
(6, 8),
(9, 8),
(2, 5),
(8, 5),
(5, NULL);
SELECT * FROM BST;
SELECT 
    N,
    CASE 
        WHEN P IS NULL THEN 'Root'
        WHEN N NOT IN (SELECT P FROM BST WHERE P IS NOT NULL) THEN 'Leaf'
        ELSE 'Inner'
    END AS node_type
FROM BST
ORDER BY N;
SELECT 
    b1.N,
    CASE 
        WHEN b1.P IS NULL THEN 'Root'
        WHEN b2.N IS NULL THEN 'Leaf'
        ELSE 'Inner'
    END AS node_type
FROM BST b1
LEFT JOIN BST b2 ON b2.P = b1.N
GROUP BY b1.N, b1.P
ORDER BY b1.N;

-- task 10 
-- Create database if needed
CREATE DATABASE IF NOT EXISTS school;
USE school;

-- Create tables
CREATE TABLE Company (
    company_code VARCHAR(50),
    founder VARCHAR(50)
);
CREATE TABLE Lead_Manager (
    lead_manager_code VARCHAR(50),
    company_code VARCHAR(50)
);
CREATE TABLE Senior_Manager (
    senior_manager_code VARCHAR(50),
    lead_manager_code VARCHAR(50),
    company_code VARCHAR(50)
);
CREATE TABLE Manager (
    manager_code VARCHAR(50),
    senior_manager_code VARCHAR(50),
    lead_manager_code VARCHAR(50),
    company_code VARCHAR(50)
);
CREATE TABLE Employee (
    employee_code VARCHAR(50),
    manager_code VARCHAR(50),
    senior_manager_code VARCHAR(50),
    lead_manager_code VARCHAR(50),
    company_code VARCHAR(50)
);

-- Insert sample data
INSERT INTO Company VALUES
('C1', 'Monika'),
('C2', 'Samantha');

INSERT INTO Lead_Manager VALUES
('LM1', 'C1'),
('LM2', 'C2');

INSERT INTO Senior_Manager VALUES
('SM1', 'LM1', 'C1'),
('SM2', 'LM1', 'C1'),
('SM3', 'LM2', 'C2');

INSERT INTO Manager VALUES
('M1', 'SM1', 'LM1', 'C1'),
('M2', 'SM3', 'LM2', 'C2'),
('M3', 'SM3', 'LM2', 'C2');

INSERT INTO Employee VALUES
('E1', 'M1', 'SM1', 'LM1', 'C1'),
('E2', 'M1', 'SM1', 'LM1', 'C1'),
('E3', 'M2', 'SM3', 'LM2', 'C2'),
('E4', 'M3', 'SM3', 'LM2', 'C2');
SELECT * FROM Company;
SELECT * FROM Lead_Manager;
SELECT * FROM Senior_Manager;
SELECT * FROM Manager;
SELECT * FROM Employee;
SELECT 
    c.company_code,
    c.founder,
    COUNT(DISTINCT lm.lead_manager_code) AS lead_managers,
    COUNT(DISTINCT sm.senior_manager_code) AS senior_managers,
    COUNT(DISTINCT m.manager_code) AS managers,
    COUNT(DISTINCT e.employee_code) AS employees
FROM Company c
LEFT JOIN Lead_Manager lm ON c.company_code = lm.company_code
LEFT JOIN Senior_Manager sm ON c.company_code = sm.company_code
LEFT JOIN Manager m ON c.company_code = m.company_code
LEFT JOIN Employee e ON c.company_code = e.company_code
GROUP BY c.company_code, c.founder
ORDER BY c.company_code;

-- task 12 
-- Create database if needed
CREATE DATABASE IF NOT EXISTS school;
USE school;

-- Create Employees table
CREATE TABLE Employees (
    employee_id INT PRIMARY KEY,
    job_family VARCHAR(50),
    location VARCHAR(50),
    salary FLOAT
);

-- Insert sample data
INSERT INTO Employees (employee_id, job_family, location, salary) VALUES
(1, 'Engineering', 'India', 50000),
(2, 'Engineering', 'India', 60000),
(3, 'Engineering', 'International', 120000),
(4, 'Sales', 'India', 40000),
(5, 'Sales', 'International', 80000),
(6, 'Marketing', 'International', 90000);
SELECT * FROM Employees;
WITH CostByFamily AS (
    SELECT 
        job_family,
        SUM(CASE WHEN location = 'India' THEN salary ELSE 0 END) AS india_cost,
        SUM(CASE WHEN location = 'International' THEN salary ELSE 0 END) AS intl_cost
    FROM Employees
    GROUP BY job_family
),
TotalCosts AS (
    SELECT 
        SUM(CASE WHEN location = 'India' THEN salary ELSE 0 END) AS total_india,
        SUM(CASE WHEN location = 'International' THEN salary ELSE 0 END) AS total_intl
    FROM Employees
)
SELECT 
    c.job_family,
    ROUND((c.india_cost / t.total_india) * 100, 2) AS India_pct,
    ROUND((c.intl_cost / t.total_intl) * 100, 2) AS International_pct
FROM CostByFamily c
CROSS JOIN TotalCosts t
ORDER BY c.job_family;

-- task 11

-- Create database if needed
CREATE DATABASE IF NOT EXISTS school;
USE school;

-- Create tables
CREATE TABLE Students (
    ID INT PRIMARY KEY,
    Name VARCHAR(50)
);
CREATE TABLE Friends (
    ID INT,
    Friend_ID INT
);
CREATE TABLE Packages (
    ID INT,
    Salary FLOAT
);

-- Insert sample data
INSERT INTO Students VALUES
(1, 'Ashley'),
(2, 'Samantha'),
(3, 'Julia'),
(4, 'Scarlet');

INSERT INTO Friends VALUES
(1, 2),
(2, 3),
(3, 4),
(4, 1);

INSERT INTO Packages VALUES
(1, 15.20),
(2, 10.06),
(3, 11.55),
(4, 12.12);
SELECT * FROM Students;
SELECT * FROM Friends;
SELECT * FROM Packages;
SELECT s.Name
FROM Students s
JOIN Friends f ON s.ID = f.ID
JOIN Packages p1 ON s.ID = p1.ID
JOIN Packages p2 ON f.Friend_ID = p2.ID
WHERE p2.Salary > p1.Salary
ORDER BY p2.Salary;

-- task 13 
-- Create database if needed
CREATE DATABASE IF NOT EXISTS school;
USE school;

-- Create BusinessUnit table
CREATE TABLE BusinessUnit (
    bu_id VARCHAR(50),
    month DATE,
    cost FLOAT,
    revenue FLOAT
);

-- Insert sample data
INSERT INTO BusinessUnit (bu_id, month, cost, revenue) VALUES
('BU1', '2025-01-01', 50000, 100000),
('BU1', '2025-02-01', 60000, 120000),
('BU2', '2025-01-01', 30000, 80000),
('BU2', '2025-02-01', 40000, 90000);
SELECT * FROM BusinessUnit;
SELECT 
    bu_id,
    month,
    ROUND(cost / NULLIF(revenue, 0), 2) AS ratio
FROM BusinessUnit
ORDER BY bu_id, month;

-- task 14 
-- Create database if needed
CREATE DATABASE IF NOT EXISTS school;
USE school;

-- Create BusinessUnit table
CREATE TABLE BusinessUnit (
    bu_id VARCHAR(50),
    month DATE,
    cost FLOAT,
    revenue FLOAT
);

-- Insert sample data
INSERT INTO BusinessUnit (bu_id, month, cost, revenue) VALUES
('BU1', '2025-01-01', 50000, 100000),
('BU1', '2025-02-01', 60000, 120000),
('BU2', '2025-01-01', 30000, 80000),
('BU2', '2025-02-01', 40000, 90000);
SELECT * FROM BusinessUnit;
SELECT 
    bu_id,
    month,
    ROUND(cost / NULLIF(revenue, 0), 2) AS ratio
FROM BusinessUnit
ORDER BY bu_id, month;

-- task 15 
 -- Create database if needed
CREATE DATABASE IF NOT EXISTS school;
USE school;

-- Create Employees table
CREATE TABLE Employees (
    employee_id INT PRIMARY KEY,
    name VARCHAR(50),
    salary FLOAT
);

-- Insert sample data
INSERT INTO Employees (employee_id, name, salary) VALUES
(1, 'Alice', 100000),
(2, 'Bob', 95000),
(3, 'Charlie', 90000),
(4, 'David', 85000),
(5, 'Eve', 80000),
(6, 'Frank', 75000),
(7, 'Grace', 70000);
SELECT * FROM Employees;
SET @rank = 0;

SELECT 
    employee_id,
    name,
    salary
FROM (
    SELECT 
        employee_id,
        name,
        salary,
        @rank := @rank + 1 AS rank
    FROM Employees e
    WHERE (
        SELECT COUNT(*) 
        FROM Employees e2 
        WHERE e2.salary > e.salary
    ) < 5
) ranked
WHERE rank <= 5;

-- task 16 

