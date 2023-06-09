create database sql_prjs;
use sql_prjs;
drop table if exists goldusers_signup;
CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 
insert into goldusers_signup values(1,"2017-09-22"),(3,"2017-04-21");

drop table if exists users;
CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
 VALUES (1,'2014-09-02'),(2,'2015-01-15'),(3,'2014-04-11');

drop table if exists sales;
CREATE TABLE sales(userid integer,created_date date,product_id integer); 
INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'2017-04-19',2),(3,'2019-12-18',1),(2,'2020-07-20',3),(1,'2019-10-23',2),
(1,'2018-03-19',3),(3,'2016-12-20',2),(1,'2016-11-09',1),(1,'2016-05-20',3),(2,'2017-09-24',1),
(1,'2017-03-11',2),(1,'2016-03-11',1),(3,'2016-11-10',1),(3,'2017-10-07',2),(3,'2016-12-15',2),
(2,'2017-11-08',2),(2,'2018-09-10',3);

drop table if exists product;
CREATE TABLE product(product_id integer,product_name text,price integer); 
INSERT INTO product(product_id,product_name,price) VALUES
(1,'p1',980),(2,'p2',870),(3,'p3',330);

select * from product;
select * from sales;
select * from users;
select * from goldusers_signup;

## 1.what is total sales ?
select s.userid, s.product_id , p.price from sales as s inner join  product as p
on s.product_id=p.product_id;
## 2.sum od total sales?
select s.userid,s.product_id, sum(p.price) from sales as s inner join  product as p
on s.product_id=p.product_id group by userid;d 

## 3. how many days have customer visited zomato?
select userid , count(distinct(created_date)) distinct_sales from sales group by userid; 

## 4. first product purchased by each user?
select * from sales order by userid ,created_date;
select * from
(select *, rank() over(partition by userid order by created_date) rnk from sales) a where rnk = 1;

## 5. most purchased product and how many times it was purchased ?
select product_id, count(product_id)from sales group by product_id order by count(product_id) desc limit 1;

select userid, count(product_id) from sales where product_id=(select product_id 
from sales group by product_id order by count(product_id) desc limit 1) group by userid;

## 6. which is the most fav product of each user?
select userid, product_id,count(product_id) from sales group by userid, product_id;

select * from 
(select * , rank() over(partition by userid order by cnt desc ) rnk from 
(select userid, product_id,count(product_id) cnt from sales group by userid, product_id)a)b where rnk =1;

## 7. what item has purchased first after becomming a member?
select * from
(select a.*, rank() over(partition by userid order by created_date) rnk from
(select s.userid, s.created_date, s.product_id, g.gold_signup_date from sales as s inner join goldusers_signup as g
on s.userid=g.userid and created_date>=gold_signup_date)a)b where rnk = 1;

## 8. which product was purchased by customer before becoming a member?
select * from
(select a.*, rank() over(partition by userid order by created_date desc) rnk from
(select s.userid, s.created_date, s.product_id, g.gold_signup_date from sales as s inner join goldusers_signup as g
on s.userid=g.userid and created_date<=gold_signup_date)a)b where rnk = 1;

##9. what is the total amount spent before becoming gold member?
select userid, count(created_date) order_purchased,sum(price) total_amt from
(select a.*, p.price from
(select s.userid, s.created_date, s.product_id, g.gold_signup_date from sales as s inner join goldusers_signup as g
on s.userid=g.userid and created_date<=gold_signup_date)a inner join product as p on a.product_id=p.product_id)b group by userid;

##10.  if buying each product generates points and each product has different points for eg p1 5rs=1 zomato point,
# p2 10rs=5zomato points and p3 5rs=1zomato point
select userid,sum(total_points)*2.5 total_points_earned from
(select c.*, amt/points as total_points from
(select b.*, case when product_id=1 then 5 when product_id=2 then 2 when product_id=3 then 5 else 0 end as points from
(select a.userid,a.product_id, sum(price) amt from
(select s.*, p.price from sales as s inner join product as p on s.product_id=p.product_id)a
group by userid,product_id)b)c)d group by userid;

## 11. rank all the transaction of the customers?

select *, rank() over (partition by userid order by created_date) rnk from sales;


