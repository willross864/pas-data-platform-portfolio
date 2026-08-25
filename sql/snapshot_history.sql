-- Sanitized BigQuery example.
-- Appends a daily snapshot only after basic source-completeness checks pass.

DECLARE snapshot_date DATE DEFAULT CURRENT_DATE('America/New_York');
DECLARE source_rows INT64;
DECLARE minimum_expected_rows INT64 DEFAULT 1000;

SET source_rows = (
  SELECT COUNT(*)
  FROM `example_project.operations.current_inventory`
);

ASSERT source_rows >= minimum_expected_rows
  AS 'Current inventory appears incomplete; snapshot cancelled.';

MERGE `example_project.history.inventory_daily` AS target
USING (
  SELECT
    snapshot_date AS snapshot_date,
    sku,
    brand,
    quantity_on_hand,
    unit_cost
  FROM `example_project.operations.current_inventory`
) AS source
ON target.snapshot_date = source.snapshot_date
AND target.sku = source.sku

WHEN NOT MATCHED THEN
  INSERT (
    snapshot_date,
    sku,
    brand,
    quantity_on_hand,
    unit_cost
  )
  VALUES (
    source.snapshot_date,
    source.sku,
    source.brand,
    source.quantity_on_hand,
    source.unit_cost
  );
