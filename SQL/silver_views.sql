
/*
===============================================================================
RETAIL ANALYTICS - SILVER LAYER
===============================================================================

Description:
    This script creates the Silver Layer views used to clean and standardize
    raw data imported into the Bronze Layer.

Main transformations:
    - Remove leading and trailing spaces
    - Standardize text values and country names
    - Handle missing or empty values
    - Correct inconsistent categories and order statuses
    - Convert columns to appropriate data types
    - Remove duplicate customer and employee records

Source schema : bronze
Target schema : silver
Database      : RetailAnalyticsDB

===============================================================================
*/


-- =============================================================================
-- 1. CUSTOMERS
-- =============================================================================
-- Clean customer information, standardize country names,
-- handle missing emails and remove duplicate records.

CREATE OR ALTER VIEW silver.Customers AS

SELECT DISTINCT
    Customer_ID,
    TRIM(First_Name) AS First_Name,
    TRIM(Last_Name) AS Last_Name,
    COALESCE(NULLIF(TRIM(Email), ''), 'Unknown') AS Email,
    TRIM(Phone) AS Phone,
    UPPER(TRIM(City)) AS City,

    UPPER(
        CASE
            WHEN TRIM(Country) = 'BE' THEN 'Belgium'
            ELSE TRIM(Country)
        END
    ) AS Country,

    TRIM(Segment) AS Segment,
    CAST(Registration_Date AS DATE) AS Registration_Date

FROM bronze.Customers;
GO


-- =============================================================================
-- 2. EMPLOYEES
-- =============================================================================
-- Standardize employee information, handle missing emails
-- and remove duplicate records.

CREATE OR ALTER VIEW silver.Employees AS

SELECT DISTINCT
    TRIM(Employee_ID) AS Employee_ID,
    TRIM(First_Name) AS First_Name,
    TRIM(Last_Name) AS Last_Name,
    COALESCE(NULLIF(TRIM(Email), ''), 'Unknown') AS Email,
    TRIM(Store_ID) AS Store_ID,
    TRIM(Role) AS Role,
    CAST(Hire_Date AS DATE) AS Hire_Date

FROM bronze.Employees;
GO


-- =============================================================================
-- 3. ORDER LINES
-- =============================================================================
-- Standardize identifiers and convert quantity, unit price
-- and discount rate to appropriate numeric data types.
-- Missing unit prices remain NULL.

CREATE OR ALTER VIEW silver.Order_Lines AS

SELECT
    TRIM(Order_Line_ID) AS Order_Line_ID,
    TRIM(Order_ID) AS Order_ID,
    TRIM(Product_ID) AS Product_ID,
    CAST(TRIM(Quantity) AS INT) AS Quantity,
    TRY_CAST(NULLIF(TRIM(Unit_Price), '') AS DECIMAL(10,2)) AS Unit_Price,
    TRY_CAST(TRIM(Discount_Rate) AS DECIMAL(5,2)) AS Discount_Rate

FROM bronze.Order_Lines;
GO


-- =============================================================================
-- 4. ORDERS
-- =============================================================================
-- Standardize order information, handle multiple date formats,
-- replace missing payment methods and correct order statuses.

CREATE OR ALTER VIEW silver.Orders AS

SELECT
    TRIM(Order_ID) AS Order_ID,

    COALESCE(
        TRY_CONVERT(DATE, TRIM(Order_Date), 23),
        TRY_CONVERT(DATE, TRIM(Order_Date), 103)
    ) AS Order_Date,

    TRIM(Customer_ID) AS Customer_ID,
    TRIM(Store_ID) AS Store_ID,
    TRIM(Employee_ID) AS Employee_ID,
    TRIM(Sales_Channel) AS Sales_Channel,

    COALESCE(
        NULLIF(TRIM(Payment_Method), ''),
        'Unknown'
    ) AS Payment_Method,

    CASE
        WHEN TRIM(Order_Status) = 'complete' THEN 'Completed'
        ELSE TRIM(Order_Status)
    END AS Order_Status,

    TRY_CONVERT(
        DATE,
        NULLIF(TRIM(Ship_Date), ''),
        23
    ) AS Ship_Date

FROM bronze.Orders;
GO


-- =============================================================================
-- 5. PRODUCTS
-- =============================================================================
-- Standardize product information, correct category spelling
-- and convert prices and costs to numeric data types.
-- Missing list prices remain NULL.

CREATE OR ALTER VIEW silver.Products AS

SELECT
    TRIM(Product_ID) AS Product_ID,
    TRIM(Product_Name) AS Product_Name,

    CASE
        WHEN TRIM(Category) = 'Accesories' THEN 'Accessories'
        ELSE TRIM(Category)
    END AS Category,

    TRIM(Subcategory) AS Subcategory,
    TRIM(Brand) AS Brand,
    CAST(TRIM(Unit_Cost) AS DECIMAL(10,2)) AS Unit_Cost,
    CAST(NULLIF(TRIM(List_Price), '') AS DECIMAL(10,2)) AS List_Price,
    TRIM(Active_Flag) AS Active_Flag

FROM bronze.Products;
GO


-- =============================================================================
-- 6. STORES
-- =============================================================================
-- Standardize store information and correct inconsistent
-- country names and abbreviations.

CREATE OR ALTER VIEW silver.Stores AS

SELECT
    TRIM(Store_ID) AS Store_ID,
    TRIM(Store_Name) AS Store_Name,
    UPPER(TRIM(City)) AS City,

    CASE
        WHEN TRIM(Country) = 'FR' THEN 'FRANCE'
        WHEN TRIM(Country) = 'Nederland' THEN 'NETHERLANDS'
        ELSE UPPER(TRIM(Country))
    END AS Country,

    TRIM(Region) AS Region

FROM bronze.Stores;
GO


/*
===============================================================================
END OF SILVER LAYER
===============================================================================
*/
