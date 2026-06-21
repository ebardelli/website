---
title: "On Redrawing School Attendance Boundaries"
date: 2025-03-21T22:09:26.000Z
lastmod: 2025-05-27T00:02:51.000Z

slug: redrawing-school-attendance-boundaries
tags: ["Data Science","Policy","Data Processing","Data Visualization","DuckDB","Geospatial"]

isStarred: true
draft: false
description: "Redrawing school attendance boundaries at time of school consolidation requires balancing data precision with community impact. This post describes the DuckDB-powered GIS tooling I built to support redrawing school attendance boundaries, starting from Census block integration and student geocoding to real-time attendance projections for public stakeholder meetings."
---

Imagine a single line drawn on a map. That line, a school attendance boundary, prescribes more than just where a child goes to school. It shapes their friendships, influences their family's home value, and defines the character of their neighborhood. Redrawing those lines is a task with far-reaching consequences that require balancing data and human impact.

In this post, I'll walk you through how our district used data science and geospatial analysis to redraw school boundaries during a challenging consolidation process. You'll learn about the custom GIS tools we built to visualize and manipulate geographic data, how we used DuckDB to power sophisticated boundary analysis, the challenges of balancing algorithmic optimization with community needs, and practical lessons for data-driven decision-making in educational policy.

Along the way, I'll share both technical insights and the human considerations that ultimately guided our process.

## Geospatial Analysis Tools for Boundary Redrawing

In the Fall of 2024, our district faced declining enrollment and budget constraints that resulted in the closing of several schools. This consolidation required redrawing attendance boundaries for the remaining schools — a process with significant implications for students, families, and neighborhoods. To support this work, we developed a set of geospatial analysis tools that allowed stakeholders to visualize current boundaries, propose changes, and immediately see their potential impacts.

While working on the consolidation project, we developed internal (and later publicly available) tools to visualize school boundaries and other maps, draw boundaries that follow Census blocks, and estimate projected attendance and financial impacts of various school closure scenarios.

### Geospatial Analysis Engine

All geospatial analysis relied on DuckDB as the data storage and analytical engine.

As I covered in a previous [blog post](/geospatial-analysis-in-duckdb/), DuckDB provides a strong set of geospatial tools through the spatial extension. This includes functions such as [`ST_Contains`](https://duckdb.org/docs/stable/extensions/spatial/functions.html#st_contains) that powered our geospatial joins of students to attendance boundaries and GeoJSON aggregation functions to combine census blocks into single attendance boundaries. GeoJSON is a standard format for representing geographic data as text — a map blueprint a computer can read. Its coordinates define each shape (like a school boundary) and can carry additional information (like school name or enrollment numbers).

One of the biggest advantages of using DuckDB over other GIS software (e.g., ArcGIS) is the ability to use SQL syntax for geospatial analysis. This lets me write queries once and reuse them across multiple scenarios. When the school board requested an urgent analysis of how a specific boundary change might affect feeder patterns between elementary and middle schools, I could generate the analysis within hours rather than days, providing critical data for their next public meeting.

Beyond code-oriented tooling, geospatial analysis also relies on map visualization and interactivity. I developed two separate web applications for this.

## Web Applications for Map Visualization

### GeoJSON Viewer

The [boundary viewer tool](https://santa-rosa-city-schools.github.io/maps/viewer.html?url=https%3A%2F%2Fraw.githubusercontent.com%2FSanta-Rosa-City-Schools%2Fmaps%2Frefs%2Fheads%2Fmain%2FSchool%2520Boundaries%2F2025-2026%2FElementary-Fixed.geojson) is a simple web application that loads a [GeoJSON](https://en.wikipedia.org/wiki/GeoJSON) file and displays it as an overlay on a [Leaflet](https://leafletjs.com/) map. I developed this tool before the school consolidation process as a support tool to display our growing number of [publicly available maps](https://github.com/santa-rosa-city-schools/maps), which included school attendance boundaries, trustee areas, and feeder district boundaries.

Before this tool, we had used [geojson.io](https://geojson.io) for both viewing and editing GeoJSON files. We used this website to digitize our attendance boundary maps in 2024, though we still used it when making small changes to existing GeoJSON files.

The inspiration for this web application came from a Friday night email from a teacher who was working on a lesson plan about attendance boundaries for their high school class. I felt bad telling them to download a GeoJSON file from GitHub, then go to geojson.io, and upload the file. To my former teacher's eyes, this looked like a process with too much friction. That realization led to the creation of the boundary viewer tool, which allows users to share a URL that encodes a GeoJSON file and automatically loads and displays it.

### Boundary Drawing Tool

While the GeoJSON Viewer helped stakeholders understand existing boundaries, we needed a more interactive tool for the actual redrawing process. We developed the Boundary Drawing Tool to support direct manipulation of attendance zones using census blocks as building blocks.

The basic design decisions behind this tool were to allow the user to color in attendance boundaries using US Census blocks as the starting layer. The tool has three main features: loading a base map from US Census blocks and district boundaries, assigning blocks to schools, and displaying basic attendance projections based on current enrollment patterns.

## Census Block Integration

##### US Census Map

The Census Bureau develops census blocks as the smallest statistical unit bounded

> by roads, streams, and railroad tracks, and by nonvisible boundaries such as property lines, city limits, school district, county limits, and short line-of-sight extensions of roads ([U.S. Census Bureau](https://www.census.gov/newsroom/blogs/random-samplings/2011/07/what-are-census-blocks.html)).

We used these pre-defined blocks to avoid dividing the city into geographic units ourselves. This saved considerable development time and gave us boundaries that residents could recognize.

We combined the US Census blocks with our district's attendance boundaries. Santa Rosa City Schools is [one of five districts](https://www.cde.ca.gov/re/lr/do/typicalconfigschooldist.asp) in California that are common administration districts — two separate elementary and secondary districts share a common school board. Our two constituent districts have different attendance boundaries, where the elementary district is contained within the secondary district. This setup posed an additional challenge: we had to develop two sets of potential attendance blocks and separate blocks that crossed the boundary between the two districts.

##### Encoding Student Data Within Census Blocks

Estimating attendance at each school under the new boundaries required a potential student count at the US Census block level.

In a separate project, I geolocated all properties that pay our secondary school district parcel tax using a parcel database we purchased from Sonoma County. While this database was outdated at the time of purchase because of record-keeping backlog from the Santa Rosa fires and the COVID-19 pandemic, it included the majority of residential addresses in our attendance boundary.

Using this database, I counted the number of current students living within each block and saved this count as a metadata field in the maps available in the Boundary Drawing Tool.

DuckDB made this process straightforward: an aggregate count with a spatial join produces the resident count per census block. A runnable example (adjust table and file paths as needed) looks like this:

```sql {title="Spatial join in DuckDB counting students living within a US Census Block"}
SELECT
        block.id AS id,                     -- Census block identifier
        COUNT(student.id) AS residents,     -- Number of students in the block
        block.geom AS geom                  -- Geographic shape of the block
FROM US_Census_Blocks AS block
JOIN students AS student
    ON ST_Contains(block.geom, ST_Point(student.lon, student.lat))
GROUP BY block.id, block.geom;
```

You can export the results to a GeoJSON file using DuckDB's COPY syntax (example using GDAL driver; adapt path/driver to your environment):

```sql {title="Exporting to GeoJSON format within DuckDB using the spatial extension GDAL integration"}
COPY (
    SELECT id, residents, geom FROM (
        SELECT block.id AS id, COUNT(student.id) AS residents, block.geom
        FROM US_Census_Blocks AS block
        JOIN students AS student
            ON ST_Contains(block.geom, ST_Point(student.lon, student.lat))
        GROUP BY block.id, block.geom
    )
) TO 'map.geojson' (FORMAT 'gdal', DRIVER 'GeoJSON');
```

#### Algorithmic Optimization and its Limitations in Boundary Drawing

The small but growing literature on school boundaries (e.g., [Monarrez, 2023](https://www.aeaweb.org/articles?id=10.1257/app.20200498), [Gillani et al., 2023](https://journals.sagepub.com/doi/full/10.3102/0013189X231170858)) discusses the potential of mathematical modeling in drawing attendance boundaries.

Optimization models and algorithms can assist in the labor-intensive planning and decision-making required when drawing a new attendance boundary. By offloading the bulk of the boundary assignment to an algorithm, the analyst's time goes toward marginal adjustments — accounting for intangibles like neighborhood boundaries, historical attendance patterns, and communities of interest.

At the same time, prior work has shown that over-reliance on mathematical models that optimize for distance to the nearest school can exacerbate segregation by institutionalizing housing segregation within attendance boundaries ([Monarrez, 2023](https://www.aeaweb.org/articles?id=10.1257/app.20200498)).

Consider a fictional town cut in half by a freeway, with two schools, each on different sides. An optimization algorithm might assign each half of the town to its nearest school. While this minimizes travel time, it could institutionalize segregation if the freeway historically served as a [redlining](https://en.wikipedia.org/wiki/Redlining) boundary.

In our own district, we encountered a similar challenge with one neighborhood that the algorithm consistently assigned to a distant school based on capacity optimization. This would have required students to travel across town with limited pedestrian infrastructure or public transportation. By incorporating local knowledge about walking safety and historic neighborhood connections, we manually overrode the algorithm's suggestion to preserve community cohesion and student safety.

## Optimization Models in the Boundary Drawing Tool

Our boundary drawing tool can automatically create attendance zones from set parameters. The algorithm is built around the [knapsack problem](https://en.wikipedia.org/wiki/Knapsack_problem) — a classic optimization challenge: pack a backpack with the most valuable items without exceeding its weight limit. In our case, we're packing students into schools while balancing two constraints: maximizing capacity utilization while minimizing travel distance. Just as you might prioritize lighter, more valuable items for your backpack, the algorithm prioritizes census blocks that are both closer to schools and help optimize enrollment numbers.

Rather than using traditional GIS software, we implemented this algorithm in SQL, allowing DuckDB to run directly in users' browsers through WebAssembly (WASM). To generate boundaries, users provide two inputs: capacity optimization preferences and block prioritization criteria.

The process has three parts:

1. Calculation of the current school enrollment count. This relies on student enrollment counts encoded in the underlying map in the `enrollment` field.

2. Identification of block candidates based on current map status and adjacency to selected blocks. This relies on a pre-computed block adjacency matrix saved in a DuckDB database.

3. Selection of the next block to assign based on user optimization options. This last query returns a single block that the mapping tool assigns to the correct school.

```sql {title="Census block selection based on user-selected optimization parameters in DuckDB"}
with current_enrollment as (
    select
        status.school,
        sum(map.enrollment) as enrollment,
        schools.capacity as capacity
    FROM status
        JOIN data.${currentTable} AS map ON map.block_of_residence = status.block
        JOIN data.schools ON schools.name = status.school
    WHERE school IS NOT NULL
    GROUP BY status.school, schools.capacity
),
block_candidates as (
    select
        current_enrollment.school,
        current_enrollment.enrollment,
        current_enrollment.capacity,
        adjacent_block AS block
    FROM data.${currentTable}_adjacency
        CROSS JOIN current_enrollment
    where 
        block_of_residence in (select block from status where school = current_enrollment.school)
        and
        adjacent_block IN (select block from status where school is NULL)
)
select
    block_candidates.school,
    block_candidates.enrollment,
    block_candidates.block,
    distances.distance,
    distances.driving_distance,
    distances.driving_time
from block_candidates
    join data.distances on distances.school = block_candidates.school 
    and distances.block_of_residence = block_candidates.block
where
    case
        when '${capacityOptimization}' = 'percentage' then (enrollment / capacity) <= 1.0
        when '${capacityOptimization}' = 'enrollment' then enrollment <= capacity
        else true
    end
order by
    case
        when '${capacityOptimization}' = 'percentage' then (enrollment / capacity)
        when '${capacityOptimization}' = 'enrollment' then enrollment
        else 1
    end, distances.${blockOptimization}
limit 1
```

The procedure is wrapped in a loop that continues selecting blocks until all blocks are assigned, schools run out of space, or adjacent blocks to current assigned areas run out.

These stopping conditions — necessary to prevent infinite loops — can produce maps where not all blocks are assigned or where a patchwork assignment emerges under specific circumstances.

Regardless of this limitation, the final maps still need some manual intervention: to make sure developed boundaries follow geographic or community boundaries (rather than computer-generated ones), to ensure all blocks are assigned to a school, and to account for historical housing policies that could contribute to school segregation.

## Data, Tools, and Human Judgment

Geospatial analysis, optimization models, and databases provided the technical foundation for our boundary work: fast iteration, repeatable queries, and clear visualizations made it possible to explore many scenarios and quantify likely impacts. But these systems are aids, not prescriptions. Algorithms can suggest efficient assignments, yet they can't perceive walking routes, neighborhood ties, or local safety concerns — factors that critically shape whether a boundary is practical and equitable.

In practice, we used automated assignment to surface feasible options and save analyst time, then layered in local knowledge and values to resolve edge cases, address patchwork assignments, and avoid reinforcing historical inequities. Visualization was essential: maps translated quantitative outputs into a form stakeholders could understand and discuss.

The work succeeded when technical capability supported community-centered decision-making rather than replacing it. In the next post, I'll explore how these tools facilitated conversations and the social dynamics that ultimately shaped our final boundary decision.

## Further Readings

- [A Beginner's Guide To Geospatial With DuckDB Spatial And MotherDuck](https://motherduck.com/blog/geospatial-analysis-duckdb/) - A practical introduction to geospatial analysis using DuckDB.
- Monarrez, T. (2023). [School Attendance Boundaries and the Segregation of Public Schools in the United States](https://www.aeaweb.org/articles?id=10.1257/app.20200498). *American Economic Journal: Applied Economics* 15 (3): 210–37. - Research examining how school boundary decisions can perpetuate segregation.
- Richards, M. P. (2014). [The Gerrymandering of School Attendance Zones and the Segregation of Public Schools: A Geospatial Analysis](https://journals.sagepub.com/doi/abs/10.3102/0002831214553652). *American Educational Research Journal*, *51*(6), 1119-1157. - Historical context on how boundary decisions impact school demographics.
- [NCES School Attendance Boundary Survey (SABS)](https://nces.ed.gov/programs/edge/SABS) - A national database of school attendance boundaries maintained by the National Center for Education Statistics.
