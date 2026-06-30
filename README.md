# PAS Data Platform

A centralized BigQuery data warehouse and automation platform built for a music retail e-commerce business. Consolidates inventory, sales, shipping, vendor, and product data into a single analytics environment — replacing manual reporting workflows and enabling automated purchasing decisions.

---

## Business Impact

- **280–300 hours/year saved** in manual report maintenance (~7 work weeks)
- **~$10K–$11K annual productivity value** from eliminated manual workflows
- Automated purchase order generation based on real-time SKU-level data
- Shifted buyer time from data preparation to decision-making

---

## Architecture

```
Data Sources
├── SalesPad (ERP / inventory)
├── PIM (product information)
├── Vendor Price Lists
├── Carrier Invoices (UPS, Estes, Ward)
└── Sales Channel Data

Processing Layer
└── Google Apps Script
    ├── Data validation and cleaning
    ├── BigQuery upload pipelines
    └── Automated report delivery

Data Warehouse
└── Google BigQuery (pas-data-platform)
    ├── PIM_Data
    ├── SalesPad_Reports
    ├── Vendor_PriceLists
    └── shipping

Reporting Layer
└── Google Sheets
    ├── Buyer purchasing reports
    ├── Aging and sell-through reports
    ├── Vendor compare and KEY sheets
    └── Green Report (margin, sales, profit by SKU)
```

---

## Datasets

### PIM_Data
Product information management data with hourly ingestion and change tracking.
- `PIM_Master` — full product catalog with pricing, listing status, UPCs, part numbers
- `PIM_LastSnapshot` — current state used for change detection
- `PIM_History` — partitioned change log (clustered by SKU)

### SalesPad_Reports
Sales, inventory, and purchasing analytics.
- `Sellthru2_Current` / `Sellthru2_History` — sell-through rates by SKU (daily snapshots)
- `Aging_Current` / `Aging_History` — inventory aging by SKU
- `SKU_Channel_Sales` / `SKU_Weekly_Metrics` — sales performance by channel and week
- `Open_PO_Lines` — open purchase orders
- `Green_Main` — margin, sales, profit, and KPIs across 30/90 day, 6m, 12m windows
- `BoM_Current` — bill of materials for kit products

### Vendor_PriceLists
Vendor pricing history with brand-level tracking.
- `vendor_data` — partitioned by upload date, clustered by brand
- `vendor_dim_master` — vendor dimension table

### Shipping
Multi-carrier shipping cost pipeline (UPS, Estes, Ward).
- Raw invoice tables per carrier
- Enrichment and matching tables joining carrier data to SalesPad orders
- `shipping_item_avg_cost` — final average shipping cost by SKU
- `pipeline_run_log` — audit log for each pipeline run

---

## Key Pipelines

### Shipping Cost Pipeline
Carrier invoices are uploaded via Apps Script into BigQuery. A stored procedure reconciles tracking numbers across carriers and SalesPad, resolving multi-box and BOM shipments, and produces an average shipping cost per SKU used in margin reporting.

```sql
CALL `pas-data-platform.shipping.refresh_shipping_pipeline`();
```

### Sell-Through Pipeline
Daily and weekly BigQuery snapshots are pushed to Google Sheets via Apps Script on a scheduled trigger. Buyers access current and historical sell-through data without any manual exports.

### Vendor Price List Automation
Vendor price list tabs are imported into brand-specific Google Sheets. Scripts run Compare, KEY, and Promo updates — detecting cost/MAP changes, new items, and discontinued items — and upload pricing history to BigQuery.

### PIM Automation
SKU lookups against `PIM_Master` are exposed to non-technical users via Google Sheets menu options. Used for inbound shipment prep, NSR workflows, and listing audits.

---

## Scheduled Queries

| Query | Schedule | Purpose |
|---|---|---|
| PIM History - Insert Changes | Hourly | Detect and log PIM field changes |
| PIM History - Refresh Snapshot | Hourly | Refresh comparison snapshot |
| Update Sellthru2_History | Daily 7:00 AM | Append daily sell-through snapshot |
| Upload Tracking Numbers | Daily 7:30 AM | Sync SalesPad tracking data |
| Refresh SKU PO Weekly Metrics | Daily 7:35 AM | Update PO metrics by SKU |
| Refresh SKU Channel Sales | Daily 7:40 AM | Update channel sales metrics |

---

## Tech Stack

- **Google BigQuery** — data warehouse, SQL analytics, stored procedures, scheduled queries
- **Google Apps Script** — ETL automation, BigQuery API, Sheets API
- **Google Cloud Platform** — IAM, service accounts, API management
- **Google Sheets** — reporting layer and buyer interface
- **SQL** — CTEs, window functions, aggregations, joins, partitioning

---

## Stack Notes

All pipelines are built without third-party ETL tools. Apps Script handles ingestion, transformation, and delivery. BigQuery handles storage, historical tracking, and analytical queries. Google Sheets serves as the interface for non-technical purchasing and operations teams.

---

*Built and maintained by Will Ross*
