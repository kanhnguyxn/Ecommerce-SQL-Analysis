--1. CREATE DATABASE
CREATE DATABASE EcommerceData;
GO

USE EcommerceData;
GO

--SELECT TOP 100
SELECT TOP 100 *
FROM dbo.ecommerce_dataset;


--2. DATA OVERVIEW
-- Total rows
SELECT COUNT(*) AS total_rows
FROM dbo.ecommerce_dataset;

-- Total columns
SELECT COUNT(*) AS total_columns
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'ecommerce_dataset';

-- Column names & data types
SELECT 
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'ecommerce_dataset';


-- 3. DATA QUANLITY CHECK
--3.1 Check NULL value
SELECT
    SUM(CASE WHEN CID IS NULL THEN 1 ELSE 0 END) AS null_cid,
    SUM(CASE WHEN TID IS NULL THEN 1 ELSE 0 END) AS null_tid,
    SUM(CASE WHEN Gender IS NULL THEN 1 ELSE 0 END) AS null_gender,
    SUM(CASE WHEN Age_Group IS NULL THEN 1 ELSE 0 END) AS null_age_group,
    SUM(CASE WHEN Purchase_Date IS NULL THEN 1 ELSE 0 END) AS null_purchase_date,
    SUM(CASE WHEN Product_Category IS NULL THEN 1 ELSE 0 END) AS null_product_category,
    SUM(CASE WHEN Discount_Availed IS NULL THEN 1 ELSE 0 END) AS null_discount_availed,
    SUM(CASE WHEN Discount_Name IS NULL THEN 1 ELSE 0 END) AS null_discount_name,
    SUM(CASE WHEN Discount_Amount_INR IS NULL THEN 1 ELSE 0 END) AS null_discount_amount,
    SUM(CASE WHEN Gross_Amount IS NULL THEN 1 ELSE 0 END) AS null_gross_amount,
    SUM(CASE WHEN Net_Amount IS NULL THEN 1 ELSE 0 END) AS null_net_amount,
    SUM(CASE WHEN Purchase_Method IS NULL THEN 1 ELSE 0 END) AS null_purchase_method,
    SUM(CASE WHEN Location IS NULL THEN 1 ELSE 0 END) AS null_location
FROM dbo.ecommerce_dataset;

--3.2 Discount logic validation
-- Check inconsistent discount records
SELECT *
FROM dbo.ecommerce_dataset
WHERE 
    (Discount_Availed = 'No' AND Discount_Amount_INR > 0)
    OR
    (Discount_Availed = 'Yes' AND Discount_Amount_INR = 0);

--3.3 Net_Amount validation
-- Validate Net_Amount = Gross_Amount - Discount_Amount_INR
SELECT *
FROM dbo.ecommerce_dataset
WHERE ABS(Net_Amount - (Gross_Amount - Discount_Amount_INR)) > 0.01;

 --3.4 
UPDATE dbo.ecommerce_dataset
SET Discount_Name = 'No discount'
WHERE Discount_Name is null

--3.5 Duplicate Transaction check
SELECT * 
FROM dbo.ecommerce_dataset

WHERE TID in (
	SELECT TID 
	FROM dbo.ecommerce_dataset
	GROUP BY TID
	HAVING COUNT(*) >1)
ORDER BY TID


-- 4 DATE CONVERSION
-- Add new date & time columns
ALTER TABLE dbo.ecommerce_dataset
ADD purchase_date_clean DATE,
    purchase_time TIME(0);

-- Convert from string to datetime
UPDATE dbo.ecommerce_dataset
SET 
    purchase_date_clean = CAST(CONVERT(DATETIME, Purchase_Date, 103) AS DATE),
    purchase_time = CAST(CONVERT(DATETIME, Purchase_Date, 103) AS TIME);

-- Remove old column
ALTER TABLE dbo.ecommerce_dataset
DROP COLUMN Purchase_Date;

-- Rename new column
EXEC sp_rename 
    'dbo.ecommerce_dataset.purchase_date_clean',
    'Purchase_Date',
    'COLUMN';


-- 5 KPI CALULATION
--5.1 Overall Performance
SELECT 
    COUNT(*) AS total_orders,
    SUM(Net_Amount) AS total_revenue,
    SUM(Discount_Amount_INR) AS total_discount,
    AVG(Net_Amount) AS average_order_value
FROM dbo.ecommerce_dataset;

--5.2 Discount and Non-Discount comparision
SELECT 
    Discount_Availed,
    COUNT(*) AS total_orders,
    SUM(Net_Amount) AS total_revenue,
    AVG(Net_Amount) AS average_order_value,
    SUM(CASE WHEN Discount_Availed = 'Yes' THEN 1 ELSE 0 END) * 100.0 
        / COUNT(*) AS discount_usage_percent
FROM dbo.ecommerce_dataset
GROUP BY Discount_Availed;


-- 6. SEGMENT ANALYSIS
--6.1 By Gender
SELECT 
    Gender,
    COUNT(*) AS total_orders,
    SUM(Net_Amount) AS total_revenue,
    AVG(Net_Amount) AS average_order_value,
    SUM(CASE WHEN Discount_Availed = 'Yes' THEN 1 ELSE 0 END) * 100.0 
        / COUNT(*) AS discount_percent
FROM dbo.ecommerce_dataset
GROUP BY Gender
ORDER BY total_revenue DESC;

--6.2 By Age Group
SELECT 
    Age_Group,
    COUNT(*) AS total_orders,
    SUM(Net_Amount) AS total_revenue,
    AVG(Net_Amount) AS average_order_value,
    SUM(CASE WHEN Discount_Availed = 'Yes' THEN 1 ELSE 0 END) * 100.0 
        / COUNT(*) AS discount_percent
FROM dbo.ecommerce_dataset
GROUP BY Age_Group
ORDER BY total_revenue DESC;

--6.3 By Product Category
SELECT 
    Product_Category,
    COUNT(*) AS total_orders,
    SUM(Net_Amount) AS total_revenue,
    AVG(Net_Amount) AS average_order_value
FROM dbo.ecommerce_dataset
GROUP BY Product_Category
ORDER BY total_revenue DESC;

--6.4 Discount Dependentce by Category
SELECT 
    Product_Category,
    COUNT(*) AS total_orders,
    SUM(Net_Amount) AS total_revenue,
    AVG(Net_Amount) AS average_order_value
FROM dbo.ecommerce_dataset
GROUP BY Product_Category
ORDER BY total_revenue DESC;

--6.5 By Location
SELECT 
    Location,
    COUNT(*) AS Total_Orders,
    SUM(Net_Amount) AS Total_Revenue,
    AVG(Net_Amount) AS AOV
FROM dbo.ecommerce_dataset
GROUP BY Location
ORDER BY Total_Revenue DESC

--6.6 City Discount Dependentce
SELECT 
    Location,
    SUM(Net_Amount) AS total_revenue,
    SUM(CASE WHEN Discount_Availed = 'Yes' THEN Net_Amount ELSE 0 END) 
        AS revenue_with_discount,
    SUM(CASE WHEN Discount_Availed = 'Yes' THEN Net_Amount ELSE 0 END) * 100.0
        / SUM(Net_Amount) AS discount_revenue_percent
FROM dbo.ecommerce_dataset
GROUP BY Location
ORDER BY discount_revenue_percent DESC;







