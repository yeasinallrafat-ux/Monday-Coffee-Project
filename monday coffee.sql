-- Monday coffee -- Data Analysis
SELECT * from city;
SELECT * FROM products;
SELECT * FROM customers;
SELECT * FROM sales;
-- Reports and data analysis
-- Q.1 Coffee consumers count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?

SELECT 
	city_name,
   round(
   (population* 0.25)/ 1000000,
   2) as coffee_consumers_in_millions,
    city_rank
FROM city
order by 2 DESC

-- Q.2 Total revenue from coffee sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

SELECT 
ci.city_name,
SUM(s.total) as total_revenue
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = C.city_id
WHERE
	EXTRACT(YEAR FROM s.sale_date)=2023
    AND
    EXTRACT(quarter FROM s.sale_date)=4
    GROUP BY 1
    ORDER BY 2 desc
    
    -- Q:3
 --   Sales count for each product
  --  How many units of each coffee product have been sold?
   SELECT
	p.product_name,
    COUNT(s.sale_id) as total_orders
FROM products as p
LEFT JOIN
sales as s
on s.product_id = p.product_id
GROUP BY 1
ORDER BY 2 DESC
--Q:4
-- Average Sales Amount per city
-- What is the average sales amount per customer in each city?

-- Here we need two things
-- 1. city and total sale
-- 2. no. of customers in each of these city
SELECT 
ci.city_name,
SUM(s.total) as total_revenue,
COUNT(DISTINCT S.customer_id) as total_cx,
ROUND(
	SUM(s.total)/ 
    COUNT(DISTINCT s.customer_id) 
    ,2) as avrg_sale_pr_cx
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = C.city_id
    GROUP BY 1
    ORDER BY 2 desc
--Q:5
-- City population and coffee consumers
-- Provide a list of cities along with their populations and estimated coffee consumers.
WITH city_table AS (
    SELECT
        city_name,
        ROUND((population * 0.25) / 1000000, 2) AS coffee_consumers
    FROM city
),
customers_table AS (
    SELECT
        ci.city_name,
        COUNT(DISTINCT c.customer_id) AS unique_cx
    FROM sales AS s 
    JOIN customers AS c
        ON c.customer_id = s.customer_id
    JOIN city AS ci
        ON ci.city_id = c.city_id
    GROUP BY 1
)
SELECT 
    ct1.city_name,
    ct1.coffee_consumers AS coffee_consumers_in_millions,
    ct2.unique_cx
FROM city_table AS ct1  
JOIN customers_table AS ct2 
    ON ct1.city_name = ct2.city_name;
    
    -- Q:6
    -- Top selling products by city
    -- What are the top 3 selling products in each city based on sales volume?
SELECT *
FROM
(
    SELECT
        ci.city_name,
        p.product_name,
        COUNT(s.sale_id) AS total_orders,
        DENSE_RANK() OVER(
            PARTITION BY ci.city_name 
            ORDER BY COUNT(s.sale_id) DESC
        ) AS item_rank
    FROM sales AS s
    JOIN products AS p
        ON s.product_id = p.product_id
    JOIN customers AS c
        ON c.customer_id = s.customer_id
    JOIN city AS ci
        ON ci.city_id = c.city_id
    GROUP BY 1, 2
) AS t1
WHERE t1.item_rank <= 3;

-- Q:7
-- Customer Segmentation by city
-- How many unique customers are there in each city who have purchased coffee products?
SELECT * FROM products;

SELECT
	ci.city_name,
    count(distinct c.customer_id) as unique_cx
FROM city as ci
LEFT JOIN
customers as c
ON c.city_id = ci.city_id
JOIN sales as s
ON s.customer_id = c.customer_id
WHERE
	s.product_id IN (1,2,3,4,5,6,7,8,9,10,11,12,13,14)
GROUP BY 1
-- Q.8
-- Average Sale vs rent
-- Find each city and their average sale per customer and average rent per customer

WITH city_table AS (
    SELECT 
        ci.city_id,
        ci.city_name,
        SUM(s.total) AS total_revenue,
        COUNT(DISTINCT s.customer_id) AS total_cx,
        ROUND(
            SUM(s.total) / NULLIF(COUNT(DISTINCT s.customer_id), 0), 
            2
        ) AS avg_sale_pr_cx
    FROM city AS ci
    LEFT JOIN customers AS c
        ON ci.city_id = c.city_id
    LEFT JOIN sales AS s
        ON c.customer_id = s.customer_id
    GROUP BY ci.city_id, ci.city_name
)
SELECT
    ci.city_name,
    ci.estimated_rent,
    ct.total_cx, 
    ct.avg_sale_pr_cx,
    ROUND(ci.estimated_rent / NULLIF(ct.total_cx, 0), 2) AS avg_rent_per_cx   
FROM city AS ci
JOIN city_table AS ct
    ON ci.city_id = ct.city_id
ORDER BY ct.total_revenue DESC;
ORDER BY 5 dESC
-- Q:9
-- Monthly sales Growth
-- Sales growth rate: calculate the percentage growth ( or decline) in sales over different time periods
-- By each city

WITH monthly_sales AS (
    SELECT
        ci.city_name,
        EXTRACT(MONTH FROM s.sale_date) AS month,
        EXTRACT(YEAR FROM s.sale_date) AS year,
        SUM(s.total) AS total_sale
    FROM sales AS s
    JOIN customers AS c
        ON c.customer_id = s.customer_id
    JOIN city AS ci
        ON ci.city_id = c.city_id
    GROUP BY ci.city_name, EXTRACT(MONTH FROM s.sale_date), EXTRACT(YEAR FROM s.sale_date)
),
growth_ratio AS (
    SELECT
        city_name,
        month,
        year,
        total_sale AS cr_month_sale,
        LAG(total_sale, 1) OVER(
            PARTITION BY city_name 
            ORDER BY year, month
        ) AS last_month_sale
    FROM monthly_sales
)
SELECT
    city_name,
    month,
    year, 
    cr_month_sale,
    last_month_sale,
    ROUND(
        ((cr_month_sale - last_month_sale) / NULLIF(last_month_sale, 0)) * 100,
        2
    ) AS growth_ratio
FROM growth_ratio
ORDER BY city_name, year, month;
WHERE 
	last_month_sale IS NOT NULL

-- Q.10
-- Market potential analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers,estimated coffee consumers

WITH city_table AS (
    SELECT 
        ci.city_id,
        ci.city_name,
        ci.estimated_rent,
        ROUND((ci.population * 0.25) / 1000000, 2) AS estimated_coffee_consumers_in_millions,
        COALESCE(SUM(s.total), 0) AS total_sale,
        COUNT(DISTINCT s.customer_id) AS total_cx
    FROM city AS ci
    LEFT JOIN customers AS c
        ON ci.city_id = c.city_id
    LEFT JOIN sales AS s
        ON c.customer_id = s.customer_id
    GROUP BY 
        ci.city_id, 
        ci.city_name, 
        ci.estimated_rent, 
        ci.population
)
SELECT
    city_name,
    total_sale,
    estimated_rent AS total_rent,
    total_cx AS total_customers,
    estimated_coffee_consumers_in_millions
FROM city_table
ORDER BY total_sale DESC
LIMIT 3;

-- Recomendation
-- city 1: Pune
		--  Avg rent per cx is very less
		-- highest total revenue
		-- avg_sale per cx is also high
-- city 2: Delhi
		-- Highest estimated coffee consumer which is 7.7m
		-- Highest total cx is 68
		-- Avg rent per cx 330
-- city 2: Jaipur
		-- Highest Number of cx
		-- avg rent per customer is 156
	    -- avg sale per cx is better
