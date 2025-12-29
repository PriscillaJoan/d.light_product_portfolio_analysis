# D.Light Retail Performance Analysis

## Project Overview
Analysis of D.Light's retail performance focusing on contract sales, payment collections, and product performance. This project includes data cleaning, exploratory analysis, and dashboard creation.

## Project Structure
```
case_study/
│
├── analyses/                           
│
├── dbt_packages/
│                      
├── dbt_logs/  
│
├── macros/                             
│
├── models/                             # dbt data models
│   └── staging/                        # Staging models for data cleaning
│       └── schema.yml
│
├── seeds/                             
├── snapshots/                         
├── target/                             
│
├── tests/                             
│
├── cleaned_data/                       # Cleaned datasets for analysis
│   ├── cleaned_payments.csv            # Valid payment records (1.7M rows)
│   ├── outlier_payments.csv            # Flagged outliers (761 rows)
│   ├── bi_case_calls_combined.csv
│   ├── bi_case_contracts_combined.csv
│   ├── bi_case_payments_combined.csv
│   ├── bi_case_service_tickets_combined.csv
│   ├── clean_contract_table.csv      # Cleaned contract tables with assumptions in some financial fields
│   └── data_dictionary.txt
│
├── sql_files/                          # SQL scripts
│   └── contracts_cleaning.sql          # scrip containing cleaning logic for the contract csv file
│
├── workbooks/                          # Analysis workbooks
│   ├── sales_performance_analysis.ipynb  # workbook containing cleaning logic for outliers in the payments table
│   └── workbook.ipynb
│
├── .gitignore                          # Git ignore rules
├── dbt_project.yml                     # dbt configuration
├── d.light.db                          # SQLite database
└── README.md                           # This file
```

## Data Quality Issues & Cleaning

### Problem Identified
Discovered **761 outlier payment records** (0.04% of all payments) that inflated reported revenue by **61,210%**.

### Examples of Impossible Payments

| Product | Contract Price | Largest Outlier Payment | Times Over Price |
|---------|---------------|------------------------|------------------|
| Small Solar | $150 | $1.87 billion | 12.45 million × |
| Large Solar Gen 1 | $300 | $7.59 billion | 25.29 million × |
| PAYGO Phone | $200 | $130,000 | 650 × |

### Why These Are Data Errors

1. **Economic Impossibility**: Customers paying billions for $150-$300 products
2. **Business Model Mismatch**: PAYG customers make small daily payments (~$0.30/day), not billion-dollar transfers
3. **Mathematical Impossibility**: At normal payment rates, these amounts would take millions of years to accumulate
4. **Concentrated Pattern**: Outliers cluster in specific months (June 2024, March-April 2025, August 2025), indicating system errors

### Impact

- **Before Cleaning**: Total revenue = $49.2 billion, Collection rate = 61,210%
- **After Cleaning**: Total revenue = $24.1 million, Collection rate = 25.29%

### Resolution
Created two datasets:
- `payments_cleaned`: 1,715,609 valid payment records for analysis
- `outlier_payments`: 761 suspicious records flagged for investigation

## Database Schema

### Tables

#### `contracts`
Main contract information including product details, pricing, and customer demographics.

**Key columns:**
- `contractid` - Unique contract identifier
- `sales_month` - Contract signing date
- `region` - Geographic region
- `product` - Product type
- `price_usd` - Contract price
- `payment_frequency` - Payment schedule (DAILY, WEEKLY, etc.)
- `tenor_length` - Contract duration in days
- `customer_gender` - Customer demographics
- `occupation` - Customer occupation

#### `payments` (original)
Raw payment records - **DO NOT USE for analysis (contains outliers)**

#### `payments_cleaned` 
Cleaned payment records with outliers removed - **USE THIS for all analysis**

**Key columns:**
- `contract_id` - Links to contracts.contractid
- `pay_month` - Payment date
- `total_paid` - Payment amount in USD

#### `outlier_payments`
Flagged suspicious payment records for investigation (761 rows)

## Setup Instructions

### Prerequisites
- Python 3.8+
- SQLite
- dbt
- Tableau Desktop (for dashboards)

### Installation

1. Clone the repository
```bash
git clone [repository-url]
cd case_study
```

2. Install Python dependencies
```bash
pip install pandas sqlite3 jupyter notebook
```

3. Install dbt
```bash
pip install dbt-core dbt-sqlite
```

4. Initialize dbt
```bash
dbt deps
dbt run
dbt test
```

## Usage

### Accessing Cleaned Data

**Python:**
```python
import sqlite3
import pandas as pd

# Connect to database
conn = sqlite3.connect('d.light.db')


### Running Analysis

1. Open Jupyter notebooks:
```bash
jupyter notebook workbooks/sales_performance_analysis.ipynb
```

2. Run dbt models:
```bash
dbt run 
```

3. Test data quality:
```bash
dbt test
```

## Dashboards

Tableau dashboards available in `workbooks/`:
- Contract Acquisition Trends
- Repayment Analysis
- Ticket Outcomes

**Important**: Ensure dashboards use `cleaned_payments` as the data source

## Data Dictionary

### Key Metrics
- **Collection Rate**: (Revenue Collected / Contract Value) × 100
- **Active Contracts**: Contracts with at least one payment
- **Contract Value**: Total expected payment (price_usd)

### Contract Status
- `ORIGINAL` - First-time contract
- `FINANCED` - Standard payment plan
- `DAILY` - Daily payment frequency

### Products
- Small Solar - Entry-level solar product ($150)
- Large Solar Gen 1 - First generation large solar ($300)
- Large Solar Gen 2 - Second generation large solar ($280)
- PAYGO Phone - Mobile phone with PAYG plan ($200)
- PAYGO Portable - Portable device ($100)

## Files Description

### Cleaned Data Files
- **cleaned_payments.csv**: Clean payment records ready for analysis (1,715,609 rows)
- **outlier_payments.csv**: Suspicious payment records for investigation (761 rows)
- **bi_case_contracts_combined.csv**: Contract master data
- **bi_case_payments_combined.csv**: Original payment data (with outliers)
- **bi_case_service_tickets_combined.csv**: Original Customer service tickets
- **bi_case_calls_combined.csv**: Original customer call records

### Database
- **d.light.db**: SQLite database containing all tables (contracts, payments_cleaned, outlier_payments)
```




