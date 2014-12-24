/* Example 5:  simplifying calculations */
/* What we want:  number of orders with discounts and total savings by month */

/* Check relative performance of each.  Be sure to turn on execution plans (Ctrl+M). */
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO


/* Method 1:  CTE with duplication of calculation. */
WITH orders AS
(
	SELECT
		DATEADD(MM, DATEDIFF(MM, 0, soh.OrderDate), 0) as OrderMonth,
		soh.SalesOrderID,
		SUM(sod.UnitPrice * sod.OrderQty * sod.UnitPriceDiscount) as TotalDiscount
	FROM
		Sales.SalesOrderHeader soh
		INNER JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
	WHERE
		sod.UnitPriceDiscount > 0
		AND soh.OrderDate > '2006-01-01'
	GROUP BY
		DATEADD(MM, DATEDIFF(MM, 0, soh.OrderDate), 0),
		soh.SalesOrderID
)
SELECT
	OrderMonth,
	COUNT(*) as NumberOfOrders,
	SUM(TotalDiscount) as TotalDiscount
FROM
	orders
GROUP BY
	OrderMonth
ORDER BY
	OrderMonth;


/* Method 2:  CROSS APPLY, with a single query and no definition duplication. */
SELECT
	mon.OrderMonth,
	COUNT(det.TotalDiscount) as NumberOfOrders,
	SUM(det.TotalDiscount) as TotalDiscount
FROM
	Sales.SalesOrderHeader soh
	CROSS APPLY
	(
		SELECT DATEADD(MM, DATEDIFF(MM, 0, soh.OrderDate), 0) as OrderMonth
	) mon
	CROSS APPLY
	(
		SELECT
			SUM(sod.UnitPrice * sod.OrderQty * sod.UnitPriceDiscount) as TotalDiscount
		FROM
			Sales.SalesOrderDetail sod 
		WHERE
			sod.SalesOrderID = soh.SalesOrderID
			AND sod.UnitPriceDiscount > 0
	) det
WHERE
	soh.OrderDate > '2006-01-01'
	AND det.TotalDiscount IS NOT NULL
GROUP BY
	mon.OrderMonth
ORDER BY
	mon.OrderMonth;