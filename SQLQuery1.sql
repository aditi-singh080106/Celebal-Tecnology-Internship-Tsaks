-- Use AdventureWorks
USE AdventureWorks2022;
GO

--  Q1 List of all customers
SELECT * FROM Sales.Customer;

--  Q2 List of all customers where company name ends in 'N'
SELECT c.CustomerID, s.Name AS CompanyName
FROM Sales.Customer c
JOIN Sales.Store s ON c.StoreID = s.BusinessEntityID
WHERE s.Name LIKE '%N';

-- Q3 List of all customers who live in Berlin or London
SELECT c.CustomerID, a.City
FROM Sales.Customer c
JOIN Person.BusinessEntityAddress bea ON c.CustomerID = bea.BusinessEntityID
JOIN Person.Address a ON bea.AddressID = a.AddressID
WHERE a.City IN ('Berlin', 'London');


-- Q4 List of all customers who live in UK or USA
SELECT DISTINCT c.CustomerID, cr.Name AS Country
FROM Sales.Customer c
JOIN Person.BusinessEntityAddress bea ON c.CustomerID = bea.BusinessEntityID
JOIN Person.Address a ON bea.AddressID = a.AddressID
JOIN Person.StateProvince sp ON a.StateProvinceID = sp.StateProvinceID
JOIN Person.CountryRegion cr ON sp.CountryRegionCode = cr.CountryRegionCode
WHERE cr.Name IN ('United Kingdom', 'United States');

-- Q5 List of all products sorted by product name
SELECT ProductID, Name
FROM Production.Product
ORDER BY Name;

-- Q6 List of all products where product name starts with an A
SELECT ProductID, Name
FROM Production.Product
WHERE Name LIKE 'A%';

-- Q7 List of customers who never placed an order

SELECT c.CustomerID
FROM Sales.Customer c
LEFT JOIN Sales.SalesOrderHeader s
    ON c.CustomerID = s.CustomerID
WHERE s.SalesOrderID IS NULL;

-- Q8 List of customers who live in London and have bought Chai
SELECT DISTINCT c.CustomerID
FROM Sales.Customer c
JOIN Sales.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN Production.Product p ON sod.ProductID = p.ProductID
JOIN Person.BusinessEntityAddress bea ON c.CustomerID = bea.BusinessEntityID
JOIN Person.Address a ON bea.AddressID = a.AddressID
WHERE a.City = 'London' AND p.Name = 'Chai';

-- Q9 List of customers who ordered Tofu
SELECT DISTINCT c.CustomerID
FROM Sales.Customer c
JOIN Sales.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN Production.Product p ON sod.ProductID = p.ProductID
WHERE p.Name = 'Tofu';

-- Q10 Details of the first order of the system
SELECT TOP 1 *
FROM Sales.SalesOrderHeader
ORDER BY OrderDate ASC;

--  Q11 Find the details of most expensive order date
SELECT TOP 1 OrderDate, TotalDue
FROM Sales.SalesOrderHeader
ORDER BY TotalDue DESC;

-- Q12 For each order, get the OrderID and average quantity of items
SELECT SalesOrderID, AVG(OrderQty) AS AverageQuantity
FROM Sales.SalesOrderDetail
GROUP BY SalesOrderID;

-- Q13: For each order, get OrderID, minimum, and maximum quantity
SELECT SalesOrderID,
       MIN(OrderQty) AS MinQuantity,
       MAX(OrderQty) AS MaxQuantity
FROM Sales.SalesOrderDetail
GROUP BY SalesOrderID;

-- Q14 List of all managers and total number of employees who report to them
SELECT 
    mgr.BusinessEntityID AS ManagerID,
    CONCAT(mgrp.FirstName, ' ', mgrp.LastName) AS ManagerName,
    COUNT(emp.BusinessEntityID) AS NumEmployees
FROM HumanResources.Employee emp
JOIN HumanResources.Employee mgr ON emp.OrganizationNode.GetAncestor(1) = mgr.OrganizationNode
JOIN Person.Person mgrp ON mgr.BusinessEntityID = mgrp.BusinessEntityID
GROUP BY mgr.BusinessEntityID, mgrp.FirstName, mgrp.LastName;


-- Q15: Get OrderID and total quantity for orders with total quantity > 300
SELECT SalesOrderID, SUM(OrderQty) AS TotalQuantity
FROM Sales.SalesOrderDetail
GROUP BY SalesOrderID
HAVING SUM(OrderQty) > 300;

-- Q16 Get the OrderID and the total quantity for each order that has a total quantity of greater than 300
SELECT SalesOrderID, SUM(OrderQty) AS TotalQuantity
FROM Sales.SalesOrderDetail
GROUP BY SalesOrderID
HAVING SUM(OrderQty) > 300;

--  Q17 List all orders placed on or after 1996/12/31
SELECT *
FROM Sales.SalesOrderHeader
WHERE OrderDate >= '1996-12-31';

-- Q18 List of all orders shipped to Canada
SELECT soh.SalesOrderID, a.AddressLine1, sp.Name AS State, cr.Name AS Country
FROM Sales.SalesOrderHeader soh
JOIN Person.Address a ON soh.ShipToAddressID = a.AddressID
JOIN Person.StateProvince sp ON a.StateProvinceID = sp.StateProvinceID
JOIN Person.CountryRegion cr ON sp.CountryRegionCode = cr.CountryRegionCode
WHERE cr.Name = 'Canada';

-- Q19: List of all orders with order total > 200
SELECT SalesOrderID, TotalDue
FROM Sales.SalesOrderHeader
WHERE TotalDue > 200;

--  Q20 List of countries and sales made in each country
SELECT cr.Name AS Country, SUM(soh.TotalDue) AS TotalSales
FROM Sales.SalesOrderHeader soh
JOIN Person.Address a ON soh.ShipToAddressID = a.AddressID
JOIN Person.StateProvince sp ON a.StateProvinceID = sp.StateProvinceID
JOIN Person.CountryRegion cr ON sp.CountryRegionCode = cr.CountryRegionCode
GROUP BY cr.Name
ORDER BY TotalSales DESC;


-- Q21 List of Customer ContactName and number of orders they placed
SELECT p.FirstName + ' ' + p.LastName AS ContactName, COUNT(soh.SalesOrderID) AS OrderCount
FROM Sales.Customer c
JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
JOIN Sales.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
GROUP BY p.FirstName, p.LastName;

-- Q22 List of customer contact names who have placed more than 3 orders
SELECT p.FirstName + ' ' + p.LastName AS ContactName, COUNT(soh.SalesOrderID) AS OrderCount
FROM Sales.Customer c
JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
JOIN Sales.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
GROUP BY p.FirstName, p.LastName
HAVING COUNT(soh.SalesOrderID) > 3;

-- Q23 List of discontinued products which were ordered between 1/1/1997 and 1/1/1998
SELECT DISTINCT p.Name, p.DiscontinuedDate
FROM Production.Product p
JOIN Sales.SalesOrderDetail sod ON p.ProductID = sod.ProductID
JOIN Sales.SalesOrderHeader soh ON sod.SalesOrderID = soh.SalesOrderID
WHERE p.DiscontinuedDate IS NOT NULL
  AND soh.OrderDate BETWEEN '1997-01-01' AND '1998-01-01';

-- Q24 List of employee FirstName, LastName, Supervisor FirstName, LastName
SELECT 
    emp.BusinessEntityID AS EmployeeID,
    empP.FirstName AS EmpFirstName,
    empP.LastName AS EmpLastName,
    mgrP.FirstName AS ManagerFirstName,
    mgrP.LastName AS ManagerLastName
FROM HumanResources.Employee emp
JOIN HumanResources.Employee mgr ON emp.OrganizationNode.GetAncestor(1) = mgr.OrganizationNode
JOIN Person.Person empP ON emp.BusinessEntityID = empP.BusinessEntityID
JOIN Person.Person mgrP ON mgr.BusinessEntityID = mgrP.BusinessEntityID;

-- Q25: List of Employees and total sale conducted by employee
SELECT p.FirstName + ' ' + p.LastName AS EmployeeName, 
       SUM(soh.TotalDue) AS TotalSales
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesPerson sp ON soh.SalesPersonID = sp.BusinessEntityID
JOIN HumanResources.Employee e ON sp.BusinessEntityID = e.BusinessEntityID
JOIN Person.Person p ON e.BusinessEntityID = p.BusinessEntityID
GROUP BY p.FirstName, p.LastName
ORDER BY TotalSales DESC;

-- Q26 List of products sold by each employee
SELECT 
    p.FirstName + ' ' + p.LastName AS EmployeeName,
    pr.Name AS ProductName,
    COUNT(*) AS TotalSold
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN Sales.SalesPerson sp ON soh.SalesPersonID = sp.BusinessEntityID
JOIN HumanResources.Employee e ON sp.BusinessEntityID = e.BusinessEntityID
JOIN Person.Person p ON e.BusinessEntityID = p.BusinessEntityID
JOIN Production.Product pr ON sod.ProductID = pr.ProductID
GROUP BY p.FirstName, p.LastName, pr.Name
ORDER BY EmployeeName, TotalSold DESC;

--  Q27 List of products sold by employee 'David'
SELECT 
    p.FirstName + ' ' + p.LastName AS EmployeeName,
    pr.Name AS ProductName,
    COUNT(*) AS QuantitySold
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN Sales.SalesPerson sp ON soh.SalesPersonID = sp.BusinessEntityID
JOIN HumanResources.Employee e ON sp.BusinessEntityID = e.BusinessEntityID
JOIN Person.Person p ON e.BusinessEntityID = p.BusinessEntityID
JOIN Production.Product pr ON sod.ProductID = pr.ProductID
WHERE p.FirstName = 'David'
GROUP BY p.FirstName, p.LastName, pr.Name;


-- Q28 Number of customers in each country
SELECT cr.Name AS Country, COUNT(DISTINCT c.CustomerID) AS CustomerCount
FROM Sales.Customer c
JOIN Person.BusinessEntityAddress bea ON c.CustomerID = bea.BusinessEntityID
JOIN Person.Address a ON bea.AddressID = a.AddressID
JOIN Person.StateProvince sp ON a.StateProvinceID = sp.StateProvinceID
JOIN Person.CountryRegion cr ON sp.CountryRegionCode = cr.CountryRegionCode
GROUP BY cr.Name
ORDER BY CustomerCount DESC;

-- Q29 Country with the highest number of customers

SELECT TOP 1 cr.Name AS Country, COUNT(DISTINCT c.CustomerID) AS CustomerCount
FROM Sales.Customer c
JOIN Person.BusinessEntityAddress bea ON c.CustomerID = bea.BusinessEntityID
JOIN Person.Address a ON bea.AddressID = a.AddressID
JOIN Person.StateProvince sp ON a.StateProvinceID = sp.StateProvinceID
JOIN Person.CountryRegion cr ON sp.CountryRegionCode = cr.CountryRegionCode
GROUP BY cr.Name
ORDER BY CustomerCount DESC;

--  Q30 Total revenue made by each employee

SELECT 
    p.FirstName + ' ' + p.LastName AS EmployeeName,
    SUM(soh.TotalDue) AS TotalRevenue
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesPerson sp ON soh.SalesPersonID = sp.BusinessEntityID
JOIN HumanResources.Employee e ON sp.BusinessEntityID = e.BusinessEntityID
JOIN Person.Person p ON e.BusinessEntityID = p.BusinessEntityID
GROUP BY p.FirstName, p.LastName
ORDER BY TotalRevenue DESC;
-- Q31 Month-wise revenue of each employee
SELECT 
    p.FirstName + ' ' + p.LastName AS EmployeeName,
    FORMAT(soh.OrderDate, 'yyyy-MM') AS OrderMonth,
    SUM(soh.TotalDue) AS MonthlyRevenue
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesPerson sp ON soh.SalesPersonID = sp.BusinessEntityID
JOIN HumanResources.Employee e ON sp.BusinessEntityID = e.BusinessEntityID
JOIN Person.Person p ON e.BusinessEntityID = p.BusinessEntityID
GROUP BY p.FirstName, p.LastName, FORMAT(soh.OrderDate, 'yyyy-MM')
ORDER BY EmployeeName, OrderMonth;


--  Q32 List employees who have never made a sale
SELECT p.FirstName + ' ' + p.LastName AS EmployeeName
FROM HumanResources.Employee e
JOIN Person.Person p ON e.BusinessEntityID = p.BusinessEntityID
LEFT JOIN Sales.SalesPerson sp ON e.BusinessEntityID = sp.BusinessEntityID
LEFT JOIN Sales.SalesOrderHeader soh ON sp.BusinessEntityID = soh.SalesPersonID
WHERE soh.SalesOrderID IS NULL;

-- Q33 List the names of customers and employees who live in the same city

SELECT DISTINCT c.CustomerID, cp.FirstName + ' ' + cp.LastName AS CustomerName,
                e.BusinessEntityID AS EmployeeID, ep.FirstName + ' ' + ep.LastName AS EmployeeName,
                a1.City
FROM Sales.Customer c
JOIN Person.BusinessEntityAddress bea1 ON c.CustomerID = bea1.BusinessEntityID
JOIN Person.Address a1 ON bea1.AddressID = a1.AddressID
JOIN Person.Person cp ON c.PersonID = cp.BusinessEntityID

JOIN HumanResources.Employee e ON 1=1
JOIN Person.BusinessEntityAddress bea2 ON e.BusinessEntityID = bea2.BusinessEntityID
JOIN Person.Address a2 ON bea2.AddressID = a2.AddressID
JOIN Person.Person ep ON e.BusinessEntityID = ep.BusinessEntityID

WHERE a1.City = a2.City;

-- Q34 Product with highest revenue

SELECT TOP 1 p.Name AS ProductName, SUM(sod.LineTotal) AS Revenue
FROM Sales.SalesOrderDetail sod
JOIN Production.Product p ON sod.ProductID = p.ProductID
GROUP BY p.Name
ORDER BY Revenue DESC;


-- Q35 Product with highest revenue in Canada
SELECT TOP 1 p.Name AS ProductName, SUM(sod.LineTotal) AS Revenue
FROM Sales.SalesOrderDetail sod
JOIN Sales.SalesOrderHeader soh ON sod.SalesOrderID = soh.SalesOrderID
JOIN Production.Product p ON sod.ProductID = p.ProductID
JOIN Person.Address a ON soh.ShipToAddressID = a.AddressID
JOIN Person.StateProvince sp ON a.StateProvinceID = sp.StateProvinceID
JOIN Person.CountryRegion cr ON sp.CountryRegionCode = cr.CountryRegionCode
WHERE cr.Name = 'Canada'
GROUP BY p.Name
ORDER BY Revenue DESC;

-- Q36 Product with highest quantity sold


SELECT TOP 1 p.Name AS ProductName, SUM(sod.OrderQty) AS TotalQuantitySold
FROM Sales.SalesOrderDetail sod
JOIN Production.Product p ON sod.ProductID = p.ProductID
GROUP BY p.Name
ORDER BY TotalQuantitySold DESC;

-- Q37 Country with highest quantity of sales
SELECT TOP 1 cr.Name AS Country, SUM(sod.OrderQty) AS TotalQuantitySold
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN Person.Address a ON soh.ShipToAddressID = a.AddressID
JOIN Person.StateProvince sp ON a.StateProvinceID = sp.StateProvinceID
JOIN Person.CountryRegion cr ON sp.CountryRegionCode = cr.CountryRegionCode
GROUP BY cr.Name
ORDER BY TotalQuantitySold DESC;
-- Q38 Top 5 customers with highest order amount
SELECT TOP 5 c.CustomerID, p.FirstName + ' ' + p.LastName AS CustomerName, SUM(soh.TotalDue) AS TotalSpent
FROM Sales.Customer c
JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
JOIN Sales.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
GROUP BY c.CustomerID, p.FirstName, p.LastName
ORDER BY TotalSpent DESC;
--  Q39 Top 5 customers who ordered the most number of products
SELECT TOP 5 c.CustomerID, p.FirstName + ' ' + p.LastName AS CustomerName, SUM(sod.OrderQty) AS TotalProducts
FROM Sales.Customer c
JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
JOIN Sales.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
GROUP BY c.CustomerID, p.FirstName, p.LastName
ORDER BY TotalProducts DESC;
--  Q40 Top 5 most selling products in Canada
SELECT TOP 5 p.Name AS ProductName, SUM(sod.OrderQty) AS TotalSold
FROM Sales.SalesOrderDetail sod
JOIN Sales.SalesOrderHeader soh ON sod.SalesOrderID = soh.SalesOrderID
JOIN Production.Product p ON sod.ProductID = p.ProductID
JOIN Person.Address a ON soh.ShipToAddressID = a.AddressID
JOIN Person.StateProvince sp ON a.StateProvinceID = sp.StateProvinceID
JOIN Person.CountryRegion cr ON sp.CountryRegionCode = cr.CountryRegionCode
WHERE cr.Name = 'Canada'
GROUP BY p.Name
ORDER BY TotalSold DESC;
-- Q41 Top 5 most selling products in Germany
SELECT TOP 5 p.Name AS ProductName, SUM(sod.OrderQty) AS TotalSold
FROM Sales.SalesOrderDetail sod
JOIN Sales.SalesOrderHeader soh ON sod.SalesOrderID = soh.SalesOrderID
JOIN Production.Product p ON sod.ProductID = p.ProductID
JOIN Person.Address a ON soh.ShipToAddressID = a.AddressID
JOIN Person.StateProvince sp ON a.StateProvinceID = sp.StateProvinceID
JOIN Person.CountryRegion cr ON sp.CountryRegionCode = cr.CountryRegionCode
WHERE cr.Name = 'Germany'
GROUP BY p.Name
ORDER BY TotalSold DESC;
-- Q42 Total revenue earned
SELECT SUM(TotalDue) AS TotalRevenue
FROM Sales.SalesOrderHeader;

