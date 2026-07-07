# Sequence ratio calculations

Using generateSequenceCohortSet to obtain sequence ratios for the
desired outcomes.

## Usage

``` r
summariseSequenceRatios(cohort, cohortId = NULL, confidenceInterval = 95)
```

## Arguments

- cohort:

  A cohort table in the cdm.

- cohortId:

  The Ids in the cohort that are to be included in the analyses.

- confidenceInterval:

  Default is 95, indicating the central 95% confidence interval.

## Value

A local table with all the analyses.

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
pssa_result <- summariseSequenceRatios(cohort = cdm$joined_cohorts)
#> Warning: For at least some combinations, index is always before marker or marker always
#> before index
#> -- 5 combinations of 8 had index always before marker
#> -- 5 combinations of 8 had marker always before index
pssa_result
#> # A tibble: 80 × 13
#>    result_id cdm_name      group_name       group_level strata_name strata_level
#>        <int> <chr>         <chr>            <chr>       <chr>       <chr>       
#>  1         1 mock database index_cohort_na… cohort_1 &… overall     overall     
#>  2         1 mock database index_cohort_na… cohort_1 &… overall     overall     
#>  3         1 mock database index_cohort_na… cohort_1 &… overall     overall     
#>  4         1 mock database index_cohort_na… cohort_1 &… overall     overall     
#>  5         1 mock database index_cohort_na… cohort_1 &… overall     overall     
#>  6         1 mock database index_cohort_na… cohort_1 &… overall     overall     
#>  7         1 mock database index_cohort_na… cohort_1 &… overall     overall     
#>  8         1 mock database index_cohort_na… cohort_1 &… overall     overall     
#>  9         1 mock database index_cohort_na… cohort_1 &… overall     overall     
#> 10         1 mock database index_cohort_na… cohort_1 &… overall     overall     
#> # ℹ 70 more rows
#> # ℹ 7 more variables: variable_name <chr>, variable_level <chr>,
#> #   estimate_name <chr>, estimate_type <chr>, estimate_value <chr>,
#> #   additional_name <chr>, additional_level <chr>
CDMConnector::cdmDisconnect(cdm)
# }
```
