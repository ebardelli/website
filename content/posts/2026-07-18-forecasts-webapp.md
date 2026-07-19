---
title: 'Show Your Assumptions: A New Tool for Fiscal Impact Forecasting'
description: "Fiscal forecasts in school districts rarely spell out the assumptions behind them, or even describe what a proposal actually changes for students and staff. These omissions make it hard to evaluate a new labor MOU or a proposed budget reduction on its merits. This post introduces a browser-based tool that treats a project's impact, not its dollar cost, as the primary object, producing a financial forecast as a by-product of describing that impact."

date: '2026-07-18T09:00:00-07:00'

slug: forecasts-webapp
tags: ["Web Application", "School Districts", "Budgeting", "DuckDB"]

isStarred: true
draft: false
math: false

cover:
  image: '/covers/budget.jpg'
  attribution: 'Photo by <a href="https://unsplash.com/@kellysikkema?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Kelly Sikkema</a> on <a href="https://unsplash.com/photos/person-holding-paper-near-pen-and-calculator-xoU52jUVUXA?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>'
---

A new MOU with the teachers' union, a reduction in force, a school consolidation: every one of these proposals ends up as a spreadsheet with a number at the bottom, and the conversation about it almost always starts and ends with that number. What rarely gets written down is what the proposal actually changes for students and staff: how many sections get combined, which positions or services are affected, what a step-and-column schedule means for a specific group of employees. That description usually lives in someone's head or in an unlabeled spreadsheet cell, if it exists anywhere at all. The dollar figure stands in for the whole analysis instead of being what it actually is: one consequence of programmatic changes nobody wrote down. When a board member asks what happens if enrollment comes in lower, or a union negotiator asks where a figure came from, the honest answer is usually a new spreadsheet, not a description of what was assumed.

This isn't a new observation.[^bias] There are real incentives to leave assumptions vague. A fuzzy forecast is harder to argue with than a precise, checkable one. Even without any intent to obscure anything, most budget spreadsheets simply weren't built to describe a proposal before they price it. So I built [a web application](https://forecasts.ebardelli.com) that inverts the usual order: instead of starting from a dollar figure and working backward, it makes you describe and quantify a proposal's impact first, as labeled assumptions, and only then generates the financial forecast from them automatically.

[^bias]: I touched on a version of this problem in an [earlier post on enrollment projections](/posts/enrollment-projections/#systemic-and-behavioral-biases): research has found that districts sometimes intentionally bias revenue and expenditure projections to build budget slack, and that this is easier to get away with when the assumptions behind a projection aren't stated explicitly enough for anyone outside the finance office to check.

## Fiscal Forecasting Shouldn't Be the Goal

The financial forecast that comes out of the tool is genuinely useful, but it's meant to be a *consequence* of a clearer exercise, not the goal of it. The goal is to estimate the educational impact of a specific proposal first, and then calculate the financial forecast after. The forecast is what you get once you have a good idea of what will change as a result of the project you are trying to forecast. If you only care about the bottom-line number, you can get that from a spreadsheet in five minutes. What a spreadsheet won't give you is a structure where someone else can open the analysis, see exactly which assumptions drove the number, disagree with one of them, and see how much that disagreement actually matters to the outcome. That last part, testing how much a single disagreement moves the bottom line, used to mean rebuilding the spreadsheet. Now it's a named scenario you can build in a couple minutes and compare directly against the baseline.

## How it works

The app is organized around four ideas, matching its four tabs.

**Assumptions.** You define reusable *units*, small, named pieces of a fiscal claim, like "step increase cost per FTE" or "Health & Welfare benefit rate." Each unit is built from one-off values, cells pulled from a hand-built assumption table, or other units, and each value carries an uncertainty percentage (treated as one standard deviation) rather than pretending to be exact. Because units can reference other units, a complicated claim like "total cost of the proposed raise" is composed out of smaller, individually labeled assumptions instead of being a single opaque number no one can unpack.

**Planning.** You create one or more *projects* (the MOU, the reduction proposal, the consolidation) and attach units to each as line items with a quantity. Units are shared and defined once, so if a benefits load rate assumption changes, every project referencing it updates together, instead of drifting apart across a dozen one-off spreadsheets built for separate board items.

**Scenarios.** Assumptions and Planning together define a single deterministic baseline, but a real budget conversation is never about just one version of the future. Scenarios let you name a branch off that baseline (say, "vendor price increase," "lower step movement," "enrollment comes in 5% low") and override just the pieces that scenario changes, either a specific cost component (which ripples through every line item that uses it) or a single line item's quantity, price, or uncertainty. Everything you don't override stays tied to the shared baseline. Running a scenario simulates possible outcomes based on the uncertainty values you select, returing useful distribution information (i.e., mean, median, P5/P10/P90/P95, a histogram, per project and overall) alongside a per-scenario breakdown, all side by side with a synthetic Baseline scenario that carries no overrides at all. That's what makes it a sensitivity analysis rather than just another forecast: you can see exactly how much a specific disagreement (e.g., one assumption, one price, one uncertainty band) moves the outcome, instead of guessing. A "Download scenario report" button exports every saved scenario plus Baseline into one comparison workbook: a summary sheet ranking them side by side, and a full distribution behind each.

**Settings.** Backup, restore, and reset live here, out of the way of the day-to-day tabs. Exporting a full backup downloads every unit, table, project, line item, and scenario (including all its overrides) as an Excel workbook; importing that file back in restores the whole database exactly, and a separate reset action wipes everything to start over. That matters for a fiscal analysis in particular. The assumptions behind a multi-year MOU or a facilities decision often need to survive staff turnover and get revisited next budget cycle, rather than get rebuilt from scratch. The backup workbook is distinct from a scenario report: the backup round-trips everything back into the app, while a scenario report is a read-only comparison meant for sharing with a board or a bargaining team.

All of this runs entirely client-side. Data lives in a real [DuckDB](https://duckdb.org) database via [`@duckdb/duckdb-wasm`](https://github.com/duckdb/duckdb-wasm), persisted to the browser's Origin Private File System, and nothing is sent to a server. For fiscal analysis tied to ongoing labor negotiations, that's not incidental. It's the difference between a tool people are willing to actually use for sensitive numbers and one they aren't.

## Trying it

The tool is available at [forecasts.ebardelli.com](https://forecasts.ebardelli.com). It works best in a Chromium-based browser (Chrome, Edge). Firefox and Safari have partial support for the browser storage feature it depends on and will fall back to an in-memory session that doesn't persist across reloads. It's free to use. If you try it or run into issues, reach out at [hello@ebardelli.com](mailto:hello@ebardelli.com).
