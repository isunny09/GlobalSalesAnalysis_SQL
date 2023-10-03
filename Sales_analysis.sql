--Inspecting data
select * from salesdata


--1.Countries and total_sales 
select COUNTRY,sum(SALES) as total_sales
from salesdata
group by COUNTRY
order by total_sales desc;

--2.. Top 10 cities with most sales
select top 10 CITY, sum(SALES) as Total_sales
from salesdata
group by CITY
order by Total_sales desc;



--3 Total revenue per country for each product line
with CountryProductSales as
(
	select COUNTRY, PRODUCTLINE, sum(SALES) as Revenue
	from salesdata
	group by COUNTRY, PRODUCTLINE
)
select 
cps.COUNTRY,
cps.PRODUCTLINE as TopProductLine,
cps.Revenue as Sales
from(
select 
	COUNTRY, PRODUCTLINE, Revenue,
	RANK() OVER (PARTITION BY COUNTRY ORDER BY Revenue desc) as SalesRank
from
	CountryProductSales
) as cps
WHERE SalesRank = 1;
---Classic Cars are the top selling products in each country except for JAPAN (PLANES), BELGIUM(Vintage Cars).



--SALES ANALYSIS

--1.TOTAL SALES FOR ALL YEARS 
select YEAR_ID, sum(sales) as sales_per_year
from salesdata group by YEAR_ID
order by 2 desc;

--year 2004 had the most sales, sales are increasing over years
---we don't have complete info for year 2005. 


--2. Total sales per product line
select PRODUCTLINE,sum(SALES) as Total_Sales
from salesdata
group by PRODUCTLINE
order by 2 desc;
--classic cars have the most sales followed by vintage cars 

--3.Classic cars sales over the years
select PRODUCTLINE, YEAR_ID ,sum(SALES) as TotalSales
from salesdata
where PRODUCTLINE   = 'Classic Cars' and YEAR_ID in (2003,2004)
group by PRODUCTLINE, YEAR_ID
order by TotalSales desc;
---The sales of the classic cars has improved from 2003 to 2004. The data for 2005 is incomplete

---4.PERCENTAGE OF SALES GROWTH FOR EACH PRODUCT LINE FROM 2003-2004
with percent_growth as (
	select PRODUCTLINE, YEAR_ID ,sum(SALES) as TotalSales
	from salesdata
	where YEAR_ID IN (2003,2004)
	group by YEAR_ID, PRODUCTLINE
)
select 
	s1.PRODUCTLINE,
	s1.TotalSales as Sales_2003,
	s2.TotalSales as Sales_2004,
	((s2.TotalSales - s1.TotalSales)/s1.TotalSales)* 100 as SalesGrowth
from 
	percent_growth as s1
join
	percent_growth as s2
on
	s1.PRODUCTLINE = s2.PRODUCTLINE
	and s1.YEAR_ID = 2003
	and s2.YEAR_ID = 2004
	order by SalesGrowth desc;
--Planes had the highest growth in sales from year 2003-2004 followed by Trains



---5. TOTAL REVENUE INCREASE PERCENTAGE FROM 2003-2004
with YearlySales as (	
	select YEAR_ID, sum(SALES) as Total_sales 
	from salesdata
	where YEAR_ID in (2003,2004)
	group by YEAR_ID
	)
select 
	--y1.YEAR_ID as Year2003,
	y1.Total_sales as Total_sales_2003,
	--y2.YEAR_ID as Year2004,
	y2.Total_sales as Total_sales_2004,
	((y2.Total_sales - y1.Total_sales) / y1.Total_sales)*100 as PercentGrowth
from YearlySales as y1
join YearlySales as y2
on y1.YEAR_ID = 2003
and y2.YEAR_ID = 2004;
---There is a 34% growth in sales from 2003-2004


---6.PRODUCTS WHOSE SALES WENT DOWN FROM 2003 to 2004
with yearlysales as (	
	select PRODUCTLINE, YEAR_ID, sum(SALES) as Total_sales
	from salesdata
	where YEAR_ID in (2003,2004)
	group by PRODUCTLINE, YEAR_ID
)
select 
	yr2003.PRODUCTLINE,
	yr2003.Total_sales as sales2003,
	yr2004.Total_sales as sales2004
from yearlysales as yr2003
join yearlysales as yr2004
on
	yr2003.PRODUCTLINE = yr2004.PRODUCTLINE
	and yr2003.YEAR_ID = 2003
	and yr2004.YEAR_ID = 2004
where
	yr2003.Total_sales > yr2004.Total_sales;
--There are no products whose sales went down from 2003-2004


--checking the months for which we have the data in the year 2005
select distinct(MONTH_ID) from salesdata
where YEAR_ID = 2005;
--We only have data for the months 1-5 for year 2005 and that's the reason for less sales.


--7.TOP SELLING PRODUCTLINE AND IT'S REVENUE FOR EACH YEAR
WITH YearlySales AS (
    SELECT
        YEAR_ID,
        PRODUCTLINE,
        SUM(SALES) AS TotalSales
    FROM
        salesdata
    GROUP BY
        YEAR_ID,
        PRODUCTLINE
)

SELECT
    YEAR_ID,
    PRODUCTLINE,
    TotalSales
FROM (
    SELECT
        YEAR_ID,
        PRODUCTLINE,
        TotalSales,
        RANK() OVER (PARTITION BY YEAR_ID ORDER BY TotalSales DESC) AS SalesRank
    FROM
        YearlySales
) RankedProducts
WHERE
    SalesRank = 1;

----

--8.REVENUE PER DEAL SIZE
select DEALSIZE, sum(SALES) as total_sales
from salesdata
group by DEALSIZE
order by 2 desc;
--Medium sized deals generate the most revenue and large deals generate the least

--9.WHICH MONTH HAS THE MOST SALES AND ORDERS FOR ALL YEARS
select MONTH_ID, sum(SALES) as Revenue, count(ORDERNUMBER) as Order_frequency
from salesdata
--where YEAR_ID = 2005 can change to see specific year
group by MONTH_ID
order by 2 desc;
-- Nov generates most revenue

--10.WHAT SELLS THE MOST IN NOVEMBER
select MONTH_ID, PRODUCTLINE, sum(SALES) as Revenue
from salesdata 
where MONTH_ID = 11 and YEAR_ID IN (2003,2004)
group by PRODUCTLINE, MONTH_ID
order by Revenue desc;
--Classic cars sell the most in november
 


--11.CUSTOMER ANALYSIS
select top 10 CUSTOMERNAME,COUNTRY ,sum(SALES) as Revenue
from salesdata
group by CUSTOMERNAME, COUNTRY
order by 3 desc;
--- Euro Shoppping Channel is the biggest customer in terms of revenue


select CUSTOMERNAME, count(ORDERNUMBER) as orderfrequency
from salesdata
group by CUSTOMERNAME
order by 2 desc;
-- Euro Shopping Channel has the most orders with 259 orders

--select max(ORDERDATE) from salesdata

---12.USING RFM TO SEGMENT CUSTOMERS WHICH CAN BE VISUALIZED IN TABLEAU

with RFM_CTE as
(
	select 
		CUSTOMERNAME,
		datediff(DD, max(ORDERDATE), (select max(ORDERDATE) from salesdata)) as Recency,
		count(distinct ORDERNUMBER) as Frequency,
		sum(SALES) as Monetaryvalue
	from salesdata
	group by CUSTOMERNAME

),
segmented_customers_cte as (
	select 
		CUSTOMERNAME,
		Recency,
		Frequency,
		Monetaryvalue,
		NTILE(4) OVER (ORDER BY Recency DESC) AS Recency_Category,
		NTILE(4) OVER (ORDER BY Frequency) AS Frequency_Category,
		NTILE(4) OVER (ORDER BY Monetaryvalue) AS MonetaryValue_Category
	from RFM_CTE
)
SELECT
    CUSTOMERNAME,
    Recency_Category,
    Frequency_Category,
    Monetaryvalue_Category,
    CASE
        WHEN Recency_Category = 4 AND Frequency_Category = 4 AND Monetaryvalue_Category = 4 THEN 'High'
        WHEN Recency_Category IN (3, 4) AND Frequency_Category IN (3, 4) AND Monetaryvalue_Category IN (3, 4) THEN 'Medium'
        ELSE 'Low'
    END AS CustomerSegment
FROM
    Segmented_Customers_cte;




