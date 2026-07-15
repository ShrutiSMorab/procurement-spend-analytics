-- ============================================================================
-- 02 — Spend overview: the spend cube
-- Concepts: SUM(qty*price), GROUP BY several dimensions, % of total with
--           window functions, strftime month bucketing
-- ----------------------------------------------------------------------------
-- "Where does the money go?" — the first question of every spend analysis.
-- The classic cuts: by category, by business unit, by month.
-- ============================================================================

-- 2.1 Total spend, PO lines, active suppliers (headline numbers)
SELECT
    ROUND(SUM(quantity * unit_price) / 1e6, 2) AS total_spend_eur_m,
    COUNT(*)                                   AS po_lines,
    COUNT(DISTINCT supplier_id)                AS active_suppliers,
    COUNT(DISTINCT po_id)                      AS purchase_orders
FROM po_lines;

-- 2.2 Spend by category, with % of total.
--     SUM(SUM(...)) OVER () = window function on top of an aggregate:
--     the inner SUM is per category, the outer OVER () spans all rows.
SELECT
    c.category_name,
    ROUND(SUM(p.quantity * p.unit_price) / 1e6, 2)         AS spend_eur_m,
    ROUND(SUM(p.quantity * p.unit_price) * 100.0
          / SUM(SUM(p.quantity * p.unit_price)) OVER (), 1) AS pct_of_total
FROM po_lines p
JOIN categories c ON c.category_id = p.category_id
GROUP BY c.category_name
ORDER BY spend_eur_m DESC;

-- 2.3 Spend by business unit
SELECT
    b.bu_name,
    ROUND(SUM(p.quantity * p.unit_price) / 1e6, 2) AS spend_eur_m,
    COUNT(DISTINCT p.supplier_id)                  AS suppliers_used
FROM po_lines p
JOIN business_units b ON b.bu_id = p.bu_id
GROUP BY b.bu_name
ORDER BY spend_eur_m DESC;

-- 2.4 Monthly spend trend (feed for the dashboard line chart)
SELECT
    strftime('%Y-%m', po_date)                     AS month,
    ROUND(SUM(quantity * unit_price) / 1e3, 0)     AS spend_eur_k
FROM po_lines
GROUP BY month
ORDER BY month;
