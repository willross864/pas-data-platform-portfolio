-- Sanitized BigQuery examples for scheduled data-quality checks.

-- 1. Duplicate business keys
SELECT
  snapshot_date,
  sku,
  COUNT(*) AS row_count
FROM `example_project.history.inventory_daily`
WHERE snapshot_date = CURRENT_DATE('America/New_York')
GROUP BY snapshot_date, sku
HAVING COUNT(*) > 1;

-- 2. Required-field failures
SELECT
  COUNTIF(sku IS NULL OR TRIM(sku) = '') AS missing_sku,
  COUNTIF(quantity_on_hand IS NULL) AS missing_quantity,
  COUNTIF(unit_cost < 0) AS negative_cost
FROM `example_project.operations.current_inventory`;

-- 3. Reconciliation between source and transformed totals
WITH source AS (
  SELECT SUM(quantity_on_hand) AS quantity
  FROM `example_project.operations.current_inventory`
),

snapshot AS (
  SELECT SUM(quantity_on_hand) AS quantity
  FROM `example_project.history.inventory_daily`
  WHERE snapshot_date = CURRENT_DATE('America/New_York')
)

SELECT
  source.quantity AS source_quantity,
  snapshot.quantity AS snapshot_quantity,
  source.quantity - snapshot.quantity AS difference
FROM source
CROSS JOIN snapshot
WHERE source.quantity != snapshot.quantity;
