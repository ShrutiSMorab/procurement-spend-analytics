-- ============================================================================
-- 06 — Tail spend: too many tiny suppliers
-- Concepts: CTE reuse, threshold bucketing, consolidation sizing
-- ----------------------------------------------------------------------------
-- Every supplier carries overhead: onboarding, master data, invoices, risk
-- checks. Dozens of sub-EUR-50k suppliers in one category = consolidation
-- opportunity (fewer, better-negotiated suppliers).
-- ============================================================================

-- 6.1 Tail suppliers (< EUR 100k over 24 months) per category
WITH supplier_cat AS (
    SELECT
        p.category_id,
        p.supplier_id,
        SUM(p.quantity * p.unit_price) AS spend
    FROM po_lines p
    GROUP BY p.category_id, p.supplier_id
)
SELECT
    c.category_name,
    COUNT(*)                                             AS suppliers_total,
    SUM(CASE WHEN sc.spend < 100000 THEN 1 ELSE 0 END)   AS tail_suppliers,
    ROUND(SUM(CASE WHEN sc.spend < 100000 THEN sc.spend ELSE 0 END) / 1e3, 0)
                                                         AS tail_spend_eur_k
FROM supplier_cat sc
JOIN categories c ON c.category_id = sc.category_id
GROUP BY c.category_name
ORDER BY tail_suppliers DESC;

-- 6.2 Consolidation shortlist: categories where tail spend could move to
--     the existing contracted suppliers (biggest prize first)
WITH supplier_cat AS (
    SELECT p.category_id, p.supplier_id,
           SUM(p.quantity * p.unit_price) AS spend
    FROM po_lines p
    GROUP BY p.category_id, p.supplier_id
)
SELECT
    c.category_name,
    SUM(CASE WHEN sc.spend < 100000 THEN 1 ELSE 0 END)          AS suppliers_to_exit,
    ROUND(SUM(CASE WHEN sc.spend < 100000 THEN sc.spend ELSE 0 END) / 1e3, 0)
                                                                AS spend_to_move_eur_k,
    -- rule of thumb: consolidation + renegotiation captures ~5% of moved spend
    ROUND(SUM(CASE WHEN sc.spend < 100000 THEN sc.spend ELSE 0 END) * 0.05 / 1e3, 0)
                                                                AS est_savings_eur_k
FROM supplier_cat sc
JOIN categories c ON c.category_id = sc.category_id
GROUP BY c.category_name
HAVING suppliers_to_exit >= 5
ORDER BY spend_to_move_eur_k DESC;
