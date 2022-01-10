-- EXPLORATORY DATA ANALYSIS PROJECT PORTFOLIO USING SQL
-- DATASET AVAILABLE AT: https://www.kaggle.com/olistbr/brazilian-ecommerce?select=olist_order_items_dataset.csv




-- THE AVERAGE DELIVERY TIME FOR ORDERS IN EACH STATE

Select cust.customer_state, Avg(Datediff(HOUR, order_purchase_timestamp, order_estimated_delivery_date)) as estimated_delivery_time, Avg(Datediff(HOUR, order_purchase_timestamp, order_delivered_customer_date)) as delivery_time
From Olist_ecommerce.dbo.orders ord
Left Join Olist_ecommerce.dbo.customers cust
	On ord.customer_id = cust.customer_id
Where ord.order_delivered_customer_date is not null
	and ord.order_status <> 'canceled' -- there are 6 delivered orders which are also canceled
Group by cust.customer_state
Order by 2





-- BEST SELLING PRODUCT CATEGORIES

Select Top 20 itm.product_id, trl.product_category_name_english, COUNT(itm.product_id) as product_count
From Olist_ecommerce.dbo.order_items itm
Left Join Olist_ecommerce.dbo.products prd
	On itm.product_id = prd.product_id
Left Join Olist_ecommerce.dbo.product_cate_name_trans trl
	On prd.product_category_name = trl.product_category_name
Group by itm.product_id, trl.product_category_name_english
Order by 3 desc
-- The product with id '5a848e4ab52fd5445cdc07aab1c40e48' does not belong to any category
-- The best selling categories are garden_tools, health_beauty, computer_accessory and watches_gifts





-- THE VALUES OF SUCCESSFUL ORDERS

Select order_id, order_purchase_date, SUM(total_fee) as total_order_value
From (
Select itm.order_id, Cast(ord.order_purchase_timestamp as date) as order_purchase_date, itm.product_id, itm.price, itm.freight_value, (itm.price + itm.freight_value) as total_fee
From Olist_ecommerce.dbo.order_items itm
Left Join Olist_ecommerce.dbo.orders ord
	On itm.order_id = ord.order_id
Where ord.order_delivered_customer_date is not null
	and ord.order_status <> 'canceled'
) successful_order_values
Group by order_id, order_purchase_date
Order by 3 desc



-- CREATE TEMP TABLE OF SUCCESSFUL ORDERS FOR FURTHER CALCULATIONS

DROP TABLE IF EXISTS #temp_successful_orders
CREATE TABLE #temp_successful_orders
(
order_id nvarchar(40),
customer_state nvarchar(10),
order_purchase_date date,
total_order_value float
)

INSERT INTO #temp_successful_orders
Select order_id, customer_state, order_purchase_date, SUM(total_fee) as total_order_value
From (
Select itm.order_id, customer_state, FORMAT(ord.order_purchase_timestamp, 'yyyy-MM-dd') as order_purchase_date, itm.product_id, itm.price, itm.freight_value, (itm.price + itm.freight_value) as total_fee
From Olist_ecommerce.dbo.order_items itm
Left Join Olist_ecommerce.dbo.orders ord
	On itm.order_id = ord.order_id
Left Join Olist_ecommerce.dbo.customers cust
	On ord.customer_id = cust.customer_id
Where ord.order_delivered_customer_date is not null
	and ord.order_status <> 'canceled'
) successful_order_values
Group by order_id, customer_state, order_purchase_date

Select customer_state, SUM(total_order_value) as state_total
From #temp_successful_orders
Group by customer_state
Order by 2 desc


-- Average, minimum, maximum total value of orders by states

Select customer_state,
	AVG(total_order_value) as avg_total,
	MIN(total_order_value) as min_total,
	MAX(total_order_value) as max_total
From #temp_successful_orders
Group by customer_state
Order by 2


-- Let's take a look at the revenue of Rio De Janeiro and Sao Paulo state by month

Select FORMAT(order_purchase_date, 'yyyy-MM') as month_RJ, CONVERT(decimal(10,3), SUM(total_order_value)) as rev_RJ
From #temp_successful_orders
Where customer_state = 'RJ'
Group by FORMAT(order_purchase_date, 'yyyy-MM')
Order by 1

Select FORMAT(order_purchase_date, 'yyyy-MM') as month_SP, CONVERT(decimal(10,3), SUM(total_order_value)) as rev_SP
From #temp_successful_orders
Where customer_state = 'SP'
Group by FORMAT(order_purchase_date, 'yyyy-MM')
Order by 1


-- CREATE VIEW TO STORE DATA FOR FURTHER CALCULATIONS OR VISUALIZATIONS

CREATE VIEW successful_orders as
Select order_id, customer_state, order_purchase_date, SUM(total_fee) as total_order_value
From (
Select itm.order_id, customer_state, FORMAT(ord.order_purchase_timestamp, 'yyyy-MM-dd') as order_purchase_date, itm.product_id, itm.price, itm.freight_value, (itm.price + itm.freight_value) as total_fee
From Olist_ecommerce.dbo.order_items itm
Left Join Olist_ecommerce.dbo.orders ord
	On itm.order_id = ord.order_id
Left Join Olist_ecommerce.dbo.customers cust
	On ord.customer_id = cust.customer_id
Where ord.order_delivered_customer_date is not null
	and ord.order_status <> 'canceled'
) successful_order_values
Group by order_id, customer_state, order_purchase_date





-- SOME INFORMATION ABOUT CANCELED ORDERS

-- Number of canceled orders by state

Select cust.customer_state, Count(ord.order_id) as num_of_canceled_order
From Olist_ecommerce.dbo.orders ord
Left Join Olist_ecommerce.dbo.customers cust
	On ord.customer_id = cust.customer_id
Where ord.order_status = 'canceled'
Group by cust.customer_state
Order by 2 desc


-- Total number of orders by state

Select cust.customer_state, Count(ord.order_id) as num_of_order
From Olist_ecommerce.dbo.orders ord
Left Join Olist_ecommerce.dbo.customers cust
	On ord.customer_id = cust.customer_id
Group by cust.customer_state
Order by 2 desc


-- Create a CTE joining 2 above tables and find the percentage of canceled orders in each state

With CTE_order (customer_state, num_of_canceled_order, num_of_order)
as
(
Select ccord.customer_state, ccord.num_of_canceled_order, tord.num_of_order
From (
	Select cust.customer_state, Count(ord.order_id) as num_of_canceled_order
	From Olist_ecommerce.dbo.orders ord
	Left Join Olist_ecommerce.dbo.customers cust
		On ord.customer_id = cust.customer_id
	Where ord.order_status = 'canceled'
	Group by cust.customer_state
	) as ccord
	
	Left Join (
	Select cust.customer_state, Count(ord.order_id) as num_of_order
	From Olist_ecommerce.dbo.orders ord
	Left Join Olist_ecommerce.dbo.customers cust
		On ord.customer_id = cust.customer_id
	Group by cust.customer_state
	) as tord
		On ccord.customer_state = tord.customer_state
)
Select *, Format(Cast(num_of_canceled_order as decimal(5,2))/(num_of_order), 'P') as percentage_canceled_order
-- If we keep the original data type of "num_of_canceled_order" column, every rows in "percentage_canceled_order" column will return 0, or 0.00%
From CTE_order
Order by 4 desc
-- Most of states have less than 1% of orders which are canceled


-- Let's see if we can find something interesting about canceled orders in Sao Paulo state

Select cust.customer_unique_id, COUNT(cust.customer_unique_id) as cust_count, cust.customer_city
From Olist_ecommerce.dbo.orders ord
Left Join Olist_ecommerce.dbo.customers cust
	On ord.customer_id = cust.customer_id
Where ord.order_status = 'canceled'
		and cust.customer_state = 'SP'
Group by cust.customer_unique_id, cust.customer_city
Having COUNT(cust.customer_unique_id) > 1
-- Looks like there is no one who cancel orders too regularly


Select cust.customer_city, COUNT(cust.customer_city) as city_count
From Olist_ecommerce.dbo.orders ord
Left Join Olist_ecommerce.dbo.customers cust
	On ord.customer_id = cust.customer_id
Where ord.order_status = 'canceled'
		and cust.customer_state = 'SP'
Group by cust.customer_city
Order by 2 desc
-- Sao Paulo city has the highest number of cancel orders in Sao Paulo state, whereas there is no significant difference among the other cities