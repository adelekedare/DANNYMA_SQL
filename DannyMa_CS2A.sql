A. Pizza Metrics

--How many pizzas were ordered?
SELECT
    COUNT(order_id) AS ordered_pizza
FROM
    customer_orders

--How many unique customer orders were made?
SELECT
    COUNT(DISTINCT order_id) as customer_orders
from
    customer_orders;

--How many successful orders were delivered by each runner?
SELECT
    runner_id,
    COUNT(order_id) delivered
from
    runner_orders
WHERE pickup_time <> 'null'
GROUP by runner_id;

--How many of each type of pizza was delivered?
SELECT
    CAST(piz.pizza_name AS NVARCHAR(50)) Pizza_type,
    COUNT(cu.pizza_id) pizza_delivered
from
    runner_orders ro
    inner JOIN customer_orders cu ON ro.order_id = cu.order_id
    INNER JOIN pizza_names piz ON piz.pizza_id = cu.pizza_id
WHERE pickup_time <> 'null'
GROUP by CAST(piz.pizza_name AS NVARCHAR(50));

--How many Vegetarian and Meatlovers were ordered by each customer?
SELECT
    customer_id,
    CAST(piz.pizza_name AS NVARCHAR(50)) Pizza_type,
    COUNT(order_id) AS ordered_pizza
FROM
    customer_orders cu
    INNER JOIN pizza_names piz ON piz.pizza_id = cu.pizza_id
GROUP by CAST(piz.pizza_name AS NVARCHAR(50)),customer_id;

--What was the maximum number of pizzas delivered in a single order?
SELECT
    TOP 1
    order_id,
    COUNT(pizza_id) pizza_delivered
FROM
    customer_orders
GROUP BY order_id
ORDER BY COUNT(pizza_id) desc
;
update customer_orders
 set extras = '0'
 WHERE extras is NULL;
--For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT
    cu.customer_id,
    count(cu.pizza_id) pizz_del,
    CASE
WHEN exclusions  = '0' AND extras = '0' THEN 'No'
WHEN exclusions  > '0' or extras > '0' THEN 'Yes'
else 'None'
 END AS Changes
from
    customer_orders cu
    inner JOIN runner_orders ro ON ro.order_id = cu.order_id
    INNER JOIN pizza_names piz ON piz.pizza_id = cu.pizza_id
WHERE pickup_time <> 'null'
GROUP by cu.customer_id, CASE
WHEN exclusions  = '0' AND extras = '0' THEN 'No'
WHEN exclusions  > '0' or extras > '0' THEN 'Yes'
else 'None'
 END
;

--How many pizzas were delivered that had both exclusions and extras?
SELECT
    count(cu.pizza_id) pizz_del,
    CASE
WHEN exclusions  != '0' AND extras != '0' THEN 'Yes'
else 'No'
 END AS Both_Changes
from
    customer_orders cu
    inner JOIN runner_orders ro ON ro.order_id = cu.order_id
    INNER JOIN pizza_names piz ON piz.pizza_id = cu.pizza_id
WHERE pickup_time <> 'null'
GROUP by  CASE
WHEN exclusions  != '0' AND extras != '0' THEN 'Yes'
else 'No'
 END
;
--What was the total volume of pizzas ordered for each hour of the day?
SELECT
    DATEPART(hour,order_time) HOURS,
    COUNT(pizza_id) AS ordered_pizza
FROM
    customer_orders
GROUP BY DATEPART(hour,order_time)
ORDER BY ordered_pizza desc;
--What was the volume of orders for each day of the week?
SELECT
    DATENAME(WEEKDAY, order_time) AS Days,
    COUNT(pizza_id) AS ordered_pizza
FROM
    customer_orders
GROUP BY DATENAME(WEEKDAY, order_time)
ORDER BY ordered_pizza DESC;
--B. Runner and Customer Experience

--How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
SELECT DATEPART(WEEK,registration_date) AS Week_Numbers,COUNT(runner_id) AS Runners
from dbo.runners
WHERE registration_date >= '2021-01-01'
GROUP BY DATEPART(WEEK,registration_date)
ORDER BY Week_Numbers ;
--What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
SELECT
            runner_id,
             --CAST(pickup_time AS datetime) pick_up,
            AVG(DATEDIFF(MINUTE,order_time,CAST(pickup_time AS datetime))) AvgTime_diff
        FROM
            runner_orders ro
            INNER JOIN customer_orders co on ro.order_id=co.order_id
        WHERE pickup_time != 'null'
        GROUP BY runner_id;
--Is there any relationship between the number of pizzas and how long the order takes to prepare?
WITH
    NOP
    AS

    (
        SELECT
            co.order_id,
            COUNT(pizza_id) AS number_pizza,
            MAX(DATEDIFF(MINUTE,order_time,CAST(pickup_time AS datetime))) prep_time
        FROM
            runner_orders ro
            INNER JOIN customer_orders co on ro.order_id=co.order_id
        WHERE pickup_time != 'null'
        GROUP BY co.order_id--,(DATEDIFF(MINUTE,order_time,CAST(pickup_time AS datetime)))
    )
SELECT
    number_pizza,
    AVG(prep_time) Avg_preptime
FROM
    NOP
GROUP BY number_pizza;
--What was the average distance travelled for each customer?
SELECT
    customer_id,
    ROUND(AVG(CAST(REPLACE(distance,'km','')AS float)),2) distance
FROM
    runner_orders ro
    INNER JOIN customer_orders co ON ro.order_id=co.order_id
WHERE pickup_time != 'null'
GROUP BY customer_id
--What was the difference between the longest and shortest delivery times for all orders?
SELECT
    CAST( MAX(duration) AS INT) - CAST(MIN(duration) AS INT) time_diff
FROM
    runner_orders
WHERE duration != 0;
--What was the average speed for each runner for each delivery and do you notice any trend for these values?
SELECT
    runner_id,
    order_id,
    --CAST(REPLACE(distance,'km','')AS float) distance,
    --CAST((duration) AS INT) duration ,
    AVG( ROUND((CAST(REPLACE(distance,'km','')AS float) /
CAST((duration) AS INT) ),2)) speed
FROM
    runner_orders
WHERE duration != 0
GROUP BY runner_id,order_id
ORDER BY runner_id,order_id;
--What is the successful delivery percentage for each runner?
SELECT
    runner_id,
    SUM(CASE 
        WHEN pickup_time = 'null' THEN 0
        ELSE 1
END)
 AS succesful_del,
    COUNT(order_id) all_orders,
    ROUND(CAST(SUM(CASE 
        WHEN pickup_time = 'null' THEN 0
        ELSE 1
END)AS decimal) / COUNT(order_id)*100,2) as percen


FROM
    runner_orders
GROUP BY runner_id


C. Ingredient Optimisation

What are the standard ingredients for each pizza?
SELECT
    COUNT(DISTINCT pizza_id) pizza_id ,
    CAST(topping_name as varchar(MAX)) topping_name
from
    pizza_recipes pr 
CROSS APPLY STRING_SPLIT((CAST(toppings AS VARCHAR(MAX))) , ',') as S
    INNER JOIN pizza_toppings pt on pt.topping_id= S.[value]
GROUP BY CAST(topping_name as varchar(MAX))
ORDER BY pizza_id
-- What was the most commonly added extra?
SELECT TOP 1
    COUNT( pizza_id) pizza ,
    CAST(topping_name as varchar(MAX)) added_extras
FROM
    customer_orders
CROSS APPLY STRING_SPLIT(extras , ',') as S
    INNER JOIN pizza_toppings pt on pt.topping_id= S.[value]
WHERE extras != '0'
GROUP BY CAST(topping_name as varchar(MAX))
-- What was the most common exclusion?
SELECT TOP 1
    COUNT( pizza_id) pizza ,
    CAST(topping_name as varchar(MAX)) common_exclusiom
FROM
    customer_orders
CROSS APPLY STRING_SPLIT(exclusions , ',') as S
    INNER JOIN pizza_toppings pt on pt.topping_id= S.[value]
WHERE extras != '0'
GROUP BY CAST(topping_name as varchar(MAX));

/*Generate an order item for each record in the customers_orders table in the format of one of the following:
Meat Lovers
Meat Lovers - Exclude Beef
Meat Lovers - Extra Bacon
Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
*/

WITH
    EXTRAS
    AS
    
    (
        SELECT
            co.order_id,
            co.pizza_id,
            co.extras,
            STRING_AGG(pt.topping_name ,',') /*WITHIN GROUP (ORDER BY pt.topping_name)*/ added_extra
        FROM
            customer_orders co 
CROSS APPLY (
    select
                distinct
                value
            from
                STRING_SPLIT(extras , ',') as S) S
            INNER JOIN pizza_toppings pt on pt.topping_id= S.[value]
        --WHERE LEN(S.value)> 0 AND S.[value] != '0'
        WHERE extras !='0'
        GROUP BY co.order_id,co.pizza_id,co.extras

    )
,
    EXCLUDED
    AS
    
    (
        SELECT
            co.order_id,
            co.pizza_id,
            co.exclusions,
            STRING_AGG(pt.topping_name ,',') /*WITHIN GROUP (ORDER BY pt.topping_name)*/ excluded
        FROM
            customer_orders co 
CROSS APPLY (
    select
                distinct
                value
            from
                STRING_SPLIT(exclusions , ',') as S) S
            INNER JOIN pizza_toppings pt on pt.topping_id= S.[value]
        --WHERE LEN(S.value)> 0 AND S.[value] != '0'
        WHERE exclusions != '0'
        GROUP BY co.pizza_id,co.order_id,co.exclusions
    )
SELECT
    co.order_id,
    co.pizza_id,
    pn.pizza_name,
    --added_extra,
    --excluded,
    CONCAT (
(CASE WHEN CAST(pn.pizza_name as varchar(MAX)) = 'Meatlovers' THEN 'Meat lovers' else pn.pizza_name END),
(CASE
WHEN added_extra is not null then CONCAT('- Extra ' ,added_extra)
ELSE '' 
END), --as added_extra,

(CASE
WHEN excluded is not null then CONCAT('- Exclude ' ,excluded)
ELSE ''
END)) order_details
--as excluded) 


--co.extras,
--co.exclusions
FROM
    customer_orders co
    LEFT join EXTRAS ext on ext.order_id = co.order_id AND ext.pizza_id =co.pizza_id AND ext.extras=co.extras
    LEFT join EXCLUDED exc on exc.order_id = co.order_id AND exc.pizza_id =co.pizza_id AND exc.exclusions=co.exclusions
    INNER JOIN pizza_names pn on co.pizza_id =pn.pizza_id
WHERE co.extras != '0' or co.exclusions !='0'

/*--Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
D. Pricing and Ratings

If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
What if there was an additional $1 charge for any pizza extras?
Add cheese is $1 extra
The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
customer_id
order_id
runner_id
rating
order_time
pickup_time
Time between order and pickup
Delivery duration
Average speed
Total number of pizzas
If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?
