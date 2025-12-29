SELECT
    *
FROM {{ source('processing', 'cleaned_payments') }}