# PAS Data Platform

A production data and automation platform built for a high-volume music retail e-commerce business. The platform centralizes product, inventory, purchasing, pricing, sales, receiving, and shipping data in BigQuery and delivers operational tools through Google Sheets, Apps Script, and Cloud Run.

The system replaces repetitive spreadsheet preparation with governed, repeatable workflows while keeping human review at the center of pricing and purchasing decisions.

## Business impact

- Saves an estimated **280-300 hours per year** in recurring report maintenance
- Supports pricing, purchasing, inventory, product, receiving, and shipping decisions
- Gives nontechnical teams direct access to current and historical data through familiar Google Sheets interfaces
- Preserves historical product, inventory, pricing, and shipping data for reconciliation and trend analysis
- Standardizes vendor workflows across **33 brand-specific Apps Script projects**

## Architecture

```text
Operational sources
|-- SalesPad ERP reports
|-- Product Information Management exports
|-- Vendor price lists and promotions
|-- UPS, Estes, and Ward carrier invoices
|-- Product and SKU-management spreadsheets
`-- Buyer-maintained operational inputs
          |
          v
Ingestion and application layer
|-- Google Apps Script validation and uploads
|-- Python services on Cloud Run
|-- Cloud Scheduler with authenticated OIDC requests
`-- BigQuery scheduled queries
          |
          v
Google BigQuery: pas-data-platform
|-- PIM_Data
|-- SalesPad_Reports
|-- Vendor_PriceLists
|-- shipping
|-- Mappings
`-- Magento_Data
          |
          v
Delivery layer
|-- Buyer and purchasing reports
|-- Vendor Compare, KEY, and Promo sheets
|-- Inventory aging and sell-through analysis
|-- Pricing and price-protection tools
|-- Shipping-cost analysis
`-- Automated receiving and new-item notifications
```

## Production scale

Snapshot from August 2026:

| Area | Example asset | Scale |
|---|---|---:|
| Product catalog | `PIM_Data.PIM_Master` | 131K+ SKUs |
| Product change history | `PIM_Data.PIM_History` | 159K+ changes |
| Current sell-through | `SalesPad_Reports.SellThru2_Current` | 131K SKUs |
| Sell-through history | `SalesPad_Reports.Sellthru2_History` | 3.4M+ rows |
| Inventory aging history | `SalesPad_Reports.Aging_History` | 797K+ rows |
| Margin history | `SalesPad_Reports.Green_Main_History` | 933K+ rows |
| Item receipts | `SalesPad_Reports.Item_Receipts` | 325K+ rows |
| Vendor pricing history | `Vendor_PriceLists.vendor_data` | 57K+ rows |
| UPS invoices | `shipping.ups_invoices` | 524K+ rows |
| Sales and margin detail | `SalesPad_Reports.sales_margin_report` | 1.2M+ rows |

History tables use date partitioning and, where appropriate, SKU or item-level clustering to control query cost and improve analytical performance.

## Data domains

### Product information

`PIM_Data` maintains the current product catalog and an hourly field-level history.

- `PIM_Master` - current product attributes, identifiers, prices, and channel status
- `PIM_LastSnapshot` - prior state used for change detection
- `PIM_History` - partitioned product change history clustered by SKU
- `Price_Change_Events` - normalized view of detected price events

### Sales, inventory, and purchasing

`SalesPad_Reports` supports daily operational reporting and longer-term analysis.

- `SellThru2_Current` and `Sellthru2_History` - current and historical sell-through by SKU
- `Aging_Current` and `Aging_History` - current and historical inventory aging
- `Green_Main` and `Green_Main_History` - margin, sales, cost, quantity, and profitability metrics
- `BoM_Current` - bill-of-materials relationships for kit and multi-box products
- `Item_Receipts` - purchasing receipt activity used by receiving notifications
- `Tracking_Numbers` - shipment data staged for carrier reconciliation
- `Price_Protection` and related views - pricing-event and reimbursement analysis
- `open_po_lines`, `kit_build_review`, and `sales_margin_report` - purchasing and operational detail

### Vendor pricing and promotions

`Vendor_PriceLists` provides standardized vendor history across brand-specific spreadsheet formats.

- `vendor_data` - partitioned price-list history clustered by brand and price-list date
- `vendor_dim_master` - standardized vendor dimension data
- `promos` - active and historical promotional pricing inputs

### Shipping-cost attribution

`shipping` reconciles carrier invoices with SalesPad order and item data.

- Raw invoice tables for UPS, Estes, and Ward
- Staging tables for repeatable uploads
- Carrier-specific enrichment and item-shipment tables
- `shipping_enriched` - resolved shipment-level facts
- `shipping_resolved_multi_tracking` - multi-package resolution
- `ups_dim_sku_summary` and `ups_dim_bom_summary` - dimensional shipment summaries
- `shipping_item_avg_cost` - average shipping cost by SKU
- `pipeline_run_log` - operational audit history

### Reference mappings

`Mappings` contains maintained reference data such as SKU-code assignments used by downstream workflows.

## Key workflows

### Vendor price-list automation

Thirty-three brand-specific Apps Script projects normalize vendor files and support a consistent workflow:

1. Import and validate the vendor price list.
2. Standardize source columns into a common BigQuery schema.
3. Compare price-list dates and flag cost, MAP, new-item, and discontinued-item changes.
4. Present changes for human review.
5. Refresh the approved KEY and promotional outputs.
6. Preserve pricing history in BigQuery.

### Product change history

Two hourly scheduled queries detect changes between `PIM_Master` and the prior snapshot. Changed fields are written to a partitioned history table before the comparison snapshot is refreshed.

### Inventory and sell-through history

Daily scheduled queries append idempotent snapshots for sell-through, inventory aging, and margin reporting. Buyer-facing Sheets consume current tables and views without requiring manual ERP exports to be reformatted.

### Shipping reconciliation

The shipping pipeline joins carrier invoices to SalesPad shipments and resolves issues such as normalized tracking numbers, multi-package shipments, kit components, and carrier-specific formats.

```sql
CALL `pas-data-platform.shipping.refresh_shipping_pipeline`();
```

The final SKU-level shipping-cost outputs feed profitability and operational analysis.

### Price protection and repricing

BigQuery procedures and views identify qualifying price events, calculate protected inventory exposure, and create reviewable repricing outputs. These workflows support decisions; they do not automatically change production prices without review.

### Receiving and new-item notifications

Authenticated Cloud Scheduler jobs invoke Python services on Cloud Run to:

- Deliver buyer-organized item-receipt reports after source-data freshness checks
- Identify first-time receipts and high-value restocks
- Enrich notifications with product and operational context

SMTP credentials are stored in Secret Manager, and scheduled requests use dedicated service-account identities.

### SKU tag generation

A Cloud Run service generates printable PDF product tags and barcodes from SKU requests. It reads primary product attributes from BigQuery and supports a controlled spreadsheet fallback for products awaiting ingestion.

## Scheduled operations

The production platform currently uses seven BigQuery scheduled queries:

| Scheduled query | Frequency | Purpose |
|---|---|---|
| PIM History - Insert Changes | Hourly | Detect and append product changes |
| PIM History - Refresh Snapshot | Hourly | Refresh the comparison snapshot |
| Update Green Main History | Daily | Preserve SKU-level margin history |
| Update Sellthru2 History | Daily | Preserve sell-through history |
| Upload SalesPad Tracking Numbers | Daily | Incrementally load shipment data |
| Update Aging History | Daily | Preserve inventory-aging history |
| Apply Price Protection | Intraday | Refresh price-protection calculations |

Cloud Scheduler separately invokes two authenticated email services on daily or weekly business schedules.

## BigQuery routines

The platform uses stored procedures and reusable functions for complex business logic:

- `shipping.refresh_shipping_pipeline`
- `SalesPad_Reports.apply_price_protection`
- `SalesPad_Reports.protect_transfer`
- `SalesPad_Reports.green_brand_period`
- `SalesPad_Reports.price_round`

## Data-quality approach

- Normalize SKUs, tracking numbers, dates, vendor identifiers, and numeric fields before matching
- Use parameterized SQL where values enter queries from applications
- Make recurring history loads idempotent at the business-date level
- Separate staging, current-state, historical, and presentation assets
- Record pipeline executions and source freshness
- Use header and named-range mappings in spreadsheet automations so column movement does not silently break workflows
- Keep a human approval step for operationally sensitive pricing and purchasing outputs

## Technology

- **Google BigQuery** - warehouse, analytical SQL, views, scheduled queries, partitioning, clustering, and stored procedures
- **Google Apps Script** - spreadsheet interfaces, source validation, BigQuery uploads, and workflow automation
- **Python and Cloud Run** - scheduled reporting and notification services
- **Cloud Scheduler** - authenticated service invocation
- **Secret Manager and IAM** - credential storage and least-privilege service access
- **Google Sheets** - accessible operational interface for purchasing and operations teams
- **Git and GitHub** - source archival, review, and documentation

## Design principles

1. BigQuery is the durable analytical source of truth.
2. Google Sheets is an interface, not the historical database.
3. Automate repetitive preparation while preserving human review for consequential decisions.
4. Prefer incremental and idempotent processing over destructive reloads.
5. Document workflows so another operator can run and troubleshoot them.
6. Keep credentials out of source code and repositories.

## Repository scope

This public repository documents architecture and selected implementation patterns without publishing proprietary source data, credentials, internal file identifiers, customer communications, or private automation code.

---

Built and maintained by **William Ross**.
