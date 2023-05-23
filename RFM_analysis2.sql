--This is Store sales data, I will apply RFM analysis to this data to segment the customers and get the right action to each segment.

--First, We want to know the segments of the customers, You Can see the customer segments:
Select distinct(segment)
From Sales..segment_scores;

-- The segments are determined based on three factors: Recency, Frequency and Monetary. 
-- We Will see this factors and how we will get these data from our dataset.

--Let's explore the dataset.
Select * 
from Sales..train$ ;


 -- We Will figure out What is the Cities contains most customers number
 Select Top 10 City, count(Customer_Name) as Cust_Number 
 From Sales..train$
 group by City
 order by Cust_Number desc;



 -- We Can see what is the top 10 products in each city
SELECT *
FROM (
	 SELECT N.City, N.Product_name, 
			RANK() over (partition by N.city order by Cust_Sales desc) as RK,
			Cust_Sales
	 FROM(
		 Select
			City,
			Product_name,	
			Sum(Sales) over (Partition by Product_name) as Cust_Sales 
		From Sales..train$

		) as N
	) as L
Where L.RK <=10
Order By L.City ASC, L.Cust_Sales Desc


-- -- What is the most Category Sales 
Select Category, sum(Sales) as sales
from Sales..train$
group by Category
order by sales desc

-- Technology is the highest sales between categories

-- We Want to explore the most 5 valuable cusotmers in each category

SELECT new.Category, new.Customer_name, Sales_Cust 
FROM (
SELECT Category, Customer_Name, 
		RANK() over(partition by Category order by Sales Desc) as RANK,
		SUM(Sales) over (partition by Customer_name) as Sales_Cust
FROM Sales..train$
) AS new
Where RANK <=5
order by new.category, Sales_Cust desc ;

--Now, We Will work on segmenting our Customers by RFM technique analysis>

 with SalesData as (Select *
from Sales..train$
Where Segment = 'Consumer'),

order_summary as(
	Select 
		Customer_ID, Order_ID, Order_Date, sum(Sales) as sales
	from SalesData
	Group by Customer_ID, Order_ID, Order_Date
),


-- Customer Segmentation based on RFM 
-- RFM analysis is a useful tool for customer segmentation, targeted marketing, and customer retention
-- Recency measures how recently a customer has purchased from a brand.
-- Frequency measures how often a customer purchases from a brand. 
-- Monetary value measures how much a customer spends on a brand.


RFM_analysis as (
	select nw.customer_id,  
	DATEDIFF(day, (Select MAX(order_date) from order_summary where customer_ID = nw.customer_id), (Select max(order_date) from order_summary)) as Recency,
	COUNT(nw.Order_id) as Frequency,
	Sum(nw.sales) as Monetary,
	NTILE(5) over (Order by DATEDIFF(day, (Select MAX(order_date) from order_summary where customer_ID = nw.customer_id), (Select max(order_date) from order_summary))ASC) as R,
	NTILE(5) over (order by COUNT(nw.Order_id) desc) as F,
	NTILE(5) over (order by Sum(nw.sales) desc) as M

	from order_summary as nw
	group by nw.customer_id
	
), 

RFM_overall as (
	SELECT Customer_ID, CONCAT(R,F,M) as RFM_score
	FROM RFM_analysis
), 

RFM_segments as (
	SELect *
	from Sales..segment_scores
),

RR as ( 
Select O.Customer_ID, O.RFM_score, S.Segment as Customer_Segment
from RFM_overall as o
inner Join RFM_segments as S
on S.scores = o.RFM_score)

-- Now we will calculate the number of customers in each customers_segment:

select
	R.Customer_segment, 
	count(R.customer_ID) as Cust_No
from RR as R
Group by 
	Customer_segment
Order by 
	2 desc 

--I recommend to focus more on follow up with Hibernating customers and At risk customers
--We Should keep our champions customers with more rewards and special offers.

