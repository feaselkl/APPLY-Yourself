/* Example 4:  top N records for each X */
/* What we want:  a view to see the average, minimum, maximum, and total prices of each customer's last 5 orders. */

/* Sanity check:  how many rows should we get back? */
SELECT
	count(*) 
FROM
	Sales.Customer sc
	INNER JOIN Person.Person pp ON sc.PersonID = pp.BusinessEntityID;

/* Check relative performance of each.  Be sure to turn on execution plans (Ctrl+M). */
SET STATISTICS IO ON
SET STATISTICS TIME ON
GO

/* The correlated subquery method gets nasty.  Temp tables? */

/* Method 1:  CTE */
WITH Orders AS
(
	SELECT
		soh.CustomerID,
		ROW_NUMBER() OVER (PARTITION BY soh.CustomerID 
							ORDER BY soh.SalesOrderID DESC) as rownum,
		soh.TotalDue
	FROM
		Sales.SalesOrderHeader soh
)
SELECT
	sc.AccountNumber,
	pp.FirstName,
	pp.LastName,
	COUNT(*) as NumberOfOrders,
	MIN(o.TotalDue) as MinimumTotalDue,
	MAX(o.TotalDue) as MaximumTotalDue,
	AVG(o.TotalDue) as AverageTotalDue,
	SUM(o.TotalDue) as TotalDue
FROM
	Sales.Customer sc
	INNER JOIN Person.Person pp ON sc.PersonID = pp.BusinessEntityID
	LEFT OUTER JOIN Orders o 
		ON sc.CustomerID = o.CustomerID
		AND o.rownum <= 5
GROUP BY
	sc.AccountNumber,
	pp.FirstName,
	pp.LastName
ORDER BY
	sc.AccountNumber;

/* Method 2:  APPLY */
SELECT
	sc.AccountNumber,
	pp.FirstName,
	pp.LastName,
	COUNT(*) as NumberOfOrders,
	MIN(o.TotalDue) as MinimumTotalDue,
	MAX(o.TotalDue) as MaximumTotalDue,
	AVG(o.TotalDue) as AverageTotalDue,
	SUM(o.TotalDue) as TotalDue
FROM
	Sales.Customer sc
	INNER JOIN Person.Person pp ON sc.PersonID = pp.BusinessEntityID
	OUTER APPLY
	(
		SELECT TOP 5
			soh.CustomerID,
			soh.TotalDue
		FROM
			Sales.SalesOrderHeader soh
		WHERE
			soh.CustomerID = sc.CustomerID
		ORDER BY
			soh.SalesOrderID DESC
	) o
GROUP BY
	sc.AccountNumber,
	pp.FirstName,
	pp.LastName
ORDER BY
	sc.AccountNumber;

/* What about with the larger data set? */