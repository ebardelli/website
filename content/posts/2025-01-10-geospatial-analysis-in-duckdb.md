---
title: Geospatial Analysis in DuckDB
date: 2025-01-10T11:40:09.000Z
lastmod: 2025-03-03T11:02:09.000Z

slug: geospatial-analysis-in-duckdb
tags: ["DuckDB","Geospatial"]

draft: false
---

DuckDB provides a comprehensive set of tools to conduct spatial data analysis. These tools are part of the `spatial` extension, an experimental add-on that supports geospatial data processing in DuckDB.

In this post, I cover how to conduct a simple geospatial analysis that combines the US 2020 Census population data with California's school district enrollment to identify school districts that over- or under-enrolled based on the population base residing within their attendance boundaries.

## Setting Up the Data

### TIGER/Line Shapefiles

The US Census Bureau maintains large geospatial databases of the US to support their decennial census. TIGER/Line shapefiles collect the census' land features, such as roads, rivers, and lakes, as well as areas such as counties, census tracts, and census blocks. The [2024 TIGER/Line Shapefiles](https://www.census.gov/geographies/mapping-files/time-series/geo/tiger-line-file.html) were released on September 25, 2024.

We will use the 2020 Census blocks in this analysis.

These are available for download through the Census ftp server:

```bash
wget 'https://www2.census.gov/geo/tiger/TIGER2024/TABBLOCK20/tl_2024_06_tabblock20.zip'
unzip tl_2024_06_tabblock20.zip -d census_blocks
```

Download US Census blocks

### California School District Shapefiles

The California Department of Education also provides (a more modest) number of geospatial datasets. However, these are not as easily accessible as the census datasets.

You will need to manually download the geospatial database of California's districts from this [map](https://gis.data.ca.gov/datasets/CDEGIS::california-school-district-areas-2023-24/explore?location=36.948239%2C-119.002226%2C6.36). Download the database in GeoJSON format.

## Data Cleaning

### Setting Up spatial

We will use the `spatial` extension in DuckDB to conduct our geospatial analysis. While this is an official DuckDB extension maintained by the DuckDB developers, it doesn't come automatically installed with DuckDB.

These two commands will install and load the extension:

```sql
INSTALL spatial;
LOAD spatial;
```

Load spatial in DuckDB

Installing the extension is only needed once. After that, you will only need to use the `LOAD`command to activate `spatial` within the current DuckDB process.

### Loading the Data

We are going to load the data as views in DuckDB. This allows us to access the data just-in-time when running the analysis and only uses a minimal amount of additional storage on top of the original databases on disk to store some metadata.

The TIGER/Line data comes in a `dbf`, which spatial can read natively:

```sql
create view census_blocks as
select * 
from st_read('census_blocks/tl_2024_06_tabblock20.dbf');
```

Load US Census blocks

To load the California district data, you will have to read the `geojson` file you:

```sql
create view ca_districts as 
select * 
from st_read('DistrictAreas2324_-2286165690798712574.geojson');
```

Load CA district map

## Analysis

Now that we have the `census_blocks` and `ca_districts` views ready, we can move on to the analysis. The plan has three steps:

- Identify which blocks belong within the attendance boundary of a particular school district.
- Aggregate the total 2020 Census population for each school district attendance boundary.
- Regress the population on the district enrollment to identify potential over- and under-enrolled school districts based on population.

### Working with Geospatial Geometries

The first step in the analysis plan requires us to identify which census blocks are part of individual districts' attendance boundaries.

We are going to leverage two functions in `spatial`: `st_Contains` and `st_Point`. The first function checks if a geometry contains a point or another geometry. In our case, we will use it to check if a district boundary contains a census block's centroid. The second function builds a spatial point using the centroid coordinates that the Census Bureau provides for each block.

We can use these functions as part of a `join` statement to identify which blocks are part of a California district:

```sql
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

Combine US Blocks and CA District map

This will save a reference view that identifies which census blocks are part of which school district.

### Over- and Under-Enrolled

We can estimate the expected enrollment in each district by regressing total enrollment on the population residing within a district attendance boundary.

This model is rather naive and doesn't take into consideration that California allows for elementary districts that serve K-8 grades, high districts that serve 9-12 grades, and unified districts that serve K-12 grades.

We can conduct this simple OLS regression with:

```sql
with pop as (
select
    ca_districts.DistrictName, 
    ca_districts.DistrictType,
    ca_districts.LocaleDistrict, 
    ca_districts.EnrollTotal, 
    ca_districts.EnrollNonCharter, 
    ca_districts.EnrollCharter, 
    sum(census_blocks.POP20) as ResidentPopulation,
from districts_blocks
    join ca_districts on ca_districts.CDSCode = districts_blocks.CDSCode
    join census_blocks on census_blocks.GEOIDFQ20 = districts_blocks.GEOIDFQ20
group by all
),
reg as (
select
    regr_intercept(EnrollTotal, ResidentPopulation) as intercept,
    regr_slope(EnrollTotal, ResidentPopulation) as slope,
from pop
group by all
)
select
    DistrictName,
    DistrictType,
    EnrollTotal,
    (intercept + slope * ResidentPopulation)::INT as ExpectedEnrollment,
    EnrollTotal - ExpectedEnrollment as EnrollDeviation,
from pop
    cross join reg
order by EnrollDeviation;
```

Regress student enrollment on population

We find that these are the five most under-enrolled districts in California:

```
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

Under-enrollment estimates

and the five most over-enrolled districts in California:

```
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

Over-enrollment estiamtes

---

## Further Reading

The team at Motherduck has written a [blog post](https://motherduck.com/blog/geospatial-for-beginner-duckdb-spatial-motherduck/) that covers the history of GIS software and give some more examples on how to use DuckDB for geospatial analysis. Give it a read if you want to find out more details about geospatial work with  
