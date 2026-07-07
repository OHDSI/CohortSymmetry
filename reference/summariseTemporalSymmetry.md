# Summarise temporal symmetry

Using generateSequenceCohortSet to obtain temporal symmetry (aggregated
counts) of two cohorts.

## Usage

``` r
summariseTemporalSymmetry(cohort, cohortId = NULL, timescale = "month")
```

## Arguments

- cohort:

  A cohort table in the cdm.

- cohortId:

  The Ids in the cohort that are to be included in the analyses.

- timescale:

  Timescale for the x axis of the plot (month, day, year).

## Value

An aggregated table with difference in time (marker - index) and the
relevant counts.

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
cdm <- generateSequenceCohortSet(cdm = cdm,
                                 name = "joined_cohorts",
                                 indexTable = "cohort_1",
                                 markerTable = "cohort_2")
#> Warning: restarting interrupted promise evaluation
temporal_symmetry <- summariseTemporalSymmetry(cohort = cdm$joined_cohorts)
CDMConnector::cdmDisconnect(cdm)
# }
```
