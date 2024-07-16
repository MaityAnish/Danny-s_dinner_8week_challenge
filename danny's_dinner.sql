CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');


select * from dannys_diner.menu
	select * from dannys_diner.sales
	   select * from members
---1.What is the total amount each customer spent at the restaurant?
select s.customer_id,sum(m.price)
from sales s join menu m on m.product_id=s.product_id
group by s.customer_id

--or

SELECT customer_id, 
       SUM(price) AS money_spent 
FROM sales 
JOIN menu 
ON menu.product_id = sales.product_id
GROUP BY customer_id

---2.How many days has each customer visited the restaurant?
select customer_id,count(distinct(order_date)) as no_of_customer
from sales
group by customer_id

---3.What was the first item from the menu purchased by each customer?
select distinct(customer_id),product_name from sales s join menu m
	on m.product_id=s.product_id
	where order_date=any
	(select min(order_date)
from sales
group by customer_id)


---4 What is the most purchased item on the menu and how many times was it purchased by all customers?
select count(product_name) as count,
product_name from sales s
join menu m on 
s.product_id=m.product_id
group by product_name order by count desc
limit 1

---5 Which item was the most popular for each customer?
with r as(
SELECT s.customer_id,m.product_name,
        COUNT(s.product_id) as count,
        DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY COUNT(s.product_id) DESC) AS r
FROM menu m 
JOIN sales s 
ON s.product_id = m.product_id
GROUP BY s.customer_id, s.product_id, m.product_name
	)
SELECT customer_id, product_name, count
FROM r
WHERE r = 1
---6. Which item was purchased first by the customer after they became a member?
with r as
(SELECT s.customer_id,
       m.product_name,
    DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS ranks
FROM sales s
JOIN menu m ON s.product_id = m.product_id
JOIN members AS mem
ON mem.customer_id = s.customer_id
WHERE s.order_date >= mem.join_date
)
select * from r
where ranks=1


---7.Which item was purchased just before the customer became a member?
with rank as
	(SELECT s.customer_id,
    s.order_date,
       m.product_name,
    DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS ranks, mem.join_date
FROM sales s
JOIN menu m ON s.product_id = m.product_id
JOIN members AS mem
ON mem.customer_id = s.customer_id
WHERE s.order_date < mem.join_date
)
select * from rank
where ranks=1
---8.What is the total items and amount spent for each member before they became a?

SELECT s.customer_id,
       count(s.product_id) AS total_items, 
       SUM(price) AS money_spent
FROM sales AS s
JOIN menu AS m 
ON m.product_id = s.product_id
JOIN members AS mem 
ON s.customer_id = mem.customer_id
WHERE s.order_date < mem.join_date
GROUP BY s.customer_id


---9.If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have? 

WITH points AS 
(
SELECT *,
    CASE 
    WHEN m.product_name = 'sushi' THEN price * 20
    WHEN m.product_name != 'sushi' THEN price * 10
    END AS points
FROM menu m
    )
SELECT customer_id, SUM(points) AS points
FROM sales s
JOIN points p ON p.product_id = s.product_id
GROUP BY s.customer_id

--10.In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
Select
        s.customer_id
	,Sum(CASE
                 When (DATEDIFF(DAY,me.join_date, s.order_date) between 0 and 7) or (m.product_ID = 1) Then m.price * 20
                 Else m.price * 10
              END) As Points
From members as me
    Inner Join sales as s on s.customer_id = me.customer_id
    Inner Join menu as m on m.product_id = s.product_id
where s.order_date >= me.join_date and s.order_date <= CAST('2021-01-31' AS DATE)
Group by s.customer_id
