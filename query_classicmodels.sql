SELECT orderNumber, quantityOrdered, priceEach, ROUND(quantityOrdered * priceEach) AS sales
FROM `classicmodels.orderdetails`
ORDER BY 3 DESC;

-- Hanya menampilkan angka terbesar
SELECT * FROM (
  SELECT MAX(priceEach) AS largest_price FROM `classicmodels.orderdetails`
);

-- Menampilkan seluruh kolom dengan kondisi harga terbesar
SELECT * FROM `classicmodels.orderdetails`
WHERE priceEach IN (
  SELECT MAX(priceEach) AS largest_price FROM `classicmodels.orderdetails`
);

-- Sales Performance per Country per City
SELECT country, city, SUM(quantityOrdered) AS qty, SUM(priceEach) AS price, COUNT(DISTINCT(o.orderNumber)) AS orders
FROM `classicmodels.customers` c 
  INNER JOIN `classicmodels.orders` o ON o.customerNumber = c.customerNumber
  LEFT JOIN `classicmodels.orderdetails` od ON od.orderNumber = o.orderNumber
WHERE o.orderDate BETWEEN '2005-01-01' AND '2005-12-31'
GROUP BY 1,2
ORDER BY 4 DESC;

-- Combine where-between & like 
SELECT lastName, firstName, jobTitle, country AS office_country
FROM `classicmodels.employees` e
  LEFT JOIN `classicmodels.offices` ofc ON ofc.officeCode = e.officeCode
WHERE e.officeCode BETWEEN 3 AND 7 AND firstName LIKE '_a%';

-- Membuat nota lengkap dengan customer tertentu
SELECT
  c.customerName, o.orderNumber,  o.orderDate, p.productName, od.quantityOrdered, od.priceEach, (quantityOrdered * priceEach) AS total
FROM `classicmodels.customers` c
INNER JOIN `classicmodels.orders` o USING(customerNumber)
LEFT JOIN `classicmodels.orderdetails` od USING(orderNumber)
LEFT JOIN `classicmodels.products` p USING(productCode)
WHERE o.orderNumber = 10103;

-- Menghitung Transaksi 'Cancelled', 'On Hold', 'Disputed'
SELECT * FROM (
  SELECT 
    jobTitle, CONCAT(firstName, ' ', lastName) AS name, o.status,
    SUM(quantityOrdered) AS qty
  FROM `classicmodels.employees` e
    LEFT JOIN `classicmodels.customers` c     ON c.salesRepEmployeeNumber = e.employeeNumber
    LEFT JOIN `classicmodels.orders` o        ON o.customerNumber = c.customerNumber
    LEFT JOIN `classicmodels.orderdetails` od ON od.orderNumber = o.orderNumber
  WHERE jobTitle = 'Sales Rep' AND EXTRACT(YEAR FROM orderDate) IN (2003, 2004)
  GROUP BY 1,2,3
  ORDER BY 4 DESC
)
WHERE qty > 300 AND status IN ('Cancelled', 'On Hold', 'Disputed');

-- Sales Rep Performance 2003-2004
WITH sales AS (  
  SELECT 
    jobTitle, 
    CONCAT(firstName, ' ', lastName) AS name, 
    EXTRACT(YEAR FROM orderDate) years, 
    SUM(quantityOrdered) AS qty, 
    SUM(priceEach) AS price, 
    COUNT(o.orderNumber) AS orders

  FROM `classicmodels.employees` e
    LEFT JOIN `classicmodels.customers` c     ON c.salesRepEmployeeNumber = e.employeeNumber
    LEFT JOIN `classicmodels.orders` o        USING(customerNumber)
    LEFT JOIN `classicmodels.orderdetails` od USING(orderNumber)
  WHERE jobTitle = 'Sales Rep' AND EXTRACT(YEAR FROM orderDate) <> 2005
  GROUP BY 1,2,3
),
rev AS (
  SELECT s.*, (qty * price) AS revenue, ROUND((qty * price)/orders) AS rev_per_order
  FROM sales s
),
performance AS (
SELECT r.*,
  CASE
    WHEN revenue BETWEEN 10000000 AND 20000000 THEN 'Enough'
    WHEN revenue BETWEEN 20000001 AND 40000000 THEN 'Good'
    WHEN revenue > 40000000 THEN 'Best'
    ELSE 'Bad'
  END AS performance,
FROM rev r
ORDER BY 6 DESC
),
bonus_performance AS (
  SELECT p.*,
    CASE 
      WHEN performance = 'Best' THEN 0.01
      WHEN performance = 'Good' AND orders >= 100 THEN 0.005
      WHEN performance = 'Good' AND orders < 100 THEN 0.003
      WHEN performance = 'Enough' THEN 0.001
    END AS percentage
  FROM performance p
)
SELECT  
  jobTitle, name, years, qty, price, orders, revenue, rev_per_order, performance,
  IF(percentage IS NULL, 0, ROUND(revenue * percentage)) AS bonus
FROM bonus_performance bp;

-- Office Performance
WITH office AS (
  SELECT  
    k.country, k.city, k.officeCode, 
    COUNT(DISTINCT(e.employeenumber)) AS jml_karyawan, 
    SUM(od.quantityOrdered) AS qty, SUM(od.priceEach) AS price, 
    COUNT(*) orders,
  FROM `classicmodels.offices` k
    LEFT JOIN `classicmodels.employees` e USING(officeCode)
    LEFT JOIN `classicmodels.customers` c ON e.employeeNumber = c.salesRepEmployeeNumber
    LEFT JOIN `classicmodels.orders` o USING(customerNumber)
    LEFT JOIN `classicmodels.orderdetails` od USING(orderNumber)
  GROUP BY 1,2,3 
),
rev AS (
  SELECT o.*, (qty * price) AS revenue
  FROM office o
  ORDER BY revenue DESC
)
SELECT r.*, ROUND((revenue/orders),0) AS rev_per_order, ROUND((revenue/r.jml_karyawan),0) AS rev_per_kry
FROM rev r