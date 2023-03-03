/*  Question 1  */
/* Provide the list of markets in which customer "Atliq Exclusive" operates its
business in the APAC region.*/

Select customer_code, market 
from dim_customer
where customer = 'Atliq Exclusive' and region = 'APAC' ;

/*  Question 2 */
/* What is the percentage of unique product increase in 2021 vs. 2020? The
final output contains these fields,
unique_products_2020
unique_products_2021
percentage_chg */


WITH unique_prod
AS (SELECT
  sm.fiscal_year,
  COUNT(DISTINCT pc.product_code) AS unique_products
FROM fact_sales_monthly sm
INNER JOIN dim_product pc
  ON pc.product_code = sm.product_code
GROUP BY sm.fiscal_year)

SELECT
  u1.unique_products AS unique_products_2020,
  u2.unique_products AS unique_products_2021,
  Round(((u2.unique_products - u1.unique_products) / (u1.unique_products) * 100 ),3) AS percentage_chg
FROM unique_prod u1
CROSS JOIN unique_prod u2
WHERE u1.fiscal_year = 2020
AND u2.fiscal_year = 2021;



/* Question 3 */
/*  Provide a report with all the unique product counts for each segment and
sort them in descending order of product counts. The final output contains
2 fields,
segment
product_count
 */
 
select segment , Count(distinct product_code) as product_Count
from dim_product 
group by segment
order by Count(distinct product_code);

/* Question 4 */
 /* Follow-up: Which segment had the most increase in unique products in
2021 vs 2020? The final output contains these fields,
segment
product_count_2020
product_count_2021
difference */

WITH segment_table AS
  (SELECT dp.segment,
          sm.fiscal_year,
          COUNT(DISTINCT dp.product_code) AS product_count
   FROM dim_product dp
   INNER JOIN fact_sales_monthly sm ON dp.product_code = sm.product_code
   GROUP BY dp.segment,
            sm.fiscal_year)
            
SELECT a.segment,
       a.product_count AS product_count_2020,
       b.product_count AS product_count_2021,
       (b.product_count - a.product_count) AS difference
FROM segment_table a
 JOIN segment_table b ON a.segment = b.segment
WHERE a.fiscal_year = '2020'
  AND b.fiscal_year = '2021';
  


/* Question 5 */
 /* Get the products that have the highest and lowest manufacturing costs.
The final output should contain these fields,
product_code
product
manufacturing_cost */

 
 select dp.product , mc.product_code, mc.manufacturing_cost
 from fact_manufacturing_cost mc join dim_product dp
 on mc.product_code = dp.product_code
 where manufacturing_cost IN ((select min(manufacturing_cost) from fact_manufacturing_cost) , (Select max(manufacturing_cost) from fact_manufacturing_cost));
 
 /* Question 6 */
 /* Generate a report which contains the top 5 customers who received an
average high pre_invoice_discount_pct for the fiscal year 2021 and in the
Indian market. The final output contains these fields,
customer_code
customer
average_discount_percentage */

select dc.customer_code, dc.customer, round(avg(pid.pre_invoice_discount_pct),3) as average_discount_percentage
from fact_pre_invoice_deductions pid join dim_customer dc
on pid.customer_code = dc.customer_code
where pid.fiscal_year = 2021 and dc.market = 'India'
group by dc.customer_code, dc.customer
order by avg(pid.pre_invoice_discount_pct) desc
limit 5;

/* Question 7 */
 /* Get the complete report of the Gross sales amount for the customer “Atliq
Exclusive” for each month. This analysis helps to get an idea of low and
high-performing months and take strategic decisions.
The final report contains these columns:
Month
Year
Gross sales Amount */


select monthname(sm.date) as Month , year(sm.date) as Year, round(sum(sold_quantity * gross_price),2) as Gross_sales_Amount
from fact_sales_monthly sm join fact_gross_price gp 
on 
sm.product_code= gp.product_code 
join dim_customer dc 
ON 
sm.customer_code = dc.customer_code
where dc.customer = 'Atliq Exclusive'
group by  Month , year(sm.date) 
order by  Year , month(Month);

/* Question 8 */
 /* In which quarter of 2020, got the maximum total_sold_quantity? The final
output contains these fields sorted by the total_sold_quantity,
Quarter
total_sold_quantity
 */
 
 With quarter_sales as (
  select 
    month(date), 
    fiscal_year, 
    sold_quantity, 
    case when month(date) in (9, 10, 11) Then '1' when month(date) in (12, 1, 2) 
    Then '2' when month(date) in (3, 4, 5) Then '3' when month(date) in (6, 7, 8) Then '4' else null end as quarter_number 
  FROM 
    fact_sales_monthly 
  where 
    fiscal_year = 2020
) 
Select 
  quarter_number, 
  sum(sold_quantity) as sold_quantity
from 
  quarter_sales 
group by 
  quarter_number 
order by 
  quarter_number asc ;
  
  /* Question 9 */
 /* Which channel helped to bring more gross sales in the fiscal year 2021
and the percentage of contribution? The final output contains these fields,
channel
gross_sales_mln
percentage
 */
 
With channel_sales as ( select dc.channel, Round(Sum(fs.sold_quantity * fg.gross_price)/ 1000000, 2) as gross_sales_mln 
  FROM 
    fact_sales_monthly fs 
    join fact_gross_price fg 
    join dim_customer dc on dc.customer_code = fs.customer_code 
    and fg.product_code = fs.product_code 
    and fg.fiscal_year = fs.fiscal_year 
  where 
    fs.fiscal_year = 2021 
  group by 
    dc.channel
) 
select 
channel, gross_sales_mln, Round (gross_sales_mln /(Select sum(gross_sales_mln) as total_gross_sales 
    from 
      channel_sales
  )* 100, 3) as percentage 
from 
  channel_sales
order by gross_sales_mln desc;

/* Question 10 */
 /* Get the Top 3 products in each division that have a high
total_sold_quantity in the fiscal_year 2021? The final output contains these fields,
division
product_code
product
total_sold_quantity
rank_order
 */
 
 With tmp as (select dp.division, dp.product_code, dp.product, Sum(fs.sold_quantity) as total_sold_quantity, 
    Rank() over(partition by division order by Sum(fs.sold_quantity) desc) as rank_order 
  from 
    dim_product dp 
	join fact_gross_price fg on dp.product_code = fg.product_code 
    join fact_sales_monthly fs on fg.fiscal_year = fs.fiscal_year 
    and fg.product_code = fs.product_code 
  where 
    fs.fiscal_year = 2021 
  group by 
    dp.division, 
    dp.product_code, 
    dp.product
) 
Select * from tmp 
where rank_order <= 3 ;

/* Sample Questions */

/* Generate a yearly report for 'croma' customer where the output contains these fields:
           fiscal_year
           yearly_gross_sales
   make sure that yearly_gross_sales are in millions (divide the total by 1000000) */


select sm.fiscal_year ,round(sum(sm.sold_quantity*gp.gross_price)/1000000,2) as Yearly_sales 
from gdb023.fact_sales_monthly sm join gdb023.fact_gross_price gp
on sm.product_code = gp.product_code 
	and sm.fiscal_year = gp.fiscal_year
    where customer_code = 90002002
    group by fiscal_year
    order by fiscal_year;

/* Generate a report which contain fiscal year and also the number of unique products sold in that year.  */


select  Count(distinct product_code) as product_count, fiscal_year
from fact_sales_monthly 
group by fiscal_year;





 
