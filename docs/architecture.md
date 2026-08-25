# Architecture

## Design Goals

The platform was built to solve three recurring operational problems:

1. Core data was split across ERP exports, PIM, Magento, vendor workbooks, carrier invoices, and Google Sheets.
2. Large SKU requests required repeated exports, spreadsheet joins, and manual cleanup.
3. Recurring reports depended on a person remembering to export, upload, reconcile, and distribute them.

The resulting design centralizes source data and business logic in BigQuery while preserving Sheets as an accessible interface for non-technical users.

## Layers

### Sources

- SalesPad ERP reports for sales, inventory, purchasing, receipts, tracking, aging, and bills of material
- PIM catalog exports and product-change snapshots
- Magento web, Amazon, eBay, and Reverb product data
- Vendor pricing and promotion workbooks
- UPS, Estes, and Ward invoice data
- Operational control data maintained in Google Sheets

### Warehouse

BigQuery is divided into seven functional datasets:

| Dataset | Responsibility |
|---|---|
| `Magento_Data` | Channel product records and work-in-progress catalog-audit snapshots |
| `Mappings` | Shared canonical mappings |
| `PIM_Data` | Current product data and change history |
| `SKU_Attributes` | AI output, canonical values, and review views |
| `SalesPad_Reports` | Sales, inventory, purchasing, margin, and operational reporting |
| `Vendor_PriceLists` | Vendor price and promotion history |
| `shipping` | Carrier invoices, reconciliation, dimensions, and SKU shipping costs |

Large history tables are partitioned by snapshot or event date. Frequently filtered identifiers such as SKU or brand are used as clustering keys where they improve scan efficiency.

### Transformation and Controls

- Scheduled queries maintain snapshots and histories.
- Stored procedures coordinate multi-step workflows such as shipping and price protection.
- Views expose current, enriched, and exception-based datasets.
- Parameterized queries protect user-driven workflows.
- Freshness checks prevent selected downstream writes when sources are stale.
- Run logs and ledgers support reconciliation and late-arriving data.

### Services

Cloud Run services handle work that is better suited to Python or Node than Apps Script:

- Daily item-receipt reporting
- Weekly new-item reporting
- Promotion import generation
- Report-freshness monitoring
- Printable SKU-tag generation

Cloud Build uses path-filtered triggers so a change deploys only the affected service.

### User Interfaces

Apps Script connects the platform to existing purchasing and operations workflows:

- Brand price-list compare and key generation
- PIM and report refreshes
- Promotion, calendar, task, and embargo synchronization
- Price-protection submission
- Catalog and SKU-action queues
- BigQuery-backed ad hoc update tools

Each workflow has technical and user-facing SOPs so business users can operate it and technical stakeholders can troubleshoot it.

## Catalog QA Patterns

Catalog QA consists of two distinct systems:

### Cross-System State Audit

The state audit will compare more than 100,000 PIM SKUs with their live Magento state. It normalizes identifiers and values before reporting missing listings and field-level mismatches. Magento data is available in BigQuery, while the complete PIM dataset still needs to be loaded before full-catalog coverage is possible.

### Multimodal Listing Review

The planned content-QA layer will evaluate product images, titles, product copy, descriptions, and short descriptions through the Claude API. Its output will feed a second resolution step that identifies the correct product link and creates an actionable support record. This workflow is separate from both the structured state audit and the attribute-enrichment program.

## AI Enrichment Pattern

The product-attribute system uses a repeatable staged design:

1. BigQuery selects products that still require enrichment.
2. Python builds category-specific structured requests from titles, descriptions, and specifications.
3. Claude returns schema-constrained attributes rather than free-form text.
4. Validation and canonical-mapping scripts normalize the output.
5. Raw results remain append-only for auditability.
6. Cleaned values and review exceptions return to BigQuery.
7. Approved records are formatted for PIM upload.

The current rollout is processing roughly 3,000 electric-guitar SKUs and is designed for more than 25,000 live listings.

## Reliability Roadmap

The next engineering phase is focused on reproducibility and automated validation:

- Run unit and integration tests before Cloud Build deployment.
- Add warehouse assertions for freshness, uniqueness, nulls, reconciliation totals, and row-count anomalies.
- Version all production SQL in a shared repository.
- Combine dependent snapshot steps into single transactional scripts where possible.
- Move remaining manually invoked warehouse procedures to service-account schedules with alerts.
- Complete the full PIM ingestion required for 100,000+ SKU state comparison.
- Add multimodal content-QA validation and product-link resolution.
