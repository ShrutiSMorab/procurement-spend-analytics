# Procurement Spend Analytics — Complete Study Dump

*Everything behind the €92.5M case study in one place: the data model, every field, sample raw rows, and each analysis step with its SQL, the fields it touches, and its result. Read top to bottom and you can defend any number in the report or deck.*

**Source:** `spend.db` (synthetic SQLite) from `github.com/ShrutiSMorab/procurement-spend-analytics`.
**Companion file:** `spend-raw-data.xlsx` — the full raw data, one sheet per table, plus a field dictionary sheet.

---

## 1. The data model in one picture

The database is a **spend cube**: one big fact table of transactions (`po_lines`) surrounded by small dimension tables that describe them.

```
                    business_units          contracts
                          │                    │  │
     WHO bought ──────────┤                    │  │
                          ▼                    ▼  ▼
   items ──WHICH item──►  po_lines  ◄──WHAT category── categories
                          ▲   ▲
                          │   └── FROM WHOM ── suppliers
                          └────── the transactions themselves
```

Every question in the study is answered by summing `quantity × unit_price` on `po_lines` and grouping by a different dimension.

| Table | Rows | Role | What one row means |
|---|---|---|---|
| `po_lines` | 13,199 | **Fact** | One line of one purchase order |
| `suppliers` | 109 | Dimension | One supplier |
| `items` | 118 | Dimension | One catalogue item |
| `categories` | 10 | Dimension | One indirect spend category |
| `contracts` | 20 | Dimension | One negotiated agreement (category + supplier + dates) |
| `business_units` | 4 | Dimension | One internal buying unit |

(4,400 distinct purchase orders — `po_id` — spread across those 13,199 lines; 24 months, Jul 2024 → Jun 2026.)

---

## 2. Every field, in plain English

**`business_units`** — the four internal buyers
- `bu_id` — primary key
- `bu_name` — e.g. *Operations South*
- `city` — Berlin, Hamburg, Munich

**`categories`** — the ten indirect spend categories
- `category_id` — primary key
- `category_name` — e.g. *Marketing Services*

**`suppliers`** — the 109 vendors
- `supplier_id` — primary key
- `supplier_name`
- `country` — e.g. DE, AT

**`items`** — the 118 catalogue items
- `item_id` — primary key
- `item_name`
- `category_id` — → `categories` (which category the item sits in)
- `list_price` — a reference price in EUR. **Not** what was actually paid — the analysis uses the real paid price on `po_lines` instead.

**`contracts`** — the 20 negotiated agreements
- `contract_id` — primary key
- `category_id` — → `categories`
- `supplier_id` — → `suppliers`
- `valid_from`, `valid_to` — the dates the contract is active. This table is what makes maverick spend measurable.

**`po_lines`** — the fact table, one row per PO line
- `po_line_id` — primary key
- `po_id` — the PO header number (several lines share one PO)
- `po_date` — when it was placed
- `bu_id` — → `business_units` (**who** bought)
- `supplier_id` — → `suppliers` (**from whom**)
- `category_id` — → `categories` (**what** category)
- `item_id` — → `items` (**which** item)
- `quantity` — units bought
- `unit_price` — **EUR actually paid per unit**

> **The one formula that runs through everything:** `spend = quantity × unit_price`.

---

## 3. Sample raw rows (first rows of each table)

**business_units**
```
bu_id  bu_name            city
1      Central Functions  Berlin
2      Operations North   Hamburg
3      Operations South   Munich
4      Digital & Tech     Berlin
```

**categories**
```
category_id  category_name
1            IT Hardware
2            Software & SaaS
3            Facilities Services
4            Logistics Services
5            Marketing Services
6            Professional Services
...          (10 total)
```

**suppliers** (109 total)
```
supplier_id  supplier_name    country
1            Spree Partners   AT
2            Core Services    DE
3            Solid Concepts   DE
4            Falcon Agentur   DE
5            Green Office     DE
```

**items** (118 total)
```
item_id  item_name            category_id  list_price
1        IT Hardware item 01  1            1489.86
2        IT Hardware item 02  1            383.00
3        IT Hardware item 03  1            1522.27
4        IT Hardware item 04  1            2381.76
```

**contracts** (20 total)
```
contract_id  category_id  supplier_id  valid_from   valid_to
1            1            1            2024-07-01   2026-12-31
2            1            2            2024-07-01   2026-12-31
3            2            8            2024-07-01   2026-12-31
```

**po_lines** (13,199 total)
```
po_line_id  po_id    po_date     bu_id  supplier_id  category_id  item_id  quantity  unit_price
1           PO-1001  2024-07-10  2      1            1            8        2         1578.24
2           PO-1001  2024-07-09  1      4            1            9        1         448.52
3           PO-1001  2024-07-22  2      1            1            8        7         1601.78
4           PO-1002  2024-07-10  4      3            1            6        4         1540.85
```

*(Full data for every table is in `spend-raw-data.xlsx`.)*

---

## 4. Step-by-step analysis

Six stages, in the order a real spend analysis runs. For each: the question, the SQL, the fields it touches, what it does, and the result.

### Stage 0 — Data quality (trust the data first)

**Question:** can we trust the data before computing a single KPI?

```sql
-- Orphan check: every PO line must reference a real supplier
SELECT COUNT(*) AS lines_with_unknown_supplier
FROM po_lines p
LEFT JOIN suppliers s ON s.supplier_id = p.supplier_id
WHERE s.supplier_id IS NULL;

-- No zero/negative quantities or prices
SELECT SUM(CASE WHEN quantity <= 0 THEN 1 ELSE 0 END) AS bad_quantity,
       SUM(CASE WHEN unit_price <= 0 THEN 1 ELSE 0 END) AS bad_price
FROM po_lines;

-- Item's category must match the PO line's category
SELECT COUNT(*) AS category_mismatches
FROM po_lines p JOIN items i ON i.item_id = p.item_id
WHERE i.category_id <> p.category_id;
```

**Fields:** `po_lines.supplier_id / quantity / unit_price / item_id / category_id`, `items.category_id`.
**Result:** 0 orphans, 0 bad quantities/prices, 0 category mismatches. Data is clean — proceed.
**Talking point:** in the real world this step catches duplicate invoice loads, POs pointing at deleted suppliers, and negative prices from credit notes.

### Stage 1 — Spend overview (where does the money go?)

**Question:** total spend, and how it splits by category, business unit and month.

```sql
-- Spend by category, with % of total (window function over an aggregate)
SELECT c.category_name,
       ROUND(SUM(p.quantity * p.unit_price) / 1e6, 2) AS spend_eur_m,
       ROUND(SUM(p.quantity * p.unit_price) * 100.0
             / SUM(SUM(p.quantity * p.unit_price)) OVER (), 1) AS pct_of_total
FROM po_lines p
JOIN categories c ON c.category_id = p.category_id
GROUP BY c.category_name
ORDER BY spend_eur_m DESC;
```

**Fields:** `po_lines.quantity / unit_price / category_id / bu_id / po_date`, `categories.category_name`, `business_units.bu_name`.
**How it works:** the inner `SUM` is spend per category; `SUM(SUM(...)) OVER ()` is the grand total across all categories, so the ratio gives each category's share.

**Result — spend by category:**
```
Marketing Services      24.95   27.0%
Professional Services   19.94   21.6%
Facilities Services     13.38   14.5%
Logistics Services       9.52   10.3%
IT Hardware              6.55    7.1%
Software & SaaS          6.35    6.9%
Travel                   5.02    5.4%
MRO & Maintenance        4.15    4.5%
Packaging                1.49    1.6%
Office Supplies          1.15    1.2%
```
**By business unit:** Central Functions €28.18M · Operations South €24.48M · Operations North €22.23M · Digital & Tech €17.61M.
**Takeaway:** ~63% of spend in three categories; a recurring October spike (~€5.0M vs €3.4M baseline) flags year-end budget-flush.

### Stage 2 — Supplier concentration (Pareto / ABC)

**Question:** how few suppliers carry most of the spend?

```sql
-- How many suppliers make up 80% of spend?
WITH ranked AS (
  SELECT SUM(p.quantity * p.unit_price) AS spend,
         SUM(SUM(p.quantity * p.unit_price)) OVER
             (ORDER BY SUM(p.quantity * p.unit_price) DESC) AS cum_spend,
         SUM(SUM(p.quantity * p.unit_price)) OVER () AS total_spend
  FROM po_lines p GROUP BY p.supplier_id
)
SELECT COUNT(*) AS suppliers_for_80_pct
FROM ranked WHERE cum_spend <= total_spend * 0.80;
```

**Fields:** `po_lines.quantity / unit_price / supplier_id`, `suppliers.supplier_name`.
**How it works:** sum spend per supplier, sort descending, keep a running (cumulative) total, and count how many suppliers it takes to reach 80%.

**Result:**
```
14 suppliers (12.8% of the 109-supplier base) = 80% of spend
Top supplier alone = 16.1% of total
ABC:  A = 14 suppliers, €72.86M   |   B = 34, €14.85M   |   C = 61, €4.79M
```
**Takeaway:** concentration is leverage *and* single-supplier risk. The 61-supplier C-tail shares under €5M.

### Stage 3 — Price variance (same item, different price)

**Question:** are we paying different prices for identical items, and what's the gap worth?

```sql
-- Reprice every line at the item's best observed price
WITH best AS (
  SELECT item_id, MIN(unit_price) AS best_price
  FROM po_lines GROUP BY item_id
)
SELECT ROUND(SUM(p.quantity * (p.unit_price - b.best_price)) / 1e6, 2) AS savings_potential_eur_m,
       ROUND(SUM(p.quantity * (p.unit_price - b.best_price)) * 100.0
             / SUM(p.quantity * p.unit_price), 1) AS savings_pct
FROM po_lines p JOIN best b ON b.item_id = p.item_id;
```

**Fields:** `po_lines.item_id / unit_price / quantity`, `items.item_name`, `categories.category_name`.
**How it works:** for each `item_id` find the lowest price ever paid (`MIN(unit_price)`), then for every line measure the gap between what was paid and that best price. **`list_price` is deliberately not used** — the benchmark is the best *actual* price, not the catalogue price.

**Result — theoretical ceiling €5.68M (6.1%). By category (where the euros live):**
```
Professional Services   €1.49M   (7.5%)
Marketing Services      €1.29M   (5.2%)
Logistics Services      €0.72M   (7.6%)
Facilities Services     €0.54M   (4.1%)
IT Hardware             €0.52M   (7.9%)
```
**Takeaway / the reframe:** IT Hardware has the worst *percentage* spread (33–37% on individual items), but Professional Services and Marketing hold ~3× the recoverable *euros* because they're far bigger. Start where the euros are.

### Stage 4 — Maverick spend (buying off-contract)

**Question:** how much spend bypasses contracts, and what does it cost?

```sql
-- Maverick rate per business unit
SELECT b.bu_name,
       ROUND(SUM(CASE WHEN ct.contract_id IS NULL
                      THEN p.quantity * p.unit_price ELSE 0 END) * 100.0
             / SUM(p.quantity * p.unit_price), 1) AS maverick_pct
FROM po_lines p
JOIN business_units b ON b.bu_id = p.bu_id
LEFT JOIN contracts ct
       ON ct.category_id = p.category_id
      AND ct.supplier_id = p.supplier_id
      AND p.po_date BETWEEN ct.valid_from AND ct.valid_to
GROUP BY b.bu_name ORDER BY maverick_pct DESC;
```

**Fields:** `po_lines.category_id / supplier_id / po_date / quantity / unit_price / bu_id`, `contracts.category_id / supplier_id / valid_from / valid_to`.
**How it works — the key trick:** a `LEFT JOIN` to `contracts` on category **and** supplier **and** an in-date PO. When there's no matching contract, `ct.contract_id IS NULL` — that line was placed off-contract. NULL becomes the business signal.

**Result:**
```
Operations South   23.7%      Network-wide:  16.5% off-contract (€15.2M)
Digital & Tech     16.6%      Off-contract price premium:  8.4%
Operations North   14.3%      Annualisable leakage:  ≈ €1.2M
Central Functions  11.8%
```
**Takeaway:** a process problem, not a pricing one — fix with catalogue coverage, approval workflows and BU compliance scorecards, starting at Operations South.

### Stage 5 — Tail spend (too many tiny suppliers)

**Question:** which categories are fragmented across many small suppliers?

```sql
WITH supplier_cat AS (
  SELECT p.category_id, p.supplier_id, SUM(p.quantity * p.unit_price) AS spend
  FROM po_lines p GROUP BY p.category_id, p.supplier_id
)
SELECT c.category_name,
       SUM(CASE WHEN sc.spend < 100000 THEN 1 ELSE 0 END) AS tail_suppliers,
       ROUND(SUM(CASE WHEN sc.spend < 100000 THEN sc.spend ELSE 0 END)/1e3,0) AS tail_spend_eur_k
FROM supplier_cat sc JOIN categories c ON c.category_id = sc.category_id
GROUP BY c.category_name ORDER BY tail_suppliers DESC;
```

**Fields:** `po_lines.category_id / supplier_id / quantity / unit_price`, `categories.category_name`.
**How it works:** total each supplier's spend *within* a category, then count the ones under €100k over the 24 months.

**Result:**
```
MRO & Maintenance   16 tail suppliers   €534k    -> est. €27k/yr saving
Office Supplies      14                 €158k    -> est. €8k/yr
Packaging             5                 €184k    -> est. €9k/yr
```
**Takeaway:** ~€44k/yr — a real quick win, but sequenced after price variance and maverick.

---

## 5. From analysis to the savings bridge

The report/deck don't quote the theoretical ceilings — they haircut them to realistic capture. Data spans ~2 years, so 24-month totals are halved to annual run-rate.

| Lever | Identified /yr | Capture rate (assumption) | Realistic /yr |
|---|---|---|---|
| Framework agreements + catalogue (top-5 variance categories) | €2.28M | 30–50% | €0.7–1.1M |
| Maverick compliance (Operations South first) | €1.2M | 50–60% | €0.6–0.7M |
| Tail consolidation | €0.09M | ~50% | €0.04M |
| **Total** | **≈ €4.0M ceiling** | | **€1.3–1.9M** |

The €2.28M is half of the top-5 categories' combined €4.56M variance (€1.49 + 1.29 + 0.72 + 0.54 + 0.52 = €4.56M over 24 months). Capture rates are stated assumptions, adjustable once category owners validate scope.

---

## 6. Fields present but barely used (your "next steps" hooks)

These are in the data but not yet in the analysis — each is a ready extension if an interviewer asks "what would you do next?":

- `suppliers.country` — supplier-risk / single-source overlay by country.
- `business_units.city` — geographic spend view.
- `items.list_price` — compare paid price vs catalogue price (contract-compliance angle) instead of best-observed price.
- `contracts.valid_from / valid_to` — a contract-expiry pipeline (what's up for renewal in the next N months).

---

## 7. Reproduce it yourself

```bash
git clone https://github.com/ShrutiSMorab/procurement-spend-analytics.git
cd procurement-spend-analytics
sqlite3 spend.db                    # then, inside sqlite:
.read 02_spend_overview.sql         # run any of the 6 numbered SQL files
```

Files in the repo: `00_schema.sql` (table definitions) · `01`–`06` (the analyses above) · `generate_data.py` (rebuilds the synthetic `spend.db`) · `build_dashboard.py` (rebuilds the Excel dashboard) · `query_outputs.txt` (all raw outputs) · `README.md`.

---

*All data is synthetic. No employer or client data is used. Verified real-world CV metrics (7% sourcing savings, 25% RFP turnaround, 20% onboarding efficiency, 30% manual-effort reduction, 98% data accuracy) are separate from every figure in this project.*
