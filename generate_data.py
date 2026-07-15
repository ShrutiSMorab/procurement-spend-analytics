"""
Synthetic data generator for the Indirect Procurement Spend Analytics project.

Creates spend.db (SQLite): 24 months of purchase-order lines for a mid-size
company buying indirect goods & services across 4 business units.

All data is SYNTHETIC. Patterns deliberately baked in, so the SQL finds
real signal:
  * Pareto concentration: a handful of suppliers carry most of the spend
  * Price variance: identical items bought at different unit prices
    across suppliers and business units
  * Maverick spend: ~12% of spend in contracted categories is placed with
    non-contracted suppliers, at systematically higher prices
  * Tail spend: Marketing, MRO and Office Supplies carry many tiny,
    one-off suppliers (consolidation opportunity)
  * Mild spend growth plus a Q4 year-end spike

Run:  python3 generate_data.py   -> writes spend.db in this folder
"""

import random
import sqlite3
from datetime import date, timedelta

random.seed(7)
DB = "spend.db"

BUS = [(1, "Central Functions", "Berlin"), (2, "Operations North", "Hamburg"),
       (3, "Operations South", "Munich"), (4, "Digital & Tech", "Berlin")]

# category, item price band (min,max), n_core_suppliers, n_tail_suppliers, monthly PO-line volume
CATS = [
    ("IT Hardware",           (250, 2500), 3, 4,  55),
    ("Software & SaaS",       (80, 1800),  3, 5,  60),
    ("Facilities Services",   (500, 6000), 2, 6,  35),
    ("Logistics Services",    (300, 4000), 3, 5,  50),
    ("Marketing Services",    (400, 9000), 2, 18, 45),
    ("Professional Services", (900, 12000),3, 8,  30),
    ("Travel",                (120, 1600), 2, 4,  60),
    ("Office Supplies",       (15, 400),   2, 14, 65),
    ("MRO & Maintenance",     (40, 1500),  2, 16, 55),
    ("Packaging",             (60, 900),   2, 5,  45),
]

ADJ = ["Nord", "Prime", "Delta", "Racoon", "Kiez", "Alpen", "Hanse", "Vertex",
       "Quantum", "Linden", "Spree", "Falcon", "Orbit", "Baltic", "Cedar",
       "Metro", "Atlas", "Nova", "Pixel", "Summit", "Core", "Bright", "Union",
       "Rhein", "Isar", "Elbe", "Solid", "Clever", "Rapid", "Green"]
NOUN = ["Solutions", "Services", "Group", "Systems", "Partners", "Consulting",
        "Supply", "Tech", "Media", "Logistik", "Handel", "Works", "Facility",
        "Trading", "Digital", "Industrie", "Office", "Concepts", "Agentur", "GmbH"]
COUNTRIES = ["DE", "DE", "DE", "DE", "NL", "PL", "AT", "FR", "CZ", "GB"]


def main():
    conn = sqlite3.connect(DB)
    cur = conn.cursor()
    cur.executescript(open("00_schema.sql").read())

    for bu in BUS:
        cur.execute("INSERT INTO business_units VALUES (?,?,?)", bu)

    used_names = set()
    def new_supplier_name():
        while True:
            n = f"{random.choice(ADJ)} {random.choice(NOUN)}"
            if n not in used_names:
                used_names.add(n)
                return n

    sup_id = item_id = contract_id = 0
    core_by_cat, tail_by_cat, items_by_cat, contracted_by_cat = {}, {}, {}, {}

    for cid, (cname, band, n_core, n_tail, _) in enumerate(CATS, start=1):
        cur.execute("INSERT INTO categories VALUES (?,?)", (cid, cname))

        core_by_cat[cid], tail_by_cat[cid] = [], []
        for _ in range(n_core):
            sup_id += 1
            cur.execute("INSERT INTO suppliers VALUES (?,?,?)",
                        (sup_id, new_supplier_name(), random.choice(COUNTRIES)))
            core_by_cat[cid].append(sup_id)
        for _ in range(n_tail):
            sup_id += 1
            cur.execute("INSERT INTO suppliers VALUES (?,?,?)",
                        (sup_id, new_supplier_name(), random.choice(COUNTRIES)))
            tail_by_cat[cid].append(sup_id)

        # 10-14 catalogue items per category
        items_by_cat[cid] = []
        for i in range(random.randint(10, 14)):
            item_id += 1
            lp = round(random.uniform(*band), 2)
            cur.execute("INSERT INTO items VALUES (?,?,?,?)",
                        (item_id, f"{cname} item {i+1:02d}", cid, lp))
            items_by_cat[cid].append((item_id, lp))

        # contracts: the top 1-2 core suppliers are contracted for the category
        contracted_by_cat[cid] = core_by_cat[cid][:2]
        for s in contracted_by_cat[cid]:
            contract_id += 1
            cur.execute("INSERT INTO contracts VALUES (?,?,?,?,?)",
                        (contract_id, cid, s, "2024-07-01", "2026-12-31"))

    # supplier price personality: each supplier prices the list price +/- a bias
    price_bias = {}
    def bias_for(s):
        if s not in price_bias:
            price_bias[s] = random.uniform(-0.06, 0.10)
        return price_bias[s]

    # BU discipline: Operations South is the maverick-heavy BU
    bu_maverick = {1: 0.06, 2: 0.10, 3: 0.22, 4: 0.12}

    start = date(2024, 7, 1)
    line_id = 0
    po_seq = 1000

    for m in range(24):                                   # 24 months
        month_first = date(start.year + (start.month - 1 + m) // 12,
                           (start.month - 1 + m) % 12 + 1, 1)
        growth = 1.006 ** m                               # mild growth
        q4 = 1.25 if month_first.month in (10, 11) else 1.0

        for cid, (cname, band, n_core, n_tail, vol) in enumerate(CATS, start=1):
            n_lines = int(vol * growth * q4 * random.uniform(0.85, 1.15))
            for _ in range(n_lines):
                line_id += 1
                if line_id % 3 == 1:
                    po_seq += 1
                bu = random.choices([1, 2, 3, 4], [30, 25, 25, 20])[0]
                d = month_first + timedelta(days=random.randint(0, 27))

                maverick = random.random() < bu_maverick[bu]
                if maverick and tail_by_cat[cid]:
                    sup = random.choice(tail_by_cat[cid])
                    premium = random.uniform(1.05, 1.16)  # off-contract costs more
                else:
                    # weight core suppliers unevenly -> Pareto concentration
                    weights = [6, 3, 1][:len(core_by_cat[cid])]
                    sup = random.choices(core_by_cat[cid], weights)[0]
                    premium = 1.0

                itm, lp = random.choice(items_by_cat[cid])
                unit = round(lp * (1 + bias_for(sup)) * premium
                             * random.uniform(0.98, 1.02), 2)
                qty = max(1, int(random.expovariate(1 / 3)) + 1)

                cur.execute("INSERT INTO po_lines VALUES (?,?,?,?,?,?,?,?,?)",
                            (line_id, f"PO-{po_seq}", d.isoformat(),
                             bu, sup, cid, itm, qty, unit))

    conn.commit()
    for t in ["business_units", "categories", "suppliers", "items",
              "contracts", "po_lines"]:
        print(f"{t:16s} {cur.execute(f'SELECT COUNT(*) FROM {t}').fetchone()[0]:>7,} rows")
    total = cur.execute("SELECT ROUND(SUM(quantity*unit_price)/1e6,1) FROM po_lines").fetchone()[0]
    print(f"total spend      EUR {total}m over 24 months")
    conn.close()


if __name__ == "__main__":
    main()
