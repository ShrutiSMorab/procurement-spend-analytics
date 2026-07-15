# Indirect Spend Optimisation & Supplier Rationalisation

### A procurement consulting case study — €92.5M indirect spend, 109 suppliers, 24 months

**Prepared by** Shruti Morab · Procurement & Strategic Sourcing
**Client** A European logistics-tech scale-up *(anonymised, illustrative)*
**Data** Synthetic — 13,199 PO lines · 109 suppliers · 10 categories · 4 business units · Jul 2024–Jun 2026

> *All data in this case study is synthetic and generated for portfolio purposes. No employer or client data is used. Savings figures are modelled, not realised results.*

---

## Executive summary

A fast-growing European logistics-tech scale-up asked me to review €92.5M of indirect spend and answer a simple question: **where is the money leaking, and what should we do first?** Rapid growth had left indirect procurement fragmented — no central category ownership, spend spread across 109 suppliers, and rising off-contract purchasing.

I identified a **realistic annual savings opportunity of €1.3–1.9M** — against a theoretical ceiling closer to **€4.0M**. The gap between those two numbers is the point of this study. The ceiling assumes every item is repriced to its best-ever price and every off-contract euro is recovered. The realistic figure applies capture rates that reflect how sourcing actually lands.

> **Bottom line:** the biggest prize is *not* the category with the worst price discipline. It is the two largest categories, where even a modest price spread applies to a very large base. **Sequence by euros at stake, not by percentage spread.**

---

## 1. Situation & mandate

The client scaled headcount and geography quickly over three years. Indirect procurement did not keep pace: category ownership is thin, buying is decentralised across four business units, and contract coverage is patchy. Ahead of the next funding round, leadership wanted two things — demonstrable savings, and a supply base that no longer carries concentration risk.

**The four questions I was asked:**

1. Where is our indirect spend concentrated, and where is it fragmenting?
2. How much spend bypasses our contracts, and what is it costing us?
3. Which categories and suppliers are the priority savings opportunities?
4. What should we do first — over the next 90 days?

*Every finding and recommendation below traces back to one of these four.*

## 2. Approach

I followed a standard analytics workflow — **Ask → Prepare → Process → Analyse → Share → Act** — applied to line-item purchase-order data. The data model is a classic spend cube: who bought (business units), what (categories, items), from whom (suppliers), and the transactions themselves, plus a contracts table that flags any spend placed off-contract.

| Phase | What I did |
|---|---|
| **Ask** | Framed the four mandate questions as testable hypotheses |
| **Prepare** | Validated the data: no orphan suppliers, no negative quantities or prices, no category mismatches |
| **Process** | Segmented spend by category, business unit, supplier and month; flagged on- vs off-contract lines |
| **Analyse** | Pareto/ABC concentration, price variance, maverick spend, tail consolidation — in SQL |
| **Share** | Translated findings into a report and executive deck for a non-technical audience |
| **Act** | Built a capture-rate-adjusted savings bridge and a phased 90-day roadmap |

---

## 3. Diagnostic findings

### 3.1 Where the money goes

![Spend by category](assets/spend-by-category.png)

Spend is heavily weighted to a few categories. **Marketing Services (27%), Professional Services (22%) and Facilities (14%) together account for almost two-thirds of the €92.5M base.**

A recurring **October spike** — roughly €5.0M against a €3.4M baseline month — points to year-end budget-flush behaviour. That is a governance flag, not a sourcing one.

### 3.2 Supplier concentration cuts both ways

![Supplier Pareto curve](assets/pareto-suppliers.png)

**14 suppliers — 13% of a 109-supplier base — carry 80% of spend.** That concentration is leverage at the negotiating table, but it is also risk: the single largest supplier alone represents **16% of total spend**.

An ABC view makes the tail visible:

| ABC class | Suppliers | Spend | % of supplier base |
|---|---|---|---|
| A — top 80% of spend | 14 | €72.86M | 12.8% |
| B — next 15% | 34 | €14.85M | 31.2% |
| C — tail 5% | 61 | €4.79M | 56.0% |

61 C-suppliers share less than €5M between them — each carrying fixed onboarding, compliance and payment overhead.

### 3.3 Price variance is the biggest prize — and a reframe

![Price variance: euros vs percentage](assets/price-variance-reframe.png)

The same catalogue items are bought at very different unit prices across business units and suppliers. Repricing all volume to each item's best observed price would free **€5.68M (6.1% of spend)** in theory.

IT Hardware shows the worst discipline *by percentage* — spreads of 33–37% between the best and worst price paid for identical items. But in absolute euros, the exposure sits in the large categories:

| Category | Recoverable | % of category spend |
|---|---|---|
| **Professional Services** | **€1.49M** | 7.5% |
| **Marketing Services** | **€1.29M** | 5.2% |
| Logistics Services | €0.72M | 7.6% |
| Facilities Services | €0.54M | 4.1% |
| IT Hardware | €0.52M | 7.9% |

> **Consultant's read.** Percentage spread tells you where discipline is worst; absolute euros tell you where to start. Professional Services and Marketing carry roughly **three times** the recoverable value of IT Hardware despite lower percentage spreads. This reorders the sourcing agenda.

### 3.4 Maverick spend is a process problem with a name

![Maverick spend by business unit](assets/maverick-by-bu.png)

**16.5% of network spend — €15.2M over the period — is placed off-contract.** It is not evenly spread: Operations South runs at **23.7%** off-contract versus 11.8% at Central Functions.

Off-contract lines carry an **8.4% average price premium** over on-contract prices for identical items, which annualises to roughly **€1.2M of leakage**.

The fix is process, not negotiation — catalogue coverage, approval workflows, and business-unit compliance reporting.

### 3.5 The supplier tail is real but modest

Fragmentation concentrates in a few low-value categories: **MRO & Maintenance carries 16 sub-€100k suppliers** (€534k of scattered spend) and Office Supplies 14. Consolidating these is worthwhile housekeeping — roughly **€44k a year** — but it is a quick win to be sequenced after the price-variance and maverick fixes, not a headline.

---

## 4. The savings bridge

Theoretical ceilings overstate what sourcing actually captures. I scoped each lever to where the euros are, then applied realistic capture rates. Figures are **annual run-rate** (the dataset spans two years, so 24-month totals are halved).

| Lever | Identified /yr | Capture rate | **Realistic /yr** |
|---|---|---|---|
| Framework agreements & catalogue enforcement (top-5 categories) | €2.28M | 30–50% | **€0.7–1.1M** |
| Maverick-spend compliance programme (Operations South first) | €1.20M | 50–60% | **€0.6–0.7M** |
| Tail consolidation (MRO, Office Supplies, Packaging) | €0.09M | ~50% | **€0.04M** |
| **Total** | **≈ €4.0M ceiling** | | **€1.3–1.9M** |

*Capture rates are assumptions, stated on purpose. They reflect that no programme reprices every line to the best-ever price or recovers every off-contract euro. They can be tightened once category owners validate the scope.*

---

## 5. Recommendations

**Priority 1 — Framework agreements + catalogue enforcement**
Put framework agreements and enforced catalogues behind the two largest categories first — Professional Services and Marketing — then IT Hardware, where the percentage spread is worst. This removes price variance at source rather than chasing it line by line.

**Priority 2 — Maverick-spend compliance programme**
Stand up a compliance programme targeting Operations South: expand catalogue coverage, route spend through approval workflows, and publish maverick-percentage scorecards per business unit. This is a governance fix that pays back quickly because it needs no new negotiation.

**Priority 3 — Tail consolidation**
Consolidate the sub-€100k tail in MRO, Office Supplies and Packaging onto preferred suppliers. Modest savings, but it also cuts onboarding and compliance overhead and is an easy early proof point.

**Risk move — De-risk the top of the base**
With one supplier at 16% and 14 suppliers at 80% of spend, agree dual-source or contingency arrangements for the top three vendors and build a contract-expiry pipeline. This directly addresses the funding-round readiness the client asked for.

---

## 6. 90-day roadmap

| Window | Focus | Actions |
|---|---|---|
| **Days 0–30** | Mobilise & quick wins | Validate findings with category owners; consolidate Office Supplies / MRO tail; stand up the spend dashboard as a monthly cadence |
| **Days 30–60** | Compliance & catalogue | Launch the maverick programme in Operations South: catalogue coverage, approval workflow, BU compliance scorecards |
| **Days 60–90** | Sourcing waves | Open framework-agreement tenders in Professional Services and IT Hardware; agree dual-source plan for the top-3 suppliers |
| **Beyond 90** | Scale & sustain | Roll frameworks across Marketing, Facilities and Logistics; build a contract-expiry pipeline; quarterly reviews with A-suppliers |

---

## 7. Risks, assumptions & limitations

- Savings estimates are **modelled**, using rule-of-thumb capture rates. They are directional and should be firmed up with category owners before targets are set.
- The dataset is **synthetic** and simplifies reality — no payment terms, currencies, credit notes, or supplier parent/child hierarchies.
- Price-variance analysis assumes items are genuinely comparable; some spread may reflect specification or service-level differences rather than pure price.
- The theoretical ceiling (best-ever price on every line) is a **benchmark, not a target** — it will not be captured in full.

---

## Appendix — Data & method

A synthetic SQLite spend database (6 tables, line-item grain) with a companion Excel dashboard. Analyses written in SQL:

- **Pareto/ABC** — cumulative `SUM() OVER (ORDER BY ...)` window functions
- **Maverick spend** — `LEFT JOIN` to the contracts table on category + supplier + PO date within contract validity; a `NULL` match means off-contract
- **Price variance** — per-item best-price simulation using `MIN(unit_price)` grouped by `item_id`
- **Tail** — threshold bucketing at €100k per supplier per category

Full query set, raw outputs, and the reproducible data generator are in this repository. See **[STUDY-GUIDE.md](STUDY-GUIDE.md)** for a field-by-field, query-by-query walkthrough.

**Also in this repo:** the same case study as a formatted [Word report](deliverables/) and an [11-slide executive deck](deliverables/) with speaker notes.
