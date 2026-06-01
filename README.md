# 🏷️ Loyalty Voucher Redemption — BigQuery SQL Pipeline

SQL pipeline built in **BigQuery (GoogleSQL)** to identify customers who successfully redeemed a monthly loyalty voucher benefit granted by a partner program — enabling CRM and CDP teams to track benefit utilization and trigger personalized campaigns.

> ⚠️ All project names, dataset references, partner names, and identifiers in this query have been anonymized for portfolio purposes. The logic and structure reflect real production code.

---

## What it does

This query identifies customers who have effectively used a monthly loyalty voucher benefit at the point of sale (POS), crossing two data sources:

1. **Campaign segment table** — contains customer emails enriched by the CDP platform
2. **Loyalty dimension and fact tables** — contain redemption history with status and product details

The result is a deduplicated table of customers flagged as active benefit users (`loyalty_contracts = TRUE`), ready to be consumed by downstream CRM pipelines or CDP attribute sync jobs.

---

## Pipeline Logic

```
Campaign Segment (CDP)
        │
        │  JOIN on tax_id (CPF)
        ▼
Loyalty Customer Dimension
        │
        │  Deduplicate by customer (ROW_NUMBER)
        ▼
email CTE — one row per customer
        │
        │  JOIN on customer_id
        ▼
Loyalty Fact Table (redemptions)
        │
        │  Filter: status = delivered, correct partner, exclude known bad IDs
        ▼
items CTE — flag loyalty_contracts = TRUE/FALSE
        │
        ▼
Final table — customers who used the benefit
```

---

## Key Techniques

| Technique | Purpose |
|---|---|
| `QUALIFY ROW_NUMBER()` | Deduplicates customers keeping the earliest CDP record |
| `LPAD(SAFE_CAST(...), 11, '0')` | Normalizes tax ID format for safe joining across sources |
| Boolean column from equality expression | Flags benefit usage directly in SELECT |
| `NOT IN (...)` | Excludes known erroneous redemption IDs |
| `CREATE OR REPLACE TABLE` | Overwrites the output table on each scheduled run |

---

## Output

| Column | Type | Description |
|---|---|---|
| `email` | STRING | Customer email from CDP |
| `customer_id` | STRING | Internal customer identifier |
| `loyalty_contracts` | BOOLEAN | TRUE if customer redeemed the monthly voucher benefit |

---

## Stack

| Tool | Purpose |
|---|---|
| BigQuery (GoogleSQL) | Query execution and table materialization |
| CDP Platform | Source of customer email and segment data |
| Loyalty Data Warehouse | Source of redemption fact and dimension tables |

---

## Context

This query is part of a broader **CRM data pipeline** that syncs customer attributes from BigQuery to a CDP platform via REST API. The output table feeds an attribute sync job that updates customer profiles in real time, enabling targeted loyalty campaigns based on benefit usage behavior.
