-- LeetCode Problrms Task 6
-- LeetCode Account : https://leetcode.com/u/Singh_Aditi08/
-- 1. Combine Two Tables
-- solution
    SELECT p.firstname , p.lastname , a.city , a.state FROM PERSON p
    LEFT JOIN ADDRESS a 
    ON p.personId = a.personId ;
-- 2. Second Highest Salary
-- Solution
SELECT MAX(salary) AS SecondHighestSalary
From Employee
WHERE salary <> (SELECT MAX(salary) FROM Employee);
-- 3. Employees Earning More Than Their Managers
-- Solution
 SELECT e1.name AS Employee 
 FROM employee e1 
 JOIN employee e2 
 ON e1.managerId = e2.id 
 where e1.salary > e2.salary;
-- 4. Duplicate Emails
-- Solution 
SELECT email FROM Person GROUP BY email HAVING COUNT(email) > 1;
-- 5. Customers Who Never Order
-- Solution
SELECT c.name AS Customers FROM customers as c  LEFT JOIN orders AS o 
ON (c.id = o.customerid) WHERE o.customerId IS NULL; 
-- 6. Delete Duplicate Emails
-- Solution
DELETE p1 
from person p1 
join person p2 
on p1.email = p2.email and p1.id > p2.id ;
-- 7. Game Play Analysis I
-- Solution
select player_id , MIN(event_date) as first_login from Activity group by player_id;
-- 8. Find Customer Referee
-- Solution 
SELECT name FROM Customer WHERE referee_id != 2 OR referee_id IS null ;
-- 9. Big Countries
-- Solution
SELECT name , population , area FROM World WHERE
    area >= 3000000 OR
    population >= 25000000;
-- 10. Product Sales Analysis I
-- Solution 
SELECT p.product_name , year , price 
FROM Sales AS s 
JOIN Product AS p 
ON s.product_id = p.product_id 
WHERE sale_id IS NOT NULL;
