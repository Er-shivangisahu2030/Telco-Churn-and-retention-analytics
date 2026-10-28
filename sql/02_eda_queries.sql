-- EDA queries for telco_churn.customers.
-- Each query below is delimited by its own name marker line so
-- scripts/03_eda_plots.py can parse and run them individually; feel free to
-- run any of these standalone in a MySQL client too.

-- === overall_churn_rate ===
-- Headline number: what fraction of customers have churned?
SELECT
    COUNT(*) AS total_customers,
    SUM(ChurnFlag) AS churned_customers,
    ROUND(AVG(ChurnFlag) * 100, 2) AS churn_rate_pct
FROM customers;

-- === churn_by_contract ===
-- Churn rate by contract type -- expect month-to-month to churn far more than
-- one/two-year contracts since there's no switching cost.
SELECT
    Contract,
    COUNT(*) AS customers,
    SUM(ChurnFlag) AS churned,
    ROUND(AVG(ChurnFlag) * 100, 2) AS churn_rate_pct,
    ROUND(AVG(MonthlyCharges), 2) AS avg_monthly_charges
FROM customers
GROUP BY Contract
ORDER BY churn_rate_pct DESC;

-- === churn_by_payment_method ===
SELECT
    PaymentMethod,
    COUNT(*) AS customers,
    ROUND(AVG(ChurnFlag) * 100, 2) AS churn_rate_pct
FROM customers
GROUP BY PaymentMethod
ORDER BY churn_rate_pct DESC;

-- === churn_by_internet_service ===
SELECT
    InternetService,
    COUNT(*) AS customers,
    ROUND(AVG(ChurnFlag) * 100, 2) AS churn_rate_pct,
    ROUND(AVG(MonthlyCharges), 2) AS avg_monthly_charges
FROM customers
GROUP BY InternetService
ORDER BY churn_rate_pct DESC;

-- === churn_by_senior_citizen ===
SELECT
    SeniorCitizen,
    COUNT(*) AS customers,
    ROUND(AVG(ChurnFlag) * 100, 2) AS churn_rate_pct
FROM customers
GROUP BY SeniorCitizen;

-- === churn_by_tenure_bucket ===
-- Bucket tenure into year-ish bands to see whether churn concentrates early
-- (a classic subscription-business pattern: risk is highest right after signup).
SELECT
    CASE
        WHEN tenure <= 6 THEN '0-6 mo'
        WHEN tenure <= 12 THEN '7-12 mo'
        WHEN tenure <= 24 THEN '13-24 mo'
        WHEN tenure <= 48 THEN '25-48 mo'
        ELSE '49-72 mo'
    END AS tenure_bucket,
    COUNT(*) AS customers,
    ROUND(AVG(ChurnFlag) * 100, 2) AS churn_rate_pct
FROM customers
GROUP BY tenure_bucket
ORDER BY MIN(tenure);

-- === charges_by_churn_status ===
-- Do churned customers pay more or less on average than retained ones?
SELECT
    Churn,
    COUNT(*) AS customers,
    ROUND(AVG(tenure), 1) AS avg_tenure_months,
    ROUND(AVG(MonthlyCharges), 2) AS avg_monthly_charges,
    ROUND(AVG(TotalCharges), 2) AS avg_total_charges
FROM customers
GROUP BY Churn;

-- === services_vs_churn ===
-- Relationship between number of subscribed add-on services and churn --
-- expect more add-ons (more "stickiness") to correlate with lower churn.
SELECT
    NumServices,
    COUNT(*) AS customers,
    ROUND(AVG(ChurnFlag) * 100, 2) AS churn_rate_pct
FROM customers
GROUP BY NumServices
ORDER BY NumServices;

-- === revenue_concentration ===
-- Full population ranked by TotalCharges descending, used to compute a
-- Pareto / revenue-concentration curve (cumulative revenue share vs
-- cumulative customer share). Only 7,043 rows so no LIMIT needed.
SELECT
    customerID,
    TotalCharges,
    Churn,
    Contract,
    tenure
FROM customers
ORDER BY TotalCharges DESC;

-- === churn_heatmap_contract_internet ===
-- Two-dimensional churn-rate breakdown: Contract type x Internet service.
SELECT
    Contract,
    InternetService,
    COUNT(*) AS customers,
    ROUND(AVG(ChurnFlag) * 100, 2) AS churn_rate_pct
FROM customers
GROUP BY Contract, InternetService
ORDER BY Contract, InternetService;

-- === raw_tenure_charges_churn ===
-- Row-level tenure/MonthlyCharges/Churn for distribution plots (histograms).
SELECT tenure, MonthlyCharges, TotalCharges, Churn
FROM customers;

-- === contract_length_comparison ===
-- Direct month-to-month vs long-contract comparison.
SELECT
    CASE WHEN Contract = 'Month-to-month' THEN 'Month-to-month' ELSE 'One/Two year' END AS contract_group,
    COUNT(*) AS customers,
    ROUND(AVG(ChurnFlag) * 100, 2) AS churn_rate_pct,
    ROUND(AVG(MonthlyCharges), 2) AS avg_monthly_charges,
    ROUND(AVG(TotalCharges), 2) AS avg_total_charges,
    ROUND(AVG(tenure), 1) AS avg_tenure_months
FROM customers
GROUP BY contract_group;

-- === payment_method_revenue ===
SELECT
    PaymentMethod,
    COUNT(*) AS customers,
    ROUND(SUM(TotalCharges), 2) AS total_revenue,
    ROUND(AVG(MonthlyCharges), 2) AS avg_monthly_charges
FROM customers
GROUP BY PaymentMethod
ORDER BY total_revenue DESC;
