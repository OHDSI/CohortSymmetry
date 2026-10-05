# Intersecting the index and marker cohorts prior to calculating Sequence Symmetry Ratios

Join two tables in the CDM (one for index and the other for marker
cohorts) into a new table in the cdm taking into account the maximum
time interval between events. Index and marker cohorts should be
instantiated in advance by the user.

## Usage

``` r
generateSequenceCohortSet(
  cdm,
  indexTable,
  markerTable,
  name,
  indexId = NULL,
  markerId = NULL,
  cohortDateRange = as.Date(c(NA, NA)),
  daysPriorObservation = 365,
  washoutWindow = 365,
  indexMarkerGap = Inf,
  combinationWindow = c(0, 365)
)
```

## Arguments

- cdm:

  A CDM reference.

- indexTable:

  A table in the CDM that the index cohorts should come from.

- markerTable:

  A table in the CDM that the marker cohorts should come from.

- name:

  The name within the cdm that the output is called. Default is
  joined_cohorts.

- indexId:

  Cohort definition IDs in indexTable to be considered for the analysis.
  Change to NULL if all indices are wished to be included.

- markerId:

  Cohort definition IDs in markerTable to be considered for the
  analysis. Change to NULL if all markers are wished to be included.

- cohortDateRange:

  Two dates indicating study period and the sequences that the user
  wants to restrict to.

- daysPriorObservation:

  The minimum amount of prior observation required on both the index and
  marker cohorts per person. Default is 365 days.

- washoutWindow:

  A washout window to be applied on both the index cohort event and
  marker cohort. Default is 365 days.

- indexMarkerGap:

  The maximum allowable gap between the end of the first episode and the
  start of the second episode in a sequence/combination. Default is Inf.

- combinationWindow:

  A constrain to be placed on the gap between two initiations. Default
  c(0,365), meaning the gap should be larger than 0 but less than or
  equal to 365.

## Value

A table within the cdm reference.

## Examples

``` r
# \donttest{
library(CohortSymmetry)
cdm <- mockCohortSymmetry()
cdm <- generateSequenceCohortSet(
  cdm = cdm,
  name = "joined_cohorts",
  indexTable = "cohort_1",
  markerTable = "cohort_2"
)
 cdm$joined_cohorts
#> # A tibble: 11 × 6
#>    cohort_definition_id subject_id cohort_start_date cohort_end_date index_date
#>  *                <int>      <int> <date>            <date>          <date>    
#>  1                    1          3 2009-09-09        2010-01-01      2009-09-09
#>  2                    6          3 2010-01-01        2010-09-30      2010-01-01
#>  3                    3          1 2019-05-25        2020-04-01      2020-04-01
#>  4                    1          1 2020-04-01        2020-12-30      2020-04-01
#>  5                    2          1 2020-04-01        2021-01-01      2020-04-01
#>  6                    8          4 2021-01-01        2021-05-25      2021-01-01
#>  7                    7          1 2020-12-30        2021-01-01      2021-01-01
#>  8                    2          4 2021-05-25        2021-06-01      2021-06-01
#>  9                    3          4 2021-06-01        2022-05-25      2021-06-01
#> 10                    6          2 2022-05-22        2022-05-25      2022-05-22
#> 11                    5          2 2022-05-22        2022-05-31      2022-05-22
#> # ℹ 1 more variable: marker_date <date>
 CDMConnector::cdmDisconnect(cdm = cdm)
# }
```
