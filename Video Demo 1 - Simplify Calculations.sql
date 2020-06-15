-- Create the fact table
CREATE TABLE #Fact
(
    ReportDate INT NOT NULL,
    UseSource1 BIT NOT NULL,
    ClickSource1 INT NULL,
    ClickSource2 INT NULL,
    CostSource1 DECIMAL(23, 4) NULL,
    CostSource2 DECIMAL(23, 4) NULL,
    OrderCount INT NULL,
    OrderRevenue DECIMAL(23, 4) NULL,
    ProductCost DECIMAL(23, 4) NULL
);
 
-- Load some sample data
INSERT INTO dbo.#Fact
(
    ReportDate,
    UseSource1,
    ClickSource1,
    ClickSource2,
    CostSource1,
    CostSource2,
    OrderCount,
    OrderRevenue,
    ProductCost
)
VALUES
(20150101, 1, 25, NULL, 285.86, NULL, 18, 1349.56, 187.39),
(20150102, 0, 25, 6, 285.86, 8.36, 3, 98.72, 75.14),
(20150103, 1, 16, NULL, 28.38, NULL, 1, 9.99, 5.42),
(20150104, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(20150105, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(20150106, 1, 108, NULL, 39.80, NULL, 12, 2475.02, 918.60),
(20150107, 0, NULL, 85, NULL, 85.00, 67, 428.77, 206.13);

-- Query the fact table
-- Nested functions and calculations can be hard to read, right?
SELECT
    SUM(CASE WHEN f.UseSource1 = 1 THEN ISNULL(f.ClickSource1, 0) ELSE ISNULL(f.ClickSource2, 0) END) AS Clicks,
    SUM(ISNULL(f.OrderCount, 0)) AS OrderCount,
    SUM(ISNULL(f.OrderRevenue, 0)) AS OrderRevenue,
    SUM(ISNULL(f.ProductCost, 0)) AS ProductCost,
    SUM(CASE WHEN f.UseSource1 = 1 THEN ISNULL(f.CostSource1, 0) ELSE ISNULL(f.CostSource2, 0) END) AS Cost,
    CAST
    (
        CASE
            WHEN SUM(CASE WHEN f.UseSource1 = 1 THEN ISNULL(f.ClickSource1, 0) ELSE ISNULL(f.ClickSource2, 0) END) = 0 THEN 0.0
            WHEN SUM(ISNULL(f.OrderCount, 0)) = 0 THEN 0.0
            WHEN SUM(ISNULL(f.OrderCount, 0)) > SUM(CASE WHEN f.UseSource1 = 1 THEN ISNULL(f.ClickSource1, 0) ELSE ISNULL(f.ClickSource2, 0) END) THEN 1.0
            ELSE 1.0 * SUM(ISNULL(f.OrderCount, 0)) / SUM(CASE WHEN f.UseSource1 = 1 THEN ISNULL(f.ClickSource1, 0) ELSE ISNULL(f.ClickSource2, 0) END)
        END AS DECIMAL(19, 4)
    ) AS ConversionRate,
    SUM(ISNULL(f.OrderRevenue, 0) - (ISNULL(f.ProductCost, 0) + CASE WHEN f.UseSource1 = 1 THEN ISNULL(f.CostSource1, 0) ELSE ISNULL(f.CostSource2, 0) END)) AS NetMargin,
    CASE
        WHEN SUM(CASE WHEN f.UseSource1 = 1 THEN ISNULL(f.CostSource1, 0) ELSE ISNULL(f.CostSource2, 0) END) = 0 THEN
            CASE
                WHEN SUM(ISNULL(f.OrderRevenue, 0)) = 0 THEN 0.0
                ELSE 1.0
            END
        ELSE SUM(ISNULL(f.OrderRevenue, 0)) / SUM(CASE WHEN f.UseSource1 = 1 THEN ISNULL(f.CostSource1, 0) ELSE ISNULL(f.CostSource2, 0) END)
    END AS ReturnOnAdSpend
FROM dbo.#Fact f
WHERE
    f.ReportDate BETWEEN 20150101 AND 20150107;

-- Key problems:
-- 1)  ISNULL() after ISNULL() after ISNULL()
-- 2)  Duplicated blocks of logic, e.g., CASE WHEN f.UseSource1 = 1 THEN ... ELSE ... END
-- 3)  Lots of functions obscure what we're actually doing.






-- Step 1:  Use APPLY to shunt off ISNULLs.
SELECT
    ISNULL(f.ClickSource1, 0) AS ClickSource1,
    ISNULL(f.ClickSource2, 0) AS ClickSource2,
    ISNULL(f.CostSource1, 0) AS CostSource1,
    ISNULL(f.CostSource2, 0) AS CostSource2,
    ISNULL(f.OrderCount, 0) AS OrderCount,
    ISNULL(f.OrderRevenue, 0) AS OrderRevenue,
    ISNULL(f.ProductCost, 0) AS ProductCost
FROM dbo.#Fact f
WHERE
    f.ReportDate BETWEEN 20150101 AND 20150107;

-- Now let's move this to an APPLY block.
SELECT
    nonull.ClickSource1,
    nonull.ClickSource2,
    nonull.CostSource1,
    nonull.CostSource2,
    nonull.OrderCount,
    nonull.OrderRevenue,
    nonull.ProductCost
FROM dbo.#Fact f
    CROSS APPLY
    (
        SELECT
            ISNULL(f.ClickSource1, 0) AS ClickSource1,
            ISNULL(f.ClickSource2, 0) AS ClickSource2,
            ISNULL(f.CostSource1, 0) AS CostSource1,
            ISNULL(f.CostSource2, 0) AS CostSource2,
            ISNULL(f.OrderCount, 0) AS OrderCount,
            ISNULL(f.OrderRevenue, 0) AS OrderRevenue,
            ISNULL(f.ProductCost, 0) AS ProductCost
    ) nonull
WHERE
    f.ReportDate BETWEEN 20150101 AND 20150107;




-- Step 2:  Use APPLY to handle case logic.
SELECT
    CASE WHEN f.UseSource1 = 1 THEN ISNULL(f.ClickSource1, 0) ELSE ISNULL(f.ClickSource2, 0) END AS Clicks,
    CASE WHEN f.UseSource1 = 1 THEN ISNULL(f.CostSource1, 0) ELSE ISNULL(f.CostSource2, 0) END AS Cost
FROM dbo.#Fact f
WHERE
    f.ReportDate BETWEEN 20150101 AND 20150107;

-- Now let's *chain* APPLY blocks.
SELECT
    us1.Clicks,
    us1.Cost
FROM dbo.#Fact f
    CROSS APPLY
    (
        SELECT
            ISNULL(f.ClickSource1, 0) AS ClickSource1,
            ISNULL(f.ClickSource2, 0) AS ClickSource2,
            ISNULL(f.CostSource1, 0) AS CostSource1,
            ISNULL(f.CostSource2, 0) AS CostSource2,
            ISNULL(f.OrderCount, 0) AS OrderCount,
            ISNULL(f.OrderRevenue, 0) AS OrderRevenue,
            ISNULL(f.ProductCost, 0) AS ProductCost
    ) nonull
    CROSS APPLY
    (
        SELECT
            CASE WHEN f.UseSource1 = 1 THEN nonull.ClickSource1 ELSE nonull.ClickSource2 END AS Clicks,
            CASE WHEN f.UseSource1 = 1 THEN nonull.CostSource1 ELSE nonull.CostSource2 END AS Cost
    ) us1
WHERE
    f.ReportDate BETWEEN 20150101 AND 20150107;


-- The final product.
SELECT
    SUM(us1.Clicks) AS Clicks,
    SUM(nonull.OrderCount) AS OrderCount,
    SUM(nonull.OrderRevenue) AS OrderRevenue,
    SUM(nonull.ProductCost) AS ProductCost,
    SUM(us1.Cost) AS Cost,
    CAST
    (
        CASE
            WHEN SUM(us1.Clicks) = 0 THEN 0.0
            WHEN SUM(nonull.OrderCount) = 0 THEN 0.0
            WHEN SUM(nonull.OrderCount) > SUM(us1.Clicks) THEN 1.0
            ELSE 1.0 * SUM(nonull.OrderCount) / SUM(us1.Clicks)
        END AS DECIMAL(19, 4)
    ) AS ConversionRate,
    SUM(nonull.OrderRevenue - (nonull.ProductCost + us1.Cost)) AS NetMargin,
    CASE
        WHEN SUM(us1.Cost) = 0 THEN
            CASE
                WHEN SUM(nonull.OrderRevenue) = 0 THEN 0.0
                ELSE 1.0
            END
        ELSE SUM(nonull.OrderRevenue) / SUM(us1.Cost)
    END AS ReturnOnAdSpend
FROM dbo.#Fact f
    CROSS APPLY
    (
        SELECT
            ISNULL(ClickSource1, 0) AS ClickSource1,
            ISNULL(ClickSource2, 0) AS ClickSource2,
            ISNULL(CostSource1, 0) AS CostSource1,
            ISNULL(CostSource2, 0) AS CostSource2,
            ISNULL(OrderCount, 0) AS OrderCount,
            ISNULL(OrderRevenue, 0) AS OrderRevenue,
            ISNULL(ProductCost, 0) AS ProductCost
    ) nonull
    OUTER APPLY
    (
        SELECT
            CASE WHEN f.UseSource1 = 1 THEN nonull.ClickSource1 ELSE nonull.ClickSource2 END AS Clicks,
            CASE WHEN f.UseSource1 = 1 THEN nonull.CostSource1 ELSE nonull.CostSource2 END AS Cost
    ) us1
WHERE
    f.ReportDate BETWEEN 20150101 AND 20150107;

-- For reference, here is the original form of that query once more:
SELECT
    SUM(CASE WHEN f.UseSource1 = 1 THEN ISNULL(f.ClickSource1, 0) ELSE ISNULL(f.ClickSource2, 0) END) AS Clicks,
    SUM(ISNULL(f.OrderCount, 0)) AS OrderCount,
    SUM(ISNULL(f.OrderRevenue, 0)) AS OrderRevenue,
    SUM(ISNULL(f.ProductCost, 0)) AS ProductCost,
    SUM(CASE WHEN f.UseSource1 = 1 THEN ISNULL(f.CostSource1, 0) ELSE ISNULL(f.CostSource2, 0) END) AS Cost,
    CAST
    (
        CASE
            WHEN SUM(CASE WHEN f.UseSource1 = 1 THEN ISNULL(f.ClickSource1, 0) ELSE ISNULL(f.ClickSource2, 0) END) = 0 THEN 0.0
            WHEN SUM(ISNULL(f.OrderCount, 0)) = 0 THEN 0.0
            WHEN SUM(ISNULL(f.OrderCount, 0)) > SUM(CASE WHEN f.UseSource1 = 1 THEN ISNULL(f.ClickSource1, 0) ELSE ISNULL(f.ClickSource2, 0) END) THEN 1.0
            ELSE 1.0 * SUM(ISNULL(f.OrderCount, 0)) / SUM(CASE WHEN f.UseSource1 = 1 THEN ISNULL(f.ClickSource1, 0) ELSE ISNULL(f.ClickSource2, 0) END)
        END AS DECIMAL(19, 4)
    ) AS ConversionRate,
    SUM(ISNULL(f.OrderRevenue, 0) - (ISNULL(f.ProductCost, 0) + CASE WHEN f.UseSource1 = 1 THEN ISNULL(f.CostSource1, 0) ELSE ISNULL(f.CostSource2, 0) END)) AS NetMargin,
    CASE
        WHEN SUM(CASE WHEN f.UseSource1 = 1 THEN ISNULL(f.CostSource1, 0) ELSE ISNULL(f.CostSource2, 0) END) = 0 THEN
            CASE
                WHEN SUM(ISNULL(f.OrderRevenue, 0)) = 0 THEN 0.0
                ELSE 1.0
            END
        ELSE SUM(ISNULL(f.OrderRevenue, 0)) / SUM(CASE WHEN f.UseSource1 = 1 THEN ISNULL(f.CostSource1, 0) ELSE ISNULL(f.CostSource2, 0) END)
    END AS ReturnOnAdSpend
FROM dbo.#Fact f
WHERE
    f.ReportDate BETWEEN 20150101 AND 20150107;