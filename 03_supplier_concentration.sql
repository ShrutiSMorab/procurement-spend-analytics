-- ============================================================================
-- 03 — Supplier concentration (Pareto / ABC analysis)
-- Concepts: CTEs, cumulative SUM() OVER (ORDER BY ...), RANK, bucketing
-- ----------------------------------------------------------------------------
-- Procurement's most famous rule of thumb: ~20% of suppliers carry ~80% of
-- spend. The cumulative-percentage pattern below is THE window-function
-- showcase — the running total "so far" down a ranked list.
-- ============================================================================

-- 3.1 Top 15 suppliers by spend, with cumulative % of total
WITH supplier_spend AS (
    SELECT
        s.supplier_name,
        SUM(p.quantity * p.unit_price) AS spend
    FROM po_lines p
    JOIN suppliers s ON s.supplier_id = p.supplier_id
    GROUP BY s.supplier_id
)
SELECT
    supplier_name,
    ROUND(spend / 1e6, 2)                                           AS spend_eur_m,
    ROUND(spend * 100.0 / SUM(spend) OVER (), 1)                    AS pct_of_total,
    ROUND(SUM(spend) OVER (ORDER BY spend DESC) * 100.0
          / SUM(spend) OVER (), 1)                                  AS cumulative_pct
FROM supplier_spend
ORDER BY spend DESC
LIMIT 15;

-- 3.2 The Pareto check itself: how many suppliers make up 80% of spend?
WITH ranked AS (
    SELECT
        SUM(p.quantity * p.unit_price) AS spend,
        SUM(SUM(p.quantity * p.unit_price)) OVER
            (ORDER BY SUM(p.quantity * p.unit_price) DESC) AS cum_spend,
        SUM(SUM(p.quantity * p.unit_price)) OVER ()        AS total_spend
    FROM po_lines p
    GROUP BY p.supplier_id
)
SELECT
    COUNT(*)                                                AS suppliers_for_80_pct,
    (SELECT COUNT(DISTINCT supplier_id) FROM po_lines)      AS total_active_suppliers,
    ROUND(COUNT(*) * 100.0 /
          (SELECT COUNT(DISTINCT supplier_id) FROM po_lines), 1)
                                                            AS pct_of_supplier_base
FROM ranked
WHERE cum_spend <= total_spend * 0.80;

-- 3.3 ABC classification: A = top 80% of spend, B = next 15%, C = last 5%
WITH ranked AS (
    SELECT
        s.supplier_name,
        SUM(p.quantity * p.unit_price) AS spend,
        SUM(SUM(p.quantity * p.unit_price)) OVER
            (ORDER BY SUM(p.quantity * p.unit_price) DESC) * 1.0
          / SUM(SUM(p.quantity * p.unit_price)) OVER ()    AS cum_share
    FROM po_lines p
    JOIN suppliers s ON s.supplier_id = p.supplier_id
    GROUP BY s.supplier_id
)
SELECT
    CASE WHEN cum_share <= 0.80 THEN 'A (top 80% of spend)'
         WHEN cum_share <= 0.95 THEN 'B (next 15%)'
         ELSE                        'C (tail 5%)' END      AS abc_class,
    COUNT(*)                                                AS suppliers,
    ROUND(SUM(spend) / 1e6, 2)                              AS spend_eur_m
FROM ranked
GROUP BY abc_class
ORDER BY abc_class;
