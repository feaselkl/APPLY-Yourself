-- A brief foray into APPLY.
-- Point one:  has existed in SQL Server since 2005.

-- Point two:  APPLY runs once per row and applies a function.
SELECT
    *
FROM (VALUES (1), (2), (3)) AS tbl(col)
    CROSS APPLY (SELECT col * 3 AS colx3) mult;

-- Point three:  there are two variants of APPLY:  CROSS and OUTER.
-- CROSS APPLY filters out cases when the function does not produce a value.
SELECT
    *
FROM (VALUES (1), (2), (3)) AS tbl(col)
    CROSS APPLY (SELECT col * 3 AS colx3 WHERE col > 1) mult;

-- OUTER APPLY does not filter out these cases.
SELECT
    *
FROM (VALUES (1), (2), (3)) AS tbl(col)
    OUTER APPLY (SELECT col * 3 AS colx3 WHERE col > 1) mult;

-- Point four:  function application *typically* uses a nested loop join.
-- Run this with actual execution plans enabled.
SELECT
    *
FROM (VALUES (1), (2), (3)) AS tbl(col)
    OUTER APPLY (SELECT col * 3 AS colx3 WHERE col > 1) mult;

-- Compare to an alternative way of writing this:
SELECT
    tbl.col,
	CASE
		WHEN tbl.col > 1 THEN tbl.col * 3
		ELSE NULL
	END AS colx3
FROM (VALUES (1), (2), (3)) AS tbl(col);

-- But APPLY doesn't always mean a nested loop join!
SELECT
    *
FROM (VALUES (1), (2), (3)) AS tbl(col)
    CROSS APPLY (SELECT col * 3 AS colx3) mult;

-- Point five:  simply rewriting a calculation with APPLY
-- *usually* will not change performance.
SELECT
    *
FROM (VALUES (1), (2), (3)) AS tbl(col)
    CROSS APPLY (SELECT col * 3 AS colx3) mult;

SELECT
    tbl.col,
	tbl.col * 3 AS colx3
FROM (VALUES (1), (2), (3)) AS tbl(col);