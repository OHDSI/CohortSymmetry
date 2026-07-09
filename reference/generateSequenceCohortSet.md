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
  daysPriorObservation = 0,
  washoutWindow = 0,
  indexMarkerGap = Inf,
  combinationWindow = c(0, 365),
  movingAverageRestriction = 548
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
  marker cohorts per person.

- washoutWindow:

  A washout window to be applied on both the index cohort event and
  marker cohort.

- indexMarkerGap:

  The maximum allowable gap between the end of the first episode and the
  start of the second episode in a sequence/combination.

- combinationWindow:

  A constrain to be placed on the gap between two initiations. Default
  c(0,365), meaning the gap should be larger than 0 but less than or
  equal to 365.

- movingAverageRestriction:

  The moving window when calculating nSR, default is 548.

## Value

A table within the cdm reference.

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
cdm <- generateSequenceCohortSet(
  cdm = cdm,
  name = "joined_cohorts",
  indexTable = "cohort_1",
  markerTable = "cohort_2"
)
#> Warning: restarting interrupted promise evaluation
 cdm$joined_cohorts
#> # A query:  ?? x 6
#> # Database: DuckDB 1.5.4 [unknown@Linux 6.17.0-1018-azure:R 4.6.1/:memory:]
#>    cohort_definition_id subject_id cohort_start_date cohort_end_date index_date
#>                   <int>      <int> <date>            <date>          <date>    
#>  1                    3          5 2019-08-01        2020-02-29      2019-08-01
#>  2                    3          1 2019-05-25        2020-04-01      2020-04-01
#>  3                    2          1 2020-04-01        2021-01-01      2020-04-01
#>  4                    1          1 2020-04-01        2020-12-30      2020-04-01
#>  5                    8          4 2021-01-01        2021-05-25      2021-01-01
#>  6                    5          2 2022-05-22        2022-05-31      2022-05-22
#>  7                    6          3 2010-01-01        2010-09-30      2010-01-01
#>  8                    6          2 2022-05-22        2022-05-25      2022-05-22
#>  9                    2          5 2019-08-01        2020-05-25      2019-08-01
#> 10                    9          5 2019-04-07        2020-02-29      2019-04-07
#> 11                    3          4 2021-06-01        2022-05-25      2021-06-01
#> 12                    7          1 2020-12-30        2021-01-01      2021-01-01
#> 13                    2          4 2021-05-25        2021-06-01      2021-06-01
#> 14                    1          3 2009-09-09        2010-01-01      2009-09-09
#> # ℹ 1 more variable: marker_date <date>
 CDMConnector::cdmDisconnect(cdm = cdm)
# }
```
