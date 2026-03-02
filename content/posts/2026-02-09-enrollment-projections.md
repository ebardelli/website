---
title: 'A New Approach to Enrollment Projections for School Districts'
date: 2026-02-09T12:21:09.000Z
lastmod: '2026-02-16T09:45:00.000-07:00'

slug: enrollment-projections
tags: ["Data Science","Projections","Forecasting","DuckDB","Monte Carlo Simulations"]

isStarred: true
draft: false
math: true
---

Enrollment projections are a fundamental component of the planning and budgeting processes for school districts. 
The primary purpose of these projections is to help districts prepare for long-term changes in educational demand, 
which directly affects the need for resources, personnel, and school facilities. 

The most widely used method for school district enrollment projection is the cohort-survival ratio (CSR), 
also known as the grade progression method. 
This approach uses historical data to determine the percentage of students "surviving" from one grade to the next, 
while projecting incoming kindergarten classes based on birth rates from five years prior. 
Many districts favor CSR because they can easily compute it in a spreadsheet, 
even though more advanced methods like multiple linear regression exist.

To be effective, enrollment projections must account for a variety of demographic and socioeconomic factors. 
Beyond simple birth and enrollment trends, 
administrators must consider migration patterns, student transfers to charter or private schools, 
and "exogenous shocks," such as policy changes that influence whether students enter or leave the district. 
Finally, simple methods like CSR or regression-based models often struggle when conditions significantly change year-to-year, 
leading policymakers to rely on their own judgment and "guesses" to adjust projections based on local knowledge of trends and conditions.

In this blog post, I describe a new approach to enrollment projections that builds upon the strengths of existing methods while addressing some of their limitations. 
This approach uses a Monte Carlo simulation framework to explicitly model uncertainty in enrollment projections 
and provide a range of potential outcomes rather than a single point estimate. 
By modeling student survival and new student generation as separate stochastic processes, 
this method allows for more robust modeling, 
especially in the presence of strong *exogenous shocks* that might affect one process more than another. 
Finally, this approach uses off-the-shelf, open-source, and freely available tools, such as `DuckDB` for data processing and analysis, 
making it accessible to school district staff without advanced statistical software or programming languages.

# Background on Enrollment Projection Methods

Existing enrollment projection models range from simple historical trend analyses to complex econometric and computational frameworks. 
We can categorize these models into two broad approaches: 
projection, which relies on historical data to extend existing trends, 
and prediction, which incorporates additional variables known as exogenous factors.

## Cohort-Survival Ratio (CSR) / Grade Progression Method

The most widely used approach in school districts is the cohort-survival ratio. 
School districts favor this method for its simplicity because they can compute it using standard spreadsheet software without advanced statistical capacity.

This method uses percentages of students "surviving" from one grade to the next over recent years to project future numbers. 
For example, if Grade 1 enrollment has historically been 102% of the previous year's kindergarten class, that ratio applies to current kindergarten numbers to project next year's first grade.

However, districts rarely rely on a single year's data; 
instead, they often use a three-to-five-year average of ratios. 
Some use weighting schemes to give more influence to the most recent years.

Another decision is about how to predict new entries into kindergarten. 
Calculating the ratio of incoming kindergarten children to local birth rates from five years prior typically handles this.

## Regression and Structural Models

More sophisticated prediction models attempt to explain the "why" behind enrollment changes by using multiple regression or structural equations.

Regression models use the correlation between historical enrollment data alongside external variables to project future enrollment. 
For example, a regression model might find that enrollment is correlated with local unemployment rates, 
and use projected unemployment rates to forecast enrollment. 
The CSR method can be seen as a special case of a regression model where the only predictor is the previous year's enrollment.

Structural equation models combine multiple regression equations to model more complex relationships between enrollment and various predictors, 
such as population growth, economic conditions, and policy changes. 
These models can capture feedback loops and interactions between variables, providing a more nuanced understanding of enrollment dynamics.

One major benefit of using these more complex models is the ability to include external, new variables in the projections beyond historical enrollment data. 
Such external variables include population growth rates, per capita income, unemployment rates, and employment growth.

## Approaches to Modeling School- and District-Level Projections

Different computational approaches exist for modeling enrollment projections at the school and district levels, including top-down, bottom-up, and hybrid models.

Top-down models start with a district-wide projection and then allocate students to individual schools based on historical percentages or current enrollment shares. 

Bottom-up models project each individual school's enrollment independently and then aggregate to reach a district total. 

Hybrid models project both independently and then reconcile the two sets of numbers, often through a series of "passes" to ensure the figures agree.

While these different computational approaches provide a baseline, practitioners often emphasize that human judgment is required to adjust for "exogenous shocks," 
such as policy changes regarding charter schools, changes in district boundaries, or unexpected economic shifts that cause sudden migration.

## Limitations

Existing enrollment projection models face several significant limitations, 
ranging from a heavy reliance on historical trends to difficulties in obtaining high-quality data for more complex models.

### Cohort-Survival Ratio (CSR) Weaknesses

The primary drawback of the CSR method is its fundamental assumption that the future will not vary significantly from the past. 
While effective for stable districts, it cannot anticipate sudden shifts caused by economic factors, changes in district boundaries, or new promotion policies.

CSR is notably less accurate for individual grades and schools than for district-wide totals. 
This is because of the compounding effect of small errors in grade-to-grade progression rates. 
Also, school-level projections are more sensitive to localized, yearly "exogenous shocks", which might lead to biased estimates when using historical averages.

The CSR accuracy also declines sharply as the projection period extends beyond one year. 
This issue is like the *compounding error* problem in financial forecasting, where small, individual errors can lead to a significant divergence from actual outcomes.
When yearly projections consistently favor one direction, like being too optimistic or pessimistic, 
it creates compounding errors where the projections can be off several percentage points from the eventual enrollment. 
Over time, this persistent bias can lead to systematic overestimation or underestimation of enrollment, 
which can have significant implications for resource allocation and planning.

Finally, CSR models usually provide a single point estimate as the projection. 
While this might be sufficient for some planning purposes, it makes it difficult to account for expected external shocks or uncertainty in enrollment, 
leaving further guesswork for the policy maker to adjust the projection based on their knowledge of local trends and conditions.

### Regression and Structural Model Challenges

Regression and structural models attempt to incorporate external variables and can provide an estimate of the uncertainty of the predicted enrollment.
However, the difficulty of acquiring adequate time-series data for all necessary variables often limits them. 
Even when data is available, it is often of poor quality (e.g., population estimates in the American Community Survey are only available at the tract level) or are the wrong granularity (e.g., unemployment rates are usually available at the county level). 
Also, including too many exogenous variables can lead to statistical problems like multicollinearity or overfitting of the prediction to the historical data.

Another limitation of using these models for school- and district-level projections is data availability. 
Most external variables are usually available only at the county level (e.g., population growth, unemployment rates), 
which may not accurately reflect the local conditions for a specific school district. 
For example, a new production plan might open in a county, leading to a reduction in unemployment rates, suggesting an increase in enrollment. 
The new production plan will not equally affect all districts in the county, as some districts may be more impacted than others, influencing the enrollment increase unevenly.

These reasons lead experts to frequently use these more complex models for state or national enrollment predictions, 
which benefit from better data quality and availability, rather than for local district projections.

### Systemic and Behavioral Biases

Research has shown that districts may intentionally bias their projections based on financial or political incentives. 
For example, studies in New York and Kentucky found that districts often underestimate revenues and overestimate expenditures to build budget slack or reach optimal fund balance levels. 
These adjustments are often made without explicitly stating the assumptions or rationale behind them, 
making it difficult to evaluate the accuracy of projections, 
leading to a lack of transparency and accountability in the decisions made using these projections.

Most of the existing projection models also do not provide a clear picture regarding possible variability in the possible enrollment projections. 
Even if all projection models are subject to the inherent uncertainty of the future, 
providing a single point estimate from a CSR might suggest overconfidence in a projection that is actually quite uncertain. 
This can lead to a false sense of precision and may not adequately prepare districts for potential fluctuations in enrollment. 
For example, if a district is projecting enrollment for the next five years for facilities planning purposes, the uncertainty around that projection will likely increase with each year. 
A single point estimate does not capture this increasing uncertainty, which can lead to underpreparedness for potential enrollment changes.

# A New Approach: Monte Carlo Simulations

In this blog post, I describe an alternative approach to enrollment projections 
that builds upon the strengths of the CSR and regression methods while addressing some of their limitations. 
This approach uses similar input data as these traditional models, enrollment by grade and school, 
while separately calculating student survival rates and new student generation rates, and combining them using a new Monte Carlo simulation framework.

A Monte Carlo simulation framework allows for explicit modeling of uncertainty and presents a range of outcomes instead of a single point estimate. 
Separate simulations run thousands of times, each time randomly changing the underlying projection assumptions, 
and are combined together in an overall distribution of possible enrollment outcomes. 
These outcome ranges inform decision making by both providing a projection point estimate alongside possible alternative outcomes, 
which offer a quantitative measure of uncertainty in enrollment projections and guide adjustments for *exogenous shocks* by enabling local experts to choose a projection percentile for further forecasting.

In addition, the simulations explicitly model student survival, or continued year-to-year enrollment, and new student generation, or new entries into the system, as separate processes, 
unlike traditional CSR models that combine these into a single grade progression ratio. 
This allows for more robust modeling, especially in the presence of strong *exogenous shocks* that might affect one process more than another. 
For example, the completion of a new housing development might lead to a surge in new student generation, 
while a change in promotion policies might lead to a drop in student survival rates. 

Finally, this approach uses off-the-shelf, open-source, and freely available tools, such as `DuckDB` for data processing and analysis. 
This analysis uses `SQL` queries, which are more accessible to school district staff than specialized statistical software or programming languages. 
Student-level data is required to run the simulations, with certified CALPADS data being ideal for California districts.

## The Stochastic Processes of Continued Enrollment and New Student Enrollment

The Monte Carlo simulation approach models enrollment as a stochastic process driven by two key components: 
continued enrollment (i.e., student survival) and new student enrollment (i.e., new student generation). 

The simulation handles these two enrollment types as random processes, similar to how we would expect them to play out in the real world. 
In other words, enrollment is not predicted by a set of circumstances that are known using past data. 
Instead, each enrollment projection is based on a set of possible outcomes, each one with its own likelihood of happening. 
All these separate outcomes are combined into a known distribution of outcomes, 
which can be analyzed to understand the range of potential enrollment outcomes and their probabilities.

The Monte Carlo simulation approach models these enrollment outcomes directly by simulating the enrollment process multiple times, 
each time randomly drawing from the underlying distributions of continued enrollment and new student enrollment rates. 
This allows us to capture the natural uncertainty in enrollment projections and provide a range of potential outcomes rather than a single point estimate.

The name of the method comes from a common approach in statistics and computational mathematics, 
where random sampling is used to understand the behavior of a system that is difficult to model analytically. 
Its name comes from the Monte Carlo Casino in Monaco, which is famous for its games of chance, 
reflecting the method's reliance on randomness and probability.

## Technical Overview of the Simulation

In technical terms, the simulation models enrollments as:

$$
Enrollment_{grade, sim} = Survival_{grade, sim} + Generation_{grade, sim} 
$$

where
 - $ Enrollment_{grade, sim} $ is the projected enrollment for a specific `grade` in a specific `sim` simulation run
 - $ Survival_{grade, sim} $ is the number of students projected to continue enrollment from the previous `grade` in that `sim` simulation run
 - $ Generation_{grade, sim} $ is the number of new students projected to enroll in that `grade` in that `sim` simulation run

### Modeling Survival Rates

Survival is modeled as the ratio of students who continue enrollment from one grade to the next. 
This ratio naturally falls between 0 and 1, so we can use the beta distribution to model survival rates. 
The parameters of the beta distribution are calculated based on the average and standard deviation of historical survival rates, as well as the number of observations:

$$
Survival_{grade, sim} \sim Beta(\alpha, \beta)
$$

where
 - $ \alpha = \mu \cdot k $
 - $ \beta = (1 - \mu) \cdot k $
 - $ \mu $ is the average survival rate for that grade
 - $ k = \frac{\text{max variance}}{\text{observed variance}} - 1 $

### Modeling New Student Generation

New student generation is modeled as the number of new students entering the system at each grade level. 
The choice of distribution for modeling new student generation depends on the relationship between the mean and variance of the historical generation data. 
If the variance is less than the mean (underdispersion), a binomial distribution is used. 
If the variance is approximately equal to the mean (equidispersion), a Poisson distribution is used. 
If the variance is greater than the mean (overdispersion), a negative binomial distribution is used.

$$
Generation_{grade, sim} \sim Dist(params)
$$

where `Dist` is chosen based on the dispersion of the historical data:
 - If underdispersion: $ Binomial(n, p) $
 - If equidispersion: $ Poisson(\lambda) $
 - If overdispersion: $ NegativeBinomial(r, p) $

With underdispersion, the binomial distribution is used, which requires a fixed maximum count $ n $. 
Here, we can use the maximum observed generation across all years as `n`, and the average generation divided by that maximum as the probability $ p $. 
In practical terms the probability is calculated as $p = \frac{\mu}{n}$ (where $\mu$ is the average count and $n$ is the chosen maximum, e.g., `N_max`). 
In the SQL examples this is computed as `mu / generation.n_max`.
This approach allows us to model the number of new students entering the system while accounting for the observed underdispersion in the historical data.

With equidispersion, the Poisson distribution is used, which is appropriate for modeling count data where the mean and variance are approximately equal. 
The parameter $ \lambda $ represents the average number of new students generated over the historical period.

With overdispersion, the negative binomial distribution is used, which is appropriate for modeling count data where the variance exceeds the mean. 
The parameter $ r $ is calculated as $ r = \frac{\mu^2}{\sigma^2 - \mu} $, 
where $\mu$ is the average generation for that grade and $\sigma^2$ is the variance of generation for that grade. 
The parameter $ p $ is calculated as $ p = \frac{\mu}{\sigma^2} $. 
This approach allows us to model the number of new students entering the system while accounting for the observed overdispersion in the historical data.

Accounting for variation in the historical data is important for generating realistic projections, 
as it allows us to capture the variability in new student generation that the historical average alone may not fully explain. 
When the historical data shows less variability than expected, it may indicate that there are constraints on the number of new students entering the system (e.g., limited housing availability). 
When the historical data shows more variability than expected, it may indicate that there are unobserved factors influencing new student generation (e.g., economic conditions, new housing becoming available). 
The instability in the historical data can lead to unrealistic projections if not properly accounted for, 
which is why the choice of distribution based on dispersion is a critical aspect of the Monte Carlo simulation approach.

Intuitively, the three different distribution choices for modeling new student generation allow us to capture different patterns in the historical data.

When year-to-year variation in new student generation is minimal (i.e., underdispersion, meaning variance is less than the mean), the binomial distribution restricts the number of new students produced.

When the number of new students generated matches the historical pattern (i.e., equidispersion, meaning that the historical mean and variance are approximately equal), the Poisson distribution's allowance for greater variability in new student numbers around a known mean.

When the variance exceeds the mean (i.e., overdispersion, meaning that the historical variance is greater than the historical mean), the negative binomial distribution allows for greater variability in the number of new students.

Choosing the appropriate distribution based on the observed dispersion in the historical data will help ensure that the projections generated by the Monte Carlo simulations are realistic, 
reflect the historical patterns in new student generation, 
and provide a more accurate representation of the uncertainty in enrollment projections.

## Combining Survival and Generation in Monte Carlo Simulations

The Monte Carlo framework combines the two separate survival and generation simulations into a single enrollment estimate. 
The overall enrollment estimate predicts enrollment by summing the number of students surviving from the previous grade and the number of new students generated for that grade. 
Repeating this process for each grade and school over many simulation runs enables us to generate a distribution of projected enrollment outcomes for each grade and school. 
These repeated simulations, each one separate from the others, allow us to capture the uncertainty in enrollment projections and provide a range of potential outcomes rather than a single point estimate.

As a final step, these separate simulation runs are combined to determine the overall distribution of possible enrollment outcomes for each grade and school. 
By analyzing this distribution, we can understand the range of potential enrollment outcomes and their likelihood when compared to other predictions, 
which can inform decision-making and help districts prepare for a variety of future scenarios. 
Usually, the midpoint of this distribution (i.e., the median or 50th percentile) is used as the point estimate for enrollment projections. 
Other percentiles (e.g., the 25th percentile and the 75th percentile) can provide a more conservative or optimistic projection based on local knowledge of trends and conditions.

The intuition behind using different percentiles is that they quantify the uncertainty in enrollment projections and give a sense of the range of outcomes. 
This gives policy makers the tools to make informed decisions based on their specific circumstances and risk tolerance. 
For example, if a district is facing significant uncertainty because of potential external factors (e.g., a new charter school opening, a change in promotion policies) or has experienced an unexpected decline in enrollment year-over-year, 
they might choose to use a more conservative percentile (e.g., the 40th percentile) to account for the possibility of lower enrollment than historically observed. 
Conversely, if a district is expecting strong growth trends and wants to plan for higher enrollment, it might choose to use a more optimistic percentile (e.g., the 60th percentile).

# Implementation Steps

## Required Tools

The Monte Carlo simulation example is implemented in `DuckDB`, an open-source, in-process SQL database management system that is designed for analytical workloads. 
`DuckDB` is particularly well-suited for this type of analysis because it can efficiently handle large datasets and complex queries, making it ideal for processing student-level enrollment data and running simulations. 
`DuckDB` can be installed on a variety of operating systems and platforms using their [official installation guides](https://duckdb.org/install/).

Modeling the stochastic process relies on a community extension for `DuckDB` (aptly) named `stochastic`, 
which provides functions for generating random numbers from specified distributions. 

Install and load this extension from the 'DuckDB' community extensions marketplace:

```sql {title="Installing Stochastic Extension"}
install stochastic from community;
load stochastic;
```

## Data Collection

The first step in this simulation approach is to collect and prepare the data. 
The simulation requires historical enrollment data at the student level. 
For California districts, CALPADS report 1.2 Enrollment - Primary and Short Term Enrollment Student List is ideal, 
as it provides detailed information on student enrollment by grade and school. 
If this report is not available, districts can use their own student-level enrollment data, ensuring that it includes school codes, student id, and grade level data.

Multiple years of data are preferable, with five years being the recommended minimum to calculate more stable survival rates and new student generation rates.

Below, I show a sample query that processes CALPADS data to create a clean enrollment table. 
This query assumes a folder named `CALPADS` stores the raw CALPADS data, and that all reports are available as separate CSV files with this naming convention: `Enrollment_1_2_[YY]_[YY].csv`. 
The example `SQL` code can be easily adjusted to fit other data formats, as long as the necessary information on school codes, student id, and grade level is included.

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
from read_csv('CALPADS/Enrollment_1_2_*.csv', union_by_name=true, filename=true)
```

District-wide projections can be created by combining enrollment data across schools. 
The rest of the code remains the same. 
Here, the `sc` column can be set to a constant value representing the district name, 
or different aggregate levels representing regular enrollment, charter enrollment, and non-public school enrollment.

## Data Processing

To run the simulations, we need two separate intermediate data tables: 
one for student survival rates and another for new student generation rates. 
Processing the same historical enrollment data in slightly different ways creates these tables.

### Student Survival Rates

We calculate student survival rates by tracking individual students across years to determine the percentage that "survive," or continue enrollment, from one grade to the next. 
For example, to calculate the survival rate from kindergarten to first grade, we divide the number of students who enrolled in first grade at year `t+1` after being enrolled in kindergarten at year `t` by the total number of students enrolled in kindergarten at year `t`.

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

Different ways to aggregate survival rates can be used instead of averaging across years, such as using the most recent year's survival rate or using a weighted average that gives more weight to recent years. 
The choice of aggregation method can be informed by the stability of survival rates over time and the presence of any external factors that might have affected survival rates in specific years.

In my experience, the choice of aggregation method does not significantly affect the overall projections, 
as the Monte Carlo simulation framework captures the uncertainty in survival rates. 
However, using a weighted average that gives more weight to recent years can help capture any recent trends or changes in survival rates that might not be fully reflected in a simple average.

## New Student Generation Rates

We calculate new student generation rates by finding the number of new students entering the system at each grade level. 
The calculation of new student generation rates is important for kindergarten, as birth rates and other factors determine the number of new students entering the system. 
This is also true for any other grade level where new students might enter the system, such as through transfers or late enrollments.

We estimate new student generation by comparing the number of students enrolled in a grade level at year `t` with the number of students enrolled in the previous grade level at year `t-1`. 
For example, to calculate the new student generation rate for 2nd grade, you count the number of new students in 2nd grade at year `t` who were not enrolled in 1st grade at year `t-1`. 
Then, you divide that number by the total number of students enrolled in 2nd grade at year 't'.

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
    sem(generation) as N_sd
from generation
group by all
order by generation.sc, generation.gr
;
```

This table provides three different estimates of new student generation: 
a regression-based estimate (`N_reg`), an average-based estimate (`N_avg`), and a maximum-based estimate (`N_max`). 

The regression-based estimate uses simple linear regression to project the number of new students based on historical trends, 
while the average-based and maximum-based estimates provide alternative projections based on historical averages and maximums, respectively.

Each of these estimates allows us to model different scenarios and account for uncertainty in new student generation in the Monte Carlo simulations.

Similar to the survival rates, the choice of aggregation method can be informed by the stability of generation rates over time and the presence of any external factors that might have affected generation rates in specific years. 
However, the choice of aggregation method does not significantly affect the overall projections, as the Monte Carlo simulation framework captures the uncertainty in generation rates.

## Monte Carlo Simulations

With the survival and generation tables prepared, the next step is to run the Monte Carlo simulations.

Using survival and generation rates, the simulations will project future enrollment for each grade and school. 
We will run the simulations for a specified number of iterations (e.g., 10,000), 
and in each iteration, we will randomly sample the survival rates and generation rates from their respective distributions (using the average and standard deviation calculated in the previous steps).

The example below illustrates how to perform two-year Monte Carlo simulations. 
The first part simulates survival and generation rates for year 1 and year 2. 
The second part combines these separate simulations into a final simulation at the district or school level. 
Adding more simulation and projection steps allows us to extend the code to simulate over two years of projections if needed.

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
        end as survival_draw
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
        end as survival_draw
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
        coalesce(sim_generation_y1.generation_draw, 0) as n_y1_generation
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

Student survival is modeled using a beta distribution, which is appropriate for modeling probabilities that are bounded between 0 and 1. 
The parameters of the beta distribution are calculated based on the average and standard deviation of survival rates and the number of observations. 
If the observed variance is greater than the maximum variance for a beta distribution, or if the standard deviation is zero, 
the simulation defaults to a survival rate of `0.99` to avoid unrealistic values.

For new student generation, the distribution is chosen based on the relationship between the mean and variance of the historical generation data. 
If the variance is less than the mean (underdispersion), a binomial distribution is used. 
If the variance is approximately equal to the mean (equidispersion), a Poisson distribution is used. 
If the variance is greater than the mean (overdispersion), a negative binomial distribution is used. 
If the standard deviation is zero or negative, the simulation defaults to using the average generation as a constant value. 
These distribution choices are appropriate for count data (in our case, the number of new students), which can exhibit different dispersion characteristics than continuous data.

## Projection Analysis

The last step in the projection process is to analyze the results of the Monte Carlo simulations. 
The output of the simulations will be a distribution of projected enrollment numbers for each grade and school for each year of projection.

A simple query like

```sql {title="Analyzing Projection Results"}
select
    sc,
    gr,
    avg(N_y0) as avg_N_y0,
    quantile_cont(N_y1, 0.50) as median_N_y1,
    quantile_cont(N_y2, 0.50) as median_N_y2,
    avg(N_y1_survived) as avg_N_y1_survived,
    avg(N_y2_survived) as avg_N_y2_survived,
    avg(N_y1_generation) as avg_N_y1_generation,
    avg(N_y2_generation) as avg_N_y2_generation
from monte_carlo
group by sc, gr
order by sc, gr;
```

provides the average projected enrollment for the base year (`N_y0`), the median projected enrollment for year 1 and year 2, alongside the average number of students surviving and generated for each year.

The median projection is used in Monte Carlo simulations to represent the middle-of-the-road scenario. 
This projection sits in the middle of all simulated outcomes, meaning that there is an equal probability of the actual enrollment being above or below this value.

Different percentiles can also be calculated to represent more optimistic or pessimistic scenarios. 
For example, the `0.25` quantile would represent a more pessimistic scenario (where enrollment is lower than the median), 
while the `0.75` quantile would represent a more optimistic scenario (where enrollment is higher than the median)

For example, the query below calculates all deciles for the year 1 projections.
These deciles can help understand the range of outcomes and their associated probabilities by school and grade level, 
which are then aggregated to the district level by summing across schools.

```sql {title="Calculating Projection Percentiles"}
with details as (
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
        quantile_cont(N_y1, 0.90) as p_90
    from monte_carlo
    group by sc, gr
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
group by sc
;
```

## Smoothing School-Level Projections

A final consideration is whether to apply any smoothing techniques to the school-level projections. 
Because school-level projections are more sensitive to localized exogenous shocks and have fewer observations than district-level projections, 
they can exhibit more volatility and less accuracy.

An approach to address this issue is to calculate school-level estimates following a two-stage hybrid approach, 
where district-level projections are combined with school-level projections to produce smoothed school-level projections that align with the overall district-level projections while still reflecting the relative distribution of students across schools based on historical trends. 

In the first stage, we run projections at the district level and select an appropriate projection result to represent the overall district enrollment. 

In the second stage, we adjust the school-level projections to align with the selected district-level projection. 
In this stage, the individual school-level projections are used to calculate the percentage share of grade-level enrollment for each school, 
and then we apply these shares to the selected district-level grade projections.

Below, I show an example query that implements this two-stage approach. 
This query assumes that the district-level projections have already been calculated and stored in a csv file called `district.csv`, 
and that the school-level projections have been calculated and stored in a csv file called `schools.csv`. 
These files can be replaced with temporary tables created from the previous steps in the Monte Carlo simulation process.

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

In this blog post, I describe a fresh approach to enrollment projections using Monte Carlo simulations, 
which allows for explicit modeling of uncertainty and provides a range of outcomes rather than a single point estimate. 

This approach builds upon the strengths of traditional cohort-survival ratio models while addressing some of their limitations, 
particularly in accounting for "exogenous shocks" and providing more robust projections at the school level. 

By using open-source tools and student-level data, 
this method can be accessible to school district staff and can provide valuable insights for enrollment planning and decision-making.
