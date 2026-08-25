# Case Studies

## 1. Replacing Manual Operational Reports

**Problem:** Sell-through, margin, aging, inactive-item, sub-item, and PIM reports required recurring SalesPad exports, uploads, joins, cleanup, and distribution.

**Solution:** Centralized the reports in BigQuery, scheduled current and historical transformations, and delivered refreshed outputs through Apps Script, Cloud Run, Sheets, and email.

**Outcome:** Business users receive current data without rebuilding the reporting layer. Combined with related automations, the platform saves an estimated 400+ staff hours annually.

## 2. Catalog QA at Ecommerce Scale

**Problem:** Every new product requires image, copy, identifier, and listing review. More than 4,000 SKUs were created in 2026, and source systems can disagree about product state.

**Solution:** Built a normalized PIM-to-Magento audit that compares web and marketplace records, deduplicates source data, and writes daily exception snapshots.

**Outcome:** Reviewers can focus on missing listings and field-level discrepancies rather than manually comparing complete exports.

## 3. Catalog-Wide Product Attributes

**Problem:** More than 25,000 live listings need structured category attributes, but historical titles, descriptions, and specifications are inconsistent.

**Solution:** Built an AI-assisted pipeline using BigQuery, Python, and the Claude API. Category schemas constrain model output, while post-processing creates canonical values and upload-ready records.

**Outcome:** The first active category covers roughly 3,000 electric-guitar SKUs. The same framework is reusable across the full catalog.

## 4. Promotion Operations

**Problem:** Promotion terms were distributed across dozens of brand workbooks and had to be translated into reminders, buyer reports, pricing actions, and PIM imports.

**Solution:** Built alias-tolerant Apps Script ingestion, centralized the normalized records in BigQuery, synchronized Calendar and Tasks, and moved compute-heavy import generation to Cloud Run.

**Outcome:** One source update can drive multiple downstream workflows across approximately 53 brand spreadsheets while preserving review and exception steps.

## 5. Receipt-Lot Price Protection

**Problem:** Vendor credits can apply only to qualifying inventory receipts and vary by brand, cost, date, and available quantity.

**Solution:** Created a buyer-controlled submission workflow backed by a BigQuery procedure. It applies approved lower costs at receipt-lot level, checks source freshness, remains idempotent, and allows the effect to expire as protected inventory sells.

**Outcome:** The workflow improves cost and margin analysis without automating away the buyer's approval decision.

## 6. Multi-Carrier Shipping Economics

**Problem:** Carrier invoices, ERP orders, tracking numbers, multi-box shipments, and bundled products did not share a clean item-level cost grain.

**Solution:** Built a logged BigQuery procedure that normalizes multiple carriers, resolves order and tracking relationships, handles bills of material, and allocates cost to SKUs.

**Outcome:** Purchasing and margin analysis can use empirical SKU-level shipping costs instead of broad estimates.
