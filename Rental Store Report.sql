-- SECTION 1
-- The following code provides information to produce a sales report.
-- Note that the payments run up to 14/02/2006. The last payment before this date
-- was on 23/08/2003.

-- Total global income.
SELECT SUM(amount) AS 'Total Global Income'
FROM sakila.payment;

-- Total income by store.
SELECT co.country AS 'Store', SUM(amount) AS 'Total Income By Store'
FROM sakila.payment p
JOIN sakila.rental r ON p.rental_id = r.rental_id
JOIN sakila.inventory i on r.inventory_id = i.inventory_id
JOIN sakila.store s ON i.store_id = s.store_id -- Joins to store ID to allow you to sort totals by store
JOIN sakila.address a ON s.address_id = a.address_id
JOIN sakila.city c ON a.city_id = c.city_id
JOIN sakila.country co ON c.country_id = co.country_id -- Joins to country table to identify store location.
GROUP BY s.store_id;

-- Global monthly income.
SELECT SUM(amount) 'Global Income February 2006'
FROM sakila.payment p
WHERE CAST(p.payment_date AS DATE) < CAST("2006-03-01" AS DATE) AND CAST(p.payment_date AS DATE) >= CAST("2006-02-01" AS DATE);

-- Monthly income by store.
SELECT co.country AS 'Store', SUM(amount) AS 'Income By Store February 2006'
FROM sakila.payment p
JOIN sakila.rental r ON p.rental_id = r.rental_id
JOIN sakila.inventory i on r.inventory_id = i.inventory_id
JOIN sakila.store s ON i.store_id = s.store_id -- Joins to store ID to allow you to sort totals by store
JOIN sakila.address a ON s.address_id = a.address_id
JOIN sakila.city c ON a.city_id = c.city_id
JOIN sakila.country co ON c.country_id = co.country_id
WHERE CAST(p.payment_date AS DATE) < CAST("2006-03-01" AS DATE) AND CAST(p.payment_date AS DATE) >= CAST("2006-02-01" AS DATE)
GROUP BY s.store_id;

-- Number of monthly transactions.
SELECT COUNT(*) 'Number of Transactions February 2006'
FROM sakila.payment p
WHERE CAST(p.payment_date AS DATE) < CAST("2006-03-01" AS DATE) AND CAST(p.payment_date AS DATE) >= CAST("2006-02-01" AS DATE);

-- Average transaction amount monthly.
SELECT AVG(amount) AS 'Average Transaction Amount February 2006'
FROM sakila.payment p
WHERE CAST(p.payment_date AS DATE) < CAST("2006-03-01" AS DATE) AND CAST(p.payment_date AS DATE) >= CAST("2006-02-01" AS DATE);


-- SECTION 2
-- The following code highlights the top customers.

-- Five highest paying customers monthly.
SELECT concat(c.first_name, ' ', c.last_name) 'Highest Paying Customers February 2006', SUM(p.amount) AS 'Total Paid', co.country 'Store Location', c.email
FROM sakila.payment AS p
JOIN sakila.customer c
JOIN sakila.store s ON c.store_id = s.store_id
JOIN sakila.address a ON s.address_id = a.address_id
JOIN sakila.city ci ON a.city_id = ci.city_id
JOIN sakila.country co ON ci.country_id = co.country_id
WHERE c.customer_id = p.customer_id
AND CAST(p.payment_date AS DATE) < CAST("2006-03-01" AS DATE) AND CAST(p.payment_date AS DATE) >= CAST("2006-02-01" AS DATE)
GROUP BY c.customer_id
ORDER BY SUM(p.amount) DESC
LIMIT 5;

-- Five customers with the highest number of transactions.
SELECT concat(c.first_name, ' ', c.last_name) 'Customers with Highest Number of Transactions February 2006', COUNT(p.amount) AS 'Number of Transactions'
FROM sakila.payment AS p, sakila.customer AS c
WHERE c.customer_id = p.customer_id
AND CAST(p.payment_date AS DATE) < CAST("2006-03-01" AS DATE) AND CAST(p.payment_date AS DATE) >= CAST("2006-02-01" AS DATE)
GROUP BY c.customer_id
ORDER BY COUNT(p.amount) DESC
LIMIT 5;


-- SECTION 3
-- The following code finds the top performing films and film categories.

-- Films with the number of times they have been rented and the total rental income,
-- ordered by most number of times rented.
SELECT f.title, f.release_year, COUNT(r.rental_id) 'Number of Times Rented', SUM(p.amount) 'Total Income by Film'
FROM sakila.film f
JOIN sakila.inventory i ON f.film_id = i.film_id
JOIN sakila.rental r ON i.inventory_id = r.inventory_id
JOIN sakila.payment p ON r.rental_id = p.rental_id
GROUP BY f.film_id
ORDER BY COUNT(r.rental_id) DESC;

-- Films with the number of times they have been rented and the total rental income,
-- ordered by highest total rental income.
SELECT f.title, f.release_year, COUNT(r.rental_id) 'Number of Times Rented', SUM(p.amount) 'Total Income by Film'
FROM sakila.film f
JOIN sakila.inventory i ON f.film_id = i.film_id
JOIN sakila.rental r ON i.inventory_id = r.inventory_id
JOIN sakila.payment p ON r.rental_id = p.rental_id
JOIN sakila.film_category fc ON f.film_id = fc.film_id
JOIN sakila.category cat ON fc.category_id = cat.category_id
GROUP BY f.film_id
ORDER BY SUM(p.amount) DESC;

-- Film categories sorted by the highest total rental income.
SELECT cat.name 'Film Category', SUM(p.amount) 'Total Income by Category'
FROM sakila.film f
JOIN sakila.inventory i ON f.film_id = i.film_id
JOIN sakila.rental r ON i.inventory_id = r.inventory_id
JOIN sakila.payment p ON r.rental_id = p.rental_id
JOIN sakila.film_category fc ON f.film_id = fc.film_id
JOIN sakila.category cat ON fc.category_id = cat.category_id
GROUP BY cat.name
ORDER BY SUM(p.amount) DESC;

-- SECTION 4
-- The following code identifies the current inventory on hand.

-- Create a temporary table with total inventory grouped by film.
CREATE TEMPORARY TABLE total_inventory
SELECT f.title, COUNT(i.inventory_id) inventory
FROM sakila.film f
JOIN sakila.inventory i ON f.film_id = i.film_id
GROUP BY f.title;

-- Create a temporary table with films not yet returned.
CREATE TEMPORARY TABLE not_returned AS
SELECT f.title, COUNT(r.rental_id) not_returned_col
FROM sakila.film f
JOIN sakila.inventory i ON f.film_id = i.film_id
JOIN sakila.rental r ON i.inventory_id = r.inventory_id
WHERE CAST(r.return_date AS DATE) > CAST(CURRENT_DATE AS DATE)
GROUP BY f.title;

-- Calculate inventory on hand using the temporary tables.
SELECT total_inventory.title, total_inventory.inventory - IFNULL(not_returned.not_returned_col, 0) inventory_on_hand
FROM total_inventory
LEFT JOIN not_returned ON total_inventory.title = not_returned.title;