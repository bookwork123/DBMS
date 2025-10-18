use dbms_hw_3;

-- The two lines underneath were implemented to fix a specific group by error
SELECT @@sql_mode;
SET SESSION sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));

-- Foreign Key for sell
ALTER TABLE sell
ADD CONSTRAINT fk_sell_merchants
FOREIGN KEY (mid)
REFERENCES merchants (mid);

-- Foreign Key for sell
ALTER TABLE sell
ADD CONSTRAINT fk_sell_products
FOREIGN KEY (pid)
REFERENCES products (pid);

-- Foreign Key for contain
ALTER TABLE contain
ADD CONSTRAINT fk_contain_orders
FOREIGN KEY (oid)
REFERENCES orders (oid);

-- Foreign Key for contain
ALTER TABLE contain
ADD CONSTRAINT fk_contain_products
FOREIGN KEY (pid)
REFERENCES products (pid);

-- Foreign Key for place
ALTER TABLE place
ADD CONSTRAINT fk_place_customers
FOREIGN KEY (cid)
REFERENCES customers (cid);

-- Foreign Key for place
ALTER TABLE place
ADD CONSTRAINT fk_place_orders
FOREIGN KEY (oid)
REFERENCES orders (oid);

-- Constraint checks that product names are valid
ALTER TABLE products
ADD CONSTRAINT chk_product_name
CHECK (name IN ('Printer', 'Ethernet Adapter',
 'Desktop', 'Hard Drive', 'Laptop', 'Router', 'Network Card', 'Super Drive', 'Monitor'));
 
 -- Constraint checks that product categories are valid
ALTER TABLE products
ADD CONSTRAINT chk_product_category
CHECK (category IN ('Peripheral', 'Networking', 'Computer'));

-- Constraint checks that sell prices are valid
ALTER TABLE sell
ADD CONSTRAINT chk_sell_price
CHECK (price BETWEEN 0 AND 100000);

-- Constraint checks that sell.quantity_available is valid
ALTER TABLE sell
ADD CONSTRAINT chk_quantity_available
CHECK (quantity_available BETWEEN 0 AND 1000);

-- Constraint checks that shipping methods are valid
ALTER TABLE orders
ADD CONSTRAINT chk_shipping_method
CHECK (shipping_method IN ('UPS', 'FedEx', 'USPS'));

-- Constraint checks that shipping costs are valid
ALTER TABLE orders
ADD CONSTRAINT chk_shipping_cost
CHECK (shipping_cost BETWEEN 0 AND 500);

-- Constraint checks that order dates are valid
ALTER TABLE place
ADD CONSTRAINT chk_valid_dates
CHECK (order_date >= '2000-01-01' AND order_date <= '2025-01-01');

-- QUERY 1: List names and sellers of products that are no longer available (quantity=0)
SELECT merchants.name AS Company, products.name AS Product, sell.quantity_available
FROM merchants JOIN sell ON merchants.mid = sell.mid
JOIN products ON sell.pid = products.pid
WHERE quantity_available = 0;

-- QUERY 2: List names and descriptions of products that are not sold.
SELECT p.name AS Product, p.description
FROM products p
WHERE p.pid NOT IN ( -- WHERE clause filters against products in contain
	-- Subquery selects products that are in contain, and therefore in customer orders
    SELECT DISTINCT c.pid
    FROM contain c
);

-- QUERY 3: How many customers bought SATA drives but not any routers?
SELECT count(customers.cid) AS Num_Of_Customers
FROM customers
JOIN place ON customers.cid = place.cid
JOIN orders ON place.oid = orders.oid
JOIN contain ON orders.oid = contain.oid
JOIN products ON contain.pid = products.pid
WHERE products.description LIKE '%SATA%' -- Checks if product description includes SATA
	AND customers.cid NOT IN ( -- Filters against subquery results
    SELECT DISTINCT customers.cid -- Queries for customers placing orders on routers
    FROM customers
    JOIN place ON customers.cid = place.cid
    JOIN orders ON place.oid = orders.oid
    JOIN contain ON orders.oid = contain.oid
    JOIN products ON contain.pid = products.pid
    WHERE products.name LIKE '%Router%'
    );

-- QUERY 4: HP has a 20% sale on all its Networking products.
SELECT ROUND(s.price * 0.8) AS "Price (20% Off)", s.price AS "Full Price", m.name AS Company, p.category AS Category
FROM merchants m
JOIN sell s ON m.mid = s.mid
JOIN products p ON s.pid = p.pid
WHERE m.name = "HP" AND Category = "Networking";

-- QUERY 5: What did Uriel Whitney order from Acer? (make sure to at least retrieve product names and prices).
SELECT DISTINCT p.name AS product_name,
       s.price AS price
FROM customers c
JOIN place pl ON c.cid = pl.cid
JOIN contain co ON pl.oid = co.oid
JOIN products p ON co.pid = p.pid
JOIN sell s ON p.pid = s.pid
JOIN merchants m ON s.mid = m.mid
WHERE c.fullname = 'Uriel Whitney'
  AND m.name = 'Acer';


-- QUERY 6: List the annual total sales for each company (sort the results along the company and the year attributes).
-- Assumption: Total Sales equal to the price of products multiplied by the quantity available
SELECT m.name AS company,
       YEAR(pl.order_date) AS year, -- Gets only the year from order_date
       FORMAT(SUM(s.price) * s.quantity_available, 2) AS total_sales -- string formatting for cleaner values
FROM merchants m
JOIN sell s ON m.mid = s.mid
JOIN products p ON s.pid = p.pid
JOIN contain c ON p.pid = c.pid
JOIN orders o ON c.oid = o.oid
JOIN place pl ON o.oid = pl.oid
GROUP BY m.name, YEAR(pl.order_date)
ORDER BY m.name, YEAR(pl.order_date);

-- QUERY 7: Which company had the highest annual revenue and in what year?
-- Assumption: Total Sales/Revenue equal to the price of products multiplied by the quantity available
SELECT m.name AS company,
		YEAR (pl.order_date) AS year, -- Gets only the year from order_date
        ROUND(SUM(s.price), 2) * s.quantity_available AS total_sales -- cleaner values, but no string formatting to prevent number ordering errors
FROM merchants m
JOIN sell s ON m.mid = s.mid
JOIN products p ON s.pid = p.pid
JOIN contain c ON p.pid = c.pid
JOIN orders o ON c.oid = o.oid
JOIN place pl ON o.oid = pl.oid
GROUP BY m.name, YEAR(pl.order_date)
ORDER BY total_sales desc
LIMIT 1; -- Limited instead of subqueried because it is unlikely that there would be ties

-- QUERY 8: On average, what was the cheapest shipping method used ever?
SELECT o.shipping_method, ROUND(AVG(o.shipping_cost), 2) AS avg_shipping_cost
FROM orders o
GROUP BY o.shipping_method
HAVING AVG(o.shipping_cost) = ( -- Filters for average shipping cost equaling subquery value
    SELECT MIN(avg_cost) -- subquery finds minimum average shipping cost for each shipping method
    FROM (
        SELECT AVG(o2.shipping_cost) AS avg_cost
        FROM orders o2
        GROUP BY o2.shipping_method
    ) AS sub
);

-- QUERY 9: What is the best sold ($) category for each company?
WITH totals AS ( -- CTE represents each company's categories and their sale values
  SELECT 
      m.mid,
      m.name AS company,
      p.category,
      ROUND(SUM(s.price), 2) * s.quantity_available AS total_sales
  FROM merchants m
  JOIN sell s ON m.mid = s.mid
  JOIN products p ON s.pid = p.pid
  JOIN contain c ON p.pid = c.pid
  JOIN orders o ON c.oid = o.oid
  JOIN place pl ON o.oid = pl.oid
  GROUP BY m.mid, m.name, p.category
)
SELECT t1.company, t1.category, t1.total_sales
FROM totals t1
WHERE t1.total_sales = ( -- Filters for value equaling a subquery value
    SELECT MAX(t2.total_sales) -- Queries for max sales and checks for matching merchant when doing so
    FROM totals t2
    WHERE t2.mid = t1.mid
)
ORDER BY t1.company;

-- QUERY 10: For each company find out which customers have spent the most and the least amounts.
WITH totals AS ( -- CTE represents each customer and how much they have spent at each merchant
    SELECT 
        m.mid,
        m.name AS company,
        c.fullname AS customer,
        ROUND(SUM(s.price), 2) AS total_spent
    FROM merchants m
    JOIN sell s ON m.mid = s.mid
    JOIN products p ON s.pid = p.pid
    JOIN contain co ON p.pid = co.pid
    JOIN orders o ON co.oid = o.oid
    JOIN place pl ON o.oid = pl.oid
    JOIN customers c ON pl.cid = c.cid
    GROUP BY m.mid, m.name, c.fullname
)

SELECT -- 1st select statement, finds customer who has spent the most at each company
    t1.company,
    t1.customer,
    t1.total_spent,
    'Most Spent' AS spending_type
FROM totals t1
WHERE t1.total_spent = ( -- Filters for value equaling subquery value
    SELECT MAX(t2.total_spent) -- Queries for max total spent and matches by merchant id
    FROM totals t2
    WHERE t2.mid = t1.mid
)

UNION -- UNION merges the two queries for a singular result

SELECT -- 2nd select statement, finds customer who has spent the least at each company
    t1.company,
    t1.customer,
    t1.total_spent,
    'Least Spent' AS spending_type
FROM totals t1
WHERE t1.total_spent = ( -- Filters for value equaling subquery value
    SELECT MIN(t2.total_spent) -- Queries for min total spent and matches by merchant id
    FROM totals t2
    WHERE t2.mid = t1.mid
)

ORDER BY company, spending_type DESC;