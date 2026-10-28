"""
Shared feature engineering for churn modeling. Single source of truth for
both notebooks/model_comparison.ipynb (trains on these features) and
notebooks/churn_clv_model.ipynb (scores the full population using the
winning model trained on these same features) -- if each notebook built its
own feature set, they'd silently drift apart.

All added features are simple, interpretable, single-column derivations --
no blind polynomial expansion -- consistent with this project's existing
preference for transparent, explainable modeling choices.
"""

import pandas as pd

TENURE_BUCKET_BINS = [-1, 6, 12, 24, 48, 72]
TENURE_BUCKET_LABELS = ["0-6 mo", "7-12 mo", "13-24 mo", "25-48 mo", "49-72 mo"]

# Numeric inputs to the model, including the new engineered ratio feature.
NUMERIC_FEATURES = [
    "tenure", "MonthlyCharges", "TotalCharges", "NumServices",
    "AvgMonthlySpend", "ChargesPerService",
]

# Categorical inputs: the original demographic/service/billing fields, the
# individual add-on service flags (previously collapsed into NumServices
# only), plus the two new engineered categories.
CATEGORICAL_FEATURES = [
    "gender", "SeniorCitizen", "Partner", "Dependents",
    "PhoneService", "MultipleLines", "InternetService",
    "OnlineSecurity", "OnlineBackup", "DeviceProtection",
    "TechSupport", "StreamingTV", "StreamingMovies",
    "Contract", "PaperlessBilling", "PaymentMethod",
    "Contract_Internet", "TenureBucket",
]

FEATURES = NUMERIC_FEATURES + CATEGORICAL_FEATURES


def engineer_features(df):
    """Return a copy of df with the engineered columns added. Safe to call
    on data/cleaned_telco.csv directly, or on any subset with the same base
    columns (tenure, MonthlyCharges, NumServices, Contract, InternetService)."""
    df = df.copy()

    # Worst-combo interaction found in EDA (month-to-month + fiber optic =
    # 54.6% churn) as one column a linear model can use directly, not just
    # something tree models can implicitly reconstruct via splits.
    df["Contract_Internet"] = df["Contract"] + "|" + df["InternetService"]

    # Price-sensitivity / value-density proxy.
    df["ChargesPerService"] = df["MonthlyCharges"] / (df["NumServices"] + 1)

    # Categorical tenure, matching the buckets already used in
    # sql/02_eda_queries.sql -- lets non-tree models capture the non-linear
    # "early tenure = high risk" pattern a single linear coefficient can't.
    df["TenureBucket"] = pd.cut(
        df["tenure"], bins=TENURE_BUCKET_BINS, labels=TENURE_BUCKET_LABELS)
    df["TenureBucket"] = df["TenureBucket"].astype(str)

    return df
