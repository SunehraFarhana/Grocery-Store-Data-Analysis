-- 1. What is the average price, discount, and rating by sub-category?
SELECT
    sub_category,
    COUNT(*) AS total_products,
    ROUND(AVG(price), 2) AS avg_price,
    ROUND(AVG(discount), 2) AS avg_discount,
    ROUND(AVG(NULLIF(average_rating, 0)), 2) AS avg_rating
FROM grocery_store_schema.grocery_store_dataset_cleaned
GROUP BY sub_category
ORDER BY sub_category;


-- 2. What is the total number of discounted products?
-- Do discounted products receive higher ratings?
SELECT
    CASE
        WHEN discount > 0 THEN 'Discounted'
        ELSE 'Not Discounted'
    END AS discount_status,
    COUNT(*) AS total_products,
    ROUND(AVG(price), 2) AS avg_price,
    ROUND(AVG(NULLIF(average_rating, 0)), 2) AS avg_rating
FROM grocery_store_schema.grocery_store_dataset_cleaned
GROUP BY discount_status;


-- 3. What is the number of discounted products by sub-category?
SELECT
    sub_category,
    COUNT(*) AS total_products,
    SUM(CASE WHEN discount > 0 THEN 1 ELSE 0 END) AS discounted_products
FROM grocery_store_schema.grocery_store_dataset_cleaned
GROUP BY sub_category
ORDER BY discounted_products DESC;


-- 4. What is the total number of products per attribute, by sub-category?
SELECT
    sub_category,
    SUM(is_clean_label) AS clean_label_products,
    SUM(is_eco_friendly) AS eco_friendly_products,
    SUM(is_health_conscious) AS health_conscious_products,
    SUM(is_high_quality) AS high_quality_products,
    SUM(is_plant_based) AS plant_based_products,
    SUM(is_shelf_stable) AS shelf_stable_products,
    SUM(has_religious_certification) AS religious_certification_products,
    COUNT(*) AS total_products
FROM grocery_store_schema.grocery_store_dataset_cleaned
GROUP BY sub_category
ORDER BY sub_category;


-- 5. What is the total number of products per attribute, and its percent of the catalog?
-- What is the average price, discount, and rating by attribute?
SELECT
    attribute,
    COUNT(*) AS product_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*)
		FROM grocery_store_schema.grocery_store_dataset_cleaned),2) AS pct_of_catalog,
    ROUND(AVG(price), 2) AS avg_price,
    ROUND(AVG(discount), 2) AS avg_discount,
    ROUND(AVG(NULLIF(average_rating, 0)), 2) AS avg_rating
FROM (
    SELECT 'is_clean_label' AS attribute, price, discount, average_rating
    FROM grocery_store_schema.grocery_store_dataset_cleaned
    WHERE is_clean_label = 1

    UNION ALL

    SELECT 'is_eco_friendly', price, discount, average_rating
    FROM grocery_store_schema.grocery_store_dataset_cleaned
    WHERE is_eco_friendly = 1

    UNION ALL

    SELECT 'is_health_conscious', price, discount, average_rating
    FROM grocery_store_schema.grocery_store_dataset_cleaned
    WHERE is_health_conscious = 1

    UNION ALL

    SELECT 'is_high_quality', price, discount, average_rating
    FROM grocery_store_schema.grocery_store_dataset_cleaned
    WHERE is_high_quality = 1

    UNION ALL

    SELECT 'is_plant_based', price, discount, average_rating
    FROM grocery_store_schema.grocery_store_dataset_cleaned
    WHERE is_plant_based = 1

    UNION ALL

    SELECT 'is_shelf_stable', price, discount, average_rating
    FROM grocery_store_schema.grocery_store_dataset_cleaned
    WHERE is_shelf_stable = 1

    UNION ALL

    SELECT 'has_religious_certification', price, discount, average_rating
    FROM grocery_store_schema.grocery_store_dataset_cleaned
    WHERE has_religious_certification = 1
) t
GROUP BY attribute
ORDER BY pct_of_catalog DESC;


-- 6. How many products have multiple consumer claims?
-- Do multi-claim products cost more? Do they receive higher ratings?
SELECT
    (is_clean_label
     + is_eco_friendly
     + is_health_conscious
     + is_high_quality
     + is_plant_based
     + is_shelf_stable
     + has_religious_certification) AS claim_count,
    COUNT(*) AS total_products,
    ROUND(AVG(price), 2) AS avg_price,
    ROUND(AVG(NULLIF(average_rating, 0)), 2) AS avg_rating
FROM grocery_store_schema.grocery_store_dataset_cleaned
GROUP BY claim_count
ORDER BY claim_count DESC;


-- 7a. What is the total number of clean label products?
-- Do clean label products cost more? Do they receive higher ratings?
SELECT
    is_clean_label,
    COUNT(*) AS total_products,
    ROUND(AVG(price), 2) AS avg_price,
    ROUND(AVG(NULLIF(average_rating, 0)), 2) AS avg_rating
FROM grocery_store_schema.grocery_store_dataset_cleaned
GROUP BY is_clean_label;


-- 7b. What is the total number of eco-friendly products?
-- Do eco-friendly products cost more? Do they receive higher ratings?
SELECT
    is_eco_friendly,
    COUNT(*) AS total_products,
    ROUND(AVG(price), 2) AS avg_price,
    ROUND(AVG(NULLIF(average_rating, 0)), 2) AS avg_rating
FROM grocery_store_schema.grocery_store_dataset_cleaned
GROUP BY is_eco_friendly;


-- 7c. What is the total number of health conscious products?
-- Do health conscious products cost more? Do they receive higher ratings?
SELECT
    is_health_conscious,
    COUNT(*) AS total_products,
    ROUND(AVG(price), 2) AS avg_price,
    ROUND(AVG(NULLIF(average_rating, 0)), 2) AS avg_rating
FROM grocery_store_schema.grocery_store_dataset_cleaned
GROUP BY is_health_conscious;


-- 7d. What is the total number of high quality products?
-- Do high quality products cost more? Do they receive higher ratings?
SELECT
    is_high_quality,
    COUNT(*) AS total_products,
    ROUND(AVG(price), 2) AS avg_price,
    ROUND(AVG(NULLIF(average_rating, 0)), 2) AS avg_rating
FROM grocery_store_schema.grocery_store_dataset_cleaned
GROUP BY is_high_quality;


-- 7e. What is the total number of plant-based products?
-- Do plant-based products cost more? Do they receive higher ratings?
SELECT
    is_plant_based,
    COUNT(*) AS total_products,
    ROUND(AVG(price), 2) AS avg_price,
    ROUND(AVG(NULLIF(average_rating, 0)), 2) AS avg_rating
FROM grocery_store_schema.grocery_store_dataset_cleaned
GROUP BY is_plant_based;


-- 7f. What is the total number of shelf stable products?
-- Do shelf stable products cost more? Do they receive higher ratings?
SELECT
    is_shelf_stable,
    COUNT(*) AS total_products,
    ROUND(AVG(price), 2) AS avg_price,
    ROUND(AVG(NULLIF(average_rating, 0)), 2) AS avg_rating
FROM grocery_store_schema.grocery_store_dataset_cleaned
GROUP BY is_shelf_stable;

-- 7g. What is the total number of religiously certified products?
-- Do religiously certified products cost more? Do they receive higher ratings?
SELECT
    has_religious_certification,
    COUNT(*) AS total_products,
    ROUND(AVG(price), 2) AS avg_price,
    ROUND(AVG(NULLIF(average_rating, 0)), 2) AS avg_rating
FROM grocery_store_schema.grocery_store_dataset_cleaned
GROUP BY has_religious_certification;