-- Null-value rule for cash contracts:
-- Contracts classified as CASH (one-time payment) do not have financing terms. 
-- Therefore, for CASH contracts, the fields perc_deposit, tenor_length, and daily_amount_usd are expected to be NULL.
-- Step 1: Validation check to confirm that these fields are consistently NULL for each contract type
SELECT contract_type,
       SUM(CASE WHEN payment_frequency IS NULL THEN 1 ELSE 0 END) AS pf_nulls,
       SUM(CASE WHEN perc_deposit IS NULL THEN 1 ELSE 0 END) AS deposit_nulls,
       SUM(CASE WHEN tenor_length IS NULL THEN 1 ELSE 0 END) AS tenor_nulls,
       SUM(CASE WHEN daily_amount_usd IS NULL THEN 1 ELSE 0 END) AS daily_nulls,
       COUNT(*) AS total_contracts
FROM contracts
GROUP BY contract_type;

-- Step 2: Identify the 11 exceptional CASH contracts
-- Normally, payment_frequency and tenor_length should be NULL for cash contracts
-- These 11 records are exceptions
SELECT COUNT(*) AS invalid_cash_contracts
FROM contracts
WHERE contract_type = 'CASH'
  AND (
       payment_frequency IS NOT NULL
    OR perc_deposit IS NOT NULL
    OR daily_amount_usd IS NOT NULL
    OR tenor_length IS NOT NULL
  );
/*In these 11 cash contracts:
payment_frequency is written as "daily" and tenor_length is 0 */

SELECT *
FROM contracts
WHERE contract_type = 'CASH'
  AND (
       payment_frequency IS NOT NULL
    OR tenor_length IS NOT NULL
  );
  
-- Step 3:Fill the null values 
UPDATE contracts
SET 
    perc_deposit = 1,               -- full payment upfront
    payment_frequency = NULL,
    daily_amount_usd = NULL,
    tenor_length = 0
WHERE contract_type = 'CASH';


-- Step 4: Count remaining null values in FINANCED contracts
-- This helps identify missing data in key financing fields after excluding CASH contracts
-- Daily amount is the only financing field with null values(3728)
SELECT
    SUM(CASE WHEN payment_frequency IS NULL THEN 1 ELSE 0 END) AS pf_nulls,
    SUM(CASE WHEN perc_deposit IS NULL THEN 1 ELSE 0 END) AS deposit_nulls,
    SUM(CASE WHEN tenor_length IS NULL THEN 1 ELSE 0 END) AS tenor_nulls,
    SUM(CASE WHEN daily_amount_usd IS NULL THEN 1 ELSE 0 END) AS daily_nulls
FROM contracts
WHERE contract_type = 'FINANCED';

--Step 5: Investigate daily deposits field
-- The price_usd field is null where daily_amout_usd field is null
SELECT * FROM 
    Contracts
WHERE 
    DAILY_AMOUNT_USD IS NULL AND CONTRACT_TYPE = 'FINANCED'

/*
Assumption for filling missing daily_amount_usd in FINANCED contracts:
- Using the available fields: payment_frequency, perc_deposit, and tenor_length, we can make an assumption to estimate price and daily payment.
- Estimate method (assumption):
    1. Estimate price_usd using the average price of the same product where price_usd is missing.
    2. Compute financed amount = price_usd * (1 - perc_deposit)
    3. Compute daily_amount_usd = financed_amount / tenor_length
- This is purely an assumption for data completeness and may not reflect the actual contract value.
*/

UPDATE contracts
SET price_usd = CASE 
                    WHEN product = 'Small Solar' THEN 150
                    WHEN product = 'PAYGO_PHONE' THEN 200
                    WHEN product = 'Large Solar - Generation 1' THEN 300
                    WHEN product = 'Large Solar - Generation 2' THEN 280
                    WHEN product = 'PAYGO_PORTABLE' THEN 100
                    ELSE price_usd  -- keep original if not missing
                END
WHERE contract_type = 'FINANCED'
  AND price_usd IS NULL;

-- Add a flag column to track assumptions
ALTER TABLE contracts 
ADD COLUMN assumption_flag VARCHAR(20);

-- Compute missing daily_amount_usd based on price, perc_deposit, and tenor_length

UPDATE contracts
SET daily_amount_usd = (price_usd * (1 - perc_deposit)) / tenor_length
WHERE contract_type = 'FINANCED'
  AND daily_amount_usd IS NULL
  AND price_usd IS NOT NULL
  AND perc_deposit IS NOT NULL
  AND tenor_length IS NOT NULL;

  -- Fill the assumption_flag column
UPDATE contracts
SET assumption_flag = CASE
                      WHEN price_usd IS NULL OR daily_amount_usd IS NULL 
                      THEN 'ASSUMPTION'
                      ELSE 'ORIGINAL'
                      END;

-- After filling the values we have 1456 values that still have daily amout usd as null.

SELECT
    SUM(CASE WHEN payment_frequency IS NULL THEN 1 ELSE 0 END) AS pf_nulls,
    SUM(CASE WHEN perc_deposit IS NULL THEN 1 ELSE 0 END) AS deposit_nulls,
    SUM(CASE WHEN tenor_length IS NULL THEN 1 ELSE 0 END) AS tenor_nulls,
    SUM(CASE WHEN daily_amount_usd IS NULL THEN 1 ELSE 0 END) AS daily_nulls
FROM contracts
WHERE contract_type = 'FINANCED';

-- Some price null values also have product field as null. Without product type we cannot assign a price using assumptions.

SELECT *
FROM contracts
WHERE contract_type = 'FINANCED'
  AND product IS NULL;


-- flag all records without products by creating a new table and copy incomplete rows into it
CREATE TABLE null_financed_products AS
SELECT *
FROM contracts
WHERE contract_type = 'FINANCED'
AND product IS NULL ;

-- set an incomplete flag in the table
ALTER TABLE contracts
--drop column incomplete_flag
ADD incomplete_flag VARCHAR(20);

-- set default
UPDATE contracts
SET incomplete_flag = 'COMPLETE'
WHERE incomplete_flag IS NULL;

UPDATE contracts
SET incomplete_flag = COALESCE(
    (  -- Count number of missing fields
      IFF(product IS NULL, 1, 0) +
      IFF(price_usd IS NULL, 1, 0) +
      IFF(contract_type = 'FINANCED' AND tenor_length IS NULL, 1, 0) +
      IFF(contract_type = 'FINANCED' AND daily_amount_usd IS NULL, 1, 0) +
      IFF(contract_type = 'FINANCED' AND perc_deposit IS NULL, 1, 0)
    )::STRING,
    '0'  -- No missing fields
);



select * from contracts
-- check null products
-- Some cash contracts have the product type but dont have the price_usd
SELECT * FROM contracts WHERE product IS NOT NULL AND price_usd IS NULL;

-- Only null values left are in the cash contracts where price_usd is null
SELECT contract_type, COUNT(*) AS num_records
FROM contracts
WHERE product IS NOT NULL
  AND price_usd IS NULL
GROUP BY contract_type;

-- use price assumptions to fill the null values that have product values but no price value
UPDATE contracts
SET price_usd = CASE 
                    WHEN product = 'Small Solar' THEN 150
                    WHEN product = 'PAYGO_PHONE' THEN 200
                    WHEN product = 'Large Solar - Generation 1' THEN 300
                    WHEN product = 'Large Solar - Generation 2' THEN 280
                    WHEN product = 'PAYGO_PORTABLE' THEN 100
                    ELSE price_usd  -- keep original if product unknown
                END
WHERE contract_type = 'CASH'
  AND price_usd IS NULL;

-- check for null values in the finance fields. The fields left are field that dont have any product values
SELECT  * FROM contracts WHERE price_usd IS NULL

-- Move incomplete rows to a new table. They have already been flagged as incomplete
CREATE TABLE null_cash_products AS
SELECT *
FROM contracts
WHERE product IS NULL;


-- check for null values in sales_person_id. There is no other table with contract_id that we can use to fill the null values with. So leave as is and flag as incomplete also
select * from contracts where sales_person_id is null 

select * from contracts