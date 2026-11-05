---
title: 'Enrollment Projections in Your Browser'
description: "Running enrollment projections through SQL queries is more accurate than a spreadsheet but too cumbersome for most users. This post introduces a browser-based tool that wraps the full projection pipeline in a simple upload interface, runs all analysis client-side so no student data leaves the user's computer, and outputs an Excel workbook with forecasts, accuracy checks, and model diagnostics."

date: '2026-06-21T09:00:00-07:00'

slug: enrollment-projections-webapp
tags: ["Enrollment Projections", "Web Application", "School Districts", "CALPADS"]

isStarred: true
draft: false
math: false

cover:
  image: '/covers/projections.jpg'
  attribution: 'Photo by <a href="https://unsplash.com/@chrisliverani?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Chris Liverani</a> on <a href="https://unsplash.com/photos/turned-on-flat-screen-monitor-dBI_My696Rk?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>'
---

Last February, I wrote about a [new approach to enrollment projections](/posts/enrollment-projections/) that separates continuing-student enrollment from new-student enrollment and quantifies uncertainty instead of producing a single projection. The methodology works, but it required running SQL queries manually, which made it cumbersome compared to a spreadsheet and limited who could use it. So I built [a web application](https://projections.ebardelli.com) that automates the whole process.

[![Enrollment Projections](/posts/images/enrollment-projections.png)](https://projections.ebardelli.com)

You upload your CALPADS files,[^1] set the model parameters,[^parameters] click Run, and download an Excel workbook with the results. All of that runs in your browser, without sharing data with me or anyone else, and the webapp is free to use. If you have questions or want to let me know you used it, reach out at [hello@ebardelli.com](mailto:hello@ebardelli.com).

[^1]: At the moment, the webapp accepts CALPADS 1.2 csv reports, CALPADS 1.18 csv reports, or custom data uploaded following the [custom data format template](https://projections.ebardelli.com/enrollment-template.csv).

[^parameters]: Or leave them as they are. The default parameters work in most cases without any changes.

## What the tool does

The tool takes California CALPADS student-level reports or custom-build csv data sheets. After uploading the data, you assign each school a group[^2] which determines how the projections are segmented in the output. Then you hit Run.

The engine runs two models in parallel: a Monte Carlo simulation (5,000 draws by default) that produces a range of outcomes across three percentiles (the 30th, 50th, and 70th by default), and a traditional cohort survival analysis model[^3] for comparison. Everything happens client-side in the browser using DuckDB; your data never leaves your computer.

The output is an Excel workbook organized by group and school, with one projection sheet per segment. Each sheet shows current enrollment, the low/median/high Monte Carlo range, and the cohort survival analysis for each grade.

[^2]: By default, the app uses District, Charter, or Non-Public School (NPS). You can enter other groups if you want.

[^3]: This model allows you to set your own weights. Using a linear function (i.e., exponent 1) will mirror the projections included in the [FCMAT's Projection-Pro](https://www.fcmat.org/projection-pro) application. The results might be slightly different because Projection-Pro uses CALPADS 1.1 data.

## Evaluation mode

If you upload a file for a year that has already passed,[^4] the tool automatically switches into evaluation mode.

In this mode, the workbook gains a set of accuracy sheets that compare what the model *would have projected* against what *actually happened*. Each sheet shows the difference between actual and projected enrollment by grade, school, and group. This is useful for two things: understanding how well the model performs for your district, and building the case (or skepticism) for relying on a particular percentile in future planning cycles.

The model trains only on data through the year before the projection target, so the comparison is a genuine out-of-sample test rather than a fit to known outcomes.

[^4]: For example, if you want to evaluate enrollment accuracy after Census day.

## Diagnostics

For users who want to look under the hood, an optional Diagnostics setting adds extra sheets to the workbook showing the smoothing parameters the model learned from your data: the adaptive alpha values, the smoothed survival rates and generation counts, and their estimated standard deviations by grade and school.

These sheets are mainly useful for analysts checking whether the model's assumptions match what they know about a district. For example, you can verify that a school with a known enrollment spike in one year isn't skewing the smoothed rate, or confirm that the model is picking up a real downward trend rather than noise.

## Trying it

The tool is available at [projections.ebardelli.com](https://projections.ebardelli.com) and works in any modern browser. A sample custom template is available on the upload screen if you want to test it without CALPADS files.

## App Updates

### November 2026

- **English learner and students with disabilities projections** join the UPC projection. When every enrollment file is a CALPADS 1.2 export with the `EnglishLearner` and `StudentswithDisabilities` flags, the app projects each group by district group (`EL - District`, `SWD - Charter`, and so on). Each group now projects only its own students: a student who leaves the group counts as not continuing, the way a student leaving the district does, and a student who joins it counts as new. The UPC projection works the same way.

### October 2026

- **Long-term projection to ten years.** An optional setting under **Advanced model settings → Long-term Projection** extends each district group's projection past Y2 to the end of the California Department of Finance's [county K–12 enrollment projections](https://dof.ca.gov/forecasting/demographics/public-k-12-graded-enrollment/), through 2035–36 with the 2026 series and at most ten years from Y1. DOF only projects counties, so each group is followed as a share of its county, by grade. Y1 and Y2 stay the Monte Carlo medians. After that, TK, kindergarten, and any grade a group takes in without a class below it keep their Y2 share of the county's class, and every other grade moves up with its county cohort, keeping its share plus the group's usual change in share at that grade over the past ten years. The new **Long-term - District** sheet charts the projection with a low/high range for each group's total, which widens with how much the group's share of its county has drifted. In a backtest on every California district since 1987, taking DOF's county numbers and Y2 as known so that only the share assumption was tested, the 80% range held the actual enrollment about 80% of the time at every horizon from Y3 to Y10. So the range covers share drift, not DOF's own forecast error, and the full uncertainty is wider. A **Long-term - School** sheet splits each group's projection among its schools by their Y2 shares, for information only. Download the county workbook from DOF and choose it in the setting; like the CALPADS files, it stays in your browser.
- **Kindergarten from county births.** An optional setting under **Advanced model settings → New Students** forecasts each district group's kindergarten from the number of children born in its county five years earlier, which is already known when the projection is made. It fits the share of each year's births that enrolled in the district's kindergarten and applies it to the incoming class's births, then subtracts the students already counted as continuing from TK. Fitting the kindergarten total rather than new kindergartners keeps the TK expansion, which moved children from kindergarten into TK, from looking like a decline. TK and the other grades are unchanged. In a backtest on one district's data it cut kindergarten error in every year from 2021 to 2026. It uses the monthly births file from [CHHS Live Birth Profiles by County](https://data.chhs.ca.gov/dataset/live-birth-profiles-by-county).
- **Students moving between district groups**, for example from a K–8 charter to the district's high school, used to count as new students at their destination. Steady flows between groups are now forecast as a share of the origin group's class one grade below, and only the rest are treated as new. The flows used are listed on a new **Movers - District** sheet.
- **A Summary sheet, workbook presets, and charts.** Every workbook now opens on a Summary sheet with the run's settings, the projected totals for each group, and a linked list of sheets. Minimal, Standard, and Full presets choose which sheets to include, and optional chart sheets show each group and school by grade, continuing versus new students, and the projection range.

### September 2026

- **New school-level projection model.** School-level results used to be produced by simulating each school independently and rescaling to match the district total. The model now anchors each school's share of the district's already-simulated draw to that school's own survival-model projection, so school and district totals reconcile by construction and prediction intervals are tighter and better calibrated (confirmed with a walk-forward backtest against 11 years of real enrollment data). This shipped alongside an explicit model for in-district school-to-school transfers, which fixed a bug where a school's structural entry grade, for example a high school's 9th grade fed by a separate K–8 school, projected only new students instead of accounting for the continuing cohort moving over.
- **New schools are no longer dropped from projections.** A school with less than two years of enrollment history used to produce zero rows in the survival and generation tables and disappear from every downstream sheet. These schools now borrow a peer-average rate for grades without their own history, so newly opened schools show up correctly.
- **A series of accuracy fixes** landed to the underlying statistical models: a corrected standard-error formula for survival rates (the old one overstated uncertainty by roughly 3x at typical rates), a fix for an inverted weighting bug that had softened variance estimates as more years of history became available, and fixes to two edge cases that could contaminate one school or grade's forecast with an unrelated school's data. Together these tighten and correct the width of the published percentile bands.

### August 2026

- **Desktop app** packages the same client-side tool as a native download for macOS, Linux, and Windows, alongside the browser version. No server, no change to how your data is handled. It's not published anywhere yet; email [hello@ebardelli.com](mailto:hello@ebardelli.com) if you'd like a copy.
- **Monte Carlo reproducibility fix.** A subtle issue in how random draws were sequenced meant that re-running the same inputs with the same seed could shuffle which draw landed on which row. Runs with a fixed seed now reproduce byte-identical output.

### July 2026

- **Grade exclusion and splitting** are now available in the school editor. Users can drop individual grades from a school's enrollment for specific years, for example, to account for a school closure or grade-band realignment, or split a school into two named groups by grade range (e.g., reroute grades K–5 to "Lincoln Elementary" and grades 6–8 to "Lincoln Middle"). All edits to school enrollment files are now also persisted across sessions in `localStorage`.
- **Results preview** adds a new section to the app that lets users inspect projection outcomes without downloading the Excel file. It includes a table view (switchable between District, School, UPC, and Cohort Model variants) and a Monte Carlo histogram with Low/Med/High percentile lines. In evaluation mode, an actual enrollment line is overlaid on the histogram. The histogram bins and axis ticks are computed from the rank-sorted MC draws, so the median line aligns exactly with the summary table values.
- **Light theme** is now available alongside the existing dark mode. The app detects the system preference on first load.
