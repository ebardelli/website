---
title: 'Enrollment Projections'
date: '2025-08-23T13:53:43-07:00'
draft: true
---

# Data

## Enrollment by District

- Census Day Enrollment by Grade: https://www.cde.ca.gov/ds/ad/filesenrcensus.asp

## Population Estimates

- US Census Estimates by Age and Census Tract
    - https://seer.cancer.gov/censustract-pops/
- CA State Forecasts
    - https://dof.ca.gov/forecasting/demographics/projections/
- CA State Births by Zip Code
    - https://data.chhs.ca.gov/dataset/cdph_live-birth-by-zip-code

# Models

## Grade-by-Grade Retention

- Model the ratio of students who get retained year-to-year using a survival model
- Explore the use of a time factor to control for time-based trends in retention
    - Pre- vs Post-COVID retention

## School Setting Promotion

- Develop models for rolling over enrollment between school settings (i.e., elementary to middle school, middle school to high school)
- Link districts by feeder pattern

## District-Level vs. School-Level Estimates

- How to develop school-level estimates from district and county estimates

# Results

- Develop a way to explore the data
    - Evidence?
    - Observable?
    - Shiny?