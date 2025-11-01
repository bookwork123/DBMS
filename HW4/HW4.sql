create schema dbms_hw4;
use dbms_hw4;
SET SESSION sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));

-- PRIMARY KEY CONSTRAINTS
ALTER TABLE actor
ADD CONSTRAINT pk_actor PRIMARY KEY (actor_id);

ALTER TABLE address
ADD CONSTRAINT pk_address PRIMARY KEY (address_id);

ALTER TABLE category
ADD CONSTRAINT pk_category PRIMARY KEY (category_id);

ALTER TABLE city
ADD CONSTRAINT pk_city PRIMARY KEY (city_id);

ALTER TABLE country
ADD CONSTRAINT pk_country PRIMARY KEY (country_id);

ALTER TABLE customer
ADD CONSTRAINT pk_customer PRIMARY KEY (customer_id);

ALTER TABLE film
ADD CONSTRAINT pk_film PRIMARY KEY (film_id);

ALTER TABLE film_actor
ADD CONSTRAINT pk_film_actor PRIMARY KEY (actor_id, film_id);

ALTER TABLE film_category
ADD CONSTRAINT pk_film_category PRIMARY KEY (film_id, category_id);

ALTER TABLE inventory
ADD CONSTRAINT pk_inventory PRIMARY KEY (inventory_id);

ALTER TABLE payment
ADD CONSTRAINT pk_payment PRIMARY KEY (payment_id);

ALTER TABLE rental
ADD CONSTRAINT pk_rental PRIMARY KEY (rental_id);

ALTER TABLE staff
ADD CONSTRAINT pk_staff PRIMARY KEY (staff_id);

ALTER TABLE store
ADD CONSTRAINT pk_store PRIMARY KEY (store_id);

-- FOREIGN KEY CONSTRAINTS
-- ADDRESS → CITY
ALTER TABLE address
ADD CONSTRAINT fk_address_city
FOREIGN KEY (city_id) REFERENCES city(city_id);

-- CITY → COUNTRY
ALTER TABLE city
ADD CONSTRAINT fk_city_country
FOREIGN KEY (country_id) REFERENCES country(country_id);

-- CUSTOMER → ADDRESS
ALTER TABLE customer
ADD CONSTRAINT fk_customer_address
FOREIGN KEY (address_id) REFERENCES address(address_id);

-- FILM → LANGUAGE
ALTER TABLE film
ADD CONSTRAINT fk_film_language
FOREIGN KEY (language_id) REFERENCES language(language_id);

-- FILM_ACTOR → ACTOR
ALTER TABLE film_actor
ADD CONSTRAINT fk_film_actor_actor
FOREIGN KEY (actor_id) REFERENCES actor(actor_id);

-- FILM_ACTOR → FILM
ALTER TABLE film_actor
ADD CONSTRAINT fk_film_actor_film
FOREIGN KEY (film_id) REFERENCES film(film_id);

-- FILM_CATEGORY → FILM
ALTER TABLE film_category
ADD CONSTRAINT fk_film_category_film
FOREIGN KEY (film_id) REFERENCES film(film_id);

-- FILM_CATEGORY → CATEGORY
ALTER TABLE film_category
ADD CONSTRAINT fk_film_category_category
FOREIGN KEY (category_id) REFERENCES category(category_id);

-- INVENTORY → FILM
ALTER TABLE inventory
ADD CONSTRAINT fk_inventory_film
FOREIGN KEY (film_id) REFERENCES film(film_id);

-- INVENTORY → STORE
ALTER TABLE inventory
ADD CONSTRAINT fk_inventory_store
FOREIGN KEY (store_id) REFERENCES store(store_id);

-- PAYMENT → CUSTOMER
ALTER TABLE payment
ADD CONSTRAINT fk_payment_customer
FOREIGN KEY (customer_id) REFERENCES customer(customer_id);

-- PAYMENT → STAFF
ALTER TABLE payment
ADD CONSTRAINT fk_payment_staff
FOREIGN KEY (staff_id) REFERENCES staff(staff_id);

-- PAYMENT → RENTAL
ALTER TABLE payment
ADD CONSTRAINT fk_payment_rental
FOREIGN KEY (rental_id) REFERENCES rental(rental_id);

-- RENTAL → INVENTORY
ALTER TABLE rental
ADD CONSTRAINT fk_rental_inventory
FOREIGN KEY (inventory_id) REFERENCES inventory(inventory_id);

-- RENTAL → CUSTOMER
ALTER TABLE rental
ADD CONSTRAINT fk_rental_customer
FOREIGN KEY (customer_id) REFERENCES customer(customer_id);

-- RENTAL → STAFF
ALTER TABLE rental
ADD CONSTRAINT fk_rental_staff
FOREIGN KEY (staff_id) REFERENCES staff(staff_id);

-- STAFF → ADDRESS
ALTER TABLE staff
ADD CONSTRAINT fk_staff_address
FOREIGN KEY (address_id) REFERENCES address(address_id);

-- STAFF → STORE
ALTER TABLE staff
ADD CONSTRAINT fk_staff_store
FOREIGN KEY (store_id) REFERENCES store(store_id);

-- STORE → ADDRESS
ALTER TABLE store
ADD CONSTRAINT fk_store_address
FOREIGN KEY (address_id) REFERENCES address(address_id);

-- OTHER CONSTRAINTS
-- CATEGORY: restrict name values
ALTER TABLE category
ADD CONSTRAINT chk_category_name CHECK (
    name IN ('Animation', 'Comedy', 'Family', 'Foreign', 'Sci-Fi', 'Travel',
             'Children', 'Drama', 'Horror', 'Action', 'Classics', 'Games',
             'New', 'Documentary', 'Sports', 'Music')
);

-- FILM: special features, rating, duration, etc.
ALTER TABLE film
ADD CONSTRAINT chk_film_special_features CHECK (
    special_features IN ('Behind the Scenes', 'Commentaries', 'Deleted Scenes', 'Trailers')
),
ADD CONSTRAINT chk_film_rental_duration CHECK (rental_duration BETWEEN 2 AND 8),
ADD CONSTRAINT chk_film_rental_rate CHECK (rental_rate BETWEEN 0.99 AND 6.99),
ADD CONSTRAINT chk_film_length CHECK (length BETWEEN 30 AND 200),
ADD CONSTRAINT chk_film_rating CHECK (rating IN ('PG', 'G', 'NC-17', 'PG-13', 'R')),
ADD CONSTRAINT chk_film_replacement_cost CHECK (replacement_cost BETWEEN 5.00 AND 100.00);

-- CUSTOMER and STAFF: active flag
ALTER TABLE customer
ADD CONSTRAINT chk_customer_active CHECK (active IN (0, 1));

ALTER TABLE staff
ADD CONSTRAINT chk_staff_active CHECK (active IN (0, 1));

-- PAYMENT: amount nonnegative
ALTER TABLE payment
ADD CONSTRAINT chk_payment_amount CHECK (amount >= 0);

-- RENTAL: ensure valid date order
ALTER TABLE rental
ADD CONSTRAINT chk_rental_dates CHECK (return_date IS NULL OR return_date >= rental_date);

-- QUERY 1: What is the average length of films in each category? List the results in alphabetic order of categories.
SELECT AVG(film.length), category.name
FROM film
JOIN film_category ON film.film_id = film_category.film_id
JOIN category ON film_category.category_id = category.category_id
GROUP BY category.name
ORDER BY category.name ASC;

-- QUERY 2: Which categories have the longest and shortest average film lengths?
WITH avg_category_length AS ( -- CTE for the average length of each category
    SELECT AVG(film.length) AS film_length, category.name AS c_name
    FROM film
    JOIN film_category ON film.film_id = film_category.film_id
    JOIN category ON film_category.category_id = category.category_id
    GROUP BY category.name
)
SELECT film_length, c_name, 'Longest' AS Average_Film_Length -- 1st query finds longest
FROM (
    SELECT film_length, c_name
    FROM avg_category_length
    ORDER BY film_length DESC
    LIMIT 1
) AS longest

UNION -- joins longest and shortest for easier presentation

SELECT film_length, c_name, 'Shortest' AS Average_Film_Length -- 2nd query finds shortest
FROM (
    SELECT film_length, c_name
    FROM avg_category_length
    ORDER BY film_length ASC
    LIMIT 1
) AS shortest;

-- QUERY #3: Which customers have rented action but not comedy or classic movies?
SELECT DISTINCT customer.first_name, customer.last_name
FROM customer
JOIN rental ON customer.customer_id = rental.customer_id
JOIN inventory ON rental.inventory_id = inventory.inventory_id
JOIN film ON inventory.film_id = film.film_id
JOIN film_category ON film.film_id = film_category.film_id
JOIN category ON film_category.category_id = category.category_id
WHERE category.name = "Action" -- filtering for action
	AND (customer.first_name, customer.last_name) NOT IN ( -- subquery filters out comedy and classics
		SELECT DISTINCT customer.first_name, customer.last_name
		FROM customer
		JOIN rental ON customer.customer_id = rental.customer_id
		JOIN inventory ON rental.inventory_id = inventory.inventory_id
		JOIN film ON inventory.film_id = film.film_id
		JOIN film_category ON film.film_id = film_category.film_id
		JOIN category ON film_category.category_id = category.category_id
		WHERE category.name IN ("Comedy", "Classics") -- tuple
    );
    
-- QUERY #4: Which actor has appeared in the most English-language movies?
SELECT actor.actor_id, actor.first_name, actor.last_name, COUNT(film.film_id) AS Number_of_films
FROM actor
JOIN film_actor ON actor.actor_id = film_actor.actor_id
JOIN film ON film_actor.film_id = film.film_id
JOIN `language` ON film.language_id = `language`.language_id -- backticks around language so that mySQL doesn't think its a keyword
WHERE `language`.name = "English"
GROUP BY actor.actor_id
ORDER BY Number_of_films DESC
LIMIT 1;

-- QUERY #5: How many distinct movies were rented for exactly 10 days from the store where Mike works?
SELECT COUNT(DISTINCT film.film_id) AS num_films
FROM rental
JOIN inventory ON rental.inventory_id = inventory.inventory_id
JOIN film ON inventory.film_id = film.film_id
JOIN store ON inventory.store_id = store.store_id
JOIN staff ON store.store_id = staff.store_id
WHERE staff.first_name = "Mike"
	AND DATEDIFF(rental.return_date, rental.rental_date) = 10; -- DATEDIFF function finds difference easily
    
-- QUERY #6: Alphabetically list actors who appeared in the movie with the largest cast of actors.
WITH film_cast_number AS ( -- CTE contains the movie with the biggest cast
	SELECT film_actor.film_id AS movie, COUNT(film_actor.actor_id) AS num_actors
    FROM film_actor
    GROUP BY movie
    ORDER BY num_actors DESC
    LIMIT 1
)
SELECT DISTINCT actor.first_name, actor.last_name
FROM actor
JOIN film_actor ON actor.actor_id = film_actor.actor_id
JOIN film_cast_number ON film_actor.film_id = film_cast_number.movie
ORDER BY actor.last_name, actor.first_name;