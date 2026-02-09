---
title: 'Monte Carlo Enrollment Projections for School Districts'
date: 2026-02-09T12:21:09.000Z

slug: enrollment-projections
tags: ["Data Science","Projections","Forecasting","DuckDB","Monte Carlo Simulations"]

isStarred: true
draft: false
---

Enrollment projections are a fundamental component of the planning and budgeting processes for school districts. 

The primary purpose of these projections is to help districts prepare for long-term changes in educational demand, which directly affects the need for resources, personnel, and school facilities. 

Specifically, enrollment data is used for:

 - Personnel Planning: Determining the number of teachers, administrators, and staff to meet programmatic needs.
 - Budgeting and Revenue Forecasting: Informing short-term and long-term financial plans, including salary and benefit expenditures.
 - Facilities and Capital Planning: Deciding on building utilization, the need for new school facilities, and capital-improvement projects.
 - Operational Logistics: Planning for student transportation and the allocation of supplies and textbooks.

The most widely used method for school district enrollment projection is the cohort-survival ratio (CSR), also known as the grade retention method. This approach uses historical data to determine the percentage of students "surviving" from one grade to the next, while projecting incoming kindergarten classes based on birth rates from five years prior. Many districts favor CSR because they can easily compute it in a spreadsheet, even though more advanced methods like multiple linear regression exist.

To be effective, enrollment projections must account for a variety of demographic and socioeconomic factors. Beyond simple birth and enrollment trends, administrators must consider migration patterns, student transfers to charter or private schools, and "exogenous shocks," such as policy changes that influence whether students enter or leave the district.

# Projection Methods

Existing enrollment projection models range from simple historical trend analyses to complex econometric and computational frameworks. We can categorize these models into two broad approaches: projection, which relies on historical data to extend existing trends, and prediction, which incorporates additional variables known as exogenous factors.

## Cohort-Survival Ratio (CSR) / Grade Retention Method

The most widely used approach in school districts is the cohort-survival ratio. School districts favor this method for its simplicity because they can compute it using standard spreadsheet software without advanced statistical capacity.

This method uses percentages of students "surviving" from one grade to the next over recent years to project future numbers. For example, if Grade 1 enrollment has historically been 102% of the previous year's kindergarten class, that ratio applies to current kindergarten numbers to project next year's first grade.

However, districts rarely rely on a single year's data; instead, they often use a three-to-five-year average of ratios. Some use weighting schemes to give more influence to the most recent years.

Another decision is about how to predict new entries into kindergarten. Calculating the ratio of incoming kindergarten children to local birth rates from five years prior typically handles this.

Mathematically, regression models include the CSR as a special case. Here, the grade progression ratio regresses against a constant term. This results in an arithmetic average of past observed values.

## Structural and Regression Models

More sophisticated models attempt to explain the "why" behind enrollment changes by using multiple regression or structural equations.

Structural equation models define enrollment in a specific grade as the sum of the previous year's enrollment in the prior grade, adjusted for net migration, net transfers to private schools, non-promotions, and dropouts.

One major benefit of using regression models is the ability to include exogenous variables in the projections.  Such external variables include population growth rates, per capita income, unemployment rates, and employment growth.

## Approaches to Modeling

We can also categorize enrollment projections based on the computational approach used to generate projections.

Top-down models start with a district-wide projection and then allocate students to individual schools based on historical percentages or current enrollment shares. 

Bottom-up models project each individual school's enrollment independently and then aggregate to reach a district total. 

Hybrid models project both independently and then reconcile the two sets of numbers, often through a series of "passes" to ensure the figures agree.

While these different computational approaches provide a baseline, practitioners often emphasize that human judgment is required to adjust for "exogenous shocks," such as policy changes regarding charter schools, changes in district boundaries, or unexpected economic shifts that cause sudden migration.

## Limitations

Existing enrollment projection models face several significant limitations, ranging from a heavy reliance on historical trends to difficulties in obtaining high-quality data for more complex formulas.

### Cohort-Survival Ratio (CSR) Weaknesses

The primary drawback of the CSR method is its fundamental assumption that the future will not vary significantly from the past. While effective for stable districts, it cannot anticipate sudden shifts caused by economic factors, changes in district boundaries, or new promotion policies.

CSR is notably less accurate for individual grades and schools than for district-wide totals. This is because of the compounding effect of small errors in grade-to-grade progression rates. Also, school-level projections are more sensitive to localized, yearly "exogenous shocks", which might lead to biased estimates when using historical averages.

The CSR accuracy also declines sharply as the projection period extends beyond one year. Like the *compounding error* problem in financial forecasting, where small, individual errors can lead to a significant divergence from actual outcomes, this issue presents a similar challenge. When yearly projections consistently favor one direction, like being too optimistic or pessimistic, it creates problems. Over time, this persistent bias can lead to systematic overestimation or underestimation of enrollment.

Finally, CSR models usually provide a single point estimate as the projection. While this might be sufficient for some planning purposes, it makes it difficult to account for expected external shocks or uncertainty in enrollment, leaving further guesswork for the analyst to adjust the projection based on their knowledge of local trends and conditions.

### Structural and Regression Model Challenges

While these models attempt to incorporate external variables, the difficulty of acquiring adequate time-series data for all necessary variables often limits them. Even when data is available, it is often of poor quality, particularly regarding net migration by grade and private school enrollment. Including too many exogenous variables can lead to statistical problems like multicollinearity.

Another limitation of these models is data availability. Most external variables are usually available only at the county level (e.g., population growth, unemployment rates), which may not accurately reflect the local conditions for a specific school district. For example, a new production plan might open in a county, leading to a reduction in unemployment rates, suggesting an increase in enrollment. The new production plan will not equally affect all districts in the county, as some districts may be more impacted than others, influencing the enrollment increase unevenly.

These reasons lead experts to frequently use these more complex models for state or national enrollment predictions, benefiting from better data quality and availability, rather than for local district projections.

### Systemic and Behavioral Biases

Prior literature has shown that districts may intentionally bias their projections based on financial or political incentives. For example, studies in New York and Kentucky found that districts often underestimate revenues and overestimate expenditures to build budget slack or reach optimal fund balance levels.

Models often struggle to factor in the impact of charter school competition, which can significantly alter enrollment and costs.

Because no computational model can account for every local variable, the process remains highly subjective. Decision-makers often must use "guesses" and multiple "passes" to reconcile model outputs with their own knowledge of local trends, such as the relocation of special education programs or new magnet school openings.

Finally, all models are subject to the inherent uncertainty of the future; for instance, forecast error increases significantly during economic downturns like the Great Recession.

# A New Approach: Monte Carlo Simulations

This blog post describes an alternative approach to enrollment projections that builds upon the strengths of the CSR method while addressing some of its limitations. This approach uses similar input data as traditional CSR models: enrollment by grade and school, student survival rates, and new student generation rates.

A Monte Carlo simulation framework handles this data, allowing for explicit modeling of uncertainty and presenting a range of outcomes instead of a single point estimate. These simulations can run thousands of times, and each time they randomly change the underlying projection assumptions. Analyzing the distribution of outcomes from these separate runs helps us understand the range of potential enrollment outcomes and their probabilities.

These outcome ranges, which offer a quantitative measure of uncertainty in enrollment projections and guide adjustments for "exogenous shocks" by enabling local experts to choose a projection percentile for further forecasting, can inform decision-making.

In addition, the simulations explicitly model student survival, or continued year-to-year enrollment, and new student generation, or new entries into the system, as separate processes, unlike traditional CSR models that combine these into a single grade progression ratio. This allows for more robust modeling, especially in the presence of strong "exogenous shocks" that might affect one process more than another. For example, the completion of a new housing development might lead to a surge in new student generation, while a change in promotion policies might lead to a drop in student survival rates. 

Finally, this approach uses off-the-shelf, open-source, and freely available tools, such as `DuckDB` for data processing and analysis. All the analysis is done using `SQL` queries, which are more accessible to school district staff than specialized statistical software or programming languages. Student-level data is required to run the simulations, with certified CALPADS data being ideal for California districts.

# Worked-Out Simulation Example

## Data Collection

The first step in this simulation approach is to collect and prepare the data. At a minimum, this includes historical enrollment data at the student level. For California districts, CALPADS certification report 1.2 Enrollment - Primary and Short Term Enrollment Student List is ideal, as it provides detailed information on student enrollment by grade and school.

If this report is not available, districts can use their own student-level enrollment data, ensuring that it includes school codes, student id, and grade level at a minimum.

Multiple years of data are preferable, with five years being the recommended minimum to calculate more stable survival rates and new student generation rates.

Below, I show a sample query that processes CALPADS data to create a clean enrollment table. This query assumes a folder named `CALPADS` stores the raw CALPADS data, and that all reports are available as separate CSV files.

```sql {title="Processing Enrollment Data"}
create or replace temp table enrollment as
select
    '20' || regexp_extract(filename, '_(\d\d)_\d\d.csv$', 1) || '-20' || regexp_extract(filename, '_\d\d_(\d\d).csv$', 1) as yr,
    SchoolName as sc,
    LocalID as id,
    CASE
        when Grade = 'TK' then -1
        when Grade = 'KN' then 0
        else Grade::int
    end as gr
from read_csv('CALPADS/Elem_1_2_*.csv', union_by_name=true, filename=true)
union
select
    '20' || regexp_extract(filename, '_(\d\d)_\d\d.csv$', 1) || '-20' || regexp_extract(filename, '_\d\d_(\d\d).csv$', 1) as yr,
    SchoolName as sc,
    LocalID as id,
    CASE
        when Grade = 'TK' then -1
        when Grade = 'KN' then 0
        else Grade::int
    end as gr
from read_csv('CALPADS/Sec_1_2_*.csv', union_by_name=true, filename=true)
;
```

District-wide projections can be created by combining enrollment data across schools. The rest of the code remains the same. Here, the `sc` column can be set to a constant value representing the district name, or different aggregate levels representing regular enrollment, charter enrollment, and non-public school enrollment.

## Data Processing

To run the simulations, we need two separate intermediate data tables: one for student survival rates and another for new student generation rates. Processing the same historical enrollment data in slightly different ways creates these tables.

### Prerequisites

The Monte Carlo process relies on an external extension for `DuckDB` called `stochastic`, which provides functions for generating random numbers from specified distributions. Install and load this extension from the 'DuckDB' community extensions marketplace:

```sql {title="Installing Stochastic Extension"}
install stochastic from community;
load stochastic;
```

### Student Survival Rates

We calculate student survival rates by tracking individual students across years to determine the percentage that "survive," or continue enrollment, from one grade to the next. For example, to calculate the survival rate from kindergarten to first grade, we divide the number of students who enrolled in first grade at year `t+1` after being enrolled in kindergarten at year `t` by the total number of students enrolled in kindergarten at year `t`.

This query calculates the average and standard deviation of survival rates for each grade level.

```sql {title="Calculating Student Survival Rates"}
create or replace temp table survival as
with
enrollment_data as (
    select
        left(yr, 4)::int as yr,
        sc,
        gr,
        id
    from enrollment
),
survival_data as (
    select
        enrollment_data.*,
        case
            when enrollment_next.id is not null then 1
            else 0
        end as survival
    from enrollment_data
        left join enrollment_data as enrollment_next
            on enrollment_data.id = enrollment_next.id
            and enrollment_data.yr = enrollment_next.yr - 1
    qualify
        enrollment_data.yr < max(enrollment_data.yr) over (partition by enrollment_data.sc, enrollment_data.gr)
),
survival_long as (
    select
        yr,
        sc,
        gr,
        avg(survival) as avg_survival_rate,
        sqrt(avg(survival) / count(id)) as sd_survival_rate,
        count(*) as n_obs,
        sum(survival) as n_survived
    from survival_data
    group by all
),
survival_stats as (
    select
        sc,
        gr,
        avg(avg_survival_rate) as avg_survival_rate,
        avg(sd_survival_rate) as sd_survival_rate,
        avg(n_obs) as n_obs,
        avg(n_survived) as n_survived
    from survival_long
    group by all
)
select * from survival_stats
order by sc, gr
;
```

## New Student Generation Rates

We calculate new student generation rates by finding the number of new students entering the system at each grade level. The calculation of new student generation rates is important for kindergarten, as birth rates and other factors determine the number of new students entering the system. This is also true for any other grade level where new students might enter the system, such as through transfers or late enrollments.

We estimate new student generation by comparing the number of students enrolled in a grade level at year `t` with the number of students enrolled in the previous grade level at year `t-1`. For example, to calculate the new student generation rate for 2nd grade, you count the number of new students in 2nd grade at year `t` who were not enrolled in 1st grade at year `t-1`. Then, you divide that number by the total number of students enrolled in 2nd grade at year 't'.

```sql {title="Calculating New Student Generation Rates"}
create or replace temp table generation as
with
enrollment_data as (
    select
        left(yr, 4)::int as yr,
        sc,
        gr,
        id
    from enrollment
),
generation_long as (
    select
        enrollment_data.*,
        case
            when enrollment_prev.id is null then 1
            else 0
        end as generation
    from enrollment_data
        left join enrollment_data as enrollment_prev on enrollment_data.id = enrollment_prev.id and enrollment_data.sc = enrollment_prev.sc and enrollment_data.yr - 1 = enrollment_prev.yr
    qualify
        enrollment_data.yr > min(enrollment_data.yr) over (partition by enrollment_data.sc, enrollment_data.gr)
),
generation as (
    select
        sc,
        gr,
        yr,
        sum(generation) as generation
    from generation_long
    group by all
)
select
    generation.sc,
    generation.gr,
    regr_intercept(generation, yr) + regr_slope(generation, yr) * (max(yr) + 1) as N_reg,
    avg(generation) as N_avg,
    max(generation) as N_max,
    sem(generation) as N_sd,
from generation
group by all
order by generation.sc, generation.gr
;
```

This table provides three different estimates of new student generation: a regression-based estimate (`N_reg`), an average-based estimate (`N_avg`), and a maximum-based estimate (`N_max`). 

The regression-based estimate uses simple linear regression to project the number of new students based on historical trends, while the average-based and maximum-based estimates provide alternative projections based on historical averages and maximums, respectively.

Each of these estimates allows us to model different scenarios and account for uncertainty in new student generation in the Monte Carlo simulations.

## Monte Carlo Simulations

With the survival and generation tables prepared, the next step is to run the Monte Carlo simulations.

Using survival and generation rates, the simulations will project future enrollment for each grade and school. We will run the simulations for a specified number of iterations (e.g., 10,000), and in each iteration, we will randomly sample the survival rates and generation rates from their respective distributions (using the average and standard deviation calculated in the previous steps).

The example below illustrates how to perform two-year Monte Carlo simulations. The first part simulates survival and generation rates for year 1 and year 2. The second part combines these separate simulations into a final simulation at the district or school level. Adding more simulation and projection steps allows us to extend the code to simulate over two years of projections if needed.

```sql {title="Running Monte Carlo Simulations"}
create or replace temp table monte_carlo as
with 
seed as (
    select setseed(20260209) as seed
),
enrollment as (
    select
        sc,
        gr as gr,
        count(id) as n_obs
    from enrollment
    where gr between -2 and 12
    group by yr, sc, gr
    qualify left(yr, 4)::int = max(left(yr, 4)::int) over (partition by sc, gr)
),
-- simulate survival rates for year 1 and year 2
sim_survival_y1 as (
    select
        survival.sc,
        survival.gr as gr,
        g.sim_idx,
        coalesce(survival.avg_survival_rate, 1.0) as mu,
        coalesce(survival.sd_survival_rate, 0.0) as sigma,
        (coalesce(survival.avg_survival_rate, 1.0) * (1.0 - coalesce(survival.avg_survival_rate, 1.0))) as max_variance, 
        (coalesce(survival.sd_survival_rate, 0.0) * coalesce(survival.sd_survival_rate, 0.0)) as observed_variance,
        ((max_variance) / (observed_variance) - 1.0) as k,
        case
            -- draw from beta
            when observed_variance < max_variance and sigma > 0 then 
                dist_beta_sample(
                    mu * k,
                    (1.0 - mu) * k
                )
            else 0.99
        end as survival_draw,
    from survival
        cross join generate_series(1, 10000) g(sim_idx)
),
sim_survival_y2 as (
    select
        survival.sc,
        survival.gr as gr,
        g.sim_idx,
        coalesce(survival.avg_survival_rate, 1.0) as mu,
        coalesce(survival.sd_survival_rate, 0.0) as sigma,
        (coalesce(survival.avg_survival_rate, 1.0) * (1.0 - coalesce(survival.avg_survival_rate, 1.0))) as max_variance, 
        (coalesce(survival.sd_survival_rate, 0.0) * coalesce(survival.sd_survival_rate, 0.0)) as observed_variance,
        ((max_variance) / (observed_variance) - 1.0) as k,
        case
            -- draw from beta
            when observed_variance < max_variance and sigma > 0 then 
                dist_beta_sample(
                    mu * k,
                    (1.0 - mu) * k
                )
            else 0.99 
        end as survival_draw,
    from survival
        cross join generate_series(1, 10000) g(sim_idx)
),
-- simulate generation for year 1 and year 2
sim_generation_y1 as (
    select
        generation.sc,
        generation.gr - 1 as gr,
        g.sim_idx,
        generation.n_avg as mu,
        generation.n_sd as sigma,
        sigma * sigma as sigma_sq,
        sigma_sq - mu as dispersion_diff,
        (mu * mu) / dispersion_diff as r_nb,
        mu / sigma_sq as p_nb,
        -- conditional draw based on dispersion
        case
            -- 1. check for zero sd / data error (avoid division by zero)
            when sigma <= 0 then mu::bigint
            -- case a: underdispersion (variance < mean) --> use binomial
            when dispersion_diff < 0 then
                -- the binomial model requires a fixed maximum count (n).
                -- we use n_max observed generation across all years
                dist_binomial_sample(
                    generation.n_max::bigint, 
                    mu / generation.n_max
                )
            -- case b: equidispersion (variance approx. = mean) --> use poisson
            -- use a small tolerance (e.g., 1e-6) for floating-point comparison
            when abs(dispersion_diff) < 0.000001 then
                dist_poisson_sample(mu)
            -- case c: overdispersion (variance > mean) --> use negative binomial
            when dispersion_diff > 0 then
                dist_negative_binomial_sample(
                    r_nb::bigint, -- r must be positive and often integer/bigint
                    p_nb            -- p must be 0 < p < 1
                )
        end as generation_draw
    from generation
        cross join generate_series(1, 10000) g(sim_idx)
),
sim_generation_y2 as (
    select
        generation.sc,
        generation.gr - 1 as gr,
        g.sim_idx,
        generation.n_avg as mu,
        generation.n_sd as sigma,
        sigma * sigma as sigma_sq,
        sigma_sq - mu as dispersion_diff,
        (mu * mu) / dispersion_diff as r_nb,
        mu / sigma_sq as p_nb,
        -- conditional draw based on dispersion
        case
            -- 1. check for zero sd / data error (avoid division by zero)
            when sigma <= 0 then mu::bigint
            -- case a: underdispersion (variance < mean) --> use binomial
            when dispersion_diff < 0 then
                -- the binomial model requires a fixed maximum count (n).
                -- we use n_max observed generation across all years
                dist_binomial_sample(
                    generation.n_max::bigint, 
                    mu / generation.n_max
                )
            -- case b: equidispersion (variance approx. = mean) --> use poisson
            -- use a small tolerance (e.g., 1e-6) for floating-point comparison
            when abs(dispersion_diff) < 0.000001 then
                dist_poisson_sample(mu)
            -- case c: overdispersion (variance > mean) --> use negative binomial
            when dispersion_diff > 0 then
                dist_negative_binomial_sample(
                    r_nb::bigint, -- r must be positive and often integer/bigint
                    p_nb            -- p must be 0 < p < 1
                )
        end as generation_draw
    from generation
        cross join generate_series(1, 10000) g(sim_idx)
),
-- run projections for year 1 and year 2
projections_y1 as (
    select
        sim_generation_y1.sc,
        sim_generation_y1.gr + 1 as gr,
        sim_generation_y1.sim_idx,
        enrollment.n_obs as cohort,
        -- draw survival from binomial distribution
        dist_binomial_sample(
            cohort,
            coalesce(sim_survival_y1.survival_draw, 0)
        ) as n_y1_survived,
        coalesce(sim_generation_y1.generation_draw, 0) as n_y1_generation,
    from sim_generation_y1
        left join sim_survival_y1 
            on sim_survival_y1.sc = sim_generation_y1.sc
            and sim_survival_y1.gr = sim_generation_y1.gr
            and sim_survival_y1.sim_idx = sim_generation_y1.sim_idx
        left join enrollment 
            on enrollment.sc = sim_generation_y1.sc
            and enrollment.gr  = sim_generation_y1.gr
),
projections_y2 as (
    select
        sim_generation_y2.sc,
        sim_generation_y2.gr + 1 as gr,
        sim_generation_y2.sim_idx,
        coalesce(projections_y1.n_y1_survived, 0) + coalesce(projections_y1.n_y1_generation, 0) as cohort_y1,
        -- draw survival from binomial distribution
        case
            when cohort_y1 = 0 then 0
            else
                dist_binomial_sample(
                    cohort_y1,
                    coalesce(sim_survival_y2.survival_draw, 0)
                ) 
        end as n_y2_survived,
        coalesce(sim_generation_y2.generation_draw, 0) as n_y2_generation
    from sim_generation_y2
        left join sim_survival_y2 
            on sim_survival_y2.sc = sim_generation_y2.sc
            and sim_survival_y2.gr = sim_generation_y2.gr
            and sim_survival_y2.sim_idx = sim_generation_y2.sim_idx
        left join projections_y1 
            on projections_y1.sc = sim_generation_y2.sc
            and projections_y1.gr = sim_generation_y2.gr
            and projections_y1.sim_idx = sim_generation_y2.sim_idx
)
select
    projections_y1.sim_idx,
    projections_y1.sc,
    enrollment.gr,
    enrollment.n_obs as n_y0,
    projections_y1.n_y1_survived,
    projections_y1.n_y1_generation,
    (coalesce(projections_y1.n_y1_survived, 0) + coalesce(projections_y1.n_y1_generation, 0)) as n_y1,
    projections_y2.n_y2_survived,
    projections_y2.n_y2_generation,
    (coalesce(projections_y2.n_y2_survived, 0) + coalesce(projections_y2.n_y2_generation, 0)) as n_y2
from enrollment
    left join projections_y1 on projections_y1.sc = enrollment.sc and projections_y1.gr = enrollment.gr
    left join projections_y2 on projections_y2.sc = enrollment.sc and projections_y2.gr = enrollment.gr and projections_y2.sim_idx = projections_y1.sim_idx
;
```

There are a few assumptions about the distributions for student survival and new student generation that are worth noting.

Student survival is modeled using a beta distribution, which is appropriate for modeling probabilities that are bounded between 0 and 1. The parameters of the beta distribution are calculated based on the average and standard deviation of survival rates and the number of observations. If the observed variance is greater than the maximum variance for a beta distribution, or if the standard deviation is zero, the simulation defaults to a survival rate of `0.99` to avoid unrealistic values.

For new student generation, the distribution is chosen based on the relationship between the mean and variance of the historical generation data. If the variance is less than the mean (underdispersion), a binomial distribution is used. If the variance is approximately equal to the mean (equidispersion), a Poisson distribution is used. If the variance is greater than the mean (overdispersion), a negative binomial distribution is used. If the standard deviation is zero or negative, the simulation defaults to using the average generation as a constant value. These distribution choices are appropriate for count data (in our case, the number of new students), which can exhibit different dispersion characteristics than continuous data.

## Projection Analysis

The last step in the projection process is to analyze the results of the Monte Carlo simulations. The output of the simulations will be a distribution of projected enrollment numbers for each grade and school for each year of projection.

A simple query like

```sql {title="Analyzing Projection Results"}
from monte_carlo 
select 
    sc,
    gr, 
    avg(N_y0), quantile_cont(N_y1, 0.50), quantile_cont(N_y2, 0.50),
    avg(N_y1_survived), avg(N_y2_survived),
    avg(N_y1_generation), avg(N_y2_generation),

group by sc, gr order by sc, gr;
```

provides the average projected enrollment for the base year (`N_y0`), the median projected enrollment for year 1 and year 2, alongside the average number of students surviving and generated for each year.

The median projection is used in Monte Carlo simulations to represent the middle-of-the-road scenario. This projection sits in the middle of all simulated outcomes, meaning that there is an equal probability of the actual enrollment being above or below this value.

Different percentiles can also be calculated to represent more optimistic or pessimistic scenarios. For example, the `0.25` quantile would represent a more pessimistic scenario (where enrollment is lower than the median), while the `0.75` quantile would represent a more optimistic scenario (where enrollment is higher than the median)

For example, the query below calculates all deciles for the year 1 projections, which can help understand the range of outcomes and their associated probabilities by school and grade level, which are then aggregated to the district level by summing across schools.

```sql {title="Calculating Projection Percentiles"}
with
details as (
from monte_carlo 
  select 
      sc,
      gr,
      quantile_cont(N_y1, 0.10) as p_10,
      quantile_cont(N_y1, 0.20) as p_20,
      quantile_cont(N_y1, 0.30) as p_30,
      quantile_cont(N_y1, 0.40) as p_40,
      quantile_cont(N_y1, 0.50) as p_50,
      quantile_cont(N_y1, 0.60) as p_60,
      quantile_cont(N_y1, 0.70) as p_70,
      quantile_cont(N_y1, 0.80) as p_80,
      quantile_cont(N_y1, 0.90) as p_90,
  
  group by sc, gr order by sc, gr
)
select
  sc,
  sum(p_10) as p_10,
  sum(p_20) as p_20,
  sum(p_30) as p_30,
  sum(p_40) as p_40,
  sum(p_50) as p_50,
  sum(p_60) as p_60,
  sum(p_70) as p_70,
  sum(p_80) as p_80,
  sum(p_90) as p_90
from details
group by all
;
```

## Smoothing School-Level Projections

A final consideration is whether to apply any smoothing techniques to the school-level projections.  Because school-level projections are more sensitive to localized "exogenous shocks" and have fewer observations than district-level projections, they can exhibit more volatility and less accuracy.

An approach to address this issue is to calculate school-level estimates following a two-stage hybrid approach, where district-level projections are combined with school-level projections to produce smoothed school-level projections that align with the overall district-level projections while still reflecting the relative distribution of students across schools based on historical trends. 

In the first stage, we run projections at the district level and select an appropriate projection result to represent the overall district enrollment. 

In the second stage, we adjust the school-level projections to align with the selected district-level projection. In this stage, the individual school-level projections are used to calculate the percentage share of grade-level enrollment for each school, and then we apply these shares to the selected district-level grade projections.

Below, I show an example query that implements this two-stage approach. This query assumes that the district-level projections have already been calculated and stored in a csv file called `district.csv`, and that the school-level projections have been calculated and stored in a csv file called `schools.csv`.

```sql {title="Smoothing School-Level Projections"}
WITH
district as (
    select
        sc,
        gr,
        max(N_y0) as N_low,
        max(N_y0) as N_med,
        max(N_y0) as N_high,
        percentile_cont(0.25) within group (order by N_y1) as N1_low,
        percentile_cont(0.50) within group (order by N_y1) as N1_med,
        percentile_cont(0.75) within group (order by N_y1) as N1_high,
        percentile_cont(0.25) within group (order by N_y2) as N2_low,
        percentile_cont(0.50) within group (order by N_y2) as N2_med,
        percentile_cont(0.75) within group (order by N_y2) as N2_high
    from 'district.csv'
    where
      gr between -1 and 12
    group by sc, gr
    order by sc, grouping_sort, gr
),
schools as (
    select
        sc,
        gr::int as gr,
        max(N_y0) as N_low,
        max(N_y0) as N_med,
        max(N_y0) as N_high,
        percentile_cont(0.25) within group (order by N_y1) as N1_low,
        percentile_cont(0.50) within group (order by N_y1) as N1_med,
        percentile_cont(0.75) within group (order by N_y1) as N1_high,
        percentile_cont(0.25) within group (order by N_y2) as N2_low,
        percentile_cont(0.50) within group (order by N_y2) as N2_med,
        percentile_cont(0.75) within group (order by N_y2) as N2_high
    from 'schools.csv'
    group by sc, gr
    order by sc, gr
),
difference as (
    select
        district.sc,
        schools.grouping,
        schools.grouping_sort,
        schools.gr,
        sum(schools.N_low) as school_N_low,
        sum(schools.N_med) as school_N_med,
        sum(schools.N_high) as school_N_high,
        sum(schools.N1_low) as school_N1_low,
        sum(schools.N1_med) as school_N1_med,
        sum(schools.N1_high) as school_N1_high,
        sum(schools.N2_low) as school_N2_low,
        sum(schools.N2_med) as school_N2_med,
        sum(schools.N2_high) as school_N2_high,
        district.N_low as district_N_low,
        district.N_med as district_N_med,
        district.N_high as district_N_high,
        district.N1_low as district_N1_low,
        district.N1_med as district_N1_med,
        district.N1_high as district_N1_high,
        district.N2_low as district_N2_low,
        district.N2_med as district_N2_med,
        district.N2_high as district_N2_high
    from schools
        join district on schools.gr = district.gr
    group by all
)
select
    schools.sc,
    schools.grouping,
    schools.grouping_sort,
    schools.gr,
    -- Current Enrollment
    round(schools.N_low * (difference.district_N_low / difference.school_N_low)) as N_low,
    round(schools.N_med * (difference.district_N_med / difference.school_N_med)) as N_med,
    round(schools.N_high * (difference.district_N_high / difference.school_N_high)) as N_high,
    -- Year 1 Projection
    round(schools.N1_low * (difference.district_N1_low / difference.school_N1_low)) as N1_low,
    round(schools.N1_med * (difference.district_N1_med / difference.school_N1_med)) as N1_med,
    round(schools.N1_high * (difference.district_N1_high / difference.school_N1_high)) as N1_high,
    -- Year 2 Projection
    round(schools.N2_low * (difference.district_N2_low / difference.school_N2_low)) as N2_low,
    round(schools.N2_med * (difference.district_N2_med / difference.school_N2_med)) as N2_med,
    round(schools.N2_high * (difference.district_N2_high / difference.school_N2_high)) as N2_high
from schools
    join difference on schools.gr = difference.gr
;
```

# Conclusion

In this blog post, I describe a fresh approach to enrollment projections using Monte Carlo simulations, which allows for explicit modeling of uncertainty and provides a range of outcomes rather than a single point estimate. 

This approach builds upon the strengths of traditional cohort-survival ratio models while addressing some of their limitations, particularly in accounting for "exogenous shocks" and providing more robust projections at the school level. 

By using open-source tools and student-level data, this method can be accessible to school district staff and can provide valuable insights for enrollment planning and decision-making.
