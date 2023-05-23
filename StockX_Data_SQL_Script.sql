/*
StockX Sales data Exploration

Skills used: CTEs, Window Functions, Aggregate Functions, Converting Data Types, Unions
Table Creation, and Views
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

#Lets clean the data further by making dates into dates
update sales set order_date = str_to_date(order_date,'%m/%d/%Y');
update sales set release_date = str_to_date(release_date,'%m/%d/%Y');
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

#These queries show avgs of shoes that sell over 500 dollars and profit margins
select sneaker_name, avg(clean_sale) as 'AVG of Sales', 
avg(clean_sale)/avg(clean_retail)*100 as profit_margin 
from sales group by sneaker_name having avg(clean_sale) >= 500 order by 2 desc;


#Regional Data showing where sales go
select distinct region from sales;
select count(distinct region) from sales;

# Lets see which region turned the most profit in the region
select region, round(avg(clean_sale)/avg(clean_retail)*100,2) as 'Avg Region Profit'
from sales group by region order by 2 desc;

#Which state profited the most with a view for later visaulizations
create view regionalSales as
select region, avg(clean_sale) as avg_sale_amt, 
avg(clean_sale)/avg(clean_retail)*100 as avg_profit_margin, 
avg(clean_retail)/avg(clean_sale)*100 as Cost_of_Sales_ratio 
from sales where year(order_date) = 2018 group by region order by 3,2;


select region, sneaker_name, avg(clean_sale) as avg_sale_amt, 
avg(clean_sale)/avg(clean_retail)*100 as avg_profit_margin 
from sales where year(order_date) = 2018 group by region, sneaker_name order by 1,3,2;

select sneaker_name, round(avg(clean_sale)/avg(clean_retail),2)*100 as average_profit_margin
 from sales group by sneaker_name order by 2 desc;
 
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


