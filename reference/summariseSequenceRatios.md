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
cdm <- generateSequenceCohortSet(cdm = cdm,
                                 name = "joined_cohorts",
                                 indexTable = "cohort_1",
                                 markerTable = "cohort_2")
pssa_result <- summariseSequenceRatios(cohort = cdm$joined_cohorts)
#> Warning: For at least some combinations, index is always before marker or marker always
#> before index
#> -- 4 combinations of 7 had index always before marker
#> -- 4 combinations of 7 had marker always before index
pssa_result
#> # A tibble: 77 × 13
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
#> # ℹ 67 more rows
#> # ℹ 7 more variables: variable_name <chr>, variable_level <chr>,
#> #   estimate_name <chr>, estimate_type <chr>, estimate_value <chr>,
#> #   additional_name <chr>, additional_level <chr>
CDMConnector::cdmDisconnect(cdm)
# }
```
