# Case Studies

## 1. Replacing Manual Operational Reports

**Problem:** Sell-through, margin, aging, inactive-item, sub-item, and PIM reports required recurring SalesPad exports, uploads, joins, cleanup, and distribution.

**Solution:** Centralized the reports in BigQuery, scheduled current and historical transformations, and delivered refreshed outputs through Apps Script, Cloud Run, Sheets, and email.

**Outcome:** Business users receive current data without rebuilding the reporting layer. Combined with related automations, the platform saves an estimated 400+ staff hours annually.

## 2. PIM-to-Magento State Audit

**Problem:** PIM and Magento can disagree about the live state of a catalog containing more than 100,000 SKUs.

**Current implementation:** Magento product data is loaded in BigQuery, and the comparison framework normalizes identifiers and values before identifying missing listings and field-level mismatches. Loading the complete PIM dataset remains in progress.

**Intended outcome:** Reviewers will work from an exception queue instead of manually comparing full PIM and Magento exports.

## 3. Multimodal Listing QA

**Problem:** Structured state comparison cannot determine whether images, titles, product copy, descriptions, and short descriptions accurately represent a product. More than 4,000 new SKUs were created in 2026, and the same quality controls must eventually scale across the catalog.

**Planned solution:** Send listing content and images to the Claude API for discrepancy review, then use a second layer to resolve the correct product page and prepare an actionable support record.

**Intended outcome:** Focus human review on likely content defects and give the support team the exact listing link needed for correction.

## 4. Catalog-Wide Product Attributes

**Problem:** More than 25,000 live listings need structured category attributes, but historical titles, descriptions, and specifications are inconsistent.

**Solution:** Built an AI-assisted pipeline using BigQuery, Python, and the Claude API. Category schemas constrain model output, while post-processing creates canonical values and upload-ready records.

**Outcome:** The first active category covers roughly 3,000 electric-guitar SKUs. The same framework is reusable across the full catalog.

## 5. Promotion Operations

**Problem:** Promotion terms were distributed across dozens of brand workbooks and had to be translated into reminders, buyer reports, pricing actions, and PIM imports.

**Solution:** Built alias-tolerant Apps Script ingestion, centralized the normalized records in BigQuery, synchronized Calendar and Tasks, and moved compute-heavy import generation to Cloud Run.

**Outcome:** One source update can drive multiple downstream workflows across approximately 53 brand spreadsheets while preserving review and exception steps.

## 6. Receipt-Lot Price Protection

**Problem:** Vendor credits can apply only to qualifying inventory receipts and vary by brand, cost, date, and available quantity.

**Solution:** Created a buyer-controlled submission workflow backed by a BigQuery procedure. It applies approved lower costs at receipt-lot level, checks source freshness, remains idempotent, and allows the effect to expire as protected inventory sells.

**Outcome:** The workflow improves cost and margin analysis without automating away the buyer's approval decision.

## 7. Multi-Carrier Shipping Economics

**Problem:** Carrier invoices, ERP orders, tracking numbers, multi-box shipments, and bundled products did not share a clean item-level cost grain.

**Solution:** Built a logged BigQuery procedure that normalizes multiple carriers, resolves order and tracking relationships, handles bills of material, and allocates cost to SKUs.

**Outcome:** Purchasing and margin analysis can use empirical SKU-level shipping costs instead of broad estimates.
