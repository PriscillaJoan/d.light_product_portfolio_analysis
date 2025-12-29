# D.Light Retail Performance Analysis

## Project Overview
Analysis of D.Light's retail performance focusing on contract sales, payment collections, and product performance. This project includes data cleaning, exploratory analysis, and dashboard creation.

## Project Structure
```
## Project Structure
```
case_study/
│
├── analyses/                           
│
├── dbt_packages/                       
│
├── logs/                               
├── macros/                             
│
├── models/                             # dbt data models
│   └── staging/                        # Staging models for data cleaning
│       ├── readme
│       ├── schema.yml                  # dbt schema definitions
│       ├── stg_cleaned_contracts.sql   # Cleaned contracts staging model
│       ├── stg_cleaned_payments.sql    # Cleaned payments staging model
│       └── cleaned_contracts.sql       # Final cleaned contracts model
│
├── seeds/                              
│   └── .gitkeep
│
├── snapshots/                          
│   └── .gitkeep
│
├── target/                             
│
├── tests/                              # Data quality tests
│   ├── .gitkeep
│   └── outliers.sql                    # Tests for outlier detection
│
├── cleaned_data/                       # Cleaned datasets for analysis
│   ├── cleaned_payments.csv            # Valid payment records (1.7M rows)
│   ├── outlier_payments.csv            # Flagged outliers (761 rows)
│
├── data/                               # Raw data files
│   ├── bi_case_calls_combined.csv    # Original customer call records
│   ├── bi_case_contracts_combined.csv # Contract master data
│   ├── bi_case_payments_combined.csv   # Original payment data (with outliers)
│   ├── bi_case_service_tickets_combined.csv  # Original Customer service tickets
│   ├── clean_contract_table.csv     # Cleaned contract data with imputed nulls
│   └── data_dictionary.txt
│
├── workbooks/                          # Analysis workbooks
│   ├── sales_performance_analysis.ipynb  # Main analysis and outlier cleaning
│   └── workbook.ipynb                    # Additional analysis notebook
│
├── .gitignore                          # Git ignore rules
├── dbt_project.yml                     # dbt configuration
├── README.md                           # This file
└── d.light.db                          # SQLite database
```
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
2. **Business Model Mismatch**: PAYG customers make small daily payments not billion-dollar transfers
3. **Mathematical Impossibility**: At normal payment rates, these amounts would take millions of years to accumulate
4. **Concentrated Pattern**: Outliers cluster in specific months indicating system errors

### Impact

- **Before Cleaning**: Total revenue = $49.2 billion, Collection rate = 61,210%
- **After Cleaning**: Total revenue = $24.1 million, Collection rate = 25.29%

### Resolution
Created two datasets:
- `payments_cleaned`: 1,715,609 valid payment records for analysis
- `outlier_payments`: 761 suspicious records flagged for investigation

### Tables

#### `cleaned_data/cleaned_payments.csv`
Main payment information. Use this as outliers have been handled

**Key columns:**
- `contract_id` - Links to contracts.contractid
- `pay_month` - Payment date
- `total_paid` - Payment amount in USD


#### `data/cleaned_contract_table.csv` 
Cleaned payment records with nulls removed - **USE THIS for all analysis** 

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
```
git clone [repository-url]
cd case_study
```

2. Install Python dependencies
```
pip install pandas sqlite3, jupyter notebook
```

3. Install dbt
```
pip install dbt
pip install  dbt-snowflake
```

4. Initialize dbt
```
dbt init
```

## Usage

### Accessing Cleaned Data

**Python:**
```
import sqlite3
import pandas as pd

# Connect to database
conn = sqlite3.connect('d.light.db')
```


### Running Analysis

1. Open Jupyter notebooks:
```bash
jupyter notebook workbooks/sales_performance_analysis.ipynb
```

2. Run dbt models:
```
dbt run 
```

3. Test data quality:
```
dbt test
```

## Dashboards

Tableau dashboards available in `workbooks/`:
- Customer Aqcuisition
- Repayment ratio (actual/expected payments) per product
- Product Quality Analysis

**Important**: Ensure dashboards use `cleaned_payments` as the data source

## Files Description

### Database
- **d.light.db**: SQLite database containing all tables (contracts, payments_cleaned, outlier_payments)
```

