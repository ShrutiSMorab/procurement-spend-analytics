-- ============================================================================
-- 04 — Price variance: same item, different prices
-- Concepts: GROUP BY item with MIN/MAX/AVG, HAVING, savings simulation
-- ----------------------------------------------------------------------------
-- If Business Unit A pays EUR 100 for the same item that BU B buys at
-- EUR 88, the gap is negotiable money. "Best-price alignment" — repricing
-- all volume at the best observed price — is the standard way to size the
-- opportunity (an upper bound, in practice you capture part of it).
-- ============================================================================

-- 4.1 Items with the widest price spread (min vs max unit price paid)
SELECT
    i.item_name,
    c.category_name,
    COUNT(*)                                        AS times_bought,
    ROUND(MIN(p.unit_price), 2)                     AS best_price,
    ROUND(MAX(p.unit_price), 2)                     AS worst_price,
    ROUND((MAX(p.unit_price) / MIN(p.unit_price) - 1) * 100, 1)
                                                    AS spread_pct
FROM po_lines p
JOIN items i      ON i.item_id = p.item_id
JOIN categories c ON c.category_id = p.category_id
GROUP BY i.item_id
HAVING COUNT(*) >= 20
ORDER BY spread_pct DESC
LIMIT 15;

-- 4.2 Savings opportunity: reprice every line at the item's best observed
--     price. actual spend - best-price spend = the size of the prize.
WITH best AS (
    SELECT item_id, MIN(unit_price) AS best_price
    FROM po_lines
    GROUP BY item_id
)
SELECT
    ROUND(SUM(p.quantity * p.unit_price) / 1e6, 2)              AS actual_spend_eur_m,
    ROUND(SUM(p.quantity * b.best_price) / 1e6, 2)              AS best_price_spend_eur_m,
    ROUND(SUM(p.quantity * (p.unit_price - b.best_price)) / 1e6, 2)
                                                                AS savings_potential_eur_m,
    ROUND(SUM(p.quantity * (p.unit_price - b.best_price)) * 100.0
          / SUM(p.quantity * p.unit_price), 1)                  AS savings_pct
FROM po_lines p
JOIN best b ON b.item_id = p.item_id;
