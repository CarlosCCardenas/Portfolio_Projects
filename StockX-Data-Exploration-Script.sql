/*
StockX Sales data Exploration

Skills used: CTEs, Window Functions, Aggregate Functions, Converting Data Types, Unions
Table Creation, and Views

About the Data:
The data is a StockX sales data set from Kaggle. 
It has the sales from late 2017 to early 2019 for Yeezy and Off-White sneakers.
These sneakers are often high ticket items because they are in high demand from sneaker
collectors. StockX is a platform for collectors to buy and sell to each other.
StockX then takes 12% of each transaction to generate profit.
The dataset is in the form of a CSV file with some format issues that need to be 
resolved. For example, the dataset has dollar signs and commas in monetary fields and
sneaker names are separated by "-".
*/


#creating a template to import the CSV file into
/*
create table sales (
order_date varchar(30),
brand varchar(30),
sneaker_name varchar(50),
sale_price varchar(30),
retail_price varchar(30),
release_date varchar(30),
size double,
region varchar(30)
);
*/


#Used to see the progress of the import and determine the number of records
select count(*) from sales;

select * from sales limit 1;

select count(distinct sneaker_name), count(distinct region) from sales;


#Some string formatting to convert into an integer
/*
update sales set sale_price = replace(sale_price, "$","");
update sales set retail_price = replace(retail_price, "$","");
update sales set sale_price = replace(sale_price, ",","");
update sales set retail_price = replace(retail_price, ",","");
*/


/* 
#Creating a new column with integers for manipulation
alter table sales add clean_sale integer;
update sales set clean_sale = sale_price*1;
alter table sales add clean_retail integer;
update sales set clean_retail = retail_price*1;
alter table sales drop column sale_price, retail_price;
alter table sales add column grossProft float;
update sales set grossProft = clean_sale - clean_retail;

#Lets clean the data further by making varchar dates into dates
update sales set order_date = str_to_date(order_date,'%m/%d/%Y');
update sales set release_date = str_to_date(release_date,'%m/%d/%Y');

#Time to clean the Sneaker Names
alter table sales drop column short_name;
alter table sales add column short_name varchar(50);
update sales set short_name = replace(lower(sneaker_name),"adidas-yeezy-boost-","");
update sales set sneaker_name = short_name;
alter table sales drop column short_name;
*/

#Now lets check if any Null values exist
select count(*) from sales
where 
order_date is null or brand is null or sneaker_name is null or sale_price is null or
retail_price is null or release_date is null or size is null or region is null;


#Quick Ad-hoc analysis of the data

select min(order_date), max(order_date) from sales;

# We can see from the query that both Off-White and Yeezy prices declined
select brand, round(avg(clean_sale),2) as average_sale, year(order_date) as 'year' 
from sales group by brand, year(order_date);


#Now lets check the percentages of sales each sneaker made up
select sneaker_name, 
count(sneaker_name)/(select count(*) from sales) *100 as percentage_of_orders
from sales group by sneaker_name order by 2 desc;


#Regional Data showing where sales go
select distinct region from sales;
select count(distinct region) from sales;

# Lets see which region turned the most profit in the region
with regionalP as (select region,sum(clean_sale)-(sum(clean_sale)*(1-.25)) as profit 
from sales group by region)
select region, round(avg(regionalP.profit),0) as 'Avg Region Profit'
from regionalP group by region order by 2 desc;

#Which state profited the most with a view for later visaulizations
create view regionalSales as
with kpis as (
select region, sum(clean_sale) as totalSales,
sum(clean_sale)*(1-.12) as COGS, 
sum(clean_sale)-(sum(clean_sale)*(1-.12)) as profit
from sales
where year(order_date) = 2018
group by region
) 
select region, avg(totalSales) as avg_sale_amt, 
round(avg(profit/totalSales)*100,2) as avg_profit_margin, 
avg(COGS/totalSales)*100 as Cost_of_Sales_ratio 
from kpis group by region order by 3,2;


select region, sneaker_name, avg(clean_sale) as avg_sale_amt
from sales where year(order_date) = 2018 group by region, sneaker_name order by 1,3,2;


 -- Top order dates for each brand
 select ye.* from(
 select sneaker_name, brand, clean_sale, order_date,
 dense_rank() over (partition by brand order by clean_sale desc) 'ranks'
 from sales where brand like '%Yeezy%') as ye
 where ye.ranks <= 5
 union
select nike.* from(
 select sneaker_name, brand, clean_sale, order_date,
 dense_rank() over (partition by brand order by clean_sale desc) 'ranks'
 from sales where brand like '%Off%') as nike
 where nike.ranks <= 5;

#Lets do an analysis on shoe sizes

select avg(size) as avg_shoe_size from sales;

select size, count(size) as no_orders from sales group by size order by size asc; 

select region, avg(size) from sales group by region;

select size, avg(sale_price) from sales group by size order by size asc;

with cte(siz) as (
select size from sales group by size order by count(size) desc limit 1
) select si.* from(
select order_date,brand, sneaker_name, size, sale_price, 
dense_rank() over (partition by size order by sale_price desc) as 'ranks'
from sales) as si, cte 
where si.size = cte.siz and si.ranks <= 10 order by si.ranks;


create view totalAggs as(
select sum(clean_sale) as totalRev, sum(clean_retail) as TotalCOGS,
sum(clean_sale)-sum(clean_retail) as TotalCustomerGrossProfit 
from sales
where year(order_date) = 2018);


create view SneakerSales as(
select region,year(order_date) as year, month(order_date) as month, brand, 
sneaker_name, size, 
sum(clean_sale) as totSales, sum(clean_retail) as COGS,
sum(clean_sale)-sum(clean_retail) as GrossProfit
from sales
where year(order_date) = 2018
group by region,year,month,sneaker_name,size);

with totSales as (
select sum(clean_sale) as totrev, sum(clean_retail) as totcogs from sales)
select region,year(order_date) as year, month(order_date) as month, brand, 
sneaker_name,  
sum(clean_sale) as totSalesMon, sum(retail_price) as COGSMon,
sum(clean_sale)-sum(retail_price) as GrossProfitMon,
(sum(clean_sale)-sum(clean_retail))/sum(clean_sale) as GrossMarginMon,
sum(clean_sale)/totSales.totrev as PercOfTotal
from sales, totSales
where year(order_date) = 2018
group by region,year,month,sneaker_name;


# The views below are to create a data model in Power BI.
# Models there are best served with relational tables.
# These views create those relationships by using distinct values as a primary key.

create view dbrands as(
select distinct brand from sales);

create view ddates as(
select order_date from sales);

create view dsizes as (select distinct size from sales);

create view dsneaker as (select distinct sneaker_name from sales);

create view dregions as(
select distinct region from sales);



