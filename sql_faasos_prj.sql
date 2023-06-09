use sql_prjs;
drop table if exists driver;
CREATE TABLE driver(driver_id integer,reg_date date); 

INSERT INTO driver(driver_id,reg_date) 
 VALUES (1,'2021-01-01'),
(2,'2021-01-03'),
(3,'2021-01-08'),
(4,'2021-01-15');


drop table if exists ingredients;
CREATE TABLE ingredients(ingredients_id integer,ingredients_name varchar(60)); 

INSERT INTO ingredients(ingredients_id ,ingredients_name) 
 VALUES (1,'BBQ Chicken'),
(2,'Chilli Sauce'),
(3,'Chicken'),
(4,'Cheese'),
(5,'Kebab'),
(6,'Mushrooms'),
(7,'Onions'),
(8,'Egg'),
(9,'Peppers'),
(10,'schezwan sauce'),
(11,'Tomatoes'),
(12,'Tomato Sauce');

drop table if exists rolls;
CREATE TABLE rolls(roll_id integer,roll_name varchar(30)); 

INSERT INTO rolls(roll_id ,roll_name) 
 VALUES (1	,'Non Veg Roll'),
(2	,'Veg Roll');

drop table if exists rolls_recipes;
CREATE TABLE rolls_recipes(roll_id integer,ingredients varchar(24)); 

INSERT INTO rolls_recipes(roll_id ,ingredients) 
 VALUES (1,'1,2,3,4,5,6,8,10'),
(2,'4,6,7,9,11,12');

drop table if exists driver_order;
CREATE TABLE driver_order(order_id integer,driver_id integer,pickup_time datetime,distance VARCHAR(7),duration VARCHAR(10),cancellation VARCHAR(23));
INSERT INTO driver_order(order_id,driver_id,pickup_time,distance,duration,cancellation) 
 VALUES(1,1,'2021-01-01 18:15:34','20km','32 minutes',''),
(2,1,'2021-01-01 19:10:54','20km','27 minutes',''),
(3,1,'2021-01-03 00:12:37','13.4km','20 mins','NaN'),
(4,2,'2021-01-04 13:53:03','23.4','40','NaN'),
(5,3,'2021-01-08 21:10:57','10','15','NaN'),
(6,3,null,null,null,'Cancellation'),
(7,2,'2020-01-08 21:30:45','25km','25mins',null),
(8,2,'2020-01-08 00:15:02','23.4 km','15 minute',null),
(9,2,null,null,null,'Customer Cancellation'),
(10,1,'2020-01-11 18:50:20','10km','10minutes',null);


drop table if exists customer_orders;
CREATE TABLE customer_orders(order_id integer,customer_id integer,roll_id integer,not_include_items VARCHAR(4),extra_items_included VARCHAR(4),order_date datetime);
INSERT INTO customer_orders(order_id,customer_id,roll_id,not_include_items,extra_items_included,order_date)
values (1,101,1,'','','2021-01-01  18:05:02'),
(2,101,1,'','','2021-01-01 19:00:52'),
(3,102,1,'','','2021-01-02 23:51:23'),
(3,102,2,'','NaN','2021-01-02 23:51:23'),
(4,103,1,'4','','2021-01-04 13:23:46'),
(4,103,1,'4','','2021-01-04 13:23:46'),
(4,103,2,'4','','2021-01-04 13:23:46'),
(5,104,1,null,'1','2021-01-08 21:00:29'),
(6,101,2,null,null,'2021-01-08 21:03:13'),
(7,105,2,null,'1','2021-01-08 21:20:29'),
(8,102,1,null,null,'2021-01-09 23:54:33'),
(9,103,1,'4','1,5','2021-01-10 11:22:59'),
(10,104,1,null,null,'2021-01-11 18:34:49'),
(10,104,1,'2,6','1,4','2021-01-11 18:34:49');

select * from customer_orders;
select * from driver_order;
select * from ingredients;
select * from driver;
select * from rolls;
select * from rolls_recipes;

# 1. how many rolls were order?
select count(roll_id) from customer_orders;

#2. how many unique customers order?
select count(distinct customer_id) from customer_orders;

#3. how many orders were deliver by driver?
select driver_id, count(order_id) from driver_order where cancellation not in ('Cancellation','Customer Cancellation')
group by driver_id;

#4. how many sucessful delivery were made?
select * from driver_order where cancellation not in ('Cancellation','Customer Cancellation') ;
select * from
(select *, case when cancellation in ('Cancellation','Customer Cancellation') then 'c' else 'nc' 
end as order_cancel_details from driver_order)a
where order_cancel_details='nc';

#5. how many of each type of roll were deliver?
select roll_id, count(roll_id)from customer_orders where order_id in
(select order_id from
(select *, case when cancellation in ('Cancellation','Customer Cancellation') then 'c' else 'nc' 
end as order_cancel_details from driver_order)a where order_cancel_details='nc') group by roll_id;

#6. how many veg and non veg were order by each customer?
select customer_id,roll_id,count(roll_id) from customer_orders group by customer_id,roll_id;

#7. for each customer, how many delivered rolls have at least 1 change and how many has no change?
drop table if exists  temp_customer_orders;
create table temp_customer_orders as  
select order_id,customer_id,roll_id,
case when not_include_items is null or not_include_items = '  ' then '0' else not_include_items end as new_not_include_items,
case when extra_items_included is null or extra_items_included = '  ' or extra_items_included = 'Nan' then '0' else extra_items_included end as new_extra_items_included,
order_date from customer_orders;
select * from  temp_customer_orders;

create table temp_driver_order as 
select order_id,driver_id,pickup_time,distance,duration,
case when cancellation in ('Cancellation','Customer Cancellation') then 0 else 1 end as new_cancellation from driver_order;
select * from temp_driver_order;

#select *, case when new_not_include_items='0' and new_extra_items_included = '0' then 'no change' else 'change' end as chg_no_chg from temp_customer_orders
# where in(select * from temp_driver_order where new_cancellation!=0)
 
 #8. what was the number of order for each day of week
 select dow, count(distinct order_id) from
 (select *,dayname(order_date) dow from customer_orders)a group by dow;
 
 #9. what was the avg time in mins it took for a driver to arrive at fasoos hq to pick the order
 select driver_id,sum(diff)/count(order_id) from
 (select * from
 (select *,row_number() over (partition by order_id order by diff) rnk from
 (select c.*,d.driver_id,d.pickup_time,d.distance,d.duration,d.cancellation,timestampdiff(minute,c.order_date,d.pickup_time) as diff
 from customer_orders as c inner join driver_order as d on c.order_id=d.order_id
 where d.pickup_time is not null)a)b where rnk=1)c 
 group by driver_id;
 
 #10. is there any relationship between number of rollls and how long the order takes to prepare?
 select order_id,count(roll_id),sum(diff)/count(roll_id) tym from
 (select c.*,d.driver_id,d.pickup_time,d.distance,d.duration,d.cancellation,timestampdiff(minute,c.order_date,d.pickup_time) as diff
 from customer_orders as c inner join driver_order as d on c.order_id=d.order_id
 where d.pickup_time is not null)a 
 group by order_id;
 
 #11. what was the avg distance travell for each customer?
 select customer_id,sum(distance)/count(order_id) as avg_distance from
(select * from
 (select *,row_number() over (partition by order_id order by diff) rnk from
 (select c.*,d.driver_id,d.pickup_time,convert(trim(replace(lower(d.distance),'km','')),decimal(4,2)),
 d.duration,d.cancellation,timestampdiff(minute,c.order_date,d.pickup_time) as diff
 from customer_orders as c inner join driver_order as d on c.order_id=d.order_id
 where d.pickup_time is not null)a)b where rnk=1)c group by customer_id;
 
# cleaning of distance
 select convert(trim(replace(lower(distance),'km','')),decimal(4,2)) from driver_order;
 

 
 
 