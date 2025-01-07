-- AIRBNB DATA ANALYSIS QUERIES

-- 1. Basic Summary Statistics

-- Retrieve the total number of listings available on Airbnb.
SELECT COUNT(*) AS total_listings FROM listings;

-- Find the average price of listings across all neighborhoods.
SELECT ROUND(AVG(CAST(REPLACE(price, '$', '') AS DECIMAL(10, 2))), 2) AS avg_price FROM listings;

-- Count the number of listings available for each property type (e.g., apartment, house).
SELECT property_type, COUNT(*) AS total_listings 
FROM listings 
GROUP BY property_type 
ORDER BY total_listings DESC;

-- List the top 5 most expensive listings along with their names, neighborhood, and price.
SELECT name, neighbourhood, CAST(REPLACE(price, '$', '') AS DECIMAL(10, 2)) AS price 
FROM listings 
ORDER BY price DESC 
LIMIT 5;

-- List the top 5 least expensive listings along with their names, neighborhood, and price.
SELECT name, neighbourhood, CAST(REPLACE(price, '$', '') AS DECIMAL(10, 2)) AS price 
FROM listings 
ORDER BY price ASC 
LIMIT 5;

-- 2. Neighborhood Insights

-- Find the average price of listings by neighborhood and sort in descending order.
SELECT neighbourhood, ROUND(AVG(CAST(REPLACE(price, '$', '') AS DECIMAL(10, 2))), 2) AS avg_price 
FROM listings 
GROUP BY neighbourhood 
ORDER BY avg_price DESC;

-- Count the number of listings in each neighborhood and calculate the average price per neighborhood.
SELECT neighbourhood, COUNT(id) AS total_listings, ROUND(AVG(CAST(REPLACE(price, '$', '') AS DECIMAL(10, 2))), 2) AS avg_price 
FROM listings 
GROUP BY neighbourhood 
ORDER BY total_listings DESC;

-- 3. Availability Analysis

-- Calculate the percentage of listings that are available for the entire year.
SELECT 
    ROUND((COUNT(id) * 100.0) / (SELECT COUNT(*) FROM listings), 2) AS percentage_available_full_year 
FROM listings 
WHERE availability_365 = 365;

-- Identify the listings with the highest availability for the maximum number of days.
SELECT id, availability_365 
FROM listings 
ORDER BY availability_365 DESC 
LIMIT 10;

-- How many listings are available for a minimum of 15 days in a given month?
SELECT listing_id, EXTRACT(MONTH FROM date) AS month, COUNT(*) AS available_days 
FROM calendar 
WHERE available = 't' 
GROUP BY listing_id, month 
HAVING COUNT(*) >= 15 
ORDER BY month, available_days DESC;

-- 4. Correlation Analysis

-- Find the correlation between price and the number of bedrooms.
SELECT 
    (COUNT(*) * SUM(CAST(REPLACE(price, '$', '') AS DECIMAL(10, 2)) * bedrooms) - 
     SUM(CAST(REPLACE(price, '$', '') AS DECIMAL(10, 2))) * SUM(bedrooms)) /
    SQRT((COUNT(*) * SUM(POWER(CAST(REPLACE(price, '$', '') AS DECIMAL(10, 2)), 2)) - 
          POWER(SUM(CAST(REPLACE(price, '$', '') AS DECIMAL(10, 2))), 2)) * 
         (COUNT(*) * SUM(POWER(bedrooms, 2)) - POWER(SUM(bedrooms), 2))) AS correlation 
FROM listings;

-- 5. Room Type Insights

-- Calculate the percentage of listings for each room type.
SELECT 
    room_type, 
    ROUND((COUNT(id) * 100.0) / (SELECT COUNT(*) FROM listings), 2) AS percentage 
FROM listings 
GROUP BY room_type;

-- For each room type, calculate the average price and availability.
SELECT 
    room_type, 
    has_availability, 
    ROUND(AVG(CAST(REPLACE(price, '$', '') AS DECIMAL(10, 2))), 2) AS avg_price 
FROM listings 
GROUP BY room_type, has_availability;

-- 6. Review Insights

-- Retrieve the listing name, host name, price, and corresponding review comments.
SELECT 
    l.name AS listing_name, 
    l.host_name, 
    l.price, 
    r.comments 
FROM listings l
JOIN reviews r 
ON l.id = r.listing_id;

-- 7. Calendar Analysis

-- List all available dates and corresponding prices for listings.
SELECT 
    c.date, 
    l.price 
FROM calendar c
JOIN listings l 
ON c.listing_id = l.id 
WHERE c.available = 't';

-- Calculate the average availability per listing over the course of a year.
SELECT 
    EXTRACT(YEAR FROM date) AS year, 
    ROUND(AVG(CASE WHEN available = 't' THEN 1 ELSE 0 END), 2) AS avg_availability 
FROM calendar 
GROUP BY year 
ORDER BY year;

-- Find the listings that have the most availability in a given month.
SELECT 
    listing_id, 
    EXTRACT(MONTH FROM date) AS month, 
    COUNT(*) AS total_available_days 
FROM calendar 
WHERE available = 't' 
GROUP BY listing_id, month 
ORDER BY month, total_available_days DESC;

-- Retrieve listing details along with their reviews to analyze customer feedback for specific listings.
SELECT 
    l.name AS listing_name, 
    l.host_name, 
    l.price, 
    r.comments 
FROM listings l
JOIN reviews r 
ON l.id = r.listing_id
ORDER BY l.name;

-- Count the total number of reviews for each listing to identify popular listings.
SELECT 
    l.id AS listing_id, 
    l.name AS listing_name, 
    COUNT(r.id) AS total_reviews 
FROM listings l
LEFT JOIN reviews r 
ON l.id = r.listing_id 
GROUP BY l.id, l.name
ORDER BY total_reviews DESC;

-- Rank listings based on the number of reviews in each neighborhood to identify the most reviewed properties.
SELECT *
FROM (
    SELECT 
        l.neighbourhood, 
        l.name AS listing_name, 
        COUNT(r.id) AS total_reviews, 
        ROW_NUMBER() OVER (PARTITION BY l.neighbourhood ORDER BY COUNT(r.id) DESC) AS row_num 
    FROM listings l
    LEFT JOIN reviews r 
    ON l.id = r.listing_id 
    GROUP BY l.neighbourhood, l.name
) subquery 
WHERE row_num = 1
ORDER BY neighbourhood;

-- List all available dates and corresponding prices for each listing to analyze trends in pricing.
SELECT 
    c.date, 
    l.name AS listing_name, 
    l.price 
FROM calendar c
JOIN listings l 
ON c.listing_id = l.id 
WHERE c.available = 't'
ORDER BY c.date;

-- Find the total availability for each listing over a year to understand their price-performance ratio.
SELECT 
    l.id AS listing_id, 
    l.name AS listing_name, 
    COUNT(c.date) AS total_available_days 
FROM listings l
JOIN calendar c 
ON l.id = c.listing_id 
WHERE c.available = 't' 
GROUP BY l.id, l.name 
ORDER BY total_available_days DESC;

-- Rank listings based on price within each neighborhood to identify premium listings.
SELECT 
    id AS listing_id, 
    neighbourhood, 
    name AS listing_name, 
    CAST(REPLACE(price, '$', '') AS DECIMAL(10, 2)) AS price, 
    RANK() OVER (PARTITION BY neighbourhood ORDER BY CAST(REPLACE(price, '$', '') AS DECIMAL(10, 2)) DESC) AS price_rank 
FROM listings
ORDER BY neighbourhood, price_rank;

-- Calculate the rolling average price of listings in a neighborhood to observe trends.
SELECT 
    neighbourhood, 
    name AS listing_name, 
    CAST(REPLACE(price, '$', '') AS DECIMAL(10, 2)) AS price, 
    AVG(CAST(REPLACE(price, '$', '') AS DECIMAL(10, 2))) OVER (PARTITION BY neighbourhood ORDER BY CAST(REPLACE(price, '$', '') AS DECIMAL(10, 2))) AS rolling_avg_price 
FROM listings
ORDER BY neighbourhood, price;

-- Calculate the percentage of days each listing is available over the year.
SELECT 
    l.id AS listing_id, 
    l.name AS listing_name, 
    ROUND(100.0 * COUNT(c.date) / 365, 2) AS availability_percentage 
FROM listings l
JOIN calendar c 
ON l.id = c.listing_id 
WHERE c.available = 't'
GROUP BY l.id, l.name
ORDER BY availability_percentage DESC;

-- List all available dates and prices by listing for seasonal analysis.
SELECT 
    c.listing_id, 
    c.date, 
    l.price 
FROM calendar c
JOIN listings l 
ON c.listing_id = l.id
WHERE c.available = 't'
ORDER BY c.listing_id, c.date;

-- Rank listings by availability within each month to identify the most available listings for short-term planning.
SELECT *
FROM (
    SELECT 
        c.listing_id, 
        EXTRACT(MONTH FROM c.date) AS month, 
        COUNT(c.date) AS total_available_days, 
        RANK() OVER (PARTITION BY EXTRACT(MONTH FROM c.date) ORDER BY COUNT(c.date) DESC) AS rank_by_month 
    FROM calendar c 
    WHERE c.available = 't' 
    GROUP BY c.listing_id, EXTRACT(MONTH FROM c.date)
) subquery 
WHERE rank_by_month = 1
ORDER BY month;

-- Calculate the cumulative availability of listings across the year for yearly trends.
SELECT 
    listing_id, 
    EXTRACT(YEAR FROM date) AS year, 
    SUM(CASE WHEN available = 't' THEN 1 ELSE 0 END) OVER (PARTITION BY listing_id ORDER BY EXTRACT(YEAR FROM date)) AS cumulative_availability 
FROM calendar
ORDER BY listing_id, year;

-- Calculate the total number of listings and their average price by room type within each neighborhood.
SELECT 
    neighbourhood, 
    room_type, 
    COUNT(id) AS total_listings, 
    AVG(CAST(REPLACE(price, '$', '') AS DECIMAL(10, 2))) AS avg_price 
FROM listings 
GROUP BY neighbourhood, room_type
ORDER BY neighbourhood, avg_price DESC;

-- Calculate the percentage of listings by room type in each neighborhood.
SELECT 
    neighbourhood, 
    room_type, 
    COUNT(*) AS total_listings, 
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY neighbourhood), 2) AS percentage 
FROM listings 
GROUP BY neighbourhood, room_type
ORDER BY neighbourhood, percentage DESC;
