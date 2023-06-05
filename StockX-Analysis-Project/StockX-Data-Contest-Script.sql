/* 
This is the compeition part of the StockX sales competition from 2019.
Here are the questions I will be answering.
These questions will be answered from the persepctive of a StockX user
Users buy sneakers then resell them on StockX.

 1) What shoes are most popular?
 2) What shoes have the best/worst profit margins?
 3) What factors affect profit margin?
 4) Is it possible to predict the sale price of a shoe at a given time? (When should I sell?)
 
 Below are some queries to answer this questions at the end I will create views to
 create visualizations in powerBI.
 */
 
 
 #! The Following table and data cleaning was done during my exploration of the data set.
 #! This code is reused from there, no need to reinvent the wheel.

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

#Question 1
create view Question1 as(
with orderTots as(
select sneaker_name, count(*) as total_sales 
from sales group by sneaker_name
order by 2 desc)
select rank() over(order by o.total_sales desc) as 'rank',
o.sneaker_name, o.total_sales
from orderTots as o);

#Question 2 and 3
drop view Question2and3;
create view Question2and3 as(
select region,year(order_date) as yr, month(order_date) as mon,sneaker_name, size,
round(((clean_sale-(clean_retail+(clean_sale*.12)))/clean_sale)*100,2) as profitMargin
from sales group by region,yr,mon,sneaker_name,size);

#Question 4
drop view Question4;
create view Question4 as(
select region,sneaker_name,size,avg(clean_sale-(clean_retail+clean_sale*(.12))) as avgProfit,
year(order_date) yr, month(order_date) mon, 
avg(datediff(order_date,release_date)) daysOut
from sales group by region,sneaker_name,size,yr,mon);










