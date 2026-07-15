-- ============================================================================
-- 05 — Maverick spend: buying outside the contract
-- Concepts: LEFT JOIN against contracts, NULL as a business signal,
--           conditional aggregation per business unit
-- ----------------------------------------------------------------------------
-- A contract exists for the category, but the buyer used another supplier.
-- That spend loses the negotiated conditions AND weakens your volume story
-- at the next negotiation. Target is usually < 5% maverick; >15% means the
-- process, the catalogue, or the contract itself has a problem.
-- ============================================================================

-- 5.1 Maverick rate per business unit
SELECT
    b.bu_name,
    ROUND(SUM(p.quantity * p.unit_price) / 1e6, 2)              AS spend_eur_m,
    ROUND(SUM(CASE WHEN ct.contract_id IS NULL
                   THEN p.quantity * p.unit_price ELSE 0 END) / 1e6, 2)
                                                                AS maverick_eur_m,
    ROUND(SUM(CASE WHEN ct.contract_id IS NULL
                   THEN p.quantity * p.unit_price ELSE 0 END) * 100.0
          / SUM(p.quantity * p.unit_price), 1)                  AS maverick_pct
FROM po_lines p
JOIN business_units b ON b.bu_id = p.bu_id
LEFT JOIN contracts ct
       ON ct.category_id = p.category_id
      AND ct.supplier_id = p.supplier_id
      AND p.po_date BETWEEN ct.valid_from AND ct.valid_to
GROUP BY b.bu_name
ORDER BY maverick_pct DESC;

-- 5.2 What does maverick buying cost? Compare average unit price paid
--     on-contract vs off-contract for the same items.
WITH labeled AS (
    SELECT
        p.item_id,
        p.quantity,
        p.unit_price,
        CASE WHEN ct.contract_id IS NULL THEN 'off_contract'
             ELSE 'on_contract' END AS channel
    FROM po_lines p
    LEFT JOIN contracts ct
           ON ct.category_id = p.category_id
          AND ct.supplier_id = p.supplier_id
          AND p.po_date BETWEEN ct.valid_from AND ct.valid_to
),
per_item AS (
    SELECT
        item_id,
        AVG(CASE WHEN channel = 'on_contract'  THEN unit_price END) AS on_avg,
        AVG(CASE WHEN channel = 'off_contract' THEN unit_price END) AS off_avg,
        SUM(CASE WHEN channel = 'off_contract' THEN quantity END)   AS off_qty
    FROM labeled
    GROUP BY item_id
    HAVING on_avg IS NOT NULL AND off_avg IS NOT NULL
)
SELECT
    ROUND(AVG(off_avg / on_avg - 1) * 100, 1)                   AS avg_off_contract_premium_pct,
    ROUND(SUM(off_qty * (off_avg - on_avg)) / 1e3, 0)           AS est_annualizable_leakage_eur_k
FROM per_item;
