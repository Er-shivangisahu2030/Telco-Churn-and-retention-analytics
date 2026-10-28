-- Schema for the Telco Customer Churn analysis project.
CREATE DATABASE IF NOT EXISTS telco_churn;
USE telco_churn;

-- Drop child tables (from 03_powerbi_schema.sql) first if they exist -- they
-- carry FK constraints on customers, so dropping customers first fails on a
-- pipeline re-run once step 7 has ever been executed.
DROP VIEW IF EXISTS vw_dashboard;
DROP TABLE IF EXISTS segments;
DROP TABLE IF EXISTS risk_value;
DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
    customerID          VARCHAR(20) PRIMARY KEY,
    gender               VARCHAR(10),
    SeniorCitizen        VARCHAR(5),
    Partner               VARCHAR(5),
    Dependents            VARCHAR(5),
    tenure                INT,
    PhoneService          VARCHAR(5),
    MultipleLines         VARCHAR(25),
    InternetService       VARCHAR(15),
    OnlineSecurity        VARCHAR(25),
    OnlineBackup          VARCHAR(25),
    DeviceProtection      VARCHAR(25),
    TechSupport           VARCHAR(25),
    StreamingTV           VARCHAR(25),
    StreamingMovies       VARCHAR(25),
    Contract              VARCHAR(20),
    PaperlessBilling      VARCHAR(5),
    PaymentMethod         VARCHAR(30),
    MonthlyCharges        DECIMAL(8, 2),
    TotalCharges          DECIMAL(10, 2),
    Churn                 VARCHAR(5),
    AvgMonthlySpend       DECIMAL(8, 2),
    NumServices           INT,
    ChurnFlag              TINYINT,
    INDEX idx_contract (Contract),
    INDEX idx_churn (Churn),
    INDEX idx_internet (InternetService)
);
