<style>
.reveal section img { background:none; border:none; box-shadow:none; }
</style>

## APPLY Yourself
### Using SQL Server's APPLY Operator

<a href="https://www.catallaxyservices.com">Kevin Feasel</a> (<a href="https://twitter.com/feaselkl">@feaselkl</a>)
<a href="https://csmore.info/on/apply">https://CSmore.info/on/apply</a>

---

@title[Who Am I?]

@snap[west splitscreen]
<table>
	<tr>
		<td><a href="https://csmore.info"><img src="https://www.catallaxyservices.com/media/Logo.png" height="133" width="119" /></a></td>
		<td><a href="https://csmore.info">Catallaxy Services</a></td>
	</tr>
	<tr>
		<td><a href="https://curatedsql.com"><img src="https://www.catallaxyservices.com/media/CuratedSQLLogo.png" height="133" width="119" /></a></td>
		<td><a href="https://curatedsql.com">Curated SQL</a></td>
	</tr>
	<tr>
		<td><a href="https://wespeaklinux.com"><img src="https://www.catallaxyservices.com/media/WeSpeakLinux.jpg" height="133" width="119" /></a></td>
		<td><a href="https://wespeaklinux.com">We Speak Linux</a></td>
	</tr>
</table>
@snapend

@snap[east splitscreen]
<div>
	<a href="https://www.twitter.com/feaselkl"><img src="https://www.catallaxyservices.com/media/HeadShot.jpg" height="358" width="315" /></a>
	<br />
	<a href="https://www.twitter.com/feaselkl">@feaselkl</a>
</div>
@snapend

---

### The APPLY Operator

At its simplest, `APPLY` is similar to `JOIN` but allows for a dependency between the data sets being merged together.

Microsoft introduced the `APPLY` operator in SQL Server 2005, with two variants:  `CROSS APPLY` and `OUTER APPLY`.  `CROSS APPLY` is semantically similar to `INNER JOIN`, whereas `OUTER APPLY` is akin to `OUTER JOIN`.

---?image=presentation/assets/background/2_2_motivation.jpg&size=cover&opacity=20

### Motivation

<blockquote cite="https://twitter.com/AdamMachanic/status/46265020090294272#">
	&ldquo;If you don't understand the APPLY operator, your skills are somewhere around the 50th percentile at best.&rdquo; -- Adam Machanic
</blockquote>

`APPLY` is not always the best solution, but solves a number of problems in an elegant manner.

---

@title[Joining to Functions]

## Agenda

1. **Join to Functions**
2. Pre-Aggregate Data
3. Get a Specific Child Record
4. Get the top N for Each X
5. Simplify Calculations

---

### Getting Session Info

We can use `sys.dm_exec_connections` to get basic information for each session, but this doesn't give us query text.  There is a table-valued function named `sys.dm_exec_sql_text([handle] varbinary)` but we need to pass in the handle for each row in our connections DMV.

---

### Getting Session Info

Unfortunately, you cannot use `INNER JOIN` to join to a function which expects a parameter.

![You cannot use INNER JOIN to join to a function which expects a parameter.](presentation/assets/image/InnerJoinError.png)

---

### The Solution

```sql
SELECT
	c.session_id,
	c.connect_time,
	c.num_reads,
	c.num_writes,
	T.text
FROM
	sys.dm_exec_connections c
	CROSS APPLY sys.dm_exec_sql_text(c.most_recent_sql_handle) t;
```
@[8-9](CROSS APPLY accepts a parameter from a "higher" table and returns a result set.)
@[1-6](You can reference columns just like any other result set.)

---?image=presentation/assets/background/demo.jpg&size=cover&opacity=20

### Demo Time

---

### Lessons Learned

* Use `APPLY` to execute table-valued functions as though they were tables.
* `OUTER APPLY` can show rows that `CROSS APPLY` would filter out.

---

@title[Pre-Aggregate Data]

## Agenda

1. Join to Functions
2. **Pre-Aggregate Data**
3. Get a Specific Child Record
4. Get the top N for Each X
5. Simplify Calculations

---

### The Problem Description

We want to figure out how many times somebody has ordered a water bottle from the Adventure Works store.  We'd also like to see which product category and subcategory this belongs to.

---

### The Classical Solution

```sql
SELECT 
	pc.Name AS CategoryName,
	ps.Name AS SubcategoryName,
	p.ProductID,
	p.Name,
	COUNT(*) AS NumberOfPurchases
FROM Production.ProductCategory pc 
	INNER JOIN Production.ProductSubcategory ps
		ON pc.ProductCategoryID = ps.ProductCategoryID 
	INNER JOIN Production.Product p
		ON ps.ProductSubcategoryID = p.ProductSubcategoryID 
	LEFT OUTER JOIN Sales.SalesOrderDetail sad
		ON p.ProductID = sad.ProductID 
WHERE 
	p.Name='Water Bottle - 30 oz.' 
GROUP BY 
	pc.Name,
	ps.Name,
	p.ProductID,
	p.Name 
ORDER BY 
	p.Name;
```
@[7-13](Traverse the hierarchy and then join to SalesOrderDetail.)
@[14-15](Filter to get just our water bottle.)
@[1-6](Select the columns we need.)
@[6](Because we have an aggregate function...)
@[1-5](We need to take these non-aggregated columns...)
@[16-20](And include them in a GROUP BY clause.)

---

### The APPLY Solution

```sql
SELECT
	pc.Name AS CategoryName,
	ps.Name AS SubcategoryName,
	p.ProductID,
	p.Name,
	x.DetailCount
FROM Production.ProductCategory pc
	INNER JOIN Production.ProductSubcategory ps 
		ON pc.ProductCategoryID = ps.ProductCategoryID
	INNER JOIN Production.Product p 
		ON ps.ProductSubcategoryID = p.ProductSubcategoryID
	CROSS APPLY 
	(
		SELECT 
			COUNT(*) AS DetailCount
		FROM Sales.SalesOrderDetailEnlarged sad
		WHERE 
			p.ProductID = sad.ProductID
	) x
WHERE 
	p.Name = 'Water Bottle - 30 oz.'
ORDER BY 
	p.Name;
```
@[7-11](This query starts out the same, traversing the hierarchy. But then it changes.)
@[12-19](CROSS APPLY can execute against ad hoc functions.)
@[14-18](Note that we aggregate inside the function.)
@[18](Inside our function, we can reference "higher" tables.)
@[1-6](We no longer have an aggregation function here, so no GROUP BY.)

---?image=presentation/assets/background/demo.jpg&size=cover&opacity=20

### Demo Time

---

### Lessons Learned

* Use `APPLY` to return data from ad hoc (derived) functions.
* We could also use other techniques to pre-aggregate, such as correlated sub-queries.
* **IN THIS CASE** `APPLY` worked better because early aggregation allowed us to reduce the number of rows going through a nested loop join.

---

@title[Get a Specific Child Record]

## Agenda

1. Join to Functions
2. Pre-Aggregate Data
3. **Get a Specific Child Record**
4. Get the top N for Each X
5. Simplify Calculations

---

### The Problem Description

We want to see each customer's latest order, PO numbers associated with those orders, and the total due on each order.

---

There are three set-based options that we can use to perform this operation:

* Correlated Sub-Query
* Common Table Expression (CTE) with a window function
* Derived function with `APPLY`

There are Row By Agonizing Row (RBAR) solutions available like using a cursor/WHILE loop, but these will not perform well.  We might also put something together with temporary tables which could scale, but start with simple.

---?image=presentation/assets/background/demo.jpg&size=cover&opacity=20

### Demo Time

---

### Lessons Learned

* The correlated subquery tends to be inferior to the CTE and can be worse than `APPLY`.
* The CTE solution is understandable but does not scale well.
* The `APPLY`-based solution is inefficient for small loads but scales extremely well.

With small data sets, pick the one you prefer most, as they all will perform well enough.

---

@title[Get the top N for Each X]

## Agenda

1. Join to Functions
2. Pre-Aggregate Data
3. Get a Specific Child Record
4. **Get the top N for Each X**
5. Simplify Calculations


---

### The Problem Description

This is a generalization of the "specific child record" problem.

We want to see the average, minimum, maximum, and total prices of each customer's last 5 orders.

---

There are still three set-based options that we can use to perform this operation:

* Correlated Sub-Query
* Common Table Expression (CTE) with a window function
* Derived function with `APPLY`

With that said, however, the correlated sub-query quickly becomes nasty to write, and we already know from the prior example that it doesn't scale well.

---?image=presentation/assets/background/demo.jpg&size=cover&opacity=20

### Demo Time

---

### Lessons Learned

Similar to the specific case, the `APPLY` version looks worse early on but scales **much** better.

Use either for small problem sets, but shift to `APPLY` as the sets get larger.

---

### What Makes `APPLY` More Effiient?

TODO:  fill out slides.

---

@title[Simplify Calculations]

## Agenda

1. Join to Functions
2. Pre-Aggregate Data
3. Get a Specific Child Record
4. Get the top N for Each X
5. **Simplify Calculations**

---

### Simplify Calculations

SQL Server calculations tend to be repetitious.  The `APPLY` operator can help us with that by feeding the columns from an earlier table or derived function into a later derived function.  In other words, named columns you create in one `APPLY` statement can be used in the next `APPLY` statement.

---?image=presentation/assets/background/demo.jpg&size=cover&opacity=20

### Demo Time

---

### Lessons Learned

Similar to the specific case, the `APPLY` version looks worse early on but scales **much** better.

Use either for small problem sets, but shift to `APPLY` as the sets get larger.

---

### Wrapping Up

The `APPLY` operator excels at a few activities:
* Pre-aggregating data
* Getting subsets of child records for each parent record
* Simplifying calculations without losing performance
* Splitting strings

This is not a cure-all operator, though.  Be sure to try writing your code a few different ways to see what performs best.

---

### Wrapping Up

To learn more, go here:  <a href="https://csmore.info/on/apply">https://CSmore.info/on/apply</a>

And for help, contact me:  <a href="mailto:feasel@catallaxyservices.com">feasel@catallaxyservices.com</a> | <a href="https://www.twitter.com/feaselkl">@feaselkl</a>
