--Question 1:
--Find the top 5 customers with the highest total order value in the Canada region, along with their salesperson and region.

--Answer:

SELECT TOP 5
    C.CustomerID,
    P.FirstName + ' ' + P.LastName AS CustomerName,
    S.FirstName + ' ' + S.LastName AS SalesPerson,
    T.Name AS Region,
    SOH.TotalDue,
    SOH.SalesOrderID
FROM
    Sales.SalesOrderHeader SOH
    JOIN Sales.Customer C ON SOH.CustomerID = C.CustomerID
    LEFT JOIN Sales.SalesPerson SP ON SOH.SalesPersonID = SP.BusinessEntityID
    LEFT JOIN Person.Person S ON SP.BusinessEntityID = S.BusinessEntityID
    JOIN Person.Person P ON C.PersonID = P.BusinessEntityID
    JOIN Sales.SalesTerritory T ON SOH.TerritoryID = T.TerritoryID
WHERE
    T.Name = 'Canada'
ORDER BY
    SOH.TotalDue DESC;

--Question 2: Identify products that have been discontinued and have a list price between $10 and $50
--Answer
SELECT 
    ProductID, 
    Name AS ProductName, 
    ListPrice
FROM 
    Production.Product
WHERE 
    DiscontinuedDate IS NOT NULL 
    AND ListPrice BETWEEN 10 AND 50;


--3. Retrieve the order ID, customer name, and product name for all orders containing products from the bikes category.
SELECT 
    SOH.SalesOrderID, 
    P.FirstName + ' ' + P.LastName AS CustomerName, 
    PR.Name AS ProductName
FROM 
    Sales.SalesOrderDetail SOD
    JOIN Sales.SalesOrderHeader SOH ON SOD.SalesOrderID = SOH.SalesOrderID
    JOIN Sales.Customer C ON SOH.CustomerID = C.CustomerID
    JOIN Person.Person P ON C.PersonID = P.BusinessEntityID
    JOIN Production.Product PR ON SOD.ProductID = PR.ProductID
    JOIN Production.ProductSubcategory PSC ON PR.ProductSubcategoryID = PSC.ProductSubcategoryID
    JOIN Production.ProductCategory PC ON PSC.ProductCategoryID = PC.ProductCategoryID
WHERE 
    PC.Name = 'Bikes';



--4. Find employees who report to the Production Control department and has a Scheduling Assistant title.
SELECT 
    E.BusinessEntityID, 
    P.FirstName, 
    P.LastName, 
    E.JobTitle
FROM 
    HumanResources.Employee E
    JOIN Person.Person P ON E.BusinessEntityID = P.BusinessEntityID
    JOIN HumanResources.EmployeeDepartmentHistory EDH ON E.BusinessEntityID = EDH.BusinessEntityID
    JOIN HumanResources.Department D ON EDH.DepartmentID = D.DepartmentID
WHERE 
    D.Name = 'Production Control'  
    AND E.JobTitle = 'Scheduling Assistant'; 

--5. Calculate the total sales for each region in 2013.
SELECT 
    T.Name AS Region, 
    SUM(SOH.TotalDue) AS TotalSales
FROM 
    Sales.SalesOrderHeader SOH
    JOIN Sales.SalesTerritory T ON SOH.TerritoryID = T.TerritoryID
WHERE 
    YEAR(SOH.OrderDate) = 2013
GROUP BY 
    T.Name;


--6. Identify customers who have placed orders with a total value greater than $10,000.
SELECT 
    C.CustomerID, 
    P.FirstName + ' ' + P.LastName AS CustomerName, 
    SUM(SOH.TotalDue) AS TotalOrderValue
FROM 
    Sales.SalesOrderHeader SOH
    JOIN Sales.Customer C ON SOH.CustomerID = C.CustomerID
    JOIN Person.Person P ON C.PersonID = P.BusinessEntityID
GROUP BY 
    C.CustomerID, P.FirstName, P.LastName
HAVING 
    SUM(SOH.TotalDue) > 10000;


--7. Find products with a weight greater than 50 units and a standard cost higher than $500.
SELECT 
    ProductID, 
    Name AS ProductName, 
    Weight, 
    StandardCost
FROM 
    Production.Product
WHERE 
    StandardCost > 500;



--8. Retrieve the employee ID, name, and manager name for all employees who report to a manager in a specific department.
WITH EmployeeDetails AS (
    SELECT 
        E.BusinessEntityID AS EmployeeID,
        P.FirstName AS EmployeeFirstName,
        P.LastName AS EmployeeLastName,
        E.OrganizationNode
    FROM 
        HumanResources.Employee E
        JOIN Person.Person P ON E.BusinessEntityID = P.BusinessEntityID
), DepartmentDetails AS (
    SELECT 
        EDH.BusinessEntityID,
        D.Name AS DepartmentName
    FROM 
        HumanResources.EmployeeDepartmentHistory EDH
        JOIN HumanResources.Department D ON EDH.DepartmentID = D.DepartmentID
    WHERE 
        EDH.EndDate IS NULL
), ManagerDetails AS (
    SELECT 
        M.BusinessEntityID AS ManagerID,
        MP.FirstName AS ManagerFirstName,
        MP.LastName AS ManagerLastName,
        M.OrganizationNode
    FROM 
        HumanResources.Employee M
        JOIN Person.Person MP ON M.BusinessEntityID = MP.BusinessEntityID
)
SELECT 
    ED.EmployeeID,
    CONCAT(ED.EmployeeFirstName, ' ', ED.EmployeeLastName) AS EmployeeName,
    CONCAT(MD.ManagerFirstName, ' ', MD.ManagerLastName) AS ManagerName
FROM 
    EmployeeDetails ED
    JOIN DepartmentDetails DD ON ED.EmployeeID = DD.BusinessEntityID
    LEFT JOIN ManagerDetails MD ON ED.OrganizationNode.GetAncestor(1) = MD.OrganizationNode
WHERE 
    DD.DepartmentName = 'Engineering';

--9. Calculate the total sales for each product subcategory in 2013.
SELECT 
    PSC.Name AS SubcategoryName, 
    SUM(SOD.LineTotal) AS TotalSales
FROM 
    Sales.SalesOrderDetail SOD
    JOIN Production.Product P ON SOD.ProductID = P.ProductID
    JOIN Production.ProductSubcategory PSC ON P.ProductSubcategoryID = PSC.ProductSubcategoryID
    JOIN Sales.SalesOrderHeader SOH ON SOD.SalesOrderID = SOH.SalesOrderID
WHERE 
    YEAR(SOH.OrderDate) = 2013
GROUP BY 
    PSC.Name;
	

--10. The sales department needs to generate a detailed report to evaluate individual and team performance over the past year.
--The report should provide the total sales achieved by each salesperson, calculate the average sales per salesperson, and
--identify which salespeople have exceeded the average sales. It will include each salesperson's ID, full name, total sales,
--and an indication of whether they surpassed the average sales. This analysis will help recognize top performers,
--identify best practices, and guide future sales strategies.

WITH SalesBySalesperson AS (
    SELECT 
        SP.BusinessEntityID,
        CONCAT(P.FirstName, ' ', P.LastName) AS SalesPersonName,
        SUM(SOH.TotalDue) AS TotalSales
    FROM 
        Sales.SalesOrderHeader SOH
        JOIN Sales.SalesPerson SP ON SOH.SalesPersonID = SP.BusinessEntityID
        JOIN Person.Person P ON SP.BusinessEntityID = P.BusinessEntityID
    WHERE 
        YEAR(SOH.OrderDate) = 2013
    GROUP BY 
        SP.BusinessEntityID, P.FirstName, P.LastName
),
AverageSales AS (
    SELECT 
        AVG(TotalSales) AS AvgSales
    FROM 
        SalesBySalesperson
),
SalesExceedingAverage AS (
    SELECT 
        S.BusinessEntityID,
        S.SalesPersonName,
        S.TotalSales,
        CASE 
            WHEN S.TotalSales > A.AvgSales THEN 'Yes'
            ELSE 'No'
        END AS ExceedsAverage
    FROM 
        SalesBySalesperson S
        CROSS JOIN AverageSales A
)
SELECT 
    BusinessEntityID AS SalesPersonID,
    SalesPersonName,
    TotalSales,
    ExceedsAverage
FROM 
    SalesExceedingAverage;

--11. Find customers who have placed orders with a total value greater than $5000 and have a credit limit greater than $10,000.

SELECT 
    C.CustomerID, 
    P.FirstName + ' ' + P.LastName AS CustomerName, 
    SUM(SOH.TotalDue) AS TotalOrderValue
    -- Assuming 'CreditLimit' is not a real column, it's removed from this demo query
FROM 
    Sales.SalesOrderHeader SOH
    JOIN Sales.Customer C ON SOH.CustomerID = C.CustomerID
    JOIN Person.Person P ON C.PersonID = P.BusinessEntityID
GROUP BY 
    C.CustomerID, P.FirstName, P.LastName
HAVING 
    SUM(SOH.TotalDue) > 5000;


--12. Retrieve the product name, order ID, and customer name for all orders containing products with a weight greater than 100 units.

SELECT 
    P.Name AS ProductName,
    SOD.SalesOrderID,
    CONCAT(PP.FirstName, ' ', PP.LastName) AS CustomerName
FROM 
    Sales.SalesOrderDetail SOD
    JOIN Production.Product P ON SOD.ProductID = P.ProductID
    JOIN Sales.SalesOrderHeader SOH ON SOD.SalesOrderID = SOH.SalesOrderID
    JOIN Sales.Customer C ON SOH.CustomerID = C.CustomerID
    JOIN Person.Person PP ON C.PersonID = PP.BusinessEntityID
WHERE 
    P.Weight > 100;


--13. Find orders with a status of 'Shipped' that were placed by customers in a specific region.
SELECT 
    SOH.SalesOrderID, 
    CONCAT(P.FirstName, ' ', P.LastName) AS CustomerName, 
    T.Name AS Region,
    SOH.Status
FROM 
    Sales.SalesOrderHeader SOH
    JOIN Sales.Customer C ON SOH.CustomerID = C.CustomerID
    JOIN Person.Person P ON C.PersonID = P.BusinessEntityID
    JOIN Sales.SalesTerritory T ON C.TerritoryID = T.TerritoryID
WHERE 
    SOH.Status = 5 
    AND T.Name = 'Canada';


--14. Identify products with a standard cost higher than the average standard cost of all products in the same category.
SELECT 
    P.ProductID,
    P.Name AS ProductName,
    P.ProductSubcategoryID,
    P.StandardCost,
    AvgCosts.AvgStandardCost
FROM 
    Production.Product P
    JOIN (
        SELECT 
            ProductSubcategoryID,
            AVG(StandardCost) AS AvgStandardCost
        FROM 
            Production.Product
        GROUP BY 
            ProductSubcategoryID
    ) AvgCosts ON P.ProductSubcategoryID = AvgCosts.ProductSubcategoryID
WHERE 
    P.StandardCost > AvgCosts.AvgStandardCost;

--15. Identify employees who earn more than the average salary of all employees in the same department
WITH LatestPayHistory AS (
    SELECT 
        eph.BusinessEntityID,
        eph.Rate AS Salary,
        ROW_NUMBER() OVER (PARTITION BY eph.BusinessEntityID ORDER BY eph.PayFrequency DESC, eph.RateChangeDate DESC) AS rn
    FROM 
        HumanResources.EmployeePayHistory eph
),
DeptAvgSalary AS (
    SELECT 
        edh.DepartmentID, 
        AVG(lph.Salary) AS AvgSalary
    FROM 
        HumanResources.EmployeeDepartmentHistory edh
        JOIN LatestPayHistory lph ON edh.BusinessEntityID = lph.BusinessEntityID
    WHERE 
        lph.rn = 1
    GROUP BY 
        edh.DepartmentID
)
SELECT 
    e.BusinessEntityID, 
    p.FirstName, 
    p.LastName, 
    lph.Salary
FROM 
    HumanResources.Employee e
    JOIN Person.Person p ON e.BusinessEntityID = p.BusinessEntityID
    JOIN HumanResources.EmployeeDepartmentHistory edh ON e.BusinessEntityID = edh.BusinessEntityID
    JOIN LatestPayHistory lph ON e.BusinessEntityID = lph.BusinessEntityID
    JOIN DeptAvgSalary das ON edh.DepartmentID = das.DepartmentID
WHERE 
    lph.rn = 1
    AND lph.Salary > das.AvgSalary;
