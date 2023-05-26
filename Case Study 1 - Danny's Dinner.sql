-- CASE STUDY 1 - DANNY'S DINNER

-- 1. What is the total amount each customer spent at the restaurant?

SELECT DISTINCT customer_id, 
		SUM(price) AS total_spent
FROM sales s 
JOIN menu m
	ON s.product_id = m.product_id
GROUP BY customer_id;

-- 2. How many days has each customer visited the restaurant?

SELECT  customer_id, 
	COUNT(DISTINCT order_date) AS days_visited
FROM sales
GROUP BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?

SELECT product_name,  
	customer_id,
	order_date
FROM menu m
JOIN sales s
	ON m.product_id = s.product_id
WHERE order_date = '2021-01-01';

WITH CTE AS (
SELECT s.customer_id,
	product_name,
	order_date,
    rank() over (partition by customer_id order by order_date) AS ranking
FROM menu m
JOIN sales s
ON m.product_id = s.product_id)
SELECT *
FROM CTE
WHERE ranking = 1;

-- 4. What is the most purchased item on the menu and 
-- how many times was it purchased by all customers?

SELECT product_name, 
	COUNT(*) AS most_purchased
FROM menu m
JOIN sales s
	ON m.product_id = s.product_id
GROUP BY Product_name
ORDER BY COUNT(*) desc
LIMIT 1;

-- 5. Which item was the most popular for each customer?

WITH CTE AS (
	SELECT customer_id,
		product_name,
		COUNT(*) AS most_popular,
		rank() over (partition by customer_id order by product_name) AS ranking
	FROM menu m
	JOIN sales s
		ON m.product_id = s.product_id
	GROUP BY customer_id,product_name)
    
SELECT customer_id, product_name
FROM CTE
WHERE ranking = 1;

-- 6. Which item was purchased first by the customer after they became a member?

WITH CTE AS (
	SELECT me.customer_id, 
		m.product_name, 
        order_date, 
        join_date,
		rank() over (partition by customer_id ORDER BY order_date) AS ranking
	FROM sales s
	JOIN members me
		ON s.customer_id = me.customer_id
	JOIN menu m
		ON s.product_id = m.product_id
	WHERE order_date >= join_date)

SELECT customer_id, product_name
FROM CTE
WHERE ranking = 1;

-- 7. Which item was purchased just before the customer became a member?

WITH CTE AS (
	SELECT me.customer_id, 
		m.product_name, 
        order_date, 
        join_date,
		rank() over (partition by customer_id ORDER BY order_date) AS ranking
	FROM sales s
	JOIN members me
		ON s.customer_id = me.customer_id
	JOIN menu m
		ON s.product_id = m.product_id
	WHERE order_date < join_date)

SELECT customer_id, product_name
FROM CTE
WHERE ranking = 1;

-- 8. What is the total items and amount spent for each member before they became a member?

SELECT me.customer_id,
		COUNT(product_name) AS total_item,
        SUM(m.price) AS total_price
FROM sales s
JOIN members me
	ON s.customer_id = me.customer_id
JOIN menu m
	ON s.product_id = m.product_id
WHERE order_date < join_date
GROUP BY me.customer_id;

-- 9. If each $1 spent equates to 10 points and sushi has a 2x points 
-- multiplier - how many points would each customer have?

SELECT customer_id,
	SUM(CASE 
	WHEN product_name = 'sushi' THEN price * 10 * 2
	ELSE price * 10
	END) AS new_price
FROM menu m
JOIN sales s
	ON m.product_id = s.product_id
GROUP BY customer_id;

-- OR 

WITH CTE AS (
	SELECT customer_id, m.product_name, price,
		CASE WHEN product_name = 'sushi' THEN price * 2
		ELSE price END AS new_price
	FROM menu m
	JOIN sales s
		ON m.product_id = s.product_id)
        
SELECT customer_id, 
		SUM(new_price) * 10
FROM CTE
GROUP BY customer_id;

-- 10. In the first week after a customer joins the program (including their join date) 
-- they earn 2x points on all items, not just sushi - how many points do customer A and B 
-- have at the end of January?

WITH CTE AS
(SELECT s. customer_id, m.product_name, m.price,
CASE 
	WHEN product_name = 'sushi' THEN price * 2
    WHEN s.order_date BETWEEN me.join_date 
    AND (me.join_date + interval 6 day) THEN price * 2
	ELSE m.price END AS new_price
FROM menu m
JOIN sales s
ON m.product_id = s.product_id
JOIN members me
ON me.customer_id = s.customer_id
WHERE s.order_date <= '2021-01-31'
)
SELECT customer_id, 
		SUM(new_price) * 10 AS final_price
FROM CTE
GROUP BY customer_id
ORDER BY final_price DESC;

-- BONUS QUESTIONS
-- 1. Join all the things

SELECT s.customer_id, 
		s.order_date, 
        m.product_name, 
        m.price,
        CASE WHEN order_date < join_date 
			 THEN 'N' 
             WHEN join_date IS NULL 
             THEN 'N'
             ELSE 'Y'
             END AS Member
FROM sales s
JOIN menu m
ON s.product_id = m.product_id
LEFT JOIN members me
ON s.customer_id = me.customer_id
ORDER BY s.customer_id, 
		s.order_date, 
        m.price DESC;

-- 2. Rank all the things

WITH CTE AS (
SELECT s.customer_id, 
		s.order_date, 
        m.product_name, 
        m.price,
        CASE WHEN order_date < join_date 
			 THEN 'N' 
             WHEN join_date IS NULL 
             THEN 'N'
             ELSE 'Y'
             END AS Member
FROM sales s
JOIN menu m
ON s.product_id = m.product_id
LEFT JOIN members me
ON s.customer_id = me.customer_id
ORDER BY s.customer_id, 
		s.order_date, 
        m.price DESC)

SELECT *,
	CASE WHEN Member = 'N' THEN NULL
    ELSE
    rank() over (partition by s.customer_id, Member ORDER BY order_date) 
    END AS Ranking
FROM CTE;

