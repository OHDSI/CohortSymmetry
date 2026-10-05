# Summarise temporal symmetry

Using generateSequenceCohortSet to obtain temporal symmetry (aggregated
counts) of two cohorts.

## Usage

``` r
summariseTemporalSymmetry(cohort, cohortId = NULL, days = 30)
```

## Arguments

- cohort:

  A cohort table in the cdm.

- cohortId:

  The Ids in the cohort that are to be included in the analyses.

- days:

  Numerical timescale for the x axis of the plot in days (Default is 30
  days, if users want years put 365, days put 1).

## Value

An aggregated table with difference in time (marker - index) and the
relevant counts.

## Examples

``` r
# \donttest{
library(CohortSymmetry)
cdm <- mockCohortSymmetry()
cdm <- generateSequenceCohortSet(cdm = cdm,
                                 name = "joined_cohorts",
                                 indexTable = "cohort_1",
                                 markerTable = "cohort_2")
temporal_symmetry <- summariseTemporalSymmetry(cohort = cdm$joined_cohorts)
#> `days` cast to character.
CDMConnector::cdmDisconnect(cdm)
# }
```
