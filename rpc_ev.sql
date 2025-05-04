create database ev;
select * from dim_date;
select * from `electric_vehicle_sales_by_makers`;
select * from `electric_vehicle_sales_by_state`;
alter table dim_date rename column ï»¿date to date;
alter table electric_vehicle_sales_by_makers rename column ï»¿date to date;
alter table electric_vehicle_sales_by_state rename column ï»¿date to date;
SET SQL_SAFE_UPDATES = 0;
update electric_vehicle_sales_by_makers
set date = STR_TO_DATE(date, '%d-%b-%y')
where date is not null;
update electric_vehicle_sales_by_state
set date = STR_TO_DATE(date, '%d-%b-%y')
where date is not null;
update dim_date
set date = STR_TO_DATE(date, '%d-%b-%y')
where date is not null;

-- List the top 3 and bottom 3 makers for the fiscal years 2023 and 2024 in terms of the number of 2-wheelers sold.

-- top 3 maker 

select maker,sum(electric_vehicles_sold) as total_2_wheeler_sold 
from `dim_makers`
where fiscal_year in (2023,2024)
and vehicle_category ="2-wheelers"
group by maker
order by total_2_wheeler_sold desc
limit 3 ;



-- bottom  3 makers 

select maker,sum(electric_vehicles_sold) as total_2_wheeler_sold 
from `dim_makers`
where fiscal_year in (2023,2024)
and vehicle_category ="2-wheelers"
group by maker
order by total_2_wheeler_sold
limit 3 ;


-- Identify the top 5 states with the highest penetration rate in 2-wheeler and 4-wheeler EV sales in FY 2024.

-- Top 5 states with the highest penetration rate in 2 wheeler 

select state,  
concat(round(sum(electric_vehicles_sold) / sum(total_vehicles_sold) * 100, 2), '%') as penetration_rate  
from `dim_state`  
where fiscal_year = 2024  
and vehicle_category = "2-Wheelers"  
group by state  
order by sum(electric_vehicles_sold) / sum(total_vehicles_sold) desc
limit 5;


select state,  
concat(round(sum(electric_vehicles_sold) / sum(total_vehicles_sold) * 100, 2), '%') as penetration_rate  
from `dim_state`  
where fiscal_year = 2024  
and vehicle_category = "4-Wheelers"  
group by state  
order by sum(electric_vehicles_sold) / sum(total_vehicles_sold) desc
limit 5;

-- List the states with negative penetration (decline) in EV sales from 2022 to 2024?
with pr_2022 as (
    select 
        state, 
        vehicle_category, 
        sum(electric_vehicles_sold) as total_ev_sales_2022,
        sum(total_vehicles_sold) as total_vehicles_sold_2022,
        round(sum(electric_vehicles_sold) / sum(total_vehicles_sold) * 100, 2) as  penetration_rate_2022
    from  dim_state
    where  fiscal_year =2022
    group by state, vehicle_category
),

 pr_2024 as (
    select
        state, 
        vehicle_category, 
        sum(electric_vehicles_sold) as total_ev_sales_2024,
        sum(total_vehicles_sold) as total_vehicles_sold_2024,
        round(sum(electric_vehicles_sold) / sum(total_vehicles_sold) * 100, 2) as penetration_rate_2024
    from dim_state
    where  fiscal_year = 2024
    group by  state, vehicle_category
  )
  
select 
    pr_2022.state,
    pr_2022.vehicle_category,
    pr_2022.total_ev_sales_2022,
    pr_2022.total_vehicles_sold_2022,
    pr_2024.total_ev_sales_2024,
    pr_2024.total_vehicles_sold_2024,
    concat(round(((penetration_rate_2024 - penetration_rate_2022) / penetration_rate_2022) * 100, 2),'%') AS pr_pct
from pr_2022
join pr_2024
    on  pr_2022.state = pr_2024.state
     and pr_2022.vehicle_category = pr_2024.vehicle_category
WHERE 
 ((penetration_rate_2024 - penetration_rate_2022) / penetration_rate_2022) * 100 < 0;
 
 -- What are the quarterly trends based on sales volume for the top 5 EV makers (4-wheelers) from 2022 to 2024?

with  total_sales as (
    select  maker, 
           SUM(total_sales_per_year) as  total_sales_all_years
    from quarterly_sales
    group by  maker
    order by  total_sales_all_years desc
    limit  5
)

select  qs.*
from  quarterly_sales qs
join  total_sales ts on  qs.maker = ts.maker
order  by ts.total_sales_all_years desc , qs.maker, qs.fiscal_year;


-- How do the EV sales and penetration rates in Delhi compare to Karnataka for 2024?
 
 select state, fiscal_year , sum(electric_vehicles_sold) as total_ev_sold , sum(total_vehicles_sold) as total_vehicles,
 concat(round(sum(electric_vehicles_sold)/ sum(total_vehicles_sold)*100,2),'%') as penetration_rate 
 from dim_state 
 where state = 'Delhi'
 and fiscal_year =2024 
 group by fiscal_year, state 
 union 
 select state, fiscal_year , sum(electric_vehicles_sold) as total_ev_sold , sum(total_vehicles_sold) as total_vehicles,
 concat(round(sum(electric_vehicles_sold)/ sum(total_vehicles_sold)*100,2),'%') as penetration_rate
 from dim_state 
 where state = 'Karnataka'
 and fiscal_year =2024 
 group by fiscal_year,state;
 
 -- List down the compounded annual growth rate (CAGR) in 4-wheeler units for the top 5 makers from 2022 to 2024.
with top_makers_2022 AS (
    select maker
    from  quarterly_sales
    where   fiscal_year = 2022
    group by  maker
    order by  sum(total_sales_per_year) desc
    limit 5
)
, sales_2022 AS (
    select maker, sum(total_sales_per_year) AS total_ev_sales_2022
    from quarterly_sales
    where fiscal_year = 2022
    group by maker
)

, sales_2024 AS (
    select  maker, SUM(total_sales_per_year) AS total_ev_sales_2024
    from  quarterly_sales
    where  fiscal_year = 2024
    group by  maker
)
select 
    t.maker,
    s22.total_ev_sales_2022,
    s24.total_ev_sales_2024,
    concat(
        round((power(cast(s24.total_ev_sales_2024 as float ) / s22.total_ev_sales_2022, 1.0 / 2) - 1) * 100, 2),
        '%'
    ) as CAGR_percentage
from 
    top_makers_2022 t
join sales_2022 s22 on t.maker = s22.maker
join sales_2024 s24 on  t.maker = s24.maker
order by total_ev_sales_2024 desc;


-- List down the top 10 states that had the highest compounded annual growth rate (CAGR) from 2022 to 2024 in total vehicles sold.

with total_sales_2022 as(select state , sum( total_vehicles_sold) as total_vehicles_sold_2022 from dim_state
where fiscal_year=2022
group by  state
order by total_vehicles_sold_2022 desc
),

total_sales_2024 as (select state , sum( total_vehicles_sold) as total_vehicles_sold_2024 from dim_state
where fiscal_year=2024
group by  state
order by total_vehicles_sold_2024 desc
),
cagr as (
select  total_sales_2022.state , total_vehicles_sold_2022,total_vehicles_sold_2024,
round(((power(cast(total_vehicles_sold_2024 as float) / total_vehicles_sold_2022, 1.0 / 2)) - 1)*100, 2) AS cagr
from total_sales_2022
join total_sales_2024
on total_sales_2022. state = total_sales_2024.state) 

select cagr.state , total_vehicles_sold_2022,total_vehicles_sold_2024, concat(cagr, '%') as cagr_pct
from cagr
order by cagr desc limit 10 ;

-- What are the peak and low season months for EV sales based on the data from 2022 to 2024?
with 2022_sales as(
select
    month(date) as mnth,
    monthname(date) AS month_name,
    sum(electric_vehicles_sold) AS ev_sales_2022
from dim_makers
where fiscal_year =2022
group by  
    month(date), monthname(date)
order by  ev_sales_2022 DESC),

2023_sales as (
select
    month(date) as mnth,
    monthname(date) as month_name,
    sum(electric_vehicles_sold) as ev_sales_2023
from dim_makers
where fiscal_year =2023
group by  
    month(date), monthname(date)
order by  ev_sales_2023 desc),

2024_sales as (
select
    month(date) as mnth,
    monthname(date) as month_name,
    sum(electric_vehicles_sold) as ev_sales_2024
from dim_makers
where fiscal_year =2024
group by  
    month(date), monthname(date)
order by  ev_sales_2024 desc)

select s_22.mnth, s_22.month_name,s_22.ev_sales_2022,
s_23.ev_sales_2023,s_24.ev_sales_2024 from 2022_sales s_22
join 2023_sales s_23
on s_22.month_name = s_23.month_name
join 2024_sales s_24
on s_23.month_name=s_24.month_name;


-- What is the projected number of EV sales (including 2-wheelers and 4- wheelers) for the top 10 states by penetration rate in 2030, based on the compounded annual growth rate (CAGR) from previous years?


with top10_PR_state as (
    select 
         state,
        round(sum(electric_vehicles_sold) / sum(total_vehicles_sold) * 100, 2) AS penetration_rate,
        sum(case  when fiscal_year = 2022 then electric_vehicles_sold end) AS ev_sales_2022,
        sum(case  when fiscal_year = 2024 then electric_vehicles_sold END) AS ev_sales_2024
    from  dim_state
    group by  state
    order by penetration_rate desc
    limit 10
),
growth_rate as (
    select 
        state,Penetration_rate,
        ev_sales_2022,ev_sales_2024,
        case when EV_sales_2022 > 0 then round((power(ev_sales_2024 / ev_sales_2022, 0.5) - 1) * 100, 2)
		else 0 
        end  as CAGR
    from 
        top10_PR_state
)
select  
    g.state,
    round(g.ev_sales_2024 * power((1 + g.CAGR / 100), (2030 - 2024)) / 1000000, 1) as ev_sales_2030_in_mln
from  growth_rate g
order by ev_sales_2030_in_mln desc;


-- Estimate the revenue growth rate of 4-wheeler and 2-wheelers EVs in India for 2022 vs 2024 and 2023 vs 2024, assuming an average unit price.

with  2022_revenue as (
    select  vehicle_category, revenue as revenue_2022 
    from total_revenue 
    where  fiscal_year = 2022
), 
2023_revenue as (
    select  vehicle_category, revenue as revenue_2023 
    from  total_revenue 
    where  fiscal_year = 2023
), 
2024_revenue AS (
    select  vehicle_category, revenue as revenue_2024 
    from  total_revenue 
    where fiscal_year = 2024
)
select  2022_revenue.vehicle_category, 
    concat(round((revenue_2024 - revenue_2022) / revenue_2022 * 100, 2),'%') AS revenue_22_24,
    concat(round((revenue_2024 - revenue_2023) / revenue_2023 * 100, 2),'%') AS revenue_23_24
from 2022_revenue 
join  2024_revenue
    on  2022_revenue.vehicle_category = 2024_revenue.vehicle_category
join 2023_revenue
    on  2023_revenue.vehicle_category = 2024_revenue.vehicle_category;
    
  

    




    
    
 

 
