---
title: Geospatial Analysis in DuckDB
description: "DuckDB's spatial extension enables geospatial analysis without a dedicated GIS database. This post walks through combining US 2020 Census block data with California school district shapefiles to identify districts that are over- or under-enrolled relative to the residential population within their attendance boundaries."

date: 2025-01-10T11:40:09.000Z
lastmod: 2025-03-03T11:02:09.000Z

slug: geospatial-analysis-in-duckdb
tags: ["DuckDB","Geospatial"]

draft: false
---

DuckDB has solid support for spatial data analysis through the `spatial` extension, an experimental add-on for geospatial data processing.

In this post, I walk through a geospatial analysis that combines US 2020 Census population data with California's school district enrollment to identify districts that are over- or under-enrolled relative to the population living within their attendance boundaries.

## Setting Up the Data

### TIGER/Line Shapefiles

The US Census Bureau maintains large geospatial databases to support their decennial census. TIGER/Line shapefiles collect land features like roads, rivers, and lakes, as well as administrative areas such as counties, census tracts, and census blocks.[^1] 


[^1]: The [2024 TIGER/Line Shapefiles](https://www.census.gov/geographies/mapping-files/time-series/geo/tiger-line-file.html) were released on September 25, 2024.

We'll use the 2020 Census blocks in this analysis.

These are available for download from the Census download site:

```bash {title="Download US Census blocks"}
wget 'https://www2.census.gov/geo/tiger/TIGER2024/TABBLOCK20/tl_2024_06_tabblock20.zip'
unzip tl_2024_06_tabblock20.zip -d census_blocks
```

### California School District Shapefiles

The California Department of Education also provides a (more modest) number of geospatial datasets, though they're not as easily accessible as the census data.[^2]

[^2]: In fact, the CDE maps aren't easy to navigate at all. Some of them allow to download the source data, others don't. I'm not sure why.

## Data Cleaning

### Setting Up spatial

We'll use the `spatial` extension in DuckDB for our geospatial analysis. It's an official extension maintained by the DuckDB developers, but it doesn't come preinstalled.

These two commands install and load the extension:

```sql {title="Load spatial in DuckDB"}
INSTALL spatial;
LOAD spatial;
```

You only need to install it once. After that, `LOAD` is enough to activate `spatial` within the current DuckDB process.[^3]

[^3]: DuckDB comes with both [core extensions](https://duckdb.org/docs/current/core_extensions/overview#default-extensions) and [community extensions](https://duckdb.org/community_extensions/list_of_extensions). These extensions add functionality that isn't part of the core DuckDB program.

### Loading the Data

We're going to load the data as views in DuckDB. This lets us access the data just-in-time during analysis, and uses minimal additional storage beyond the original files on disk.

The TIGER/Line data comes in a `dbf`, which spatial can read natively:

```sql {title="Load spatial in DuckDB"}
create view census_blocks as
select * 
from st_read('census_blocks/tl_2024_06_tabblock20.dbf');
```

To load the California district data, read the GeoJSON file you downloaded:

```sql {title="Load CA district map"}
create view ca_districts as 
select * 
from st_read('DistrictAreas2324_-2286165690798712574.geojson');
```

## Analysis

With `census_blocks` and `ca_districts` ready, the analysis breaks into three steps:

- Identify which census blocks fall within each school district's attendance boundary.
- Aggregate the 2020 Census population for each district boundary.
- Regress population on district enrollment to flag potential over- and under-enrollment.

### Working with Geospatial Geometries

The first step requires matching census blocks to individual districts' attendance boundaries.

We'll use two functions from `spatial`: `st_Contains` and `st_Point`. `st_Contains` checks whether a geometry contains a point or another geometry. In this example, we'll check whether a district boundary contains a census block's centroid. `st_Point` builds a spatial point from the centroid coordinates the Census Bureau provides for each block.

These functions go into a `join` to identify which blocks belong to which California district:

```sql {title="Combine US Blocks and CA District map"}
create view districts_blocks as
select 
    ca_districts.CDSCode,
    census_blocks.GEOIDFQ20
from ca_districts 
join census_blocks 
    on st_Contains(
        ca_districts.geom, 
        st_Point(
            census_blocks.INTPTLON20::DOUBLE,
            census_blocks.INTPTLAT20::DOUBLE));
```

This saves a reference view mapping census blocks to school districts.

### Over- and Under-Enrolled

We can estimate expected enrollment in each district by regressing total enrollment on the population living within a district's attendance boundary.

This model ignores an important distinction: California has elementary districts (K–8), high school districts (9–12), and unified districts (K–12). A more rigorous model would account for that. But even this simple version surfaces interesting patterns.

We run the OLS regression[^4] with:

[^4]: DuckDB isn't really setup for statistical work. This is more of an example than a real analysis. You can still use this dataset in R (for example) using the [DuckDB R package](https://duckdb.org/docs/current/clients/r).

You'll need to manually download the geospatial database of California's districts from this [map](https://gis.data.ca.gov/datasets/CDEGIS::california-school-district-areas-2023-24/explore?location=36.948239%2C-119.002226%2C6.36). Download it in GeoJSON format.

```sql {title="Regress student enrollment on population"}
WITH pop AS (
    SELECT
        ca_districts.DistrictName,
        ca_districts.DistrictType,
        ca_districts.LocaleDistrict,
        ca_districts.EnrollTotal,
        ca_districts.EnrollNonCharter,
        ca_districts.EnrollCharter,
        SUM(census_blocks.POP20) AS ResidentPopulation
    FROM districts_blocks
    JOIN ca_districts ON ca_districts.CDSCode = districts_blocks.CDSCode
    JOIN census_blocks ON census_blocks.GEOIDFQ20 = districts_blocks.GEOIDFQ20
    GROUP BY
        ca_districts.DistrictName,
        ca_districts.DistrictType,
        ca_districts.LocaleDistrict,
        ca_districts.EnrollTotal,
        ca_districts.EnrollNonCharter,
        ca_districts.EnrollCharter
),
reg AS (
    SELECT
        regr_intercept(EnrollTotal, ResidentPopulation) AS intercept,
        regr_slope(EnrollTotal, ResidentPopulation) AS slope
    FROM pop
)
SELECT
    DistrictName,
    DistrictType,
    EnrollTotal,
    (intercept + slope * ResidentPopulation)::INT AS ExpectedEnrollment,
    EnrollTotal - ExpectedEnrollment AS EnrollDeviation
FROM pop
CROSS JOIN reg
ORDER BY EnrollDeviation;
```

The five most under-enrolled districts:

``` {title="Under-enrollment estimates"}
┌──────────────────────────┬─────────────────┐
│       DistrictName       │ EnrollDeviation │
├──────────────────────────┼─────────────────┤
│ San Francisco Unified    │          -40221 │
│ East Side Union High     │          -36270 │
│ Grossmont Union High     │          -31437 │
│ Kern High                │          -29534 │
│ Chaffey Joint Union High │          -23620 │
└──────────────────────────┴─────────────────┘
```

And the five most over-enrolled:

``` {title="Over-enrollment estimates"}
┌─────────────────────────────┬─────────────────┐
│        DistrictName         │ EnrollDeviation │
├─────────────────────────────┼─────────────────┤
│ Fresno Unified              │           28006 │
│ Elk Grove Unified           │           23842 │
│ Los Angeles Unified         │           22267 │
│ Corona-Norco Unified        │           19411 │
│ San Bernardino City Unified │           19333 │
└─────────────────────────────┴─────────────────┘
```

---

## Further Reading

The Motherduck team has a [blog post](https://motherduck.com/blog/geospatial-for-beginner-duckdb-spatial-motherduck/) covering the history of GIS software alongside more examples of using DuckDB for geospatial analysis.
