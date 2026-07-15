# Study plan — 3 sessions

A structured path through this project, one session ≈ 60–90 minutes. Concepts
build on the [last-mile analytics project](https://github.com/ShrutiSMorab/lastmile-delivery-sql-analytics);
new ideas here are marked **new**.

## Session 1 — Schema, quality checks, spend cube (files 00–02)

- Review the schema: why line-item grain? Why does `contracts` link
  category + supplier rather than just supplier?
- File 01 reuses the quality-check patterns: orphans (LEFT JOIN + IS NULL),
  invalid values, consistency between related tables.
- File 02 introduces **new: window function on top of an aggregate** —
  `SUM(SUM(x)) OVER ()`: inner SUM is the GROUP BY result per row, outer
  OVER () spans all groups. That's how `pct_of_total` works.
- Exercise: write "spend by supplier country" from scratch (join suppliers,
  GROUP BY country, add pct_of_total).

## Session 2 — Pareto and price variance (files 03–04)

- **new: cumulative percentage** — `SUM(spend) OVER (ORDER BY spend DESC)`
  is a running total down the ranked list. Divide by the grand total and you
  have the Pareto curve in one expression.
- ABC classification is just CASE WHEN on that cumulative share.
- File 04: MIN/MAX per item finds price spread; the savings simulation
  reprices every line at the best observed price. Know why this is an
  *upper bound* (supplier switching costs, volume commitments, service levels).
- Exercise: change the ABC thresholds to 70/90 and explain how the supplier
  counts shift.

## Session 3 — Maverick spend, tail spend, dashboard (files 05–06 + Excel)

- File 05 uses a **LEFT JOIN as a business question**: joining po_lines to
  contracts on category + supplier + date; a NULL contract_id doesn't mean
  "missing data" — it means "this purchase was off-contract." Same SQL
  pattern as an orphan check, completely different meaning.
- File 06: threshold bucketing and opportunity sizing with an assumption
  (5% capture rate) — always state assumptions next to the number.
- Open the Excel dashboard, then open `build_dashboard.py`: every KPI is a
  SUMIF/SUMIFS over the raw Data sheet. Trace one number (e.g. Marketing
  spend) from chart → formula → data rows → the SQL query that agrees with it.
- Exercise: add a "Spend by country" sheet to the dashboard with SUMIF.

## Talking about the analysis

For each finding, practice the procurement narrative, not the SQL narrative:
what did we find, what is it worth, what would we do Monday morning? The
recommended-agenda section of the README is the model: value first, mechanism
second, sequence third.
