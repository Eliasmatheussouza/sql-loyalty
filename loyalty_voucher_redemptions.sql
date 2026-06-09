-- ============================================================
-- Loyalty Voucher Redemption Pipeline
-- Identifies customers who successfully redeemed a monthly
-- loyalty voucher benefit at the point of sale (POS).
--
-- Note: All project names, dataset references, partner names,
-- and identifiers have been anonymized for portfolio purposes.
-- ============================================================

CREATE OR REPLACE TABLE `your-project.your_dataset.loyalty_voucher_redemptions`
AS
-- updated
WITH email AS (
    SELECT
        a.email,
        b.customer_id
    FROM
        `your-project.your_dataset.campaign_segment` a
    INNER JOIN
        `your-project.your_dataset.dim_loyalty_customer` b
        ON a.document = LPAD(SAFE_CAST(b.tax_id AS STRING), 11, '0')
    WHERE
        REGEXP_CONTAINS(TRIM(a.email), r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        AND LENGTH(TRIM(a.email)) > 5
    QUALIFY ROW_NUMBER() OVER (PARTITION BY b.customer_id ORDER BY a.updated_at) = 1
),

items AS (
    SELECT
        b.email,
        b.customer_id,
        a.product_name = 'Loyalty Voucher at POS' AS loyalty_contracts
    FROM `your-project.your_dataset.fact_loyalty_redemptions` a
    INNER JOIN email b
        ON a.customer_id = b.customer_id
    WHERE
        redemption_status = 'OK - Product Delivered'
        AND redemption_id NOT IN (000000001, 000000002)
        AND partner_name = 'Your Partner'
    GROUP BY 1, 2, 3
)

SELECT
    email,
    customer_id,
    loyalty_contracts
FROM items
WHERE loyalty_contracts = TRUE;
