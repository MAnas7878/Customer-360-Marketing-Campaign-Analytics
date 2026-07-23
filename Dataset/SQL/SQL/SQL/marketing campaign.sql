CREATE TABLE marketing_customers (
    customer_id INT PRIMARY KEY,
    year_birth INT,
    education VARCHAR(50),
    marital_status VARCHAR(50),
    income NUMERIC(12,2),
    kidhome INT,
    teenhome INT,
    dt_customer DATE,
    recency INT,
    mnt_wines NUMERIC(10,2),
    mnt_fruits NUMERIC(10,2),
    mnt_meat NUMERIC(10,2),
    mnt_fish NUMERIC(10,2),
    mnt_sweets NUMERIC(10,2),
    mnt_gold NUMERIC(10,2),
    num_deals INT,
    num_web_purchases INT,
    num_catalog_purchases INT,
    num_store_purchases INT,
    num_web_visits INT,
    accepted_cmp1 INT,
    accepted_cmp2 INT,
    accepted_cmp3 INT,
    accepted_cmp4 INT,
    accepted_cmp5 INT,
    response INT,
    complain INT,
    country VARCHAR(50),
    city VARCHAR(50),
    gender VARCHAR(20),
    occupation VARCHAR(50),
    loyalty_years INT,
    customer_type VARCHAR(30),
    preferred_channel VARCHAR(30),
    last_purchase_date DATE,
    annual_spend NUMERIC(12,2),
    total_purchases INT
);

----Current Data Quality---------

---Table schema 
SELECT table_name
FROM information_schema.tables
WHERE table_schema='public';



---count
SELECT COUNT(*)
FROM marketing_customers;

--all
SELECT *
FROM marketing_customers
LIMIT 10;

--– Duplicate Check
SELECT
    customer_id,
    COUNT(*) AS duplicate_count
FROM marketing_customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

--– Missing Income Check
SELECT COUNT(*) AS missing_income
FROM marketing_customers
WHERE income IS NULL;

--– Invalid Birth Year
SELECT *
FROM marketing_customers
WHERE year_birth < 1940
   OR year_birth > EXTRACT(YEAR FROM CURRENT_DATE);

---Total colmuns
SELECT COUNT(*) AS total_columns
FROM information_schema.columns
WHERE table_name = 'marketing_customers';

---– Income Outliers Check
SELECT
    MIN(income) AS min_income,
    MAX(income) AS max_income,
    AVG(income) AS avg_income
FROM marketing_customers;


–--Negative Spending Check
SELECT *
FROM marketing_customers
WHERE mnt_wines < 0
   OR mnt_fruits < 0
   OR mnt_meat < 0
   OR mnt_fish < 0
   OR mnt_sweets < 0
   OR mnt_gold < 0;





   ---– Invalid Dates
   SELECT *
FROM marketing_customers
WHERE last_purchase_date < dt_customer;



-----START DATA CLEANING-----


----Fill to Missing Income
UPDATE marketing_customers
SET income = (
    SELECT ROUND(AVG(income),2)
    FROM marketing_customers
)
WHERE income IS NULL;

--Chaking missing income
SELECT COUNT(*)
FROM marketing_customers
WHERE income IS NULL;


----Negative Spending Fix (0)
UPDATE marketing_customers
SET
    mnt_wines   = GREATEST(mnt_wines,0),
    mnt_fruits  = GREATEST(mnt_fruits,0),
    mnt_meat    = GREATEST(mnt_meat,0),
    mnt_fish    = GREATEST(mnt_fish,0),
    mnt_sweets  = GREATEST(mnt_sweets,0),
    mnt_gold    = GREATEST(mnt_gold,0);
----checking
	SELECT *
FROM marketing_customers
WHERE mnt_wines < 0
   OR mnt_fruits < 0
   OR mnt_meat < 0
   OR mnt_fish < 0
   OR mnt_sweets < 0
   OR mnt_gold < 0;
----Income Outlier Check
   SELECT COUNT(*) AS outlier_count
FROM marketing_customers
WHERE income > 250000;





-----Data Transformation--------

---Age Column
ALTER TABLE marketing_customers
ADD COLUMN age INT;

UPDATE marketing_customers
SET age = EXTRACT(YEAR FROM CURRENT_DATE) - year_birth;


---Income Group

ALTER TABLE marketing_customers
ADD COLUMN income_group VARCHAR(20);

UPDATE marketing_customers
SET income_group =
CASE
    WHEN income < 50000 THEN 'Low'
    WHEN income BETWEEN 50000 AND 100000 THEN 'Middle'
    ELSE 'High'
END;



----Total Children
ALTER TABLE marketing_customers
ADD COLUMN total_children INT;

UPDATE marketing_customers
SET total_children = kidhome + teenhome;


---Customer Value
ALTER TABLE marketing_customers
ADD COLUMN customer_value VARCHAR(20);

UPDATE marketing_customers
SET customer_value =
CASE
    WHEN annual_spend >= 5000 THEN 'High'
    WHEN annual_spend BETWEEN 2500 AND 4999 THEN 'Medium'
    ELSE 'Low'
END;
---Age Group
ALTER TABLE marketing_customers
ADD COLUMN age_group VARCHAR(20);

UPDATE marketing_customers
SET age_group =
CASE
    WHEN age < 30 THEN '18-29'
    WHEN age BETWEEN 30 AND 45 THEN '30-45'
    WHEN age BETWEEN 46 AND 60 THEN '46-60'
    ELSE '60+'
END;
---Total Campaign Accepted
ALTER TABLE marketing_customers
ADD COLUMN total_campaigns_accepted INT;

UPDATE marketing_customers
SET total_campaigns_accepted =
accepted_cmp1 +
accepted_cmp2 +
accepted_cmp3 +
accepted_cmp4 +
accepted_cmp5 +
response;


---Verification
SELECT
age,
age_group,
income_group,
total_children,
customer_value,
total_campaigns_accepted
FROM marketing_customers
LIMIT 10;



-----------(SQL ANALYSIS)---------------

---1 — Total Customers
SELECT COUNT(*) AS total_customers
FROM marketing_customers;


---2 — Total Spending
SELECT SUM(annual_spend) AS total_spending
FROM marketing_customers;


---3 — Average Spending
SELECT ROUND(AVG(annual_spend),2) AS avg_spending
FROM marketing_customers;

---4 — Average Income
SELECT ROUND(AVG(income),2) AS avg_income
FROM marketing_customers;

---5 — Total Purchases
SELECT SUM(total_purchases) AS total_purchases
FROM marketing_customers;

---6 — Complaint Rate
SELECT
ROUND(
SUM(complain)*100.0/COUNT(*),2
) AS complaint_rate
FROM marketing_customers;

---7 — Total Campaign Accepted
SELECT SUM(total_campaigns_accepted)
FROM marketing_customers;


---8 — Campaign Response Rate
SELECT
ROUND(
SUM(response)*100.0/COUNT(*),2
) AS response_rate
FROM marketing_customers;


---9 — Product Spending
SELECT
SUM(mnt_wines) Wines,
SUM(mnt_fruits) Fruits,
SUM(mnt_meat) Meat,
SUM(mnt_fish) Fish,
SUM(mnt_sweets) Sweets,
SUM(mnt_gold) Gold
FROM marketing_customers;

---10 — Purchase Channel
SELECT
SUM(num_web_purchases) Web,
SUM(num_store_purchases) Store,
SUM(num_catalog_purchases) Catalog
FROM marketing_customers;
---11 — Spending by Income Group
SELECT
income_group,
ROUND(SUM(annual_spend),2) spending
FROM marketing_customers
GROUP BY income_group
ORDER BY spending DESC;

---12 — Spending by Age Group
SELECT
age_group,
ROUND(SUM(annual_spend),2)
FROM marketing_customers
GROUP BY age_group
ORDER BY 2 DESC;

---13 — Spending by Education
SELECT
education,
ROUND(SUM(annual_spend),2)
FROM marketing_customers
GROUP BY education
ORDER BY 2 DESC;

---14 — Spending by Marital Status
SELECT
marital_status,
ROUND(SUM(annual_spend),2)
FROM marketing_customers
GROUP BY marital_status
ORDER BY 2 DESC;

---15 — Top 10 Customers
SELECT
customer_id,
annual_spend
FROM marketing_customers
ORDER BY annual_spend DESC
LIMIT 10;

---16 — Country Analysis
SELECT
country,
COUNT(*) customers,
ROUND(SUM(annual_spend),2) spending
FROM marketing_customers
GROUP BY country
ORDER BY spending DESC;

---17 — City Analysis
SELECT
city,
COUNT(*) customers,
ROUND(SUM(annual_spend),2) spending
FROM marketing_customers
GROUP BY city
ORDER BY spending DESC;

---18 — Customer Value Analysis
SELECT
customer_value,
COUNT(*) customers,
ROUND(SUM(annual_spend),2) spending
FROM marketing_customers
GROUP BY customer_value
ORDER BY spending DESC;

---19 — Preferred Channel
SELECT
preferred_channel,
COUNT(*) customers
FROM marketing_customers
GROUP BY preferred_channel
ORDER BY customers DESC;

---20 — High Income Response
SELECT
income_group,
ROUND(AVG(response)*100,2) response_rate
FROM marketing_customers
GROUP BY income_group;