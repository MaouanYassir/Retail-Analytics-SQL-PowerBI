
/*
===============================================================================
RETAIL ANALYTICS - GOLD LAYER
===============================================================================

Description:
    This script creates the Gold Layer views used for business reporting
    and data analysis in Power BI.

    The Gold Layer transforms cleaned Silver Layer data into a
    dimensional model consisting of fact and dimension tables.

Main transformations:
    - Create customer, product, store and employee dimensions
    - Generate a date dimension for time-based analysis
    - Build a sales fact table at the order-line level
    - Calculate sales, costs, discounts and profits
    - Prepare data for Power BI reporting and DAX measures

Source schema : silver
Target schema : gold
Database      : RetailAnalyticsDB

===============================================================================
*/


-- =============================================================================
-- 1. DIM CUSTOMERS
-- =============================================================================
-- Create the customer dimension with full names and customer attributes.
-- Customer_Label combines the name and unique ID to distinguish customers
-- who share the same name in Power BI visualizations.

CREATE OR ALTER VIEW gold.Dim_Customers AS

SELECT
    Customer_ID,
    CONCAT(First_Name, ' ', Last_Name) AS Full_Name,
    CONCAT(
        First_Name, ' ', Last_Name,
        ' (', Customer_ID, ')'
    ) AS Customer_Label,
    City,
    Country,
    Segment,
    Registration_Date

FROM silver.Customers;
GO


-- =============================================================================
-- 2. DIM DATE
-- =============================================================================
-- Generate a continuous calendar from January 1, 2023 to August 31, 2026.
-- Add year, quarter, month and year-month attributes for time analysis.

CREATE OR ALTER VIEW gold.Dim_Date AS

WITH dates AS (
    SELECT
        DATEADD(
            DAY,
            value,
            CAST('2023-01-01' AS DATE)
        ) AS Full_Date

    FROM GENERATE_SERIES(
        0,
        DATEDIFF(DAY, '2023-01-01', '2026-08-31')
    )
)

SELECT
    Full_Date,
    YEAR(Full_Date) AS Year,
    DATEPART(QUARTER, Full_Date) AS Quarter,
    MONTH(Full_Date) AS Month_Number,
    DATENAME(MONTH, Full_Date) AS Month_Name,

    CONCAT(
        YEAR(Full_Date),
        '-',
        RIGHT('0' + CAST(MONTH(Full_Date) AS VARCHAR(2)), 2)
    ) AS Year_Month

FROM dates;
GO


-- =============================================================================
-- 3. DIM EMPLOYEES
-- =============================================================================
-- Create the employee dimension with full names,
-- job roles and hiring dates.

CREATE OR ALTER VIEW gold.Dim_Employees AS

SELECT
    Employee_ID,
    CONCAT(First_Name, ' ', Last_Name) AS Full_Name,
    Role,
    Hire_Date

FROM silver.Employees;
GO


-- =============================================================================
-- 4. DIM PRODUCTS
-- =============================================================================
-- Create the product dimension with product names,
-- categories, subcategories, brands and active status.

CREATE OR ALTER VIEW gold.Dim_Products AS

SELECT
    Product_ID,
    Product_Name,
    Category,
    Subcategory,
    Brand,
    Active_Flag

FROM silver.Products;
GO


-- =============================================================================
-- 5. DIM STORES
-- =============================================================================
-- Create the store dimension with store names
-- and geographical information.

CREATE OR ALTER VIEW gold.Dim_Stores AS

SELECT
    Store_ID,
    Store_Name,
    City,
    Country

FROM silver.Stores;
GO


-- =============================================================================
-- 6. FACT SALES
-- =============================================================================
-- Create the sales fact table at the order-line level.
--
-- Each row represents one product line within an order.
--
-- Business calculations:
--     Sales Amount    = Quantity * Unit Price * (1 - Discount Rate)
--     Cost Amount     = Quantity * Unit Cost
--     Discount Amount = Quantity * Unit Price * Discount Rate
--     Profit          = Sales Amount - Cost Amount
--
-- Discount rates are stored as decimal fractions (e.g. 0.15 = 15%).
-- Missing unit prices remain NULL and are not estimated.
--
-- Order status is retained so completed orders can be filtered
-- in Power BI measures.

CREATE OR ALTER VIEW gold.Fact_sales AS

WITH first_cte AS (
    SELECT
        ol.Order_Line_ID,
        ol.Order_ID,
        o.Order_Date,
        ol.Product_ID,
        o.Customer_ID,
        o.Store_ID,
        o.Employee_ID,
        ol.Quantity,
        ol.Unit_Price,
        ol.Discount_Rate,

        (ol.Quantity * ol.Unit_Price)
            * (1 - ol.Discount_Rate) AS Sales_Amount,

        ol.Quantity * p.Unit_Cost AS Cost_Amount,

        ol.Quantity * ol.Unit_Price
            * ol.Discount_Rate AS Discount_Amount,

        o.Payment_Method,
        o.Sales_Channel,
        o.Order_Status

    FROM silver.Order_Lines ol

    INNER JOIN silver.Orders o
        ON ol.Order_ID = o.Order_ID

    INNER JOIN silver.Products p
        ON ol.Product_ID = p.Product_ID
)

SELECT
    Order_Line_ID,
    Order_ID,
    Order_Date,
    Product_ID,
    Customer_ID,
    Store_ID,
    Employee_ID,
    Quantity,
    Unit_Price,
    Discount_Rate,
    Discount_Amount,
    Sales_Amount,
    Cost_Amount,
    Sales_Amount - Cost_Amount AS Profit,
    Payment_Method,
    Sales_Channel,
    Order_Status

FROM first_cte;
GO


/*
===============================================================================
END OF GOLD LAYER
===============================================================================
*/
