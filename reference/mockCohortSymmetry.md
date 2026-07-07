# Creates mock cdm object for testing

Creates a mock cdm with two default synthetic cohorts, one is the index
cohort and the other one is the marker cohort. However the users could
specify them should they wish.

## Usage

``` r
mockCohortSymmetry(
  seed = 1,
  indexCohort = NULL,
  markerCohort = NULL,
  con = NULL,
  schema = "main"
)
```

## Arguments

- seed:

  The seed to be inputted.

- indexCohort:

  The tibble of your index cohort. Default is NULL, which means the
  default indexCohort is being used.

- markerCohort:

  The tibble of your marker cohort. Default is NULL, which means the
  default markerCohort is being used.

- con:

  Connection detail.

- schema:

  Name of your write schema.

## Value

A mock cdm object contains your index and marker cohort

## Examples

``` r
# \donttest{
library(CohortSymmetry)
cdm <- mockCohortSymmetry()
#> Creating a new cdm
#> Uploading table person (5 rows) - [1/11]
#> Uploading table observation_period (5 rows) - [2/11]
#> Uploading table cdm_source (1 rows) - [3/11]
#> Uploading table concept (3361 rows) - [4/11]
#> Uploading table vocabulary (65 rows) - [5/11]
#> Uploading table concept_relationship (117257 rows) - [6/11]
#> Uploading table concept_synonym (3895 rows) - [7/11]
#> Uploading table concept_ancestor (1327 rows) - [8/11]
#> Uploading table drug_strength (45 rows) - [9/11]
#> Uploading table cohort_1 (10 rows) - [10/11]
#> Uploading table cohort_2 (11 rows) - [11/11]
cdm
#> 
#> ── # OMOP CDM reference (duckdb) of mock database ──────────────────────────────
#> • omop tables: cdm_source, concept, concept_ancestor, concept_relationship,
#> concept_synonym, drug_strength, observation_period, person, vocabulary
#> • cohort tables: cohort_1, cohort_2
#> • achilles tables: -
#> • other tables: -
CDMConnector::cdmDisconnect(cdm = cdm)
# }
```
