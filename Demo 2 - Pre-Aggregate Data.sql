/* Example 2:  pre-aggregate data */
/* What we want:  find the number of times somebody ordered a water bottle. */
/*
http://www.jasonstrate.com/2011/04/t-sql-tuesday-17-apply-knowledge/
http://www.jasonstrate.com/2011/03/aggregating-with-correlated-sub-queries-tsql2sday/
*/

/* Check relative performance of each.  Be sure to turn on execution plans (Ctrl+M). */
SET STATISTICS IO ON
SET STATISTICS TIME ON
GO

SELECT 
	ps.Name,
	p.ProductID,
	p.Name,
	COUNT(*) 
FROM 
	Production.ProductCategory pc 
	INNER JOIN Production.ProductSubcategory ps 
		ON pc.ProductCategoryID = ps.ProductCategoryID 
	INNER JOIN Production.Product p 
		ON ps.ProductSubcategoryID = p.ProductSubcategoryID 
	LEFT OUTER JOIN Sales.SalesOrderDetailEnlarged sad 
		ON p.ProductID = sad.ProductID 
WHERE 
	p.Name='Water Bottle - 30 oz.' 
GROUP BY 
	ps.Name,
	p.ProductID,
	p.Name 
ORDER BY 
	p.Name;

SELECT 
	ps.Name,
	p.ProductID,
	p.Name,
	x.DetailCount
FROM 
	Production.ProductCategory pc
	INNER JOIN Production.ProductSubcategory ps 
		ON pc.ProductCategoryID = ps.ProductCategoryID
	INNER JOIN Production.Product p 
		ON ps.ProductSubcategoryID = p.ProductSubcategoryID
	CROSS APPLY 
	(
		SELECT 
			COUNT(*) AS DetailCount
		FROM 
			Sales.SalesOrderDetailEnlarged sad
		WHERE 
			p.ProductID = sad.ProductID
	) x
WHERE 
	p.Name = 'Water Bottle - 30 oz.'
ORDER BY 
	p.Name;