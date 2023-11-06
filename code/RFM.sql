-- RFM Analysis -- 
use db
select * from [dbo].[sales_data_sample];


-- checking unique values 
select distinct status from [dbo].[sales_data_sample]; -- nice one to plot 
select distinct  year_ID from [dbo].[sales_data_sample]; -- nice one to plot 
select distinct productline from [dbo].[sales_data_sample]; 
select distinct country from [dbo].[sales_data_sample]; -- nice one to plot
select distinct TERRITORY from [dbo].[sales_data_sample]; 


-- analysis 
-- by productline 
select productline , sum(sales) as revenue 
from [dbo].[sales_data_sample] 
group by productline order by revenue desc;

-- by year 
select year_id , sum(sales) as revenue 
from [dbo].[sales_data_sample] 
group by year_id ;

-- dealsize 
select DEALSIZE, sum(sales) as revenue 
from [db].[dbo].[sales_data_sample] 
group by DEALSIZE  order by 2 desc;


-- what was the best month in a specific year ? what was the revenue ? 
select month_id, sum(sales) revenue , count(ORDERLINENUMBER) as frequency
from  [dbo].[sales_data_sample] 
where year_id = '2003' -- change year to 
 group by MONTH_ID order by revenue desc ;
 
 -- november is the best selling month ? what product are they selling in november ? 
 select month_id, productline, sum(sales) revenue , count(ORDERLINENUMBER) as frequency
from  [dbo].[sales_data_sample] 
where year_id = '2004'  and month_id = '11' -- change year to 
 group by MONTH_ID, PRODUCTLINE  order by 3 desc; 


 -- rfm analysis 
 drop table if exists #rfm 
 with rfm as (
 select 
	 customername, 
	 sum(sales) as Monetryvalue ,
	 avg(sales) as avgMonetryValue, 
	 count(orderlinenumber) as frequency, 
	 max(orderdate) as last_order_date ,
	 (select max(orderdate) from [dbo].[sales_data_sample]  ) as max_order_date,
	 datediff( day, max(orderdate), ( select max(orderdate) from [dbo].[sales_data_sample]  ) ) as recency 
 from [db].[dbo].[sales_data_sample] 
 group by CUSTOMERNAME 
 ),

 
 rfm_cal as (
 select 
	 r.*, 
	 NTILE(4)over(order by recency desc) as rfm_recency,
	 NTILE(4)over(order by frequency) as rfm_frequency ,
	 NTILE(4)over(order by MonetryValue) as rfm_Monetry
 from rfm r 
 )
 select 
	 c.*, 
	 rfm_recency + rfm_frequency + rfm_Monetry as rfm_cell,
	 cast( rfm_recency as varchar)+ cast(rfm_frequency as varchar) + cast(rfm_Monetry as varchar)  as rfm_cell_string
 into #rfm 
 from rfm_cal c;
 

 select CUSTOMERNAME,  rfm_recency , rfm_frequency , rfm_Monetry,
	case 
		when rfm_cell_string in (111, 112, 121, 122, 212, 211, 123, 132, 114, 141) then 'lost customer' -- lost_customers 
		when rfm_cell_string in (133, 134, 143, 144, 244, 234,334, 343, 344 ) then 'slipping away, cannot loose' -- Big spender 
		when rfm_cell_string in (311,411,331) then 'new customer' -- new_customers 
		when rfm_cell_string in (222,223,322,233,232) then 'potential churner' -- potential churner 
		when rfm_cell_string in (321,333,323, 421, 422,432, 432, 332,412) then 'active' -- active_customers 
		when rfm_cell_string in (444,434,433,434,443) then 'loyal' -- loyal
	end as rfm_segment
 from #rfm ;
 

 -- what products are sold more often together ? 
 select distinct ORDERNUMBER,  STUFF(

	 (select ','+ PRODUCTCODE
		 from sales_data_sample p
		 where ORDERNUMBER in (
		 select ORDERNUMBER 
			 from (
				 select ORDERNUMBER, COUNT(*) as rn 
				 from sales_data_sample 
				 where status = 'Shipped'
				 group by ORDERNUMBER
			 )m
			 where rn =  3 
		 )
		 and s.ORDERNUMBER = p.ORDERNUMBER
	 for xml path ('')),1,1,'') productcodes

from sales_data_sample s 
order by 2 desc

 