# Telco Customer Retention & Churn Analysis

Customer segmentation, retention analysis, and churn prediction on the IBM
Telco Customer Churn dataset (7,043 customers). Pipeline: **pandas** (clean) →
**MySQL** (EDA via SQL) → **matplotlib/seaborn** (plots) → subscription-adapted
**RFM segmentation** → **scikit-learn** (churn model + CLV + risk/value
segments) → a **Power BI** dashboard.

## Prerequisites

- Python 3.12+ (packages in `requirements.txt`, includes JupyterLab/ipykernel)
- MySQL Server running locally, with a root password you know
- Power BI Desktop (only needed for the dashboard step)

## 1. Setup

```powershell
python -m pip install -r requirements.txt
```

Create a `.env` file in the project root (already present if you're continuing
this project — skip if so) with your MySQL credentials:

```
MYSQL_HOST=localhost
MYSQL_PORT=3306
MYSQL_USER=root
MYSQL_PASSWORD=<your password>
MYSQL_DB=telco_churn
```

`.env` is gitignored — never commit it. `scripts/utils_db.py` reads it at
runtime; nothing else in the codebase hardcodes credentials.

## 2. Run the pipeline

The pipeline lives entirely as Jupyter notebooks in `notebooks/` (the
original numbered `.py` scripts were removed once the notebooks covered the
same ground). `scripts/` only keeps the two shared helper modules the
notebooks import at runtime — `plot_style.py` and `utils_db.py` — nothing
runnable on its own. All charts render inline in the notebooks; nothing gets
written to disk as separate image files.

Notebook filenames don't carry step numbers, so **run them in this order**
(this is the one thing alphabetical order in a file browser won't get right
for you — e.g. `churn_clv_model.ipynb` sorts before `clean_data.ipynb`
alphabetically but must run after it):

| Order | Notebook | Should produce | If it fails |
|---|---|---|---|
| 1 | `clean_data.ipynb` | `Wrote 7043 rows to ...cleaned_telco.csv`, no assertion errors | Check the raw CSV wasn't moved/renamed |
| 2 | `load_to_mysql.ipynb` | `Loaded 7043 rows into customers table` | MySQL service not running, or bad `.env` credentials — see below |
| 3 | `eda_plots.ipynb` | 13 charts rendered inline, ends with `Top 20% of customers by spend generate 53.7% of total revenue` | MySQL connection error — same checklist as above |
| 4 | `segmentation.ipynb` | Segment counts summing to 7043, churn rate ranging ~8%–60% across segments | — |
| 5 | `model_comparison.ipynb` | Comparison table of 7 tuned models, ends with `Winner: <model>, Test ROC-AUC = ...`, saves `models/best_churn_model.joblib` | Takes ~5-10 min total (hyperparameter tuning across 7 models) — this is normal, not a hang. SVM is the slowest single model (~30-40s) |
| 6 | `churn_clv_model.ipynb` | `Loaded winning model: <ModelName>`, quadrant counts summing to 7043 | Needs `models/best_churn_model.joblib` from step 5 |
| 7 | `load_analytics_to_mysql.ipynb` | `Exported 7043 rows to ...powerbi_dashboard_data.csv` | Needs steps 4-6 already run |

```powershell
python -m ipykernel install --user --name python3 --display-name "Python 3 (DA_Project)"  # one-time
jupyter lab notebooks/
```

Each notebook locates the project root automatically (walks up from the
working directory looking for `requirements.txt`), so it works regardless of
where Jupyter's cwd ends up.

To re-run a notebook non-interactively (e.g. after changing something
upstream), from the project root:

```powershell
python -m nbconvert --to notebook --execute --inplace notebooks/eda_plots.ipynb
```

**Note:** on this machine, invoking `jupyter nbconvert` directly sometimes
hits `[WinError 4551] An Application Control policy has blocked this file` —
a Windows security policy blocking the `jupyter.exe` launcher shim specifically.
The workaround above (`python -m nbconvert ...`) routes through the already-trusted
Python interpreter instead and avoids it.

**Note:** `scripts/plot_style.py` detects whether it's running inside a
notebook kernel and only forces the headless `Agg` matplotlib backend when
it's *not* (i.e. when run as a plain script) — inside a notebook it leaves
the backend alone so charts render inline. If you ever see plots not
displaying in a notebook, check that this detection didn't get bypassed by
some other backend-forcing import running first.

**MySQL connection troubleshooting:** if any MySQL-dependent notebook errors,
first check the service is running:

```powershell
Get-Service -Name "*mysql*"
```

If it's stopped: `Start-Service MySQL80`. If credentials are wrong, edit `.env`
and re-run.

**`PermissionError` on `powerbi_dashboard_data.csv`:** this means something has
the file open and locked — usually Excel (if you opened the CSV to peek at it)
or, less commonly, Power BI Desktop mid-import. Close whatever has it open and
re-run `load_analytics_to_mysql.ipynb`. Power BI Desktop itself can usually
stay open — it only locks the file transiently during Get Data/Refresh, not
continuously.

## 3. Churn model selection

`model_comparison.ipynb` tunes and compares 7 scikit-learn classifiers
(Logistic Regression, Decision Tree, Random Forest, Gradient Boosting, SVM,
k-NN, Naive Bayes) via `RandomizedSearchCV`, on an expanded feature set (see
`scripts/feature_eng.py` — individual add-on service flags instead of just a
count, a `Contract x InternetService` interaction feature, a price-sensitivity
ratio, and a categorical tenure bucket, on top of the original fields).
**Logistic Regression won** (test ROC-AUC 0.849, narrowly ahead of the tuned
Random Forest at 0.847) — the winning pipeline is saved to
`models/best_churn_model.joblib` and loaded (never retrained) by
`churn_clv_model.ipynb`, so the model actually feeding the risk/value
quadrant and the Power BI dashboard is whichever one wins, not an assumption.

`scripts/feature_eng.py`'s `engineer_features()` is the single source of
truth for the feature set — both `model_comparison.ipynb` (trains on it) and
`churn_clv_model.ipynb` (scores the full population with it) import the same
function, so they can't silently drift apart.

To find a new winner after changing features or adding a model, just re-run
`model_comparison.ipynb` then `churn_clv_model.ipynb` — everything downstream
(CLV, risk/value quadrant, `risk_value_segments.csv` schema, the Power BI
data source) is written to be model-agnostic and doesn't need any changes.

## 4. Power BI dashboard

Built and complete — 4 pages (Executive Overview, Retention Drivers,
Segmentation, Churn Risk & CLV) on top of `data/powerbi_dashboard_data.csv`.
`powerbi/BUILD_GUIDE.md` and `powerbi/measures.dax` (the spec and DAX used to
build it) were removed after the dashboard was finished — if you need to
rebuild from scratch or extend it, the data source (`vw_dashboard` MySQL view
→ `data/powerbi_dashboard_data.csv`) is still generated by
`notebooks/load_analytics_to_mysql.ipynb`.

If you change anything upstream (re-clean data, retrain the model, etc.),
re-run `load_analytics_to_mysql.ipynb` to refresh `powerbi_dashboard_data.csv`,
then hit **Refresh** in Power BI.


<img width="1320" height="737" alt="image" src="https://github.com/user-attachments/assets/9791373c-604a-4a9f-92f2-2dea81ad2b0f" />
<img width="1322" height="742" alt="image" src="https://github.com/user-attachments/assets/dbf36427-2ac3-46fc-9fef-e8b4c11c1889" />
<img width="1317" height="737" alt="image" src="https://github.com/user-attachments/assets/f83e6a78-d181-493c-b65a-608f11531c0f" />
<img width="1331" height="740" alt="image" src="https://github.com/user-attachments/assets/4e7979ec-eba6-4eb7-8464-1a80baa4a5d7" />

## Project structure

```
DA_Project/
├── WA_Fn-UseC_-Telco-Customer-Churn.csv   raw data (untouched)
├── .env                                    MySQL credentials (gitignored)
├── requirements.txt
├── data/                                   pipeline outputs (CSV)
├── models/                                 best_churn_model.joblib -- winning pipeline from model_comparison.ipynb
├── sql/                                    schema + documented EDA queries
├── notebooks/                              the pipeline -- run in the order listed in "Run the pipeline" above
│   ├── clean_data.ipynb
│   ├── load_to_mysql.ipynb
│   ├── eda_plots.ipynb                     19 charts across these 4 notebooks (13+2+3+1), all rendered
│   ├── segmentation.ipynb                  inline -- no separate image files are written to disk
│   ├── model_comparison.ipynb              trains/tunes/compares 7 models, saves the winner to models/
│   ├── churn_clv_model.ipynb               loads the winner, never retrains
│   └── load_analytics_to_mysql.ipynb
├── scripts/                                shared modules the notebooks import: plot_style.py, utils_db.py,
│                                            feature_eng.py (single source of truth for the model's feature set)
└── powerbi/                                empty -- dashboard is built; see "Power BI dashboard" below
```

## Known limitations (documented, not bugs)

- This is a single snapshot, not a transaction log — RFM's Recency/Frequency
  are subscription-adapted (tenure / service count), not literal purchase-date
  RFM. See the markdown cells at the top of `notebooks/segmentation.ipynb`
  for why.
- Projected CLV uses a transparent tenure-based heuristic, not a survival or
  BG/NBD model — the data doesn't support a rigorous probabilistic estimate.

