# Creates mock cdm object for testing

Creates a mock cdm with two default synthetic cohorts, one is the index
cohort and the other one is the marker cohort. However the users could
specify them should they wish.

## Usage

``` r
mockCohortSymmetry(seed = 1, indexCohort = NULL, markerCohort = NULL)
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

## Value

A mock cdm object contains your index and marker cohort

## Examples

``` r
# \donttest{
library(CohortSymmetry)
cdm <- mockCohortSymmetry()
cdm
#> 
#> ── # OMOP CDM reference (local) of mock database ───────────────────────────────
#> • omop tables: cdm_source, concept, concept_ancestor, concept_relationship,
#> concept_synonym, drug_strength, observation_period, person, vocabulary
#> • cohort tables: cohort_1, cohort_2
#> • achilles tables: -
#> • other tables: -
CDMConnector::cdmDisconnect(cdm = cdm)
# }
```
