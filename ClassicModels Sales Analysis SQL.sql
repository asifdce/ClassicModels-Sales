											    -- ClassicModels Sales analysis
USE classicmodels;

SELECT * FROM customers;
SELECT * FROM  employees;
SELECT * FROM  offices;
SELECT * FROM  orderdetails;
SELECT * FROM  orders;
SELECT* FROM  payments;
SELECT * FROM  productlines;
SELECT * FROM  products;

-- 1. Identify the number of missing values for columns in the customers table
SELECT 
  SUM(CASE WHEN customerNumber IS NULL THEN 1 ELSE 0 END) AS missing_customerNumber,
  SUM(CASE WHEN customerName IS NULL THEN 1 ELSE 0 END) AS missing_customerName,
  SUM(CASE WHEN state IS NULL THEN 1 ELSE 0 END) AS missing_state,
  SUM(CASE WHEN salesRepEmployeeNumber IS NULL THEN 1 ELSE 0 END) AS missing_salesRepEmployeeNumber
FROM customers;

-- 2. Identify the number of missing values for columns in the orders table
SELECT 
  SUM(CASE WHEN orderNumber IS NULL THEN 1 ELSE 0 END) AS missing_orderNumber,
  SUM(CASE WHEN orderDate IS NULL THEN 1 ELSE 0 END) AS missing_orderDate,
  SUM(CASE WHEN shippedDate IS NULL THEN 1 ELSE 0 END) AS missing_shippedDate,
  SUM(CASE WHEN comments IS NULL THEN 1 ELSE 0 END) AS missing_comments
 FROM orders;
 
-- 3. Calculate the total quantity in stock for each product line
SELECT productLine, SUM(quantityInStock) AS totalQuantityInStock
FROM products
GROUP BY productLine;

-- 4. Find the average payment amount made by each customer
SELECT customerNumber, AVG(amount) AS averagePaymentAmount
FROM payments
GROUP BY customerNumber;

-- 5. Retrieve the top 5 customers with the highest credit limit
SELECT customerNumber, customerName, creditLimit
FROM customers
ORDER BY creditLimit DESC
LIMIT 5;

-- 6. Find the total sales amount for each product
SELECT p.productCode, p.productName, SUM(od.quantityOrdered * od.priceEach) AS totalSalesAmount
FROM orderDetails od
JOIN products p ON od.productCode = p.productCode
GROUP BY p.productCode, p.productName;

-- 7. Get a count of orders placed by each customer

SELECT c.customerNumber, c.customerName, COUNT(o.orderNumber) AS orderCount
FROM customers c
JOIN orders o ON c.customerNumber = o.customerNumber
GROUP BY c.customerNumber, c.customerName;

-- 8. Find monthly sales totals for each product
SELECT 
YEAR(o.orderDate) AS orderYear, 
MONTH(o.orderDate) AS orderMonth,
p.productCode,
p.productName,
SUM(od.quantityOrdered * od.priceEach) AS monthlySalesTotal
FROM orders o
JOIN orderDetails od ON o.orderNumber = od.orderNumber
JOIN products p ON od.productCode = p.productCode
GROUP BY orderYear, orderMonth, p.productCode, p.productName
ORDER BY orderYear, orderMonth, p.productCode;

-- 9. Classify customers into different credit limit segments
SELECT 
    customerNumber,
    customerName,
    creditLimit,
    CASE
        WHEN creditLimit < 50000 THEN 'Low Credit'
        WHEN creditLimit >= 50000 AND creditLimit < 100000 THEN 'Medium Credit'
        WHEN creditLimit >= 10000 THEN 'High Credit'
        ELSE 'Unknown'
    END AS creditSegment
FROM customers;

-- 10. Rank customers based on their payment amounts
SELECT 
    customerNumber,
    amount,
    RANK() OVER (ORDER BY amount DESC) AS paymentRank
FROM payments;

-- 11. Retrieve statistics on orders per customer including total orders,
-- minimum, maximum, and average order amount
SELECT 
    o.customerNumber,
    COUNT(o.orderNumber) AS totalOrders,
    MIN(od.quantityOrdered * od.priceEach) AS minOrderAmount,
    MAX(od.quantityOrdered * od.priceEach) AS maxOrderAmount,
    AVG(od.quantityOrdered * od.priceEach) AS avgOrderAmount
FROM orders o
JOIN orderDetails od ON o.orderNumber = od.orderNumber
GROUP BY o.customerNumber;

-- 12. Identify customers who have made payments greater than the average payment
SELECT 
    customerNumber,
    amount
FROM payments
WHERE amount > (
    SELECT AVG(amount) FROM payments
);

-- 13. Stored Procedure for Retrieving Customer information
DELIMITER //

CREATE PROCEDURE GetCustomerInfo (IN custNumber INT)
BEGIN
    SELECT *
    FROM orders
    WHERE customerNumber = custNumber;
END //

DELIMITER ;
-- Execute the stored procedure
CALL GetCustomerInfo(103);

-- 14. Stored Procedure for Calculating Total Sales by Product
DELIMITER //

CREATE PROCEDURE CalculateTotalSales ()
BEGIN
    SELECT p.productCode, p.productName, SUM(od.quantityOrdered * od.priceEach) AS totalSales
    FROM products p
    JOIN orderDetails od ON p.productCode = od.productCode
    GROUP BY p.productCode, p.productName;
END //

DELIMITER ;
-- Execute the stored procedure
CALL CalculateTotalSales ()

-- 15. View for Customer Orders Details
CREATE VIEW CustomerOrdersDetails AS
SELECT 
    o.orderNumber,
    o.orderDate,
    od.productCode,
    p.productName,
    od.quantityOrdered,
    od.priceEach,
    (od.quantityOrdered * od.priceEach) AS totalPrice
FROM orders o
JOIN orderDetails od ON o.orderNumber = od.orderNumber
JOIN products p ON od.productCode = p.productCode;
-- Retrieve all rows and columns from the 'CustomerOrdersDetails' view
SELECT *
FROM CustomerOrdersDetails;

-- 16. View for High-Value Customers
CREATE VIEW HighValueCustomers AS
SELECT 
    c.customerNumber,
    c.customerName,
    c.creditLimit,
    SUM(p.amount) AS totalPayments
FROM customers c
LEFT JOIN payments p ON c.customerNumber = p.customerNumber
GROUP BY c.customerNumber
HAVING totalPayments > 100000; -- Change the threshold as needed
-- Retrieve all rows and columns from the 'HighValueCustomers' view
SELECT *
FROM HighValueCustomers;

-- 17. CTE for Monthly Sales Totals for each product(for each year)
WITH MonthlySales AS (
    SELECT 
        YEAR(o.orderDate) AS orderYear,
        MONTH(o.orderDate) AS orderMonth,
        p.productCode,
        SUM(od.quantityOrdered * od.priceEach) AS monthlySalesTotal
    FROM orders o
    JOIN orderDetails od ON o.orderNumber = od.orderNumber
    JOIN products p ON od.productCode = p.productCode
    GROUP BY orderYear, orderMonth, p.productCode
)
SELECT * FROM MonthlySales;

-- 18. CTE for Customers with Highest Payments(single time)
WITH RankedPayments AS (
    SELECT 
        customerNumber,
        amount,
        RANK() OVER (PARTITION BY customerNumber ORDER BY amount DESC) AS paymentRank
    FROM payments
)
SELECT * FROM RankedPayments WHERE paymentRank = 1;

-- 19. Window Function to Calculate Running Total Sales(for orders)
SELECT 
    orderNumber,
    productCode,
    quantityOrdered,
    priceEach,
    SUM(quantityOrdered * priceEach) OVER (ORDER BY orderNumber) AS runningTotal
FROM orderDetails;

-- 20. Window Function for Ranking Customers by Their Total Payments
SELECT 
    customerNumber,
    SUM(amount) AS totalPayments,
    RANK() OVER (ORDER BY SUM(amount) DESC) AS paymentRank
FROM payments
GROUP BY customerNumber;

-- 21. Subquery for Retrieving Product Information within a Specific Price Range(with highest buy price)
SELECT productCode, productName, buyPrice
FROM products
WHERE buyPrice IN (
    SELECT MAX(buyPrice) AS highestPrice
    FROM products
);

-- 22. Subquery to Find Customers with No Orders
SELECT customerNumber, customerName
FROM customers
WHERE customerNumber NOT IN (
    SELECT DISTINCT customerNumber
    FROM orders
);

-- 23. Creating a New Column Based on Quantity in Stock
-- (create a new column inventoryStatus categorizing products based on their quantity in stock.)
SELECT 
    productCode,
    productName,
    quantityInStock,
    CASE
        WHEN quantityInStock >= 5000 THEN 'High Inventory'
        WHEN quantityInStock >= 1000 AND quantityInStock < 5000 THEN 'Medium Inventory'
        WHEN quantityInStock < 1000 THEN 'Low Inventory'
        ELSE 'Out of Stock'
    END AS inventoryStatus
FROM products;

-- 24.  Identifying Pending Orders
-- (check if an order has been shipped or is still pending based on the shippedDate column.)
SELECT 
    orderNumber,
    orderDate,
    shippedDate,
    CASE
        WHEN shippedDate IS NULL THEN 'Pending'
        ELSE 'Shipped'
    END AS orderStatus
FROM orders;

-- 25. Grouping Products by Price Range
SELECT 
    productCode,
    productName,
    buyPrice,
    CASE
        WHEN buyPrice <= 40 THEN 'Low Price'
        WHEN buyPrice > 40 AND buyPrice <= 70 THEN 'Medium Price'
        WHEN buyPrice > 70 THEN 'High Price'
        ELSE 'Unknown'
    END AS priceCategory
FROM products;

-- 26. Determining Order Status Based on Dates
-- (check if orders were delivered on time, delayed, or still pending based on different date comparisons)
SELECT 
    orderNumber,
    orderDate,
    requiredDate,
    shippedDate,
    CASE
        WHEN shippedDate IS NOT NULL AND shippedDate <= requiredDate THEN 'On Time'
        WHEN shippedDate IS NOT NULL AND shippedDate > requiredDate THEN 'Delayed'
        ELSE 'Pending'
    END AS deliveryStatus
FROM orders;

-- 27. Determine the total sales for each customer
SELECT 
    c.customerNumber,
    c.customerName,
    SUM(od.quantityOrdered * od.priceEach) AS totalSales
FROM customers c
LEFT JOIN orders o ON c.customerNumber = o.customerNumber
LEFT JOIN orderDetails od ON o.orderNumber = od.orderNumber
GROUP BY c.customerNumber, c.customerName
ORDER BY totalSales DESC;

-- 28. Calculate monthly sales
SELECT 
    YEAR(orderDate) AS Year,
    MONTH(orderDate) AS Month,
    SUM(quantityOrdered * priceEach) AS MonthlySales
FROM orders o
JOIN orderDetails od ON o.orderNumber = od.orderNumber
GROUP BY Year, Month;

-- 29. Clculate yearly sales
SELECT 
    YEAR(orderDate) AS Year,
    SUM(quantityOrdered * priceEach) AS YearlySales
FROM orders o
JOIN orderDetails od ON o.orderNumber = od.orderNumber
GROUP BY Year;

-- 30. Determine which employee is reporting to whom 
SELECT 
    e1.employeeNumber AS EmployeeID,
    CONCAT(e1.firstName, ' ', e1.lastName) AS EmployeeName,
    e1.jobTitle AS EmployeeJobTitle,
    e2.employeeNumber AS ReportsToID,
    CONCAT(e2.firstName, ' ', e2.lastName) AS ReportsToName,
    e2.jobTitle AS ReportsToJobTitle
FROM 
    employees e1
LEFT JOIN 
    employees e2 ON e1.reportsTo = e2.employeeNumber
ORDER BY 
    EmployeeID;