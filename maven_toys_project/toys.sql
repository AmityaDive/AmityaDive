SELECT * FROM inventory
SELECT * FROM products
SELECT * FROM sales
SELECT * FROM stores

-- join of products and sales tables

SELECT p.product_id, p.product_name, p.product_category, 
		sa.sale_id, sa.date, sa.units,
		SUM((p.product_price - p.product_cost) * sa.units) AS 'profit' --profitability calculation
FROM products AS p JOIN sales AS sa
ON p.product_id = sa.product_id
GROUP BY p.product_category,
		 p.product_id, 
		 p.product_name, 
		 sa.sale_id, 
		 sa.date, 
	  	 sa.units
 
-- categories' profitability
-- toys & electronics with highets profitability

WITH base_cte AS (
SELECT   p.product_category, 
		(p.product_price - p.product_cost) * sa.units AS 'profit'
FROM products AS p JOIN sales AS sa
ON p.product_id = sa.product_id
)
SELECT product_category, SUM(profit) AS 'category_profit'
FROM base_cte
GROUP BY product_category
ORDER BY category_profit DESC

-- categories' profitability 2017 vs. 2018 (pivot table)

WITH base_cte AS (
SELECT  YEAR(sa.date) AS 'year', p.product_category, 
		DATEPART(QUARTER, sa.date) AS 'quarter',
		(p.product_price - p.product_cost) * sa.units AS 'profit'
FROM products AS p JOIN sales AS sa
ON p.product_id = sa.product_id
), base_cte2 AS (
SELECT year, quarter, product_category, SUM(profit) AS 'category_profit'
FROM base_cte
GROUP BY year, quarter, product_category
)
SELECT product_category,
		[2017 Q1], [2017 Q2], [2017 Q3], [2017 Q4],
		[2018 Q1], [2018 Q2], [2018 Q3]           -- creating year & quarter columns in order to build a pivot table
FROM (
	SELECT 
		CONCAT(year, ' Q', quarter) AS year_quarter, 
		product_category, 
		category_profit
	FROM base_cte2
	) AS TBL
PIVOT (SUM(category_profit) FOR 
		year_quarter IN ([2017 Q1], [2017 Q2], [2017 Q3], [2017 Q4],
						[2018 Q1], [2018 Q2], [2018 Q3])
	) AS PVT
ORDER BY product_category

-- number of units sold in 2017 vs. 2018 (pivot table)

WITH base_cte AS (
SELECT  YEAR(sa.date) AS 'year', 
		DATEPART(QUARTER, sa.date) AS 'quarter',
		p.product_category, 
		sa.units
FROM products AS p JOIN sales AS sa
ON p.product_id = sa.product_id
), base_cte2 AS (
SELECT year, quarter, product_category, SUM(units) AS 'units_sold'
FROM base_cte
GROUP BY year, quarter, product_category
)
SELECT product_category,
		[2017 Q1], [2017 Q2], [2017 Q3],
		[2018 Q1], [2018 Q2], [2018 Q3]
FROM (
	SELECT 
		CONCAT(year, ' Q', quarter) AS year_quarter, 
		product_category, 
		units_sold
	FROM base_cte2
	) AS TBL
PIVOT (SUM(units_sold) FOR 
		year_quarter IN ([2017 Q1], [2017 Q2], [2017 Q3],
						[2018 Q1], [2018 Q2], [2018 Q3])
	) AS PVT
ORDER BY product_category

-- products' clean profit a specific category

SELECT DISTINCT p.product_category, 
				p.product_name,
				(p.product_price - p.product_cost) AS 'profit'
FROM products AS p JOIN sales AS sa
ON p.product_id = sa.product_id
WHERE p.product_category = 'electronics'
ORDER BY profit

-- products' profit of a specific category (as PIVOT)

WITH base_cte AS (
SELECT  YEAR(sa.date) AS 'year', 
		DATEPART(QUARTER, sa.date) AS 'quarter',
		p.product_category, 
		p.product_name,
		(p.product_price - p.product_cost) * sa.units AS 'pre_profit'
FROM products AS p JOIN sales AS sa
ON p.product_id = sa.product_id
), base_cte2 AS (
SELECT year, quarter, product_name, 
		SUM(pre_profit) AS 'product_profit'
FROM base_cte
WHERE product_category = 'electronics'
GROUP BY year, quarter, product_category, product_name
)
SELECT product_name,
		[2017 Q1], [2017 Q2], [2017 Q3], [2017 Q4],
		[2018 Q1], [2018 Q2], [2018 Q3]
FROM (
	SELECT 
		CONCAT(year, ' Q', quarter) AS year_quarter, 
		product_name, 
		product_profit
	FROM base_cte2
	) AS TBL
PIVOT (SUM(product_profit) FOR 
		year_quarter IN ([2017 Q1], [2017 Q2], [2017 Q3], [2017 Q4],
						[2018 Q1], [2018 Q2], [2018 Q3])
	) AS PVT
ORDER BY product_name


-- number of units sold of a specific category (pivot table)

WITH base_cte AS (
SELECT  YEAR(sa.date) AS 'year', 
		DATEPART(QUARTER, sa.date) AS 'quarter',
		p.product_category, 
		p.product_name,
		sa.units
FROM products AS p JOIN sales AS sa
ON p.product_id = sa.product_id
), base_cte2 AS (
SELECT year, quarter, product_name, 
		SUM(units) AS 'units_sold'
FROM base_cte
WHERE product_category = 'electronics'
GROUP BY year, quarter, product_category, product_name
)
SELECT product_name,
		[2017 Q1], [2017 Q2], [2017 Q3],
		[2018 Q1], [2018 Q2], [2018 Q3]
FROM (
	SELECT 
		CONCAT(year, ' Q', quarter) AS year_quarter, 
		product_name, 
		units_sold
	FROM base_cte2
	) AS TBL
PIVOT (SUM(units_sold) FOR 
		year_quarter IN ([2017 Q1], [2017 Q2], [2017 Q3],
						[2018 Q1], [2018 Q2], [2018 Q3])
	) AS PVT
ORDER BY product_name


-- Number of units sold for Action Figure and Dino Egg, and % out of total toys' products sold in each year
WITH base_cte AS (
    SELECT  
        YEAR(sa.date) AS 'year', 
        DATEPART(QUARTER, sa.date) AS 'quarter',
        p.product_category,
        p.product_name,
        sa.units
    FROM products AS p 
    JOIN sales AS sa ON p.product_id = sa.product_id
    WHERE DATEPART(QUARTER, sa.date) != 4
    AND p.product_category = 'toys' -- choose a category
),
yearly_totals AS (
    SELECT 
        year,
        SUM(units) AS total_units_sold_per_year
    FROM base_cte
    GROUP BY year
)
SELECT 
    b.product_name, 
    b.year,
    SUM(b.units) AS 'units_sold', 
    ROUND((SUM(b.units) * 100.0 / y.total_units_sold_per_year), 0) AS '%_of_total_toys',
	y.total_units_sold_per_year
FROM base_cte b
JOIN yearly_totals y ON b.year = y.year
WHERE b.product_category = 'toys' -- choose a category
AND b.product_name IN ('Dino Egg', 'Action Figure') -- choose products
GROUP BY b.year, b.product_name, y.total_units_sold_per_year
ORDER BY b.product_name, b.year


-- Average profit per unit in each year

WITH base_cte AS (
    SELECT  
        YEAR(sa.date) AS 'year', 
        DATEPART(QUARTER, sa.date) AS 'quarter',
        sa.units,
		(p.product_price - p.product_cost) * sa.units AS 'profit'
    FROM products AS p 
    JOIN sales AS sa ON p.product_id = sa.product_id
    WHERE DATEPART(QUARTER, sa.date) != 4
    AND p.product_category = 'toys' -- choose a category
)
SELECT 
    year, 
	(SUM(profit) / SUM(units)) AS 'avg_profit_per_unit'
FROM base_cte
GROUP BY year



-- Dino Egg & Action Figure sales trend over 2017 - 2018

SELECT YEAR(sa.date) AS 'year', 
		DATEPART(QUARTER, sa.date) AS 'quarter',
		p.product_name,
		SUM(sa.units) AS 'units_sold'
FROM products AS p JOIN sales AS sa
ON p.product_id = sa.product_id
WHERE p.product_category = 'toys'
AND p.product_name IN ('Dino Egg', 'Action Figure')
AND DATEPART(QUARTER, sa.date) IN (1, 2, 3)
GROUP BY YEAR(sa.date), DATEPART(QUARTER, sa.date), p.product_name
--ORDER BY p.product_name, YEAR(sa.date), DATEPART(QUARTER, sa.date)

-- producr price & profit of electronics products

SELECT product_name,
	   product_price AS 'Price',
	   product_cost AS 'Cost',
	   (product_price - product_cost) AS 'product_profit'
FROM products
WHERE product_category = 'electronics'

-- checking for stocks of colotbuds & gamer heaphones over time in different stores in downtown (electronics category)

WITH base_cte AS (
SELECT st.store_name, 
		YEAR(sa.date) AS 'year', 
		DATEPART(QUARTER, sa.date) AS 'quarter',
		SUM(i.stock_on) AS 'stock'   
		--(p.product_price - p.product_cost) * sa.units AS 'profit'
FROM products p JOIN sales sa
ON p.product_id = sa.product_id

JOIN inventory i 
ON i.store_id = sa.store_id

JOIN stores st
ON st.store_id = sa.store_id

WHERE p.product_category = 'electronics'
AND p.product_name = 'Colorbuds'
AND st.store_location = 'downtown'

GROUP BY st.store_name, YEAR(sa.date), DATEPART(QUARTER, sa.date), p.product_price, p.product_cost, sa.units
)
SELECT store_name,
		[2017 Q1], [2017 Q2], [2017 Q3], [2017 Q4],
		[2018 Q1], [2018 Q2], [2018 Q3]
FROM (
	SELECT 
		CONCAT(year, ' Q', quarter) AS year_quarter, 
		store_name, 
		stock
	FROM base_cte
	) AS TBL
PIVOT (SUM(stock) FOR 
		year_quarter IN ([2017 Q1], [2017 Q2], [2017 Q3], [2017 Q4],
						[2018 Q1], [2018 Q2], [2018 Q3])
	) AS PVT
ORDER BY store_name

