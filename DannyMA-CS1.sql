--What is the total amount each customer spent at the restaurant?
SELECT customer_id,SUM(m.price) amount_spent
from sales AS s 
INNER JOIN menu AS m  on  s.product_id = m.product_id
GROUP BY customer_id;

--How many days has each customer visited the restaurant?
SELECT customer_id, COUNT ( distinct order_date) AS visit
from sales 
GROUP BY customer_id;

--What was the first item from the menu purchased by each customer?

WITH First_purchase AS (
    SELECT customer_id,order_date,product_name,
    RANK() OVER(PARTITION BY customer_id ORDER BY order_date ASC) Rnk,
    ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_date ASC) Rn
    from sales AS s
    INNER JOIN menu as m on s.product_id = m.product_id
)
SELECT fp.customer_id,fp.product_name
 from First_purchase fp
 WHERE fp.Rn = '1';


--What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT TOP 1 
m.product_name, COUNT(order_date) as orders 
from sales s
INNER JOIN menu as m on s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY orders desc;

--Which item was the most popular for each customer?
WITH CTE AS (
    SELECT  m.product_name,customer_id, COUNT(order_date) as orders ,
    RANK() OVER(PARTITION BY customer_id ORDER BY COUNT(order_date)  DESC ) rank,
    ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY COUNT(order_date)  DESC ) rnk
    from sales s
    INNER JOIN menu as m on s.product_id = m.product_id
    GROUP BY customer_id,product_name
)
SELECT customer_id,product_name 
from CTE
WHERE rank = '1';

--Which item was purchased first by the customer after they became a member?

WITH CTE AS (
    SELECT s.customer_id,order_date,m.product_name,mem.join_date,
        RANK() OVER(PARTITION BY s.customer_id ORDER BY order_date ASC ) rank,
        ROW_NUMBER() OVER(PARTITION BY s.customer_id ORDER BY order_date ASC ) rnk
    FROM sales s 
    INNER JOIN menu m on s.product_id = m.product_id
    JOIN members mem on s.customer_id = mem.customer_id
    WHERE order_date >= join_date
)

SELECT customer_id,product_name,order_date
FROM CTE 
WHERE rank = 1 ;

--Which item was purchased just before the customer became a member?
WITH CTE AS (
    SELECT s.customer_id,order_date,m.product_name,mem.join_date,
    RANK() OVER(PARTITION BY s.customer_id ORDER BY order_date  ) rank,
    ROW_NUMBER() OVER(PARTITION BY s.customer_id ORDER BY order_date  ) rnk
    FROM sales s 
    INNER JOIN menu m on s.product_id = m.product_id
    JOIN members mem on s.customer_id = mem.customer_id
    WHERE order_date < join_date
)
SELECT customer_id,product_name,order_date
FROM CTE 
WHERE rank = 1 ;

--What is the total items and amount spent for each member before they became a member?
SELECT  s.customer_id, COUNT(product_name) as total_items,
SUM(price) as amount_spent
from sales s 
INNER JOIN menu m on s.product_id = m.product_id
INNER JOIN members mem on s.customer_id = mem.customer_id
    WHERE order_date < join_date
    GROUP BY s.customer_id

--If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT s.customer_id,
SUM(CASE
    WHEN product_name = 'sushi' THEN price *10 *2
    ELSE price * 10

END) AS points
from sales s
LEFT JOIN menu m on s.product_id = m.product_id
GROUP by customer_id
ORDER BY points DESC;
--In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

SELECT s.customer_id,
SUM (CASE
    WHEN order_date BETWEEN join_date and DATEADD(DAY,6,mem.join_date) then price * 10 * 2
    WHEN product_name = 'sushi' THEN price *10 *2
    ELSE price * 10


END)AS points
FROM menu m 
INNER JOIN sales as s on s.product_id = m.product_id
INNER JOIN members mem on mem.customer_id = s.customer_id
WHERE order_date <= '2021-01-31'
GROUP BY s.customer_id;
