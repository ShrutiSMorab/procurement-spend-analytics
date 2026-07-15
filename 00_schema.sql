-- ============================================================================
-- 00_schema.sql — Indirect procurement spend database
-- ============================================================================
-- Design notes:
--   * Classic spend-cube shape: WHO bought (business_units), WHAT was bought
--     (categories, items), FROM WHOM (suppliers), and the transactions
--     themselves (po_lines) at line-item grain.
--   * contracts holds the negotiated agreements per category. Any spend in a
--     contracted category placed with a NON-contracted supplier is
--     "maverick spend" — a core procurement leakage metric.
--   * items carry a list_price so we can measure price variance: the same
--     item bought at different unit prices across suppliers and BUs.
-- ============================================================================

DROP TABLE IF EXISTS po_lines;
DROP TABLE IF EXISTS contracts;
DROP TABLE IF EXISTS items;
DROP TABLE IF EXISTS suppliers;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS business_units;

CREATE TABLE business_units (
    bu_id    INTEGER PRIMARY KEY,
    bu_name  TEXT NOT NULL,
    city     TEXT NOT NULL
);

CREATE TABLE categories (
    category_id    INTEGER PRIMARY KEY,
    category_name  TEXT NOT NULL UNIQUE      -- indirect categories only
);

CREATE TABLE suppliers (
    supplier_id    INTEGER PRIMARY KEY,
    supplier_name  TEXT NOT NULL,
    country        TEXT NOT NULL
);

CREATE TABLE items (
    item_id      INTEGER PRIMARY KEY,
    item_name    TEXT NOT NULL,
    category_id  INTEGER NOT NULL REFERENCES categories(category_id),
    list_price   REAL NOT NULL               -- reference price in EUR
);

CREATE TABLE contracts (
    contract_id  INTEGER PRIMARY KEY,
    category_id  INTEGER NOT NULL REFERENCES categories(category_id),
    supplier_id  INTEGER NOT NULL REFERENCES suppliers(supplier_id),
    valid_from   TEXT NOT NULL,              -- ISO date
    valid_to     TEXT NOT NULL
);

CREATE TABLE po_lines (
    po_line_id   INTEGER PRIMARY KEY,
    po_id        TEXT NOT NULL,              -- PO header number (several lines share one)
    po_date      TEXT NOT NULL,              -- ISO date
    bu_id        INTEGER NOT NULL REFERENCES business_units(bu_id),
    supplier_id  INTEGER NOT NULL REFERENCES suppliers(supplier_id),
    category_id  INTEGER NOT NULL REFERENCES categories(category_id),
    item_id      INTEGER NOT NULL REFERENCES items(item_id),
    quantity     INTEGER NOT NULL,
    unit_price   REAL NOT NULL               -- EUR, actually paid
);

CREATE INDEX idx_po_supplier ON po_lines(supplier_id);
CREATE INDEX idx_po_category ON po_lines(category_id, po_date);
CREATE INDEX idx_po_item     ON po_lines(item_id);
