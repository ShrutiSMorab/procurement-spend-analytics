-- ============================================================================
-- 01 — Data quality checks
-- Concepts: LEFT JOIN + IS NULL, GROUP BY/HAVING, CASE consistency checks
-- ----------------------------------------------------------------------------
-- Same principle as always: verify the data before computing a single KPI.
-- In real spend analysis this step catches duplicate invoice loads, POs
-- pointing to deleted suppliers, and negative prices from credit notes.
-- ============================================================================

-- 1.1 Row counts per table
SELECT 'business_units' AS table_name, COUNT(*) AS rows FROM business_units
UNION ALL SELECT 'categories', COUNT(*) FROM categories
UNION ALL SELECT 'suppliers',  COUNT(*) FROM suppliers
UNION ALL SELECT 'items',      COUNT(*) FROM items
UNION ALL SELECT 'contracts',  COUNT(*) FROM contracts
UNION ALL SELECT 'po_lines',   COUNT(*) FROM po_lines;

-- 1.2 Orphan check: every PO line must reference a real supplier
SELECT COUNT(*) AS lines_with_unknown_supplier
FROM po_lines p
LEFT JOIN suppliers s ON s.supplier_id = p.supplier_id
WHERE s.supplier_id IS NULL;

-- 1.3 Sanity: no zero/negative quantities or prices
SELECT
    SUM(CASE WHEN quantity   <= 0 THEN 1 ELSE 0 END) AS bad_quantity,
    SUM(CASE WHEN unit_price <= 0 THEN 1 ELSE 0 END) AS bad_price
FROM po_lines;

-- 1.4 Category consistency: the item's category must match the PO line's
--     category (a classic ERP data-entry error to check for)
SELECT COUNT(*) AS category_mismatches
FROM po_lines p
JOIN items i ON i.item_id = p.item_id
WHERE i.category_id <> p.category_id;

-- 1.5 Date range of the dataset
SELECT MIN(po_date) AS first_po, MAX(po_date) AS last_po FROM po_lines;
