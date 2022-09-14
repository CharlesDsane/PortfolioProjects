-- Inspecting data

select *
from PortfolioProject.dbo.sales_data_sample


-- Checking unique values

select distinct STATUS from PortfolioProject.dbo.sales_data_sample  -- Nice one to plot
select distinct YEAR_ID from PortfolioProject.dbo.sales_data_sample
select distinct PRODUCTLINE from PortfolioProject.dbo.sales_data_sample  -- Nice to plot
select distinct COUNTRY from PortfolioProject.dbo.sales_data_sample  -- Nice to plot
select distinct DEALSIZE from PortfolioProject.dbo.sales_data_sample  -- Nice to plot
select distinct TERRITORY from PortfolioProject.dbo.sales_data_sample  -- Nice to plot

select distinct MONTH_ID from PortfolioProject.dbo.sales_data_sample
where YEAR_ID = 2005



-- ANALYSIS
-- Grouping sales by productline

select PRODUCTLINE, sum(SALES) as Revenue
from PortfolioProject.dbo.sales_data_sample
group by PRODUCTLINE
order by 2 desc


-- Grouping sales by year

select YEAR_ID, sum(SALES) as Revenue
from PortfolioProject.dbo.sales_data_sample
group by YEAR_ID
order by 2 desc


-- Grouping sales by dealsize

select DEALSIZE, sum(SALES) as Revenue
from PortfolioProject.dbo.sales_data_sample
group by DEALSIZE
order by 2 desc


-- What was the best month for sales in a specific year? How much was earned that month?

select MONTH_ID, sum(SALES) as Revenue, count(ORDERNUMBER) as Frequency
from PortfolioProject.dbo.sales_data_sample
where YEAR_ID = 2003 -- change year to see the rest
group by MONTH_ID
order by 2 desc


-- November seems to be the month, what product do they sell the most in that month? (Classic cars)

select MONTH_ID, PRODUCTLINE, sum(SALES) as Revenue, count(ORDERNUMBER) as Frequency
from PortfolioProject.dbo.sales_data_sample
where YEAR_ID = 2003 and MONTH_ID = 11 -- change year to see the rest
group by MONTH_ID, PRODUCTLINE
order by 3 desc


-- Who is our best customer? (Using the RFM analysis)

DROP TABLE IF EXISTS #rfm
;with rfm as
(
	select
		CUSTOMERNAME,
		sum(sales) as MonetaryValue,
		avg(sales) as AvgMonetaryValue,
		count(ORDERNUMBER) as Frequency,
		max(ORDERDATE) as last_order_date,
		(select max(ORDERDATE) from PortfolioProject.dbo.sales_data_sample) as max_order_date,
		DATEDIFF(DD, max(ORDERDATE), (select max(ORDERDATE) from PortfolioProject.dbo.sales_data_sample)) as Recency
	from PortfolioProject.dbo.sales_data_sample
	group by CUSTOMERNAME
),
rfm_calc as
(

select r.*,
	NTILE(4) OVER (order by Recency desc) as rfm_recency,
	NTILE(4) OVER (order by Frequency) as rfm_frequency,
	NTILE(4) OVER (order by MonetaryValue) as rfm_monetary
from rfm r
)
select 
	c.*, rfm_recency+rfm_frequency+rfm_monetary as rfm_cell,
	cast(rfm_recency as varchar) + cast(rfm_frequency as varchar) + cast(rfm_monetary as varchar) as rfm_cell_string
into #rfm
from rfm_calc as c


select CUSTOMERNAME, rfm_recency, rfm_frequency, rfm_monetary,
	case
		when rfm_cell_string in (111, 112, 121, 122, 123, 132, 211, 212, 114, 141) then 'lost customer' --lost customers
		when rfm_cell_string in (133, 134, 143, 234, 244, 334, 343, 344, 144) then 'slipping away, cannot lose' --(Big spenders who haven't purchased recently)
		when rfm_cell_string in (311, 411, 331, 412, 421) then 'new customers' 
		when rfm_cell_string in (221, 222, 223, 232, 233, 322) then 'potential churners' 
		when rfm_cell_string in (323, 333, 321, 422, 423, 332, 432) then 'active' --(Customers who buy often & recently, but at low price points)
		when rfm_cell_string in (433, 434, 443, 444) then 'loyal' 
	end ref_segment

from #rfm



-- What products are most often sold together?
-- select * from PortfolioProject.dbo.sales_data_sample where ORDERNUMBER = 10411

select distinct ORDERNUMBER, stuff(

	(select ',' + PRODUCTCODE
	from PortfolioProject.dbo.sales_data_sample as p
	where ORDERNUMBER in 
		(

			select ORDERNUMBER
			from(
				select ORDERNUMBER, count(*) as rn
				from PortfolioProject.dbo.sales_data_sample
				where STATUS = 'shipped'
				group by ORDERNUMBER
			) as m
			where rn = 3
		)
		and p.ORDERNUMBER = s.ORDERNUMBER
		for xml path (''))
		, 1, 1, '') as ProductCodes

from PortfolioProject.dbo.sales_data_sample as s
order by 2 desc



