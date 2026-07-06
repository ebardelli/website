---
title: 'A New Approach to Enrollment Projections for School Districts'
description: "Standard enrollment projection methods struggle when conditions shift sharply. This post describes an approach that treats two drivers of enrollment separately: students who continue from year to year and students who are new to the district. Keeping these distinct makes projections more robust to sudden changes like new housing developments or policy shifts."

date: 2026-02-09T12:21:09.000Z
lastmod: '2026-06-22T12:00:00.000-07:00'

slug: enrollment-projections
tags: ["DuckDB", "Enrollment Projections", "School Districts", "Projections", "Data Science"]

isStarred: true
draft: false
math: true

cover:
  image: '/covers/bus.jpg'
  attribution: 'Photo by <a href="https://unsplash.com/@peterbucks?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">peter bucks</a> on <a href="https://unsplash.com/photos/yellow-school-bus-in-front-of-building-DQ0aOyqlvEs?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>'
---

> # June 2026 Update
> 
> I released a web application that implements this enrollment projection procedure. It's available at [projections.ebardelli.com](https://projections.ebardelli.com).

Enrollment projections drive planning and budgeting for school districts. Districts use them to anticipate long-term shifts in educational demand, which in turn shapes decisions about staffing, resources, and facilities.

The most widely used method is the cohort survival ratio (CSR), also known as the grade progression method. CSR uses historical data to estimate the share of students *surviving* from one grade to the next, while projecting incoming kindergarten classes from birth rates five years prior. Districts favor it because anyone can run it in a spreadsheet, even though more advanced methods like multiple linear regression exist.

Accurate projections require more than birth and enrollment trends. Administrators must also weigh migration patterns, transfers to charter or private schools, and external shocks such as policy changes that move students into or out of a district. CSR and regression-based models both struggle when conditions shift sharply year-to-year, and planners often resort to informal judgment calls to patch the gap.

In this blog post, I describe a new approach to enrollment projections that builds on the strengths of existing methods while addressing some of their limitations. It uses a Monte Carlo simulation framework to model uncertainty explicitly and produce a range of outcomes rather than a single point estimate. By treating student survival and new student generation as separate stochastic processes, the method handles external shocks more cleanly — a surge in new housing, for instance, affects generation rates without contaminating survival estimates. The implementation uses `DuckDB`, a free, open-source SQL database, keeping it accessible to district staff without specialized statistical software.

# Background on Enrollment Projection Methods

Enrollment projection models span a wide range, from simple historical trend analyses to complex econometric and computational frameworks. They fall into two broad categories: projection, which extends existing trends from historical data, and prediction, which brings in additional external variables (exogenous factors).

## Cohort Survival Ratio (CSR) / Grade Progression Method

The most widely used approach in school districts is the cohort survival ratio (CSR).[^csr] School districts favor this method for its simplicity because they can compute it using standard spreadsheet software without advanced statistical capacity.

This method uses percentages of students "surviving" from one grade to the next over recent years to project future numbers. For example, if Grade 1 enrollment has historically been 102% of the previous year's kindergarten class, that ratio applies to current kindergarten numbers to project next year's first grade.

However, districts rarely rely on a single year's data; instead, they often use a three-to-five-year average of ratios. Some use weighting schemes to give more influence to the most recent years.

Another decision is how to project new kindergarten entries. The standard approach divides incoming kindergarten enrollment by local birth rates from five years prior. When birth rate data isn't available[^births], districts fall back to averaging year-over-year enrollment changes for that grade and carrying that average forward.

[^csr]: For example, see this [New York Times article](https://www.nytimes.com/2026/05/07/nyregion/nyc-school-enrollment-declines.html) discussing the [enrollment projections](https://dnnhh5cc1.blob.core.windows.net/portals/0/Capital_Plan/Demographic_projection_Reports/Volume%202-2026.pdf?sv=2017-04-17&sr=b&si=DNNFileManagerPolicy&sig=pl1f%2BywRLsn%2BsVXvRXNIEbkxmnewwAydpZBsa%2F8kIm4%3D) for New York City Public Schools for 2025-26 to 2034-35 (the discussion of CRS methodology starts at page 109).

[^births]: The California Department of Public Health maintains a dataset of [annual births by zip code](https://data.chhs.ca.gov/dataset/cdph_live-birth-by-zip-code). However, zip codes do not match with elementary school districts, so this data isn't very informative when predicting Transitional Kindergarten or Kindergarten enrollment.

### Moving Decaying Averages Models

A particular set of CSR models is the weighted moving average model that uses decaying weights. In these models, the weights decline by a set amount, either decided beforehand or calculated from observed data.[^weights] 

The weighted average of historical survival rates is then calculated by multiplying each year's rate by its assigned weight, summing the results, and dividing by the total weight. This gives more influence to recent years when estimating the grade progression ratios used to project enrollment.

A similar calculation can be applied to new enrollment grades using the weighted average year-to-year change instead of the survival rate.

[^weights]: This is what the enrollment projections in FCMAT's Projection Pro uses. In this model, weights decline by 1 for each historical year moving back from the base year, so the most recent historical year has a weight of 4, the year before that has a weight of 3, and so on.


## Regression and Structural Models

More sophisticated prediction models attempt to explain the *why* behind enrollment changes by using multiple regression or structural equations.

Regression models use the correlation between historical enrollment data and external variables to project future enrollment. For example, a regression model might find that enrollment is correlated with local unemployment rates, and use projected unemployment rates to forecast enrollment. The CSR method can be seen as a special case of a regression model where the only predictor is the previous year's enrollment.[^regression]

Structural equation models combine multiple regression equations to model more complex relationships between enrollment and various predictors, such as population growth, economic conditions, and policy changes. These models can capture feedback loops and interactions between variables, giving planners a richer picture of what drives enrollment shifts.

One major benefit of using these more complex models is the ability to include external, new variables in the projections beyond historical enrollment data. Such external variables include population growth rates, per capita income, unemployment rates, and employment growth.

[^regression]: Similarly, moving decaying averages models can be parametrized in a regression framework using observation weights.

## Limitations

Existing enrollment projection models face several significant limitations, ranging from a heavy reliance on historical trends to difficulties in obtaining high-quality data for more complex models.

### Cohort Survival Ratio (CSR) Weaknesses

The primary drawback of the CSR method is its fundamental assumption that the future will not vary significantly from the past. While effective for stable districts, it cannot anticipate sudden shifts caused by economic factors, changes in district boundaries, or new promotion policies.[^issue]

CSR is notably less accurate for individual grades and schools than for district-wide totals. This is because of the compounding effect of small errors in grade-to-grade progression rates. Also, school-level projections are more sensitive to localized, yearly external shocks, which might lead to biased estimates when using historical averages.

The CSR accuracy also declines sharply as the projection period extends beyond one year. This issue is like the *compounding error* problem in financial forecasting, where small, individual errors can lead to a significant divergence from actual outcomes. When yearly projections consistently favor one direction, like being too optimistic or pessimistic, it creates compounding errors where the projections can be off several percentage points from the eventual enrollment. Over time, this persistent bias can lead to systematic overestimation or underestimation of enrollment, which can have significant implications for resource allocation and planning.

Finally, CSR models usually provide a single point estimate as the projection. While this might be sufficient for some planning purposes, it makes it difficult to account for expected external shocks or uncertainty in enrollment, 
leaving further guesswork for the policy maker to adjust the projection based on their knowledge of local trends and conditions.

[^issue]: This becomes a major issue because projections are really only useful in times of sudden shifts in enrollment.

### Moving Decaying Average Models

The main limitation of decaying weight models is that they still assume the recent past is the best guide to the future, and they weight it more heavily. When a district experiences a structural break (e.g., a school closure, a new housing development, a sudden boundary change), the most recent years may be the least representative of what comes next, and down-weighting older data makes that worse.[^shift] The models also offer no built-in way to quantify how uncertain the projection is. A single weighted average produces a single point estimate, leaving planners without a sense of the range of plausible outcomes.

[^shifts]: Sometimes, this can also be a strenght of these models. For example, enrollment rates were very volatile following school re-opening after COVID. Down-weighting these years isn't a bad idea after all.

### Regression and Structural Model Challenges

Regression and structural models attempt to incorporate external variables and can estimate prediction uncertainty. But they're often constrained by inadequate time-series data. Even when data is available, it's frequently the wrong granularity — population estimates from the American Community Survey come at the tract level, unemployment rates at the county level. Including too many exogenous variables also raises statistical problems like multicollinearity or overfitting.

Another limitation is that most external variables are only available at the county level, which may not reflect conditions in a specific district. A new manufacturing plant might reduce county-wide unemployment while affecting some districts far more than others.

For these reasons, complex regression models are more commonly used for state or national projections, where data quality and availability are better, rather than for local district work.

### Systemic and Behavioral Biases

Research has shown that districts may intentionally bias their projections based on financial or political incentives. For example, studies in New York and Kentucky found that districts often underestimate revenues and overestimate expenditures to build budget slack or reach optimal fund balance levels. These adjustments are often made without explicitly stating the assumptions or rationale behind them, making it difficult to evaluate the accuracy of projections, leading to a lack of transparency and accountability in the decisions made using these projections.

Most of the existing projection models also do not provide a clear picture regarding possible variability in the possible enrollment projections. Even if all projection models are subject to the inherent uncertainty of the future, providing a single point estimate from a CSR might suggest overconfidence in a projection that is actually quite uncertain. A single-number projection implies a precision that isn't there and leaves districts unprepared when enrollment shifts. For five-year facilities planning, that uncertainty grows with every year out. A point estimate hides all of it.

# A New Approach: Monte Carlo Simulations

In this blog post, I describe an alternative approach to enrollment projections that builds upon the strengths of the CSR and regression methods while addressing some of their limitations. This process uses similar input data as these traditional models, enrollment by grade and school, while separately calculating student survival rates and new student generation rates, and combining them using a new Monte Carlo simulation framework.

A Monte Carlo simulation framework allows for explicit modeling of uncertainty and presents a range of outcomes instead of a single point estimate. Separate simulations run thousands of times, each time randomly changing the underlying projection assumptions, and are combined together in an overall distribution of possible enrollment outcomes. These outcome ranges support decision-making in two ways: they provide a point estimate (the median) alongside a quantified spread of uncertainty, and they let local experts choose a projection percentile to reflect their knowledge of current conditions or anticipated shocks.

In addition, the simulations explicitly model student survival, or continued year-to-year enrollment, and new student generation, or new entries into the system, as separate processes, unlike traditional CSR models that combine these into a single grade progression ratio. This allows for more robust modeling, especially in the presence of strong external shocks that might affect one process more than another. For example, the completion of a new housing development might lead to a surge in new student generation, while a change in promotion policies might lead to a drop in student survival rates. 

This analysis uses `SQL` queries in DuckDB, which are more accessible to school district staff than specialized statistical software or programming languages. Student-level data is required to run the simulations, with certified CALPADS data being ideal for California districts.

## The Stochastic Processes of Continued Enrollment and New Student Enrollment

The Monte Carlo simulation approach models enrollment as a stochastic process driven by two key components: continued enrollment (i.e., student survival) and new student enrollment (i.e., new student generation). 

The simulation handles these two enrollment types as random processes, similar to how we would expect them to play out in the real world. In other words, enrollment is not predicted by a set of circumstances that are known using past data. Instead, each enrollment projection is based on a set of possible outcomes, each one with its own likelihood of happening. All these separate outcomes are combined into a known distribution of outcomes, which can be analyzed to understand the range of potential enrollment outcomes and their probabilities.

The Monte Carlo simulation approach models these enrollment outcomes directly by simulating the enrollment process multiple times, each time randomly drawing from the underlying distributions of continued enrollment and new student enrollment rates. This allows us to capture the natural uncertainty in enrollment projections and provide a range of potential outcomes rather than a single point estimate.

The name of the method comes from a common approach in statistics and computational mathematics, 
where random sampling is used to understand the behavior of a system that is difficult to model analytically. Its name comes from the Monte Carlo Casino in Monaco, which is famous for its games of chance, reflecting the method's reliance on randomness and probability.

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

Survival is modeled as the ratio of students who continue enrollment from one grade to the next. This ratio naturally falls between 0 and 1, so we can use the beta distribution to model survival rates. The parameters of the beta distribution are calculated based on the average and standard deviation of historical survival rates, as well as the number of observations:

$$
Survival_{grade, sim} \sim Beta(\alpha, \beta)
$$

where
 - $ \alpha = \mu \cdot k $
 - $ \beta = (1 - \mu) \cdot k $
 - $ \mu $ is the average survival rate for that grade
 - $ k = \frac{\text{max variance}}{\text{observed variance}} - 1 $

If helpful, note that max variance refers to the theoretical maximum for a Bernoulli proportion, $ \text{max_variance} = \mu (1 - \mu) $. The formula $ k = \frac{\text{max_variance}}{\text{observed_variance}} - 1 $ rescales the beta shape parameters so the beta's variance can match the observed variance when possible. If the observed variance is zero (e.g., a constant historical survival rate), avoid division-by-zero and fall back to a degenerate or conservative distribution (for example, using the observed mean or a tight beta centered on it).

### Modeling New Student Generation

New student generation is modeled as the number of new students entering the system at each grade level. The choice of distribution for modeling new student generation depends on the relationship between the mean and variance of the historical generation data. If the variance is less than the mean (underdispersion), a binomial distribution is used. If the variance is approximately equal to the mean (equidispersion), a Poisson distribution is used. In practice we treat $ \text{mean} \approx \text{variance} $ using a small numerical tolerance to avoid floating-point noise.For example, $ \abs{\text{variance}} - \abs{\text{mean}} \le 1e-6 $ is considered equidispersion and triggers the Poisson model. You can adjust this tolerance depending on sample size and the scale of counts. If the variance is greater than the mean (overdispersion), a negative binomial distribution is used.

$$
Generation_{grade, sim} \sim Dist(params)
$$

where `Dist` is chosen based on the dispersion of the historical data:
 - If underdispersion: $ Binomial(n, p) $
 - If equidispersion: $ Poisson(\lambda) $
 - If overdispersion: $ NegativeBinomial(r, p) $

With underdispersion, the binomial distribution is used, which requires a fixed maximum count $ n $. Here, we can use the maximum observed generation across all years as `n`, and the average generation divided by that maximum as the probability $ p $. In practical terms the probability is calculated as $p = \frac{\mu}{n}$ (where $\mu$ is the average count and $n$ is the chosen maximum, e.g., `N_max`). 
In the SQL examples this is computed as `mu / generation.n_max`. This approach allows us to model the number of new students entering the system while accounting for the observed underdispersion in the historical data.

With equidispersion, the Poisson distribution is used, which is appropriate for modeling count data where the mean and variance are approximately equal. The parameter $ \lambda $ represents the average number of new students generated over the historical period.

With overdispersion, the negative binomial distribution is used, which is appropriate for modeling count data where the variance exceeds the mean. The parameter $ r $ is calculated as $ r = \frac{\mu^2}{\sigma^2 - \mu} $, where $\mu$ is the average generation for that grade and $\sigma^2$ is the variance of generation for that grade. The parameter $ p $ is calculated as $ p = \frac{\mu}{\sigma^2} $. This approach allows us to model the number of new students entering the system while accounting for the observed overdispersion in the historical data.

Matching the distribution to observed dispersion keeps the simulations realistic. When the historical data shows less variability than expected, it may indicate constraints on new student entry (such as limited housing). More variability than expected often points to unobserved factors like economic shifts or new housing supply. Ignoring this instability produces unrealistic projections, which is why distribution choice is central to the Monte Carlo approach.

Intuitively, the three different distribution choices for modeling new student generation allow us to capture different patterns in the historical data.

When year-to-year variation in new student generation is minimal (i.e., underdispersion, meaning variance is less than the mean), the binomial distribution restricts the number of new students produced.

When the number of new students generated matches the historical pattern (i.e., equidispersion, meaning that the historical mean and variance are approximately equal), the Poisson distribution's allowance for greater variability in new student numbers around a known mean.

When the variance exceeds the mean (i.e., overdispersion, meaning that the historical variance is greater than the historical mean), the negative binomial distribution allows for greater variability in the number of new students.

Choosing the right distribution based on observed dispersion is what makes the simulated projections track actual historical patterns rather than just reproducing the mean.

## Combining Survival and Generation in Monte Carlo Simulations

The Monte Carlo framework combines the two separate survival and generation simulations into a single enrollment estimate. The overall enrollment estimate predicts enrollment by summing the number of students surviving from the previous grade and the number of new students generated for that grade. Repeating this process for each grade and school over many simulation runs enables us to generate a distribution of projected enrollment outcomes for each grade and school. These repeated simulations, each one separate from the others, allow us to capture the uncertainty in enrollment projections and provide a range of potential outcomes rather than a single point estimate.

As a final step, these separate simulation runs are combined to determine the overall distribution of possible enrollment outcomes for each grade and school. By analyzing this distribution, we can understand the range of potential enrollment outcomes and their likelihood when compared to other predictions, which can inform decision-making and help districts prepare for a variety of future scenarios. Usually, the midpoint of this distribution (i.e., the median or 50th percentile) is used as the point estimate for enrollment projections. Other percentiles (e.g., the 25th percentile and the 75th percentile) can provide a more conservative or optimistic projection based on local knowledge of trends and conditions.

The intuition behind using different percentiles is that they quantify the uncertainty in enrollment projections and give a sense of the range of outcomes. This gives policy makers the tools to make informed decisions based on their specific circumstances and risk tolerance. For example, if a district is facing significant uncertainty because of potential external factors (e.g., a new charter school opening, a change in promotion policies) or has experienced an unexpected decline in enrollment year-over-year, they might choose to use a more conservative percentile (e.g., the 40th percentile) to account for the possibility of lower enrollment than historically observed. Conversely, if a district is expecting strong growth trends and wants to plan for higher enrollment, it might choose to use a more optimistic percentile (e.g., the 60th percentile).

# Implementation Steps

## Required Tools

The Monte Carlo simulation example is implemented in `DuckDB`, an open-source, in-process SQL database management system that is designed for analytical workloads. `DuckDB` is particularly well-suited for this type of analysis because it can efficiently handle large datasets and complex queries, making it ideal for processing student-level enrollment data and running simulations. `DuckDB` can be installed on a variety of operating systems and platforms using their [official installation guides](https://duckdb.org/install/).


Modeling the stochastic process relies on a community extension for `DuckDB` aptly named `stochastic`, 
which provides functions for generating random numbers from specified distributions. The `stochastic` DuckDB extension provides the sampling functions used in the examples (for example, `dist_beta_sample`, `dist_poisson_sample`, `dist_negative_binomial_sample`, and `dist_binomial_sample`). Check the extension documentation for exact parameter conventions and supported types because function names and parameter orders may vary in future versions.

Install and load this extension from the 'DuckDB' community extensions marketplace:

```sql {title="Installing Stochastic Extension"}
install stochastic from community;
load stochastic;
```

## Data Collection

The first step in this simulation approach is to collect and prepare the data. The simulation requires historical enrollment data at the student level. For California districts, CALPADS report 1.2 Enrollment - Primary and Short Term Enrollment Student List is ideal, as it provides detailed information on student enrollment by grade and school. If this report is not available, districts can use their own student-level enrollment data, ensuring that it includes school codes, student id, and grade level data.

Multiple years of data are preferable, with five years being the recommended minimum to calculate more stable survival rates and new student generation rates.

Below, I show a sample query that processes CALPADS data to create a clean enrollment table. This query assumes a folder named `CALPADS` stores the raw CALPADS data, and that all reports are available as separate CSV files with this naming convention: `Enrollment_1_2_[YY]_[YY].csv`. The example `SQL` code can be easily adjusted to fit other data formats, as long as the necessary information on school codes, student id, and grade level is included.

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

District-wide projections can be created by combining enrollment data across schools. The rest of the code remains the same. Here, the `sc` column can be set to a constant value representing the district name, or different aggregate levels representing regular enrollment, charter enrollment, and non-public school enrollment.

## Data Processing

To run the simulations, we need two separate intermediate data tables: one for student survival rates and another for new student generation rates. Processing the same historical enrollment data in slightly different ways creates these tables.

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
        -- standard error for a proportion: sqrt(p * (1 - p) / n)
        sqrt(avg(survival) * (1.0 - avg(survival)) / count(id)) as sd_survival_rate,
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

### Adaptive Exponential Smoothing

The per-year rates above are combined into a single forecast using **adaptive exponential smoothing**. A simple equal-weighted average treats all historical years identically, which can be unreliable when conditions have shifted: a school closure, a new attendance boundary, or pandemic-era disruptions can make the most recent years very different from older ones.

Exponential smoothing processes historical survival rates in chronological order, updating a running state estimate each year:

$$
\hat{x}_t = \hat{x}_{t-1} + \alpha \cdot \text{winsorize}\!\left(r_t - \hat{x}_{t-1},\; \pm 2\hat{\sigma}_t\right)
$$

where $r_t$ is the annual survival rate, $\hat{x}_{t-1}$ is the smoothed state from the previous year, and the innovation $r_t - \hat{x}_{t-1}$ is clipped to $\pm 2$ estimated standard deviations before being incorporated. Clipping prevents a single outlier year from overriding the smoothed estimate.

The smoothing gain $\alpha$ is estimated from historical data for each (sc, gr) pair:

$$
\alpha = \text{clip}\!\left(1 - \frac{\sigma}{\mu},\ 0.5,\ 0.95\right)
$$

A grade with a stable survival rate (small $\sigma/\mu$) gets a high $\alpha$. This places more weight on historical observations (i.e., the smoothed level) and barely adjusts for new observations. A grade whose rate has fluctuated gets a lower $\alpha$. This allows the model to adapt more quickly to recent data. Clamping $\alpha$ to $[0.5, 0.95]$ keeps the estimator from both freezing (never adapting) and overreacting.

Alongside the smoothed level, the filter tracks an **innovation variance** $\hat{\sigma}^2_t$ — an exponentially smoothed estimate of how much the survival rate has been deviating from its smoothed estimate:

$$
\hat{\sigma}^2_t = \gamma \cdot \min\!\left(\left(r_t - \hat{x}_{t-1}\right)^2,\ 4\hat{\sigma}^2_{t-1}\right) + (1 - \gamma)\, \hat{\sigma}^2_{t-1}
$$

where $\gamma = \min(\alpha, 0.35)$. Capping the squared innovation at $4\hat{\sigma}^2_{t-1}$ prevents a single extreme observation from permanently inflating the variance estimate.

The SQL implementation uses `WITH RECURSIVE` to process years in chronological order. Each row in the recursive step requires the previous year's smoothed state and innovation variance, which DuckDB cannot fetch from a sibling CTE. The workaround is to materialize the intermediates as `TEMP TABLE` before the `WITH RECURSIVE` block:

```sql {title="Recursive Exponential Smoothing on Survival Rates"}
-- Pre-materialize smoothing parameters and ordered annual rates
CREATE OR REPLACE TEMP TABLE survival_params AS
SELECT sc, gr,
  GREATEST(0.5, LEAST(0.95,
    1.0 - STDDEV_POP(avg_survival_rate) / NULLIF(AVG(avg_survival_rate), 0)
  )) AS alpha
FROM survival_long
GROUP BY sc, gr;

CREATE OR REPLACE TEMP TABLE survival_ordered AS
SELECT yr, sc, gr, avg_survival_rate,
  ROW_NUMBER() OVER (PARTITION BY sc, gr ORDER BY yr) AS rn
FROM survival_long;

-- Recursive EMA pass
WITH RECURSIVE
survival_smoothing AS (
  -- Seed: initialize with the first observed year
  SELECT sc, gr, rn, yr, avg_survival_rate AS x, NULL::double AS innovation_var
  FROM survival_ordered
  WHERE rn = 1

  UNION ALL

  SELECT
    o.sc, o.gr, o.rn, o.yr,
    -- Winsorized EMA update
    prev.x + p.alpha * GREATEST(
      -2.0 * SQRT(COALESCE(prev.innovation_var, hist_sd * hist_sd)),
      LEAST(
         2.0 * SQRT(COALESCE(prev.innovation_var, hist_sd * hist_sd)),
         o.avg_survival_rate - prev.x
      )
    ) AS x,
    -- Innovation variance update
    LEAST(p.alpha, 0.35) * LEAST(
      4.0 * COALESCE(prev.innovation_var, hist_sd * hist_sd),
      POWER(o.avg_survival_rate - prev.x, 2)
    ) + (1.0 - LEAST(p.alpha, 0.35))
        * COALESCE(prev.innovation_var, hist_sd * hist_sd) AS innovation_var
  FROM survival_ordered o
    JOIN survival_smoothing  prev ON prev.sc = o.sc AND prev.gr = o.gr AND prev.rn = o.rn - 1
    JOIN survival_params     p    ON p.sc = o.sc AND p.gr = o.gr
    JOIN survival_winsor     wp   ON wp.sc = o.sc AND wp.gr = o.gr
)
SELECT sc, gr, x AS smoothing_survival_rate, innovation_var AS smoothing_innovation_var
FROM (SELECT *, ROW_NUMBER() OVER (PARTITION BY sc, gr ORDER BY rn DESC) AS rn_desc FROM survival_smoothing)
WHERE rn_desc = 1;
```

The final smoothed value $\hat{x}_T$ (or the estimate at the last historical year) becomes the mean survival rate fed into the beta distribution in the Monte Carlo simulations. The spread of that beta distribution uses a **blended variance**: with little data (fewer than two years), the raw historical variance dominates; with more data, the smoothing innovation variance contributes up to half the weight. This prevents the smoothed variance from over-riding the data when the history is short.

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
    sem(generation) as N_sd
from generation
group by all
order by generation.sc, generation.gr
;
```

The table retains three reference columns: a regression-based trend estimate (`N_reg`), a simple historical average (`N_avg`), and the observed maximum (`N_max`). The regression trend is useful for detecting structural growth or decline; the average and maximum bound the plausible range. However, the simulation uses a fourth estimate, `N_gen`, produced by the same adaptive exponential smoothing applied to survival rates.

The identical `WITH RECURSIVE` structure processes annual generation counts in chronological order, producing a smoothed forecast that adapts automatically to recent trends. When the smoothed estimate is positive and the historical standard deviation is non-zero, `N_gen = N_smoothing`; otherwise it falls back to `N_avg`. This removes the need to manually choose between `N_reg`, `N_avg`, and `N_max`: the smoothed estimate tracks the historical average when generation has been stable and follows the recent trajectory when counts have been trending up or down.

The generation standard deviation uses the same blended approach described above for survival rates, interpolating between the raw standard error and the smoothing innovation variance based on how many years of data are available.

## Monte Carlo Simulations

With the survival and generation tables prepared, the next step is to run the Monte Carlo simulations.

Using survival and generation rates, the simulations will project future enrollment for each grade and school. We will run the simulations for a specified number of iterations (e.g., 10,000), and in each iteration, we will randomly sample the survival rates and generation rates from their respective distributions (using the average and standard deviation calculated in the previous steps).

The example below illustrates how to perform two-year Monte Carlo simulations. The first part simulates survival and generation rates for year 1 and year 2. The second part combines these separate simulations into a final simulation at the district or school level. Adding more simulation and projection steps allows us to extend the code to simulate over two years of projections if needed.[^reproducibility]

[^reproducibility]: **Note on reproducibility**: the simulation uses a pseudorandom seed (for example, `setseed(20260209)`) to make draws reproducible. Different seeds will produce different simulated draws; when auditing sensitivity, run the full simulation across several seeds or report results aggregated across multiple seeds to ensure results are not driven by a single random draw.

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
        case
            -- draw from beta when valid: mu in (0,1) and variance > 0 and less than max variance
            when mu > 0.0 and mu < 1.0 and observed_variance > 0.0 and observed_variance < max_variance then
                dist_beta_sample(
                    mu * (max_variance / observed_variance - 1.0),
                    (1.0 - mu) * (max_variance / observed_variance - 1.0)
                )
            -- degenerate or boundary cases: return mean or bounds
            when mu <= 0.0 then 0.0
            when mu >= 1.0 then 1.0
            else mu
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
        case
            -- draw from beta when valid: mu in (0,1) and variance > 0 and less than max variance
            when mu > 0.0 and mu < 1.0 and observed_variance > 0.0 and observed_variance < max_variance then
                dist_beta_sample(
                    mu * (max_variance / observed_variance - 1.0),
                    (1.0 - mu) * (max_variance / observed_variance - 1.0)
                )
            -- degenerate or boundary cases: return mean or bounds
            when mu <= 0.0 then 0.0
            when mu >= 1.0 then 1.0
            else mu
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

Student survival is modeled using a beta distribution, which is appropriate for modeling probabilities that are bounded between 0 and 1. We estimate the beta shape parameters from the observed mean and variance of historical survival rates. If historical variance is zero or exceeds the allowable beta variance, we fallback to a conservative default. In the code, the value `0.99` is used as a conservative default for the mean survival rate, which assumes that most students will continue enrollment from one grade to the next. This fallback value can be adjusted based on local knowledge of trends and conditions to better reflect the expected survival rates in the projections.

For new student generation, the distribution is chosen based on the relationship between the mean and variance of the historical generation data. If the variance is less than the mean (underdispersion), a binomial distribution is used. If the variance is approximately equal to the mean (equidispersion), a Poisson distribution is used. If the variance is greater than the mean (overdispersion), a negative binomial distribution is used. If the standard deviation is zero or negative, the simulation defaults to using the average generation as a constant value. These distribution choices are appropriate for count data (in our case, the number of new students), which can exhibit different dispersion characteristics than continuous data.

### Gamma-Poisson Mixture for Overdispersion

When overdispersion is detected, the simulation uses a **gamma-Poisson mixture** rather than sampling directly from a negative binomial distribution. The two are mathematically equivalent. It is a Poisson whose rate is gamma-distributed follows a negative binomial, but the mixture form has two practical advantages.

First, it avoids rounding the shape parameter $r$ to an integer, which can distort the distribution for grades with small generation counts. Second, the gamma rate is drawn once per (sc, gr, sim_idx) and shared between year-1 and year-2 Poisson draws:

$$
\lambda_{\text{sim}} \sim \text{Gamma}\!\left(\frac{\mu^2}{\sigma^2 - \mu},\; \frac{\sigma^2 - \mu}{\mu}\right)
$$

$$
\text{Generation}_{Y1,\text{sim}} \sim \text{Poisson}(\lambda_{\text{sim}}), \quad \text{Generation}_{Y2,\text{sim}} \sim \text{Poisson}(\lambda_{\text{sim}})
$$

Sharing the same gamma rate introduces a natural positive correlation between year-1 and year-2 generation draws: simulations that happen to draw a high new-student intake rate in year 1 also have elevated intake in year 2. This reflects how real-world factors that affect generation (a new housing development, an attendance boundary change) tend to persist across consecutive years rather than reverting to baseline immediately.

### Coherent Percentile Bands via Sort-Merge

A subtle issue arises when aggregating simulation results into percentile bands. If survived and generated students are summed within each simulation first and percentiles taken on the total, the low-enrollment scenarios can mix draws where survival happened to be low but generation happened to be high (and vice versa). Random pairing cancels some of the variance and produces bands that are artificially narrow.

The solution is a sort-merge aggregation: the survived draws and the generated draws are independently sorted by value, then paired by rank before summing. This ensures that the low percentile of the total reflects genuinely low survived *and* genuinely low generated outcomes:

$$
N_{p,\text{total}} = N_{p,\text{survived}} + N_{p,\text{generated}}
$$

The result is wider, more conservative uncertainty bands, especially at the tails, which is the appropriate behavior when planners need to prepare for downside enrollment scenarios.

## Cohort Survival Ratio Baseline

In addition to the Monte Carlo simulation, the model runs a traditional cohort survival ratio projection as a five-year deterministic baseline. This provides a point-estimate benchmark that is directly comparable to the current industry standard and is familiar to district planners who already use that tool.[^linear]

[^linear]: For example, FCMAT's Projection-Pro uses a cohort survival ratio projection with linear decaying weights.

The cohort survival model computes grade-to-grade ratios from historical enrollment counts:

$$
R_{g,t} = \frac{Enrollment_{g,t}}{Enrollment_{g-1,\,t-1}}
$$

These ratios are averaged across the most recent years using decaying weights. The weight assigned to each historical year is:

$$
w_{t} = \left(W - \text{age}_t\right)^{\gamma}
$$

where $W$ is the number of years in the window, $\text{age}_t = \text{year} - t$ is how far back the observation is, and $\gamma$ is a configurable exponent that controls how sharply recent years are favored:

| Exponent $\gamma$ | Weight formula | Description |
|---|---|---|
| 0 | $1$ | Equal weights — simple average |
| 0.5 | $\sqrt{W - \text{age}}$ | Mild recency bias |
| 1 | $W - \text{age}$ | Linear decay (FCMAT default) |
| 2 | $(W - \text{age})^2$ | Quadratic — stronger recency bias |

At $\gamma = 0$ all years share equal weight; at any positive exponent the oldest year ($\text{age} = W$) receives weight zero and is effectively excluded. For the entry grade at each school, where there is no prior grade to supply a cohort, the model uses a weighted average of year-over-year enrollment *deltas* instead of a ratio.

```sql {title="Cohort Survival Projection"}
WITH
enrollments AS (
  SELECT sc, gr, yr, COUNT(id) AS enrollment
  FROM enrollment_data
  GROUP BY ALL
  HAVING yr BETWEEN :year - :window AND :year - 1
),
enrollments_with_prev AS (
  SELECT e.sc, e.gr, e.yr, e.enrollment,
    ep.enrollment AS enrollment_cohort
  FROM enrollments e
    LEFT JOIN enrollments ep
      ON ep.sc = e.sc AND ep.gr = e.gr - 1 AND ep.yr = e.yr - 1
),
weighted_ratios AS (
  SELECT sc, gr,
    SUM((enrollment::float / enrollment_cohort) * (:window - (:year - yr)))
      / SUM(:window - (:year - yr)) AS weighted_ratio
  FROM enrollments_with_prev
  WHERE enrollment_cohort > 0
  GROUP BY sc, gr
),
projection_y1 AS (
  SELECT r.sc, r.gr,
    CASE
      WHEN r.gr = min_grade
        THEN last_enrollment + weighted_delta   -- entry grade: use delta
      ELSE weighted_ratio * prev_last_enrollment -- upper grades: apply ratio
    END AS projected_enrollment_y1
  FROM weighted_ratios r
    JOIN min_grades mg ON mg.sc = r.sc
    ...
)
```

Because ratios chain multiplicatively across grades, the cohort survival projection is extended to five years by applying the same weighted ratios to each successive year's projected enrollment. The output reports five years of point estimates per (sc, gr) alongside the two-year Monte Carlo results with uncertainty bands.

The cohort survival projection does not produce uncertainty bands, but it serves as a useful sanity check: when its point estimate and the Monte Carlo median diverge substantially, it typically signals that recent survival rates or generation counts have shifted sharply and the exponential smoothing is capturing a trend that a simple ratio average misses.

## Projection Analysis

The last step in the projection process is to analyze the results of the Monte Carlo simulations. The output of the simulations will be a distribution of projected enrollment numbers for each grade and school for each year of projection.

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

The median projection is used in Monte Carlo simulations to represent the middle-of-the-road scenario. This projection sits in the middle of all simulated outcomes, meaning that there is an equal probability of the actual enrollment being above or below this value.

Different percentiles can also be calculated to represent more optimistic or pessimistic scenarios. For example, the `0.25` quantile would represent a more pessimistic scenario (where enrollment is lower than the median), while the `0.75` quantile would represent a more optimistic scenario (where enrollment is higher than the median)

For example, the query below calculates all deciles for the year 1 projections. These deciles can help understand the range of outcomes and their associated probabilities by school and grade level, which are then aggregated to the district level by summing across schools.

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

A final consideration is whether to apply any smoothing techniques to the school-level projections. Because school-level projections are more sensitive to localized external shocks and have fewer observations than district-level projections, they can exhibit more volatility and less accuracy.

An approach to address this issue is to calculate school-level estimates following a two-stage hybrid approach, where district-level projections are combined with school-level projections to produce smoothed school-level projections that align with the overall district-level projections while still reflecting the relative distribution of students across schools based on historical trends. 

In the first stage, we run projections at the district level and select an appropriate projection result to represent the overall district enrollment. 

In the second stage, we adjust the school-level projections to align with the selected district-level projection. In this stage, the individual school-level projections are used to calculate the percentage share of grade-level enrollment for each school, and then we apply these shares to the selected district-level grade projections.

The adjustment is implemented in a single SQL step that joins the school-level Monte Carlo results to the district-level Monte Carlo results and rescales each school's projection by the ratio of district total to school total at each grade:

```sql {title="Smoothing School-Level Projections"}
WITH
district AS (
  SELECT gr,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY N_y1) AS N1_low,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY N_y1) AS N1_med,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY N_y1) AS N1_high
  FROM district_monte_carlo
  WHERE gr BETWEEN -1 AND 12
  GROUP BY gr
),
schools AS (
  SELECT sc, gr,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY N_y1) AS N1_low,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY N_y1) AS N1_med,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY N_y1) AS N1_high
  FROM school_monte_carlo
  WHERE gr BETWEEN -1 AND 12
  GROUP BY sc, gr
),
totals AS (
  SELECT gr,
    SUM(N1_low) AS school_N1_low,
    SUM(N1_med) AS school_N1_med,
    SUM(N1_high) AS school_N1_high
  FROM schools
  GROUP BY gr
)
SELECT
  schools.sc, schools.gr,
  ROUND(schools.N1_low * (district.N1_low / totals.school_N1_low)) AS N1_low,
  ROUND(schools.N1_med * (district.N1_med / totals.school_N1_med)) AS N1_med,
  ROUND(schools.N1_high * (district.N1_high / totals.school_N1_high)) AS N1_high
FROM schools
  JOIN district ON district.gr = schools.gr
  JOIN totals   ON totals.gr   = schools.gr;
```

The key property of this adjustment is that summing the adjusted school projections across all schools recovers the district total exactly. The low-enrollment projection for each school is the district-level 25th percentile distributed across schools by each school's share of the raw low-projection total; similarly for the median and high projections. Schools do not each independently hit their own low scenario. Instead, they share the same district-wide scenario, which is more realistic than treating each school as independently volatile.

# Conclusion

In this blog post, I described a Monte Carlo simulation approach to enrollment projections that models uncertainty explicitly and produces a range of outcomes rather than a single point estimate.

The method builds on the cohort survival ratio while fixing two of its persistent weaknesses: poor handling of external shocks and no quantification of projection uncertainty. Separating survival and generation into distinct stochastic processes means a shock that affects one (say, a new charter school drawing new students) doesn't distort the other.

## Updates

Since the original post, several improvements have made the model more robust. I have updated this post to reflect these changes.

### June 2026 Update

- **Adaptive exponential smoothing** on both survival rates and generation counts replaces the simple historical average. The smoothing gain $\alpha$ is estimated from each grade's own coefficient of variation, so stable grades smooth strongly and volatile grades adapt quickly. Winsorized innovations prevent a single anomalous year from overriding the smoothed estimate.
- **Gamma-Poisson mixture** sampling for overdispersed generation replaces direct negative binomial draws, avoiding integer-rounding issues and introducing natural year-to-year correlation in generation counts across the two projection years.
- **Sort-merge aggregation** pairs independently sorted survived and generated draws by rank before summing, producing wider and more conservative uncertainty bands at the tails.
- A **cohort survival baseline** running five years out is now included alongside the Monte Carlo results, giving planners a familiar FCMAT-comparable point estimate to anchor the probabilistic output.

### July 2026 Update

- **Draw-level school adjustment** replaces the previous scalar-ratio approach. The old method computed a single percentile-level scale factor (adjusted median / raw median) and applied it uniformly to all school draws, causing the enrollment distrubutions to misalign. Now each school draw is scaled individually at its rank position so the sum of school draws equals the district draw at every rank, not just at the median. Because the join pairs school and district draws on the shared co-monotonic rank, the adjusted percentile bands are internally consistent. For example, the district-level 25th percentile of the school total exactly equals the sum of per-school 25th percentiles.
