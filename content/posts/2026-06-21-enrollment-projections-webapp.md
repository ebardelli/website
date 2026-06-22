---
title: 'Enrollment Projections in Your Browser'
description: "This post introduces a browser-based tool that wraps the full projection pipeline in a simple upload interface, runs all analysis client-side so no student data leaves the user's computer, and outputs an Excel workbook with forecasts, accuracy checks, and model diagnostics."

date: '2026-06-21T09:00:00-07:00'

slug: enrollment-projections-webapp
tags: ["Enrollment Projections", "Tools", "School Districts", "CALPADS"]

isStarred: true
draft: false
math: false
---

Last February, I wrote about a [Monte Carlo approach to enrollment projections](https://ebardelli.com/posts/enrollment-projections/) that separates student continuing student enrollment from new-student enrollment and quantifies uncertainty instead of producing a single projection. The methodology works, but it required running SQL queries manually. This makes the method cumbersome when compared to using a spreadsheet, limiting who could run it.

So I built a tool that wraps the whole process in a browser interface. Upload your CALPADS files,[^1] click Run, and download an Excel workbook with the results.

The webapp is free to use. If you want to let me know that you used it or if you have any questions, you can reach out at [hello@ebardelli.com](mailto:hello@ebardelli.com).

[^1]: At the moment, the webapp accepts CALPADS 1.2 and CALPADS 1.18 reports or custom data uploaded following the [custom data format template](https://projections.ebardelli.com/enrollment-template.csv).

## What the tool does

The tool takes California CALPADS 1.2 enrollment files as input (or 1.18 demographics files if you are interested in predicting unduplicated pupils). After uploading the data, you assign each school a group[^2] which determines how the projections are segmented in the output. Then you hit Run.

The engine runs two models in parallel: a Monte Carlo simulation (5,000 draws by default) that produces a range of outcomes across three percentiles, and a traditional cohort survival analysis model[^3] for comparison. Everything happens client-side in the browser using DuckDB; your data never leaves your computer.

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

The tool is available at [projections.ebardelli.com](https://projections.ebardelli.com). It works in any modern browser. A sample custom template is available on the upload screen if you want to test it without CALPADS files.
