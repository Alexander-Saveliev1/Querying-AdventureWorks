use adventureworks2019;
go


-- Exercise 1:

-- taking the full name from the Person.Person table
SELECT pp.FirstName, pp.MiddleName, pp.LastName 
	FROM Person.Person AS pp
-- connecting Person.Person table to HumanResources.EmployeeDepartmentHistory table to connect a person to their department history
	JOIN HumanResources.EmployeeDepartmentHistory AS edh ON pp.BusinessEntityID = edh.BusinessEntityID
-- Checking if employees have an EndDate on their EmployeeDepartmentHistory table (no EndDate means they haven't finished working there)
WHERE edh.EndDate IS NOT NULL
GROUP BY pp.FirstName, pp.MiddleName, pp.LastName 


go

-- Exercise 2:

-- Taking the full name from the Person.Person table and the name of the last department they started working on from HumanResources.Department
SELECT pp.BusinessEntityID, pp.FirstName, pp.LastName, d.Name
	FROM Person.Person AS pp
-- Connecting Person.Person table to HumanResources.EmployeeDepartmentHistory table to connect a person to their department history
	JOIN HumanResources.EmployeeDepartmentHistory AS edh ON pp.BusinessEntityID = edh.BusinessEntityID
-- Connecting HumanResources.EmployeeDepartmentHistory and HumanResources.Department to be able to see department name in the select statement
	JOIN HumanResources.Department AS d ON edh.DepartmentID = d.DepartmentID
-- The in statement needs values and the values are going to be the maximum EndDate of HumanResources.EmployeeDepartmentHistory
WHERE edh.EndDate IN (
-- Filtering whether employees have an EndDate on their EmployeeDepartmentHistory table (no EndDate means they haven't finished working there)
		select MAX(EndDate) AS MaxEndDate
			FROM HumanResources.EmployeeDepartmentHistory AS edh
			JOIN HumanResources.Department AS d ON edh.DepartmentID = d.DepartmentID
		WHERE edh.EndDate IS NOT NULL
		GROUP BY edh.BusinessEntityID)
go

-- Exercise 3:

-- Picking out the first name from Production.Product and counting how many purchase orders there are from Purchasing.PurchaseOrderDetail
SELECT TOP 1 ProP.Name, Count(PPOD.PurchaseOrderID) AS OrderAmount
	FROM Production.Product AS ProP 
	JOIN Purchasing.PurchaseOrderDetail AS PPOD ON ProP.ProductID = PPOD.ProductID
-- Grouping by Name of the product to recieve only one product name for the OrderAmount
	GROUP BY ProP.Name
-- ordering by the OrderAmount in descending order to recieve the highest OrderAmount first
	ORDER BY Count(PPOD.PurchaseOrderID) DESC

go

-- Exercise 4:

-- Picking out the first name from Production.Product and summarising the quantity of ordered items from Purchasing.PurchaseOrderDetail
SELECT TOP 1 ProP.Name, SUM(PPOD.OrderQty) AS QtyOrdered
	FROM Production.Product AS ProP 
	JOIN Purchasing.PurchaseOrderDetail AS PPOD ON ProP.ProductID = PPOD.ProductID
-- Grouping by Name of the product to recieve only one product name for the QtyOrdered
	GROUP BY ProP.Name
-- ordering by the OrderAmount in descending order to recieve the highest QtyOrdered first
	ORDER BY SUM(PPOD.OrderQty) DESC

go

-- Exercise 5:

-- Display the Details of Sales.Customers
SELECT SC.*
-- From the Sales.Customers table while making a left join with the Sales.SalesOrderHeader table to see which customers have not ordered anything yet
FROM Sales.Customer AS SC
LEFT JOIN Sales.SalesOrderHeader  AS SSOH ON SC.CustomerID = SSOH.CustomerID
-- Checking if they've ordered anything
WHERE SalesOrderID IS NULL


go

-- Exercise 6:

-- Picking out productID and name of product FROM Production.Product
SELECT PROP.ProductID, PROP.Name
	FROM Production.Product AS PROP
-- Combining with Sales.SalesOrderDetail with a LEFT JOIN so that i'll see all the products from Production.Product
	LEFT JOIN Sales.SalesOrderDetail AS SOD ON PROP.ProductID = SOD.ProductID
-- Grouping the productID and Name as I'm interested in the products not the orders
GROUP BY ProP.ProductID, ProP.Name
-- Filtering products that have had no orders made on them
HAVING COUNT(SOD.SalesOrderID) = 0
go

-- Exercise 7:

-- Creating a new subquery named OrderRank to be able to rank the orders
WITH RankedOrders (SalesOrderID, TotalPrice, OrderMonth, OrderYear, RankedOrders) AS
(
-- Selecting OrderID, the total price for that order, its' month, year and the rank based on the total price
SELECT SOH.SalesOrderID, SUM(OrderQty*UnitPrice) TotalPrice, MONTH(OrderDate) AS OrderMonth, YEAR(OrderDate) AS OrderYear,  ROW_NUMBER() OVER (PARTITION BY MONTH(OrderDate) , YEAR(OrderDate) ORDER BY SUM(OrderQty*UnitPrice) DESC) AS RankedValue
-- Getting the information in the select from SalesOrderHeader table joined with SalesOrderDetail table
FROM Sales.SalesOrderHeader AS SOH
JOIN Sales.SalesOrderDetail AS SOD ON SOH.SalesOrderID = SOD.SalesOrderID
-- Grouping by OrderID, Month and Year.
GROUP BY SOH.SalesOrderID, MONTH(OrderDate),Year(OrderDate)
)

-- Selecting all the rows from the subquery
SELECT MAX(SalesOrderID) AS ItemID, MAX(TotalPrice) AS MaxValue, OrderMonth, OrderYear, RankedOrders
FROM RankedOrders
-- Filtering by the RankedOrders column and picking the top 3 orders per month
WHERE RankedOrders IN (1,2,3)
GROUP BY  OrderMonth, OrderYear, RankedOrders
ORDER BY OrderMonth, OrderYear

go

-- Exercise 8:

-- Creating a subquery named CountedOrdersByMonth that will count orders of SalesPeople each month
WITH CountedOrdersByMonth(SalesOrderID, OrderDate, OrderYear, OrderMonth, SalesPersonID, NumberedOrdersForMonth) AS
(	
	-- Selecting OrderID, OrderDate along with its month and year, the SalesPersonsID, and numbering the orders for each month
	SELECT SalesOrderID, OrderDate, YEAR(OrderDate) OrderYear, MONTH(OrderDate) OrderMonth, SalesPersonID, ROW_NUMBER() OVER(PARTITION BY YEAR(OrderDate), MONTH(OrderDate), SalesPersonID ORDER BY SalesOrderID) NumberedOrdersForMonth
	-- Data extracted from Sales.SalesOrderHeader table
	FROM Sales.SalesOrderHeader
	-- Filter out SalesPeople that do not exist
	WHERE SalesPersonID IS NOT NULL
)

-- Show only the month, Year, PersonID and the maximum number of the numbered orders each month from the subquery
SELECT OrderMonth, OrderYear, SalesPersonID, MAX(NumberedOrdersForMonth) AmountOfOrders
FROM CountedOrdersByMonth
-- Grouped by year, month and SalesPersonID
GROUP BY OrderYear, OrderMonth, SalesPersonID
go

-- Exercise 9: 

-- Using the subquery from the last exercise
WITH CountedOrdersByMonth(SalesOrderID, OrderDate, OrderYear, OrderMonth, SalesPersonID, NumberedOrdersForMonth) AS
(	
	SELECT SalesOrderID, OrderDate, YEAR(OrderDate) OrderYear, MONTH(OrderDate) OrderMonth, SalesPersonID, ROW_NUMBER() OVER(PARTITION BY YEAR(OrderDate), MONTH(OrderDate), SalesPersonID ORDER BY SalesOrderID) NumberedOrdersForMonth
	FROM Sales.SalesOrderHeader
	WHERE SalesPersonID IS NOT NULL
)

-- Show the personID, the full name, order month, year, and summarize the total sales that the person made that month
SELECT SalesPersonID,PP.FirstName, PP.LastName, OrderMonth, OrderYear, SUM(SOH.OrderQty*SOH.UnitPrice) TotalSalesPerMonth
-- Getting the data from the subquery and traveling over to Person.Person that hold the details of  the person
FROM CountedOrdersByMonth AS COBM
JOIN Sales.SalesOrderDetail AS SOH ON COBM.SalesOrderID = SOH.SalesOrderID
JOIN Person.Person AS PP ON COBM.SalesPersonID = PP.BusinessEntityID
GROUP BY OrderYear, OrderMonth, SalesPersonID, PP.FirstName, PP.LastName
Order BY SalesPersonID, OrderMonth

go

-- Exercise 10:

WITH CountedOrdersByMonth(SalesOrderID, OrderDate, OrderYear, OrderMonth, SalesPersonID, NumberedOrdersForMonth) AS
(	
	SELECT SalesOrderID, OrderDate, YEAR(OrderDate) OrderYear, MONTH(OrderDate) OrderMonth, SalesPersonID, ROW_NUMBER() OVER(PARTITION BY YEAR(OrderDate), MONTH(OrderDate), SalesPersonID ORDER BY SalesOrderID) NumberedOrdersForMonth
	FROM Sales.SalesOrderHeader
	WHERE SalesPersonID IS NOT NULL
)

SELECT SalesPersonID,PP.FirstName, PP.LastName, OrderMonth, OrderYear, SUM(SOH.OrderQty*SOH.UnitPrice) AS TotalSalesPerMonth,
LAG(SUM(SOH.OrderQty*SOH.UnitPrice)) OVER (PARTITION BY SalesPersonID Order by OrderYear,OrderMonth) AS LastMonthSales
FROM CountedOrdersByMonth AS COBM
JOIN Sales.SalesOrderDetail AS SOH ON COBM.SalesOrderID = SOH.SalesOrderID
JOIN Person.Person AS PP ON COBM.SalesPersonID = PP.BusinessEntityID
GROUP BY OrderYear, OrderMonth, SalesPersonID, PP.FirstName, PP.LastName

go

-- Exercise 11:

Create PROCEDURE EmployeesOrdersByMonth @SalesPersonID INT
AS
IF @SalesPersonID = (SELECT SalesPersonID FROM Sales.SalesOrderHeader WHERE SalesPersonID = @SalesPersonID GROUP BY SalesPersonID) OR @SalesPersonID IS NULL
	WITH CountedOrdersByMonth(SalesOrderID, OrderDate, OrderYear, OrderMonth, SalesPersonID, NumberedOrdersForMonth) AS
	(	
		SELECT SalesOrderID, OrderDate, YEAR(OrderDate) OrderYear, MONTH(OrderDate) OrderMonth, SalesPersonID, ROW_NUMBER() OVER(PARTITION BY YEAR(OrderDate), MONTH(OrderDate), SalesPersonID ORDER BY SalesOrderID) NumberedOrdersForMonth
		FROM Sales.SalesOrderHeader
		WHERE SalesPersonID IS NOT NULL
	)
	SELECT COBM.SalesPersonID,PP.FirstName, PP.LastName, COBM.OrderMonth, COBM.OrderYear, SUM(SOD.OrderQty*SOD.UnitPrice) AS TotalSalesPerMonth,
	LAG(SUM(SOD.OrderQty*SOD.UnitPrice)) OVER (PARTITION BY SalesPersonID Order by OrderYear,OrderMonth) AS LastMonthSales
	FROM CountedOrdersByMonth AS COBM
	JOIN Sales.SalesOrderDetail AS SOD ON COBM.SalesOrderID = SOD.SalesOrderID
	JOIN Person.Person AS PP ON COBM.SalesPersonID = PP.BusinessEntityID
	WHERE SalesPersonID = CASE
		WHEN @SalesPersonID IS NOT NULL
			THEN  @SalesPersonID
		ELSE
			 SalesPersonID
		END
	GROUP BY OrderYear, OrderMonth, SalesPersonID, PP.FirstName, PP.LastName
ELSE
RAISERROR ('That SalesPersonID is invalid', 10,1)

go


-- Example of a working call to the procedure with a valid Sales Person ID:

EXEC EmployeesOrdersByMonth @SalesPersonID = 274

go

-- Example of a working call to the procedure with no Sales Person ID:

EXEC EmployeesOrdersByMonth @SalesPersonID = NULL

go

-- Example of a failed call to the function using invalid input:

EXEC EmployeesOrdersByMonth @SalesPersonID = 200

go
