SELECT
    *
FROM {{ source('processing', 'cleaned_contracts') }}
