-- Business Problem Q1: Find different payment methods, number of transactions, and quantity sold by payment method

SELECT 
    Payment_method,
    COUNT(*) AS no_payments,
    SUM(Quantity) AS no_qty_sold
FROM
    walmart_sales
GROUP BY Payment_method;

-- Business Problem Q2: Identify the highest-rated category in each branch: Display the branch, category, and avg rating

with cte as (
	select branch, category, avg(rating) as avg_rating,
    rank() over (partition by category order by avg(rating) desc) as ranking
    from walmart_sales
    group by branch, category
)

select branch, category, avg_rating
from cte
where ranking  = 1;

-- Business Problem Q3: Determine the most common payment method for each branch

With cte as (
	select branch, payment_method, count(*) as total_trans,
    rank() over(partition by branch order by count(*) desc) as ranking
    from walmart_sales
    group by branch, payment_method
)

select branch, payment_method as payment_method_preferred
from cte
where ranking = 1;

-- Business Problem Q4: Categorize sales into Morning, Afternoon, and Evening shifts

SELECT 
    branch,
    CASE
        WHEN HOUR(TIME(time)) < 12 THEN 'Morning'
        WHEN HOUR(TIME(time)) BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END AS shift,
    COUNT(*) AS num_invoices
FROM
    walmart_sales
GROUP BY branch , shift
ORDER BY branch , num_invoices DESC;

-- Business Problem Q5: Which cities have total sales higher than the average sales across all cities?

SELECT 
    City, Total_amount
FROM
    walmart_sales
GROUP BY City
HAVING Total_amount > (SELECT 
        AVG(Total_amount)
    FROM
        (SELECT 
            Total_amount
        FROM
            walmart_sales
        GROUP BY City) AS city_sales);


-- Business Problem Q6: How is the profit growing month over month?

WITH monthly_sales AS (
    SELECT 
        MONTH(STR_TO_DATE(date, '%d/%m/%y')) AS sales_month,
        SUM(unit_price * quantity * profit_margin) AS total_profit
    FROM walmart_sales
    GROUP BY sales_month
)
SELECT 
    sales_month,
    total_profit,
    LAG(total_profit, 1) OVER (ORDER BY sales_month) AS previous_month_profit,
    ROUND(((total_profit - LAG(total_profit, 1) OVER (ORDER BY sales_month)) / 
          LAG(total_profit, 1) OVER (ORDER BY sales_month)) * 100, 2) AS profit_growth_percentage
FROM monthly_sales;

-- Business Problem Q7: What is the rolling 7-day total sales per Walmart branch?

SELECT 
    branch, 
    STR_TO_DATE(date, '%d/%m/%y') AS sale_date,
    SUM(unit_price * quantity) AS daily_sales,
    SUM(SUM(unit_price * quantity)) OVER (
        PARTITION BY branch ORDER BY STR_TO_DATE(date, '%d/%m/%y') ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS rolling_7_day_sales
FROM walmart_sales
GROUP BY branch, sale_date;

-- Business Problem Q8: Which customers made purchases on consecutive days?

SELECT invoice_id, date,
       LAG(date, 1) OVER (PARTITION BY invoice_id ORDER BY STR_TO_DATE(date, '%d/%m/%y')) AS previous_date,
       DATEDIFF(STR_TO_DATE(date, '%d/%m/%y'), LAG(date, 1) OVER (PARTITION BY invoice_id ORDER BY STR_TO_DATE(date, '%d/%m/%y'))) AS days_between_purchases
FROM walmart_sales
HAVING days_between_purchases = 1;
