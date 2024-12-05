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

-- number of units sold in 2017 vs. 2018 (pivot table)

WITH base_cte AS (
SELECT  p.product_category, 
		YEAR(sa.date) AS 'year', 
		DATEPART(QUARTER, sa.date) AS 'quarter',
		SUM(sa.units) AS 'units_sold'
FROM products AS p JOIN sales AS sa
ON p.product_id = sa.product_id
--WHERE product_category = 'electronics'
GROUP BY YEAR(sa.date), DATEPART(QUARTER, sa.date), p.product_category
)
SELECT product_category,
		[2017 Q1], [2017 Q2], [2017 Q3],
		[2018 Q1], [2018 Q2], [2018 Q3]
FROM (
	SELECT 
		CONCAT(year, ' Q', quarter) AS year_quarter, 
		product_category, 
		units_sold
	FROM base_cte
	) AS TBL
PIVOT (SUM(units_sold) FOR 
		year_quarter IN ([2017 Q1], [2017 Q2], [2017 Q3],
						[2018 Q1], [2018 Q2], [2018 Q3])
	) AS PVT
ORDER BY product_category


-- TOYS --
-- products' clean profit a specific category

SELECT product_name,
	   product_price AS 'price',
	   product_cost AS 'cost',
	   (product_price - product_cost) AS 'product_profit'
FROM products
WHERE product_category = 'toys'



-- Number of units sold for Action Figure and Dino Egg, and % out of total toys' products sold in each year

WITH base_cte AS (
    SELECT  
		p.product_name,
        YEAR(sa.date) AS 'year', 
        SUM(sa.units) AS 'units_sold_per_product',
		SUM(SUM(sa.units)) OVER (PARTITION BY YEAR(sa.date)) AS 'total_units_sold_per_year',
		ROUND(SUM(sa.units) * 100.0 / SUM(SUM(sa.units)) OVER (PARTITION BY YEAR(sa.date)), 0) AS '%_of_total_toys'
    FROM products AS p 
    JOIN sales AS sa ON p.product_id = sa.product_id
    WHERE DATEPART(QUARTER, sa.date) != 4
    AND p.product_category = 'toys' -- choose a category
	GROUP BY YEAR(sa.date), p.product_name
)
SELECT *
FROM base_cte
WHERE product_name IN ('Dino Egg', 'Action Figure')
ORDER BY product_name, year;


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


-- not in the final analysis, ideas for further checks --
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
ORDER BY p.product_name, YEAR(sa.date), DATEPART(QUARTER, sa.date)

-- ELECTRONICS --
-- producr price & profit of electronics products

SELECT product_name,
	   product_price AS 'price',
	   product_cost AS 'cost',
	   (product_price - product_cost) AS 'product_profit'
FROM products
WHERE product_category = 'electronics'


-- units sold per product over time (pivot table)

WITH base_cte AS (
SELECT  p.product_name,
	    YEAR(sa.date) AS 'year', 
		DATEPART(QUARTER, sa.date) AS 'quarter',
		SUM(sa.units) AS 'units_sold'
FROM products AS p JOIN sales AS sa
ON p.product_id = sa.product_id
WHERE product_category = 'electronics'
GROUP BY p.product_name, YEAR(sa.date), DATEPART(QUARTER, sa.date)
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


-- percentage of electronics products sold over time (pivot table) 
-- % out of total electronics products sold each quarter

WITH base_cte AS (
SELECT  p.product_name,
	    YEAR(sa.date) AS 'year', 
		DATEPART(QUARTER, sa.date) AS 'quarter',
		SUM(sa.units) AS 'units_sold',
		SUM(SUM(sa.units)) OVER (PARTITION BY YEAR(sa.date)) AS 'total_units_sold_per_year',
		ROUND(SUM(sa.units) * 100.0 / SUM(SUM(sa.units)) OVER (PARTITION BY YEAR(sa.date), DATEPART(QUARTER, sa.date)), 0) AS 'percentage_of_total_products'
FROM products AS p JOIN sales AS sa
ON p.product_id = sa.product_id
WHERE product_category = 'electronics'
GROUP BY p.product_name, YEAR(sa.date), DATEPART(QUARTER, sa.date)
)
SELECT product_name,
		[2017 Q1], [2017 Q2], [2017 Q3],
		[2018 Q1], [2018 Q2], [2018 Q3]
FROM (
	SELECT 
		CONCAT(year, ' Q', quarter) AS year_quarter, 
		product_name, 
		percentage_of_total_products
	FROM base_cte
	) AS TBL
PIVOT (SUM(percentage_of_total_products) FOR 
		year_quarter IN ([2017 Q1], [2017 Q2], [2017 Q3],
						[2018 Q1], [2018 Q2], [2018 Q3])
	) AS PVT
ORDER BY product_name



-- checking for stocks of colorbuds & gamer heaphones over time in different stores in downtown (electronics category) 
-- (couldnt find an interesting findings here below)

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

