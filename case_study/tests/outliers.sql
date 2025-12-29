SELECT
    p.contract_id,
    p.total_paid_usd,
    c.total_contract_value_usd
FROM {{ source('processing', 'cleaned_payments') }} p
JOIN {{ source('processing', 'cleaned_contracts') }} c
  ON p.contract_id = c.contract_id
WHERE p.total_paid_usd > c.total_contract_value_usd
