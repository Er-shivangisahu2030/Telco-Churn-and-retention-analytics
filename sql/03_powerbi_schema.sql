-- Additional tables + a consolidated view for the Power BI dashboard.
-- Run after 01_schema.sql / customers is already loaded.
USE telco_churn;

DROP TABLE IF EXISTS segments;
CREATE TABLE segments (
    customerID    VARCHAR(20) PRIMARY KEY,
    R_score       INT,
    F_score       INT,
    M_score       INT,
    RFM_Total     INT,
    Segment       VARCHAR(40),
    FOREIGN KEY (customerID) REFERENCES customers(customerID)
);

DROP TABLE IF EXISTS risk_value;
CREATE TABLE risk_value (
    customerID          VARCHAR(20) PRIMARY KEY,
    Historical_CLV       DECIMAL(10, 2),
    Projected_CLV         DECIMAL(10, 2),
    Churn_Risk_Score      DECIMAL(6, 4),
    Risk_Value_Quadrant   VARCHAR(60),
    FOREIGN KEY (customerID) REFERENCES customers(customerID)
);

DROP VIEW IF EXISTS vw_dashboard;
CREATE VIEW vw_dashboard AS
SELECT
    c.customerID,
    c.gender,
    c.SeniorCitizen,
    c.Partner,
    c.Dependents,
    c.tenure,
    CASE
        WHEN c.tenure <= 6 THEN '0-6 mo'
        WHEN c.tenure <= 12 THEN '7-12 mo'
        WHEN c.tenure <= 24 THEN '13-24 mo'
        WHEN c.tenure <= 48 THEN '25-48 mo'
        ELSE '49-72 mo'
    END AS TenureBucket,
    c.PhoneService,
    c.MultipleLines,
    c.InternetService,
    c.OnlineSecurity,
    c.OnlineBackup,
    c.DeviceProtection,
    c.TechSupport,
    c.StreamingTV,
    c.StreamingMovies,
    c.Contract,
    c.PaperlessBilling,
    c.PaymentMethod,
    c.MonthlyCharges,
    c.TotalCharges,
    c.NumServices,
    c.Churn,
    c.ChurnFlag,
    s.R_score,
    s.F_score,
    s.M_score,
    s.RFM_Total,
    s.Segment,
    rv.Historical_CLV,
    rv.Projected_CLV,
    rv.Churn_Risk_Score,
    rv.Risk_Value_Quadrant
FROM customers c
LEFT JOIN segments s ON c.customerID = s.customerID
LEFT JOIN risk_value rv ON c.customerID = rv.customerID;
