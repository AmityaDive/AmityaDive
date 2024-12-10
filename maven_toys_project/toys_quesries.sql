SELECT * FROM inventory
SELECT * FROM products
SELECT * FROM sales
SELECT * FROM stores

-- join of products and sales tables

SELECT p.product_id, p.product_name, p.product_category, 
		sa.sale_id, sa.date, sa.units, p.Product_Cost, p.Product_Price
		--SUM((p.product_price - p.product_cost) * sa.units) AS 'profit' --profitability calculation
FROM products AS p JOIN sales AS sa
ON p.product_id = sa.product_id
ORDER BY product_name

-- (1) total revenue per category

SELECT p.product_category, 
	   SUM(p.product_price - p.product_cost) AS 'total_revenue'
FROM products AS p JOIN sales AS sa
ON p.product_id = sa.product_id
GROUP BY p.product_category
ORDER BY total_revenue DESC


-- (2) avg profit & stdev calculation for each category

WITH categorystats AS (
    SELECT 
        product_category,
        AVG(p.product_price - p.product_cost) AS 'average_profit_per_unit',
        STDEV(p.product_price - p.product_cost) AS 'std_dev_profit_per_unit',
        SUM(sa.units) AS total_units_sold,
		SUM((p.product_price - p.product_cost) * sa.units) AS 'total_revenue'
    FROM 
        products AS p
    JOIN 
        sales AS sa
    ON 
        p.product_id = sa.product_id
    GROUP BY 
        p.product_category
),
medianstats AS (
    SELECT DISTINCT
        product_category,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY p.product_price - p.product_cost)
           OVER (PARTITION BY p.product_category) AS 'median_profit_per_unit'
    FROM 
        products AS p
    JOIN 
        sales AS sa
    ON 
        p.product_id = sa.product_id
)
SELECT
    cs.product_category,
    cs.average_profit_per_unit,
    cs.std_dev_profit_per_unit,
	ms.median_profit_per_unit,
	cs.std_dev_profit_per_unit / cs.average_profit_per_unit AS 'CV(%)',
    cs.total_units_sold,
	total_revenue
FROM 
    categorystats AS cs
JOIN 
    medianstats AS ms
ON 
    cs.product_category = ms.product_category
ORDER BY 
    cs.average_profit_per_unit DESC



-- join of products and sales tables by Q

SELECT 
    p.product_id, 
    p.product_name, 
    p.product_category, 
    CONCAT(YEAR(sa.date), ' Q', DATEPART(QUARTER, sa.date)) AS quarter, -- Adding quarter grouping
    SUM(sa.units) AS total_units_sold, -- Summing units sold per quarter
    AVG(p.Product_Cost) AS avg_cost, -- Average cost per product per quarter
    AVG(p.Product_Price) AS avg_price, -- Average price per product per quarter
    SUM((p.product_price - p.product_cost) * sa.units) AS profit -- Profit calculation
FROM 
    products AS p 
JOIN 
    sales AS sa
ON 
    p.product_id = sa.product_id
GROUP BY 
    p.product_id, 
    p.product_name, 
    p.product_category, 
    YEAR(sa.date), 
    DATEPART(QUARTER, sa.date) -- Grouping by year and quarter
ORDER BY 
    p.product_name, 
    YEAR(sa.date), 
    DATEPART(QUARTER, sa.date);



-- (3) categories' revenue in Q timeline (pivot table)

WITH base_cte AS (
SELECT  p.product_category,
		YEAR(sa.date) AS 'year',  
		DATEPART(QUARTER, sa.date) AS 'quarter',
		SUM((p.product_price - p.product_cost) * sa.units) AS 'category_profit'
FROM products AS p JOIN sales AS sa
ON p.product_id = sa.product_id
--WHERE product_category = 'electronics'
GROUP BY YEAR(sa.date), DATEPART(QUARTER, sa.date), product_category
)
SELECT product_category,
		[2017 Q1], [2017 Q2], [2017 Q3], [2017 Q4],
		[2018 Q1], [2018 Q2], [2018 Q3]           -- creating year & quarter columns in order to build a pivot table
FROM (
	SELECT 
		CONCAT(year, ' Q', quarter) AS year_quarter, 
		product_category, 
		category_profit
	FROM base_cte
	) AS TBL
PIVOT (SUM(category_profit) FOR 
		year_quarter IN ([2017 Q1], [2017 Q2], [2017 Q3], [2017 Q4],
						[2018 Q1], [2018 Q2], [2018 Q3])
	) AS PVT
ORDER BY product_category


-- (4) Electronics category analysis
-- number of units sold in 2017 vs. 2018 (pivot table)

WITH base_cte AS (
SELECT  p.product_name, 
		YEAR(sa.date) AS 'year', 
		DATEPART(QUARTER, sa.date) AS 'quarter',
		SUM(sa.units) AS 'units_sold'
FROM products AS p JOIN sales AS sa
ON p.product_id = sa.product_id
WHERE product_category = 'electronics'
GROUP BY YEAR(sa.date), DATEPART(QUARTER, sa.date), p.product_name
)
SELECT product_name,
		[2017 Q1], [2017 Q2], [2017 Q3],
		[2018 Q1], [2018 Q2], [2018 Q3]
FROM (
	SELECT 
		CONCAT(year, ' Q', quarter) AS year_quarter, 
		product_name, 
		units_sold
	FROM base_cte
	) AS TBL
PIVOT (SUM(units_sold) FOR 
		year_quarter IN ([2017 Q1], [2017 Q2], [2017 Q3],
						[2018 Q1], [2018 Q2], [2018 Q3])
	) AS PVT
ORDER BY product_name


-- products' clean profit a specific category

SELECT product_name,
	   product_price AS 'price',
	   product_cost AS 'cost',
	   (product_price - product_cost) AS 'product_profit'
FROM products
WHERE product_category = 'electronics'



-- Total units sold in each Q (for Normalization & Pearson correlation teasts in Python)

SELECT 
    CONCAT(YEAR(sa.date), ' Q', DATEPART(QUARTER, sa.date)) AS 'quarter', -- create a column for the quarter
    SUM(CASE WHEN p.product_name = 'Colorbuds' THEN sa.units ELSE 0 END) AS 'colorbuds_sales', -- sum of units sold for Colorbuds
    SUM(CASE WHEN p.product_name = 'Gamer Headphones' THEN sa.units ELSE 0 END) AS 'gamer_headphones_sales' -- sum of units sold for Gamer Headphones
FROM 
    products AS p
JOIN 
    sales AS sa
ON 
    p.product_id = sa.product_id
WHERE 
    p.product_name IN ('Colorbuds', 'Gamer Headphones') -- filter for the relevant products
GROUP BY 
    YEAR(sa.date), 
    DATEPART(QUARTER, sa.date) -- group by year and quarter
ORDER BY 
    YEAR(sa.date), 
    DATEPART(QUARTER, sa.date);
