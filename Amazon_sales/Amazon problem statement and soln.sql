-- EDA
select * from category;
select * from customers;
select *from  inventory;
select * from order_items;
select * from orders;
select * from payments;
select * from products;
select * from sellers;
select * from shippings;


-- Business Problems and EDA

--1 top selling products by total sales value
-- product name, total quantity sold and total sales value
alter table order_items
add column total_sales float;

update order_items
set total_sales = (quantity * price_per_unit);


select * from order_items;


-- to get top selling products need to join two table
-- order-items and products

select pr.product_id, pr.product_name, 
sum(oi.total_sales) as total_sales,
count(o.order_id) as total_order from orders as o
join order_items as  oi
on o.order_id = oi.order_id
join  products as pr
on pr.product_id = oi.product_id
group by 1,2
order by 3 desc
limit 10;


-- 2 Revenue by category 
-- calculate total revenue generated by each category with its percentage contribution to total

select ca.category_name,sum(oi.total_sales) as sum,sum(oi.total_sales)/(select sum(total_sales) from order_items)*100 from category as ca
join products as pr
on ca.category_id = pr.category_id
join order_items as oi
on oi.product_id = pr.product_id
group by 1
order by 2 desc;


--3 	Average order value by customer with customer having more than 5 order
with AOV as
(select cu.first_name,cu.last_name,count(o.order_id), (select sum(total_sales) from order_items)/count(o.order_id) as AOV from customers as cu
join orders as o
on cu.customer_id = o.customer_id
join order_items as oi
on o.order_id = oi.order_id
group by 1,2
having count(o.order_id) >5)
select first_name, last_name, aov
from aov;



/* 4. Monthly Sales Trend
--Query monthly total sales over the past year.
Challenge: Display the sales trend, grouping by month, return current_month sale, last month sale!
*/

-- last 1 year data 
-- each month -- their sale and their prev month sale
-- window lag

SELECT 
	year,
	month,
	total_sales as current_month_sale,
	LAG(total_sales, 1) OVER(ORDER BY year, month) as last_month_sale
FROM ---
(
SELECT 
	EXTRACT(MONTH FROM o.order_date) as month,
	EXTRACT(YEAR FROM o.order_date) as year,
	ROUND(
			SUM(oi.total_sales::numeric)
			,2) as total_sales
FROM orders as o
JOIN
order_items as oi
ON oi.order_id = o.order_id
WHERE o.order_date >= CURRENT_DATE - INTERVAL '1 year'
GROUP BY 1, 2
ORDER BY year, month
) as t1



/*
5. Customers with No Purchases
Find customers who have registered but never placed an order.
Challenge: List customer details and the time since their registration.
*/

-- Approach 1
SELECT *
	-- reg_date - CURRENT_DATE
FROM customers
WHERE customer_id NOT IN (SELECT 
					DISTINCT customer_id
				FROM orders
				);


-- Approach 2
SELECT *
FROM customers as c
LEFT JOIN
orders as o
ON o.customer_id = c.customer_id
WHERE o.customer_id IS NULL



/*
6. Least-Selling Categories by State
Identify the least-selling product category for each state.
*/
with ranking_table as
(
SELECT 
	c.state,
	cat.category_name,
	SUM(oi.total_sales) as total_sale,
	RANK() OVER(PARTITION BY c.state ORDER BY SUM(oi.total_sales) ASC) as rank
FROM orders as o
JOIN 
customers as c
ON o.customer_id = c.customer_id
JOIN
order_items as oi
ON o.order_id = oi. order_id
JOIN 
products as p
ON oi.product_id = p.product_id
JOIN
category as cat
ON cat.category_id = p.category_id
GROUP BY 1, 2
)
SELECT 
*
FROM ranking_table
WHERE rank = 1;


/*
7. Customer Lifetime Value (CLTV)
Calculate the total value of orders placed by each customer over their lifetime.

*/

-- cx - o - oi
-- cx id group by sum(total_sale)
-- order by total sale 
-- rank 


SELECT 
	c.customer_id,
	CONCAT(c.first_name, ' ',  c.last_name) as full_name,
	SUM(total_sales) as CLTV,
	DENSE_RANK() OVER( ORDER BY SUM(total_sales) DESC) as cx_ranking
FROM orders as o
JOIN 
customers as c
ON c.customer_id = o.customer_id
JOIN 
order_items as oi
ON oi.order_id = o.order_id
GROUP BY 1, 2;



/*
8. Inventory Stock Alerts
Query products with stock levels below a certain threshold (e.g., less than 10 units).

*/

SELECT 
	i.inventory_id,
	p.product_name,
	i.stock as current_stock_left,
	i.last_stock_date,
	i.warehouse_id
FROM inventory as i
join 
products as p
ON p.product_id = i.product_id
WHERE stock < 10;




/*
9. Shipping Delays
Identify orders where the shipping date is later than 3 days after the order date.
Challenge: Include customer, order details, and delivery provider.
*/

-- cx -- o-- ship

SELECT 
	c.*,
	o.*,
	s.shipping_providers,
s.shipping_date - o.order_date as days_took_to_ship
FROM orders as o
JOIN
customers as c
ON c.customer_id = o.customer_id
JOIN 
shippings as s
ON o.order_id = s.order_id
WHERE s.shipping_date - o.order_date > 3;



/*
10. Payment Success Rate 
Calculate the percentage of successful payments across all orders.
*/

SELECT 
	p.payment_status,
	COUNT(*) as total_cnt,
	COUNT(*)::numeric/(SELECT COUNT(*) FROM payments)::numeric * 100 as percentage
FROM orders as o
JOIN
payments as p
ON o.order_id = p.order_id
GROUP BY 1;



/*
11. Top Performing Sellers
Find the top 5 sellers based on total sales value.
*/


WITH top_sellers
AS
(SELECT 
	s.seller_id,
	s.seller_name,
	SUM(oi.total_sales) as total_sale
FROM orders as o
JOIN
sellers as s
ON o.seller_id = s.seller_id
JOIN 
order_items as oi
ON oi.order_id = o.order_id
GROUP BY 1, 2
ORDER BY 3 DESC
LIMIT 5),
sellers_reports
AS
(SELECT 
	o.seller_id,
	ts.seller_name,
	o.order_status,
	COUNT(*) as total_orders
FROM orders as o
JOIN 
top_sellers as ts
ON ts.seller_id = o.seller_id
WHERE 
o.order_status NOT IN ('Inprogress', 'Returned')
GROUP BY 1, 2, 3
)
SELECT 
	seller_id,
	seller_name,
	SUM(CASE WHEN order_status = 'Completed' THEN total_orders ELSE 0 END) as Completed_orders,
	SUM(CASE WHEN order_status = 'Cancelled' THEN total_orders ELSE 0 END) as Cancelled_orders,
	SUM(total_orders) as total_orders,
	SUM(CASE WHEN order_status = 'Completed' THEN total_orders ELSE 0 END)::numeric/
	SUM(total_orders)::numeric * 100 as successful_orders_percentage
FROM sellers_reports
GROUP BY 1, 2;

/*
12. Product Profit Margin
Calculate the profit margin for each product (difference between price and cost of goods sold).
*/

-- o - oi - prod
-- group pid sum(total_sale - cogs * qty) as profit

SELECT 
	product_id,
	product_name,
	profit_margin,
	DENSE_RANK() OVER( ORDER BY profit_margin DESC) as product_ranking
FROM
(SELECT 
	p.product_id,
	p.product_name,
	-- SUM(total_sale - (p.cogs * oi.quantity)) as profit,
	SUM(total_sales - (p.cogs * oi.quantity))/sum(total_sales) * 100 as profit_margin
FROM order_items as oi
JOIN 
products as p
ON oi.product_id = p.product_id
GROUP BY 1, 2
) as t1;

/*
13. Most Returned Products
Query the top 10 products by the number of returns.
*/



SELECT 
	p.product_id,
	p.product_name,
	COUNT(*) as total_unit_sold,
	SUM(CASE WHEN o.order_status = 'Returned' THEN 1 ELSE 0 END) as total_returned,
	SUM(CASE WHEN o.order_status = 'Returned' THEN 1 ELSE 0 END)::numeric/COUNT(*)::numeric * 100 as return_percentage
FROM order_items as oi
JOIN 
products as p
ON oi.product_id = p.product_id
JOIN orders as o
ON o.order_id = oi.order_id
GROUP BY 1, 2
ORDER BY 5 DESC;


/*
14. Inactive Sellers
Identify sellers who haven’t made any sales in the last 6 months.
*/

WITH cte1 -- as these sellers has not done any sale in last 6 month
AS
(SELECT * FROM sellers
WHERE seller_id NOT IN (SELECT seller_id FROM orders WHERE order_date >= CURRENT_DATE - INTERVAL '6 month')
)
SELECT 
o.seller_id,
MAX(o.order_date) as last_sale_date,
MAX(oi.total_sales) as last_sale_amount
FROM orders as o
JOIN 
cte1
ON cte1.seller_id = o.seller_id
JOIN order_items as oi
ON o.order_id = oi.order_id
GROUP BY 1;


/*
15. IDENTITY customers into returning or new
if the customer has done more than 5 return categorize them as returning otherwise new
*/

SELECT 
c_full_name as customers,
total_orders,
total_return,
CASE
	WHEN total_return > 5 THEN 'Returning_customers' ELSE 'New'
END as cx_category
FROM
(SELECT 
	CONCAT(c.first_name, ' ', c.last_name) as c_full_name,
	COUNT(o.order_id) as total_orders,
	SUM(CASE WHEN o.order_status = 'Returned' THEN 1 ELSE 0 END) as total_return	
FROM orders as o
JOIN 
customers as c
ON c.customer_id = o.customer_id
JOIN
order_items as oi
ON oi.order_id = o.order_id
GROUP BY 1
)



/*
16. Top 5 Customers by Orders in Each State
Identify the top 5 customers with the highest number of orders for each state.
*/

SELECT * FROM 
(SELECT 
	c.state,
	CONCAT(c.first_name, ' ', c.last_name) as customers,
	COUNT(o.order_id) as total_orders,
	SUM(total_sales) as total_sale,
	DENSE_RANK() OVER(PARTITION BY c.state ORDER BY COUNT(o.order_id) DESC) as rank
FROM orders as o
JOIN 
order_items as oi
ON oi.order_id = o.order_id
JOIN 
customers as c
ON 
c.customer_id = o.customer_id
GROUP BY 1, 2
) as t1
WHERE rank <=5;



/*
17. Revenue by Shipping Provider
Calculate the total revenue handled by each shipping provider.
*/

-- oi - o - shipping
-- group by shipping provider id sum(total sale), total orders 



SELECT 
	s.shipping_providers,
	COUNT(o.order_id) as order_handled,
	SUM(oi.total_sale) as total_sale,
	COALESCE(AVG(s.return_date - s.shipping_date), 0) as average_days
FROM orders as o
JOIN 
order_items as oi
ON oi.order_id = o.order_id
JOIN 
shippings as s
ON 
s.order_id = o.order_id
GROUP BY 1

SELECT * FROM shippings;p





/*
18. Top 10 product with highest decreasing revenue ratio compare to last year(2022) and current_year(2023)
Challenge: Return product_id, product_name, category_name, 2022 revenue and 2023 revenue decrease ratio at end Round the result
Note: Decrease ratio = cr-ls/ls* 100 (cs = current_year ls=last_year)
*/

-- join o -oi- p 
-- filter 2022
-- group by p id sum(total sale) 


-- join o -oi- p 
-- filter 2023
-- group by p id sum(total sale) 

-- join 1 -2 


WITH last_year_sale
as
(
SELECT 
	p.product_id,
	p.product_name,
	SUM(oi.total_sales) as revenue
FROM orders as o
JOIN 
order_items as oi
ON oi.order_id = o.order_id
JOIN 
products as p
ON 
p.product_id = oi.product_id
WHERE EXTRACT(YEAR FROM o.order_date) = 2022
GROUP BY 1, 2
),
current_year_sale
AS
(
SELECT 
	p.product_id,
	p.product_name,
	SUM(oi.total_sales) as revenue
FROM orders as o
JOIN 
order_items as oi
ON oi.order_id = o.order_id
JOIN 
products as p
ON 
p.product_id = oi.product_id
WHERE EXTRACT(YEAR FROM o.order_date) = 2023
GROUP BY 1, 2
)
SELECT
	cs.product_id,
	ls.revenue as last_year_revenue,
	cs.revenue as current_year_revenue,
	ls.revenue - cs.revenue as rev_diff,
	ROUND((cs.revenue - ls.revenue)::numeric/ls.revenue::numeric * 100, 2) as reveneue_dec_ratio
FROM last_year_sale as ls
JOIN
current_year_sale as cs
ON ls.product_id = cs.product_id
WHERE 
	ls.revenue > cs.revenue
ORDER BY 5 DESC
LIMIT 10;


