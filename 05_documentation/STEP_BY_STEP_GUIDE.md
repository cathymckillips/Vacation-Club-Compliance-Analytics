# Step-by-step build guide

## Step 1 — Understand the business question
Read README and `rule_catalog.md`. Define the distinction between *anomaly*, *alert*, *investigation*, and *confirmed violation*. Deliverable: a two-sentence project objective.

## Step 2 — Generate synthetic data
From the project root run `python 02_python/generate_data.py`. Inspect six CSV files under `01_data`. Confirm membership tiers, bookings, points movements, contact center actions, and rules. Run with `--members 10000 --bookings 75000` later for scale testing; expect larger files and longer imports.

## Step 3 — Build the SQL database
In SSMS create `VacationClubCompliance`, select it in the database dropdown, and execute `03_sql/01_schema.sql`. Verify eight tables exist. Never run against a production database.

## Step 4 — Import and validate
Install ODBC Driver 18 and `pyodbc`. Run `python 02_python/load_sql_server.py --server YOUR_SERVER --trusted`. Then run `02_quality_checks.sql`. Fix any errors before proceeding. Import once into an empty database.

## Step 5 — Create six detection rules
Execute `03_detect_alerts.sql`. Read each CTE and verify that CR001–CR006 return candidate alerts. Run the script again and confirm alert counts do not increase. Discuss why flagged behavior alone is not a confirmed violation.

## Step 6 — Build investigation and reporting layers
Execute `04_investigations_and_views.sql`. Inspect `SELECT TOP 20 * FROM dbo.vw_ComplianceAlertDetail`. Review simulated case outcomes and open/closed dates. Verify the points balance and monthly control views.

## Step 7 — Connect Power BI
Get Data > SQL Server > server and database > Import. Choose dimensions, facts, and reporting views in `04_powerbi/model_and_pages.md`. In Model view establish one-to-many relationships. Disable automatic date/time if using a formal date table.

## Step 8 — Create DAX measures
Copy each measure from `04_powerbi/DAX_measures.txt` into Power BI (Modeling > New measure). Format percentages as Percentage; count metrics as whole numbers. Cross-check with SQL queries.

## Step 9 — Build page 1 (executive overview)
Add KPI cards, alert counts by rule, risk distribution, and member tier slicer. Add a footnote: "Synthetic data; illustrative rules; alerts are not proven violations." Save as `06_outputs/VacationClubCompliance.pbix`.

## Step 10 — Build pages 2 and 3
Build reservation trend, member drill-through, negative balances, and unapproved adjustment analysis. Clearly disclose the independent synthetic reservation/ledger generation.

## Step 11 — Build pages 4 and 5
Build case aging, dispositions, overdue cases, team workload, and monthly unapproved adjustment rates. Avoid implying the descriptive trend is a tested control intervention.

## Step 12 — Test, document, publish
Complete `validation_test_plan.md`. Capture screenshots to `06_outputs/`. Write a short executive summary describing detected patterns, plausible root causes, recommended controls, and limitations. Publish only synthetic files, scripts, and safe screenshots to GitHub.

## Suggested presentation narrative
"I built a synthetic vacation-club compliance monitoring system that detects six classes of operational exceptions, maintains auditable alert and investigation records, and supports prioritization through SQL and Power BI. I separated detection from confirmed violations and documented the limits of each business rule."
