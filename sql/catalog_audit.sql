-- Sanitized BigQuery example.
-- Compares the PIM source of truth with an ecommerce-channel export.

WITH pim AS (
  SELECT
    UPPER(TRIM(sku)) AS sku,
    NULLIF(TRIM(product_name), '') AS product_name,
    NULLIF(TRIM(upc), '') AS upc,
    active
  FROM `example_project.pim.products`
  QUALIFY ROW_NUMBER() OVER (
    PARTITION BY UPPER(TRIM(sku))
    ORDER BY updated_at DESC
  ) = 1
),

channel AS (
  SELECT
    UPPER(TRIM(sku)) AS sku,
    NULLIF(TRIM(title), '') AS product_name,
    NULLIF(TRIM(upc), '') AS upc,
    listing_status
  FROM `example_project.magento.products`
  QUALIFY ROW_NUMBER() OVER (
    PARTITION BY UPPER(TRIM(sku))
    ORDER BY extracted_at DESC
  ) = 1
),

compared AS (
  SELECT
    pim.sku,
    pim.product_name AS pim_name,
    channel.product_name AS channel_name,
    pim.upc AS pim_upc,
    channel.upc AS channel_upc,
    channel.listing_status,
    CASE
      WHEN channel.sku IS NULL THEN 'MISSING_FROM_CHANNEL'
      WHEN pim.product_name IS DISTINCT FROM channel.product_name THEN 'NAME_MISMATCH'
      WHEN pim.upc IS DISTINCT FROM channel.upc THEN 'UPC_MISMATCH'
      ELSE NULL
    END AS issue_type
  FROM pim
  LEFT JOIN channel USING (sku)
  WHERE pim.active
)

SELECT *
FROM compared
WHERE issue_type IS NOT NULL
ORDER BY issue_type, sku;
