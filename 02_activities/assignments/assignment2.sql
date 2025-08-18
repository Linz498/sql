/* ASSIGNMENT 2 */
/* SECTION 2 */

-- COALESCE
/* 1. Our favourite manager wants a detailed long list of products, but is afraid of tables! 
We tell them, no problem! We can produce a list with all of the appropriate details. 

Using the following syntax you create our super cool and not at all needy manager a list:

SELECT 
product_name || ', ' || product_size|| ' (' || product_qty_type || ')'
FROM product

But wait! The product table has some bad data (a few NULL values). 
Find the NULLs and then using COALESCE, replace the NULL with a 
blank for the first problem, and 'unit' for the second problem. 

HINT: keep the syntax the same, but edited the correct components with the string. 
The `||` values concatenate the columns into strings. 
Edit the appropriate columns -- you're making two edits -- and the NULL rows will be fixed. 
All the other rows will remain the same.) */

SELECT
product_name || ', ' || coalesce(product_size, '') || ' (' || coalesce(product_qty_type, 'unit') || ')' AS list_for_manager
FROM product

--Windowed Functions
/* 1. Write a query that selects from the customer_purchases table and numbers each customer’s  
visits to the farmer’s market (labeling each market date with a different number). 
Each customer’s first visit is labeled 1, second visit is labeled 2, etc. 

You can either display all rows in the customer_purchases table, with the counter changing on
each new market date for each customer, or select only the unique market dates per customer 
(without purchase details) and number those visits. 
HINT: One of these approaches uses ROW_NUMBER() and one uses DENSE_RANK(). */

SELECT
	customer_id,
	market_date,
	ROW_NUMBER()OVER(PARTITION BY customer_id ORDER BY market_date ASC)as visit_number
FROM customer_purchases

/* 2. Reverse the numbering of the query from a part so each customer’s most recent visit is labeled 1, 
then write another query that uses this one as a subquery (or temp table) and filters the results to 
only the customer’s most recent visit. */

SELECT customer_id, market_date as most_recent_visit

FROM(

	SELECT
	customer_id,
	market_date,
	ROW_NUMBER()OVER(PARTITION BY customer_id ORDER BY market_date DESC)as visit_number
	FROM customer_purchases

)visits_by_recency

WHERE visit_number = 1

/* 3. Using a COUNT() window function, include a value along with each row of the 
customer_purchases table that indicates how many different times that customer has purchased that product_id. */

/*I found this question worded in a confusing manner, and I am not quite sure what it wants.Translated directly it seems to want to know how many times a customer bought each product, 
and wants this information for each row in the customer_purchases table. That would be annoying
to try and read. To me it makes more sense to see how many times a customer bought each product, without the unique rows.
So I did some options for this one as I could not make office hours this week to clarify what the question
is looking for */

--direct translation of question

SELECT *,
    COUNT(*) OVER (PARTITION BY customer_id, product_id) AS number_of_purchases
FROM customer_purchases

--how I would prefer to read the requested information

SELECT customer_id, product_id, number_of_purchases
FROM (
    SELECT 
        customer_id,
        product_id,
        COUNT(*) OVER (PARTITION BY customer_id, product_id) AS number_of_purchases,
        ROW_NUMBER() OVER (PARTITION BY customer_id, product_id) AS rn
    FROM customer_purchases
) nop
WHERE rn = 1

-- String manipulations
/* 1. Some product names in the product table have descriptions like "Jar" or "Organic". 
These are separated from the product name with a hyphen. 
Create a column using SUBSTR (and a couple of other commands) that captures these, but is otherwise NULL. 
Remove any trailing or leading whitespaces. Don't just use a case statement for each product! 

| product_name               | description |
|----------------------------|-------------|
| Habanero Peppers - Organic | Organic     |

Hint: you might need to use INSTR(product_name,'-') to find the hyphens. INSTR will help split the column. */

SELECT 
	product_name,
	CASE WHEN INSTR(product_name, '-') THEN SUBSTR(product_name, INSTR(product_name, '-') +2)
	ELSE NULL
	END	AS description
FROM product

/* 2. Filter the query to show any product_size value that contain a number with REGEXP. */

SELECT 
	product_name,
	product_size,
	CASE WHEN INSTR(product_name, '-') THEN SUBSTR(product_name, INSTR(product_name, '-') +2)
	ELSE NULL
	END	AS description
FROM product
WHERE product_size REGEXP '[0-9]'

-- UNION
/* 1. Using a UNION, write a query that displays the market dates with the highest and lowest total sales.

HINT: There are a possibly a few ways to do this query, but if you're struggling, try the following: 
1) Create a CTE/Temp Table to find sales values grouped dates; 
2) Create another CTE/Temp table with a rank windowed function on the previous query to create 
"best day" and "worst day"; 
3) Query the second temp table twice, once for the best day, once for the worst day, 
with a UNION binding them. */

--Step 1
-- if a table named temp.sales_value_by_dates exists, delete it, other do NOTHING
DROP TABLE IF EXISTS temp.sales_value_by_dates;

--make the TABLE
CREATE TABLE temp.sales_value_by_dates AS

-- definition of the TABLE

SELECT 
	market_date,
	SUM(quantity*cost_to_customer_per_qty) as total_sales
FROM customer_purchases
	GROUP BY market_date

--Step 2

-- if a table named temp.sales_by_date_ranked, delete it, other do NOTHING
DROP TABLE IF EXISTS temp.sales_by_date_ranked;

--make the TABLE
CREATE TABLE temp.sales_by_date_ranked AS

-- definition of the TABLE

SELECT *
,rank() OVER(ORDER BY total_sales desc) as [rank]
FROM temp.sales_value_by_dates

--Step 3

SELECT *,
	CASE WHEN rank = 1 THEN 'best day'
	END AS performance
FROM temp.sales_by_date_ranked
WHERE rank = 1

UNION

SELECT *,
	CASE WHEN rank = 142 THEN 'worst day'
	END AS performance
FROM temp.sales_by_date_ranked
WHERE rank = 142

/* SECTION 3 */

-- Cross Join
/*1. Suppose every vendor in the `vendor_inventory` table had 5 of each of their products to sell to **every** 
customer on record. How much money would each vendor make per product? 
Show this by vendor_name and product name, rather than using the IDs.

HINT: Be sure you select only relevant columns and rows. 
Remember, CROSS JOIN will explode your table rows, so CROSS JOIN should likely be a subquery. 
Think a bit about the row counts: how many distinct vendors, product names are there (x)?
How many customers are there (y). 
Before your final group by you should have the product of those two queries (x*y).  */

--
/*I do not understand this at all, 
could not wrap my head around any of this let alone why I would even use a cross join here or
how to use a cross join in a subquery, and is it 5 sales of a product to customer per market date or all time???*/

SELECT 
	vi.vendor_id,
	v.vendor_name, 
	vi.product_id, 
	p.product_name, 
	original_price * 5 * (
		SELECT COUNT(DISTINCT customer_id)
		FROM customer
		) AS theoretical_sales_of_5_per_customer
FROM vendor_inventory AS vi
CROSS JOIN customer
JOIN vendor AS v
	ON vi.vendor_id = v.vendor_id
JOIN product AS p
	ON vi.product_id = p.product_id
GROUP BY vi.product_id*/

--playing around without cross join to see if I ended up in a different place, but I ended up in the same place
 
SELECT
  vi.vendor_id,
  v.vendor_name,
  vi.product_id,
  p.product_name,
  original_price * 5 * (
    SELECT COUNT(DISTINCT customer_id)
    FROM customer_purchases
  ) AS theoretical_sales_of_5_per_customer
FROM vendor_inventory AS vi
JOIN vendor AS v
  ON vi.vendor_id = v.vendor_id
JOIN product AS p
  ON vi.product_id = p.product_id
GROUP BY vi.vendor_id, vi.product_id

-- INSERT
/*1.  Create a new table "product_units". 
This table will contain only products where the `product_qty_type = 'unit'`. 
It should use all of the columns from the product table, as well as a new column for the `CURRENT_TIMESTAMP`.  
Name the timestamp column `snapshot_timestamp`. */

--make the TABLE

CREATE TABLE product_units AS

-- definition of the TABLE

SELECT *,
(CURRENT_TIMESTAMP)as snapshot_timestamp
FROM product
WHERE product_qty_type LIKE '%unit%'



/*2. Using `INSERT`, add a new row to the product_units table (with an updated timestamp). 
This can be any product you desire (e.g. add another record for Apple Pie). */

INSERT INTO product_units
VALUES(6, 'Cut Zinnias Bouquet', 'medium', 5, 'unit',CURRENT_TIMESTAMP)


-- DELETE
/* 1. Delete the older record for the whatever product you added. 

HINT: If you don't specify a WHERE clause, you are going to have a bad time.*/

DELETE FROM product_units
WHERE product_id = 6 AND snapshot_timestamp LIKE '%20:11:15%'

-- UPDATE
/* 1.We want to add the current_quantity to the product_units table. 
First, add a new column, current_quantity to the table using the following syntax.

ALTER TABLE product_units
ADD current_quantity INT;

Then, using UPDATE, change the current_quantity equal to the last quantity value from the vendor_inventory details.

HINT: This one is pretty hard. 
First, determine how to get the "last" quantity per product. 
Second, coalesce null values to 0 (if you don't have null values, figure out how to rearrange your query so you do.) 
Third, SET current_quantity = (...your select statement...), remembering that WHERE can only accommodate one column. 
Finally, make sure you have a WHERE statement to update the right row, 
	you'll need to use product_units.product_id to refer to the correct row within the product_units table. 
When you have all of these components, you can run the update statement. */


ALTER TABLE product_units
ADD current_quantity INT

--Attempt 1

WITH ranked_quantity AS (

SELECT
product_id,
quantity,
market_date,
ROW_NUMBER()OVER(PARTITION BY product_id ORDER BY market_date DESC)as recency_rank
FROM vendor_inventory)

SELECT
product_id,
quantity,
market_date,
MIN(recency_rank) as most_recent
FROM ranked_quantity
GROUP BY product_id

--but then I got stuck here trying to add a JOIN to the product table to get NULLS*/

--Attempt 2 
/*rearranged the first attempt to get a JOIN in there so I could get NULLS, but then the rank wasn't working
once I added the JOIN and everything was coming back as NULLS. I really tried but this is above me.*/

WITH ranked_quantity AS (
  SELECT
    product_id,
    quantity,
    market_date,
    ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY market_date DESC) AS recency_rank
  FROM vendor_inventory
)

SELECT
  p.*,
  rq.recency_rank,
  CASE WHEN rq.recency_rank = 1 THEN rq.quantity
  ELSE NULL END AS quantity
FROM product AS p
JOIN ranked_quantity AS rq
  ON p.product_id = rq.product_id



