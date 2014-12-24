/* Example 3a:  get latest/greatest child record given much more data */
/* What we want:  a view to see each customer's latest order, PO numbers associated with these orders, 
	and total due on these orders. */

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

/*
--Add a helpful index
CREATE INDEX [IX_SalesOrderHeaderEnlarged_CustomerID_SalesOrderID_n_PurchaseOrderNumber_OrderDate] ON Sales.SalesOrderHeaderEnlarged
(
	CustomerID,
	SalesOrderID DESC
)
INCLUDE
(
	PurchaseOrderNumber,
	OrderDate,
	TotalDue
);
*/
/*
DROP INDEX [IX_SalesOrderHeaderEnlarged_CustomerID_SalesOrderID_n_PurchaseOrderNumber_OrderDate] ON Sales.SalesOrderHeaderEnlarged;
*/

/* Method 1:  correlated sub-query */
SELECT
	sc.AccountNumber,
	pp.FirstName,
	pp.LastName,
	soh.PurchaseOrderNumber,
	soh.OrderDate,
	soh.TotalDue
FROM
	Sales.Customer sc
	INNER JOIN Person.Person pp ON sc.PersonID = pp.BusinessEntityID
	LEFT OUTER JOIN
	(
		SELECT
			soh.CustomerID,
			MAX(soh.SalesOrderID) as SalesOrderID
		FROM
			Sales.SalesOrderHeaderEnlarged soh
		GROUP BY
			soh.CustomerID
	) sohmax ON sc.CustomerID = sohmax.CustomerID
	LEFT OUTER JOIN Sales.SalesOrderHeaderEnlarged soh 
		ON sohmax.SalesOrderID = soh.SalesOrderID;

/* Method 2:  CTE with window function */
WITH Orders AS
(
	SELECT
		soh.CustomerID,
		soh.PurchaseOrderNumber,
		soh.OrderDate,
		ROW_NUMBER() OVER (PARTITION BY soh.CustomerID 
							ORDER BY soh.SalesOrderID DESC) as rownum,
		soh.TotalDue
	FROM
		Sales.SalesOrderHeaderEnlarged soh
)
SELECT
	sc.AccountNumber,
	pp.FirstName,
	pp.LastName,
	o.PurchaseOrderNumber,
	o.OrderDate,
	o.TotalDue
FROM
	Sales.Customer sc
	INNER JOIN Person.Person pp ON sc.PersonID = pp.BusinessEntityID
	LEFT OUTER JOIN Orders o 
		ON sc.CustomerID = o.CustomerID
		AND o.rownum = 1;

/* Method 3:  APPLY. */
SELECT
	sc.AccountNumber,
	pp.FirstName,
	pp.LastName,
	o.PurchaseOrderNumber,
	o.OrderDate,
	o.TotalDue
FROM
	Sales.Customer sc
	INNER JOIN Person.Person pp ON sc.PersonID = pp.BusinessEntityID
	OUTER APPLY
	(
		SELECT TOP 1
			soh.CustomerID,
			soh.PurchaseOrderNumber,
			soh.OrderDate,
			soh.TotalDue
		FROM
			Sales.SalesOrderHeaderEnlarged soh
		WHERE
			soh.CustomerID = sc.CustomerID
		ORDER BY
			soh.SalesOrderID DESC
	) o;

