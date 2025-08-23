---
title: "The Technical Blueprint: Redrawing School Attendance Boundaries"
date: 2025-03-21T22:09:26.000Z
lastmod: 2025-05-27T00:02:51.000Z

slug: technical-aspects-of-redrawing-school-attendance-boundaries
tags: ["Data Science","Policy","Data Processing","Data Visualization","DuckDB","Geospatial"]

draft: false
---

Imagine a single line drawn on a map. That line, a school attendance boundary, prescribes more than just where a child goes to school. It shapes their friendships, influences their family's home value, and defines the very fabric of their neighborhood. Redrawing those lines, then, is a task with far-reaching consequences that require balancing data and human impact.

In this post, I'll walk you through how our district used data science and geospatial analysis to redraw school boundaries during a challenging consolidation process. You'll learn about the custom GIS tools we built to visualize and manipulate geographic data, how we used DuckDB to power sophisticated boundary analysis, the challenges of balancing algorithmic optimization with community needs, and practical lessons for data-driven decision making in education policy.

Along the way, I'll share both technical insights and the human considerations that ultimately guided our process.

## Geospatial Analysis Tools for Boundary Redrawing

In the Fall of 2024, our district faced declining enrollment and budget constraints that resulted in closing of several schools. This school consolidation process required redrawing attendance boundaries for the remaining schools—a process with profound implications for students, families, and neighborhoods. To support this delicate work, we developed a suite of geospatial analysis tools that allowed stakeholders to visualize current boundaries, propose changes, and immediately see their potential impacts.

While working on our school consolidation project, we developed internal (and later publicly available) geospatial tools to visualize school boundaries (and other maps), draw school boundaries following Census blocks, and analytical tools used to estimate projected attendance and financial impacts of various school closure scenarios.

### Geospatial Analysis Engine

All geospatial analysis relied on DuckDB as the data storage and analytical engine. 

As I covered in a previous [blog post](__GHOST_URL__/geospatial-analysis-in-duckdb/), DuckDB provides a robust set of tools for geospatial analysis through the spatial extension. This includes functions such as [`ST_Contains`](https://duckdb.org/docs/stable/extensions/spatial/functions.html#st_union_agg) that powered our geospatial joins of students to attendance boundaries and GeoJSON aggregation functions to combine census blocks into single attendance boundaries. GeoJSON is a standard format for representing geographic data as text. Think of it as a blueprint for a map that a computer can read. Its coordinates define each shape (like a school boundary) and can have additional information attached to it (like school name or enrollment numbers).

One of the biggest advantages of using DuckDB over other GIS software (e.g., ArcGIS) is the ability to use SQL syntax to conduct geospatial analysis. This let me write SQL queries once and reuse the same code across multiple scenarios. When the school board requested an urgent analysis of how a specific boundary change might affect feeder patterns between elementary and middle schools, I could generate this analysis within hours rather than days, providing critical data for their next public meeting.

Beyond code-oriented tooling, geospatial analysis also relies on map visualization and interactivity. I developed two separate web applications with these functionalities.

## Web Applications for Map Visualization

### GeoJSON Viewer

The [boundary viewer tool](https://santa-rosa-city-schools.github.io/maps/viewer.html?url=https%3A%2F%2Fraw.githubusercontent.com%2FSanta-Rosa-City-Schools%2Fmaps%2Frefs%2Fheads%2Fmain%2FSchool%2520Boundaries%2F2025-2026%2FElementary-Fixed.geojson) is a simple web application that loads a [GeoJSON](https://en.wikipedia.org/wiki/GeoJSON) file and displays it as an overlay on a [Leaflet](https://leafletjs.com/) map. I developed this tool before the school consolidation process as a support tool to display our growing number of [publicly available maps](https://github.com/santa-rosa-city-schools/maps), which included school attendance boundaries, trustee areas, and feeder district boundaries.

Before this tool, we had used [geojson.io](https://geojson.io) for both viewing and editing GeoJSON files. In fact, we used this website to digitize our attendance boundary maps in 2024, though we still used it when making small changes to existing GeoJSON files.

The inspiration for this web application came from a Friday night email from a teacher who was working on a lesson plan about attendance boundaries for their high school class. I felt bad telling them to download a GeoJSON file from GitHub, then go to geojson.io, and upload the GeoJSON file. To my former teacher’s eyes, this looked like a process with too much friction and too many steps. This realization led to the creation of the boundary viewer tool, which allows users to share an URL which encodes a GeoJSON file and automatically loads and displays it.

### Boundary Drawing Tool

While the GeoJSON Viewer helped stakeholders understand existing boundaries, we needed a more interactive tool for the actual redrawing process. This led us to develop the Boundary Drawing Tool, which supports direct manipulation of attendance zones using census blocks as building blocks.

The basic design decision behind this tool was to allow the user to color in attendance boundaries using the US Census blocks as a starting layer. For this reason, this tool has three main features: 1. loading of a base map based on US Census blocks and district boundaries, 2. assign blocks to schools, and 3. display basic attendance projections based on current enrollment patterns.

## Census Block Integration

##### US Census Map

The Census Bureau develops census blocks as the smallest statistical unit bounded

> by roads, streams, and railroad tracks, and by nonvisible boundaries such as property lines, city limits, school district, county limits, and short line-of-sight extensions of roads" ([U.S. Census Bureau](https://www.census.gov/newsroom/blogs/random-samplings/2011/07/what-are-census-blocks.html)).

Building upon this established foundation, we leveraged these pre-defined blocks to avoid the time-consuming task of dividing the city into geographical units ourselves. This approach not only saved considerable development time but also provided boundaries that residents could intuitively recognize.

We combined the US Census blocks with our district’s attendance boundaries. Santa Rosa City Schools is [one of five districts](https://www.cde.ca.gov/re/lr/do/typicalconfigschooldist.asp) in California that are common administration districts—that is, two separate elementary and secondary districts share a common school board. This means that our two constituent districts have different attendance boundaries, where the elementary district is contained within the secondary district. This setup posed an additional challenge of developing two sets of potential attendance blocks and separating blocks that crossed the boundaries between the two districts.

##### Encoding Student Data Within Census Blocks

Estimating attendance at each school under the new boundaries required us to provide a potential student count at the US Census block level.

In a separate project, I geolocated all properties that pay our secondary school district parcel tax, using a parcel database that we purchased from Sonoma County. While this database was outdated at time of purchase because of record keeping backlog due to the Santa Rosa fires and the COVID-19 pandemic, this provided us with a database that included the majority of residential addresses in our attendance boundary.

Using this database, I counted the number of current students living within the boundaries of each block and saved this count as a metadata field in each of the maps available in the Boundary Drawing Tool. 

DuckDB made this process trivial, requiring an aggregate `count` and a spatial join:

```sql
SELECT
    block.id AS ID,                     -- Census block identifier
    COUNT(student.id) AS RESIDENTS,     -- Number of students in the block
    block.geom AS GEOM                  -- Geographic shape of the block
FROM US_Census_Blocks AS block
    JOIN students AS student            -- Connect student addresses to blocks
    WHERE ST_Contains(block.geom, ST_Point(student.lon, student.lat))
GROUP BY ALL
```

Spatial join in DuckDB counting students living within a US Census Block

I export this table using the [GDAL](https://gdal.org/en/latest/) extension to a GeoJSON map:

```sql
copy <table from previous query> 
to map.geojson
with (FORMAT gdal, DRIVER 'GeoJSON')
```

Exporting to GeoJSON format within DuckDB using the spatial extension GDAL integration

#### Algorithmic Optimization and its Limitations in Boundary Drawing

The small but growing literature on school boundaries (e.g., [Monarrez, 2023](https://www.aeaweb.org/articles?id=10.1257/app.20200498), [Gillani et al., 2023](https://journals.sagepub.com/doi/full/10.3102/0013189X231170858)) discusses the potential of mathematical modeling in drawing attendance boundaries. 

Optimization models and algorithms can assist in labor-intensive planning and decision-making processes required when drawing a new attendance boundary. By offloading the bulk of the boundary assignment to an algorithm, the analyst’s time is focused on marginal changes to the boundary to accommodate intangible aspects such as neighborhood implicit boundaries, historical attendance patterns, and communities of interest.

At the same time, prior work has shown that over-reliance on mathematical models that optimize, for example, distance to the nearest school, could exacerbate school segregation by institutionalizing housing segregation within school attendance boundaries ([Monarrez, 2023](https://www.aeaweb.org/articles?id=10.1257/app.20200498)). 

For example, let's assume a fictional town cut in half by a freeway, with two schools, each on different sides of the freeway. An optimization algorithm might suggest assigning each half of the town to its respective school. While this might minimize travel time to and from school, this arrangement could institutionalize segregation if the freeway had historically served as a [redlining](https://en.wikipedia.org/wiki/Redlining) boundary.

In our own district, we encountered a similar challenge with one neighborhood that an algorithm consistently assigned to a distant school based on capacity optimization. However, this would have required students to travel across town with limited pedestrian infrastructure or public transportation. By incorporating local knowledge about walking safety and historic neighborhood connections, we manually overrode the algorithm's suggestion to maintain community cohesion and student safety.

## Optimization Models in the Boundary Drawing Tool

Beyond geospatial tools, mathematical models offer another powerful approach to boundary redrawing, though they come with their own set of considerations.

Our boundary drawing tool can automatically create attendance zones based on set parameters. At its core lies the [knapsack problem](https://en.wikipedia.org/wiki/Knapsack_problem)—a classic optimization challenge that's like trying to pack a backpack with the most valuable items without exceeding its weight limit. In our case, we were 'packing' students into schools while balancing two constraints: maximizing each school's capacity utilization while minimizing students' travel distance. Just as you might prioritize lighter, more valuable items for your backpack, our algorithm prioritizes census blocks that are both closer to schools and help optimize enrollment numbers.

Rather than using traditional GIS software, we implemented this algorithm in SQL, allowing DuckDB to run directly in users' browsers through WebAssembly (WASM). To generate boundaries, users need only provide two key inputs: capacity optimization preferences and block prioritization criteria.

In more details, the process is divided into three parts:

1. Calculation of the current school enrollment count. This calculation relies on student enrollment counts encoded in the underlying map in the `enrollment` field. 

2. Identification of block candidates based on current map status and adjacency to selected blocks. This analysis relies on a pre-computed block adjacency matrix saved in a DuckDB database. 

3. Selection of the next block to assign based on user optimization options. This last query returns a single block that the mapping tool assigns to the correct school.

```sql
with current_enrollment as (
    select
        status.school,
        sum(map.enrollment) as enrollment,
        schools.capacity as capacity
    from status
        join data.${currentTable} as map on map.block_of_residence = status.block
        join data.schools on schools.name = status.school
    where school is not NULL
    group by all
),
block_candidates as (
    select
        current_enrollment.school,
        current_enrollment.enrollment,
        current_enrollment.capacity,
        adjecent_block as block,
    from data.${currentTable}_adjacency
        cross join current_enrollment
    where 
        block_of_residence in (select block from status where school = current_enrollment.school)
        and
        adjecent_block in (select block from status where school is NULL)
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

Census block selection based on user selected optimization parameters in DuckDB

The procedure is wrapped in a loop that continues to select blocks until all blocks are assigned, schools run out of space, or adjacent blocks to current assigned areas run out. 

These stopping conditions—while necessary to prevent infinite loops—can create maps where not all blocks are assigned or with a patchwork assignment under specific circumstances. 

Regardless of this limitation, the final maps still need some manual intervention to make sure that the developed boundaries follow geographic or community actual boundaries (rather than computer-generated ones), to ensure that all blocks are assigned to a school, and to account for historical housing policies that could contribute to school segregation.

## Data-Supported Decision Making

These technical systems—geospatial analysis, mathematical modeling, and databases—serve as valuable aids in the complex process of redrawing attendance boundaries. From visualizing and assigning census blocks to estimating school capacity, these technologies offer significant support in the technical work required. However, it is crucial to recognize that these methods remain supportive, not prescriptive.

While geospatial analysis and optimization models can suggest theoretically efficient boundaries, they cannot fully capture the nuanced effects of these changes on a community. The potential for these algorithms to inadvertently perpetuate existing inequalities underscores the importance of human judgment and ethical consideration alongside these systems.

The boundary drawing tools, with their ability to automatically assign blocks based on user-defined parameters, demonstrate the potential for algorithmic streamlining. Yet, the need for manual intervention to address patchwork assignments and ensure alignment between school and community boundaries highlights the limitations of purely technical solutions in redrawing school boundaries.

Ultimately, the technical infrastructure described in this blog post serves to inform and support decision-makers during the process of redrawing school boundaries. These technologies provide the necessary data, analytical capabilities, and fast iteration time to fully explore different scenarios and understand the implications of various boundary configurations. However, the final decisions require human understanding of the community's history, current social dynamics, and equity considerations.

In essence, these technical systems are useful assistants, offering clarity, choice, and efficiency during a complex process. They provide critical context, but the final decisions remain firmly with well-informed decision-makers.

## Technical Tools in Service of Community Needs 

The systems described in this post formed the technical foundation of our boundary redrawing process. By combining DuckDB's analytical power with intuitive visualization tools, we created an environment where decision-makers could rapidly develop and test scenarios and understand their impacts. 

However, as we'll explore in part two of this series, the most sophisticated tools still require human judgment. The true success of our project came not just from the SQL queries and algorithms, but from how these technical capabilities enabled more transparent, data-informed conversations with stakeholders throughout the community. 

In the next post, I'll explore how these tools facilitated those conversations and the social dynamics that ultimately shaped our final boundary decisions.

## Further Readings

- [A Beginner's Guide To Geospatial With DuckDB Spatial And MotherDuck](https://motherduck.com/blog/geospatial-analysis-duckdb/) - A practical introduction to geospatial analysis using DuckDB.
- Monarrez, T. (2023). [School Attendance Boundaries and the Segregation of Public Schools in the United States](https://www.aeaweb.org/articles?id=10.1257/app.20200549). *American Economic Journal: Applied Economics* 15 (3): 210–37. - Research examining how school boundary decisions can perpetuate segregation.
- Richards, M. P. (2014). [The Gerrymandering of School Attendance Zones and the Segregation of Public Schools: A Geospatial Analysis](https://journals.sagepub.com/doi/abs/10.3102/0002831214553652). *American Educational Research Journal*, *51*(6), 1119-1157. - Historical context on how boundary decisions impact school demographics.
- [NCES School Attendance Boundary Survey (SABS)](https://nces.ed.gov/programs/edge/SABS) - A national database of school attendance boundaries maintained by the National Center for Education Statistics.

---

## Key Takeaways — TL;DR

After completing this boundary redrawing project, several important lessons emerged that may benefit others undertaking similar work:

**Data and algorithms need human context.** While our optimization models efficiently assigned census blocks to schools, they couldn't account for historical neighborhood connections, walking routes, or community identities. The most successful boundaries came from blending algorithmic suggestions with local knowledge.

**Flexible, reusable tools accelerate decision-making.** By building our analysis on SQL-based DuckDB rather than point-and-click GIS software, we could rapidly respond to new scenarios and questions as they emerged during board meetings and community forums.

**Census blocks provide an ideal foundation.** Using pre-defined census blocks as our building units saved considerable time and provided a neutral, recognized geographic division that stakeholders could understand and reference.

**Visualization transforms abstract data into meaningful conversation.** Our web tools converted complex geospatial data into intuitive maps that allowed non-technical stakeholders to actively participate in the boundary drawing process.

## Tools and Technologies

**DuckDB** - Open-source analytical database system used for geospatial analysis and census block assignments. Particularly valuable for its SQL interface and spatial extension.

**GDAL** - Geospatial Data Abstraction Library, used for exporting DuckDB tables to GeoJSON format compatible with web mapping tools.

**Leaflet** - JavaScript library that powered our interactive maps, allowing for visualization of boundary changes.

**Census Bureau TIGER/Line Shapefiles** - Source of census block geometries that formed the foundation of our boundary drawing system.

**WebAssembly (WASM)** - Technology that enabled us to run DuckDB directly in the browser for the boundary drawing tool, providing immediate feedback on boundary change impacts.

**GeoJSON** - Data format used to represent geographic features in our mapping applications and data exchange.

**SQL** - Query language used throughout the project to manipulate and analyze geospatial data.
