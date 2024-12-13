-- Q.1 Coffee Consumers Count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?

select city_name, population *0.25 as cofee_consumers from city;

-- -- Q.2
-- Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

select city.city_name , sum(total) as total_sales from sales
JOIN
 customers ON customers.customer_id = sales.customer_id
 JOIN 
 city ON city.city_id = customers.city_id
  where extract(quarter from sale_date) = 4
   group by city_name ;
   
  -- Q.3
-- Sales Count for Each Product
-- How many units of each coffee product have been sold?

select product_name ,sum(total) as total_sales
from sales
join products
ON sales.product_id = products.product_id
group by sales.product_id;


-- Q.4
-- Average Sales Amount per City
-- What is the average sales amount per customer in each city?

-- city abd total sale
-- no cx in each these city

select  city_name , sum(total), count(distinct customers.customer_id), (round(sum(total)/ count(distinct customers.customer_id),2)) as avg_sales_per_cx from sales
JOIN customers
ON sales.customer_id = customers .customer_id
JOIN city
ON city.city_id = customers.city_id
group by city.city_name
order by 2 desc;

-- -- Q.5
-- City Population and Coffee Consumers (25%)
-- Provide a list of cities along with their populations and estimated coffee consumers.
-- return city_name, total current cx, estimated coffee consumers (25%)

with Table1 as 
(select city_name ,((population* 0.25)/10000) as people_IN_MIL from city),

table2 as
(select city_name,count(distinct  sales.customer_id) as coffee_consumers from sales
JOIN customers ON SALES.customer_id = customers.customer_ID
JOIN CITY ON city.city_id = customers.city_id
group by customers.city_id)

select table1.city_name , table1.people_IN_MIL as people , table2.coffee_consumers
FROM TABLE1
JOIN TABLE2 ON TABLE1.CITY_NAME = TABLE2.CITY_NAME;

-- Q6
-- Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?

select * from
(select city.city_name , sum(total), products.product_name,
row_number() over(partition by city.city_name order by sum(total) desc ) as rk
from sales
JOIN Products ON products.product_id = sales.product_id
JOIN customers ON customers.customer_id = sales.customer_id
JOIN city ON city.city_id = customers.city_id
group by city.city_name,products.product_name) as table1
where rk <=3 ;

 -- Q.7
-- Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?

select city_name ,count(distinct sales.customer_id) as unique_customers  from customers 
JOin city on city.city_id = customers.city_id 
JOin sales on customers.customer_id = sales.customer_id
group by 1;

-- -- Q.8
-- Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer

 select city_name , round(sum(total)/count(distinct sales.customer_id),2) as avg_sales_per_customer , 
 round(avg(estimated_rent)/count(distinct sales.customer_id),2) as avg_rent_per_customer
from sales
JOIN customers ON customers.customer_id = sales.customer_id
JoIN city ON city.city_id = customers.city_id
group by city.city_name;

 -- Q9 Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly)
-- by each city
 WITH
monthly_sales
AS
(
	SELECT 
		ci.city_name,
		EXTRACT(MONTH FROM sale_date) as month,
		EXTRACT(YEAR FROM sale_date) as YEAR,
		SUM(s.total) as total_sale
	FROM sales as s
	JOIN customers as c
	ON c.customer_id = s.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1, 2, 3
	ORDER BY 1, 3, 2
),
growth_ratio
AS
(
		SELECT
			city_name,
			month,
			year,
			total_sale as cr_month_sale,
			LAG(total_sale, 1) OVER(PARTITION BY city_name ORDER BY year, month) as last_month_sale
		FROM monthly_sales
)

SELECT
	city_name,
	month,
	year,
	cr_month_sale,
	last_month_sale,
	ROUND(
		(cr_month_sale-last_month_sale)/last_month_sale * 100
		, 2
		) as growth_ratio

FROM growth_ratio
WHERE 
	last_month_sale IS NOT NULL;



-- Q.10
-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer 

WITH city_table
AS
(
	SELECT 
		ci.city_name,
		SUM(s.total) as total_revenue,
		COUNT(DISTINCT s.customer_id) as total_cx,
		ROUND(
				SUM(s.total)/
					COUNT(DISTINCT s.customer_id)
				,2) as avg_sale_pr_cx
		
	FROM sales as s
	JOIN customers as c
	ON s.customer_id = c.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1
	ORDER BY 2 DESC
),
city_rent
AS
(
	SELECT 
		city_name, 
		estimated_rent,
		ROUND((population * 0.25)/1000000, 3) as estimated_coffee_consumer_in_millions
	FROM city
)
SELECT 
	cr.city_name,
	total_revenue,
	cr.estimated_rent as total_rent,
	ct.total_cx,
	estimated_coffee_consumer_in_millions,
	ct.avg_sale_pr_cx,
	ROUND(
		cr.estimated_rent/ct.total_cx
		, 2) as avg_rent_per_cx
FROM city_rent as cr
JOIN city_table as ct
ON cr.city_name = ct.city_name
ORDER BY 2 DESC
