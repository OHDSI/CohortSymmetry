# Step 2. Obtain the sequence ratios

## Introduction

In this vignette we will explore the functionality and arguments of
[`summariseSequenceRatios()`](https://ohdsi.github.io/CohortSymmetry/reference/summariseSequenceRatios.md)
function, which is used to generate the sequence ratios of the SSA. As
this function uses the output of
[`generateSequenceCohortSet()`](https://ohdsi.github.io/CohortSymmetry/reference/generateSequenceCohortSet.md)
function (explained in detail in the vignette: **Step 1. Generate a
sequence cohort**), we will pick up the explanation from where we left
off in the previous vignette.

Recall that in the previous vignette: Step 1. Generate a sequence
cohort, we’ve generated `cdm$aspirin` and `cdm$acetaminophen` before and
using them we could generate `cdm$intersect` like so:

``` r

# Generate a sequence cohort
cdm <- generateSequenceCohortSet(
  cdm = cdm,
  indexTable = "aspirin",
  markerTable = "acetaminophen",
  name = "intersect",
  combinationWindow = c(0,Inf))
```

## Obtain sequence ratios

One can obtain the crude and adjusted sequence ratios (with its
corresponding confidence intervals) using
[`summariseSequenceRatios()`](https://ohdsi.github.io/CohortSymmetry/reference/summariseSequenceRatios.md)
function:

``` r

summariseSequenceRatios(
  cohort = cdm$intersect
) |> 
  dplyr::glimpse()
#> Rows: 10
#> Columns: 13
#> $ result_id        <int> 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
#> $ cdm_name         <chr> "Synthea", "Synthea", "Synthea", "Synthea", "Synthea"…
#> $ group_name       <chr> "index_cohort_name &&& marker_cohort_name", "index_co…
#> $ group_level      <chr> "aspirin &&& acetaminophen", "aspirin &&& acetaminoph…
#> $ strata_name      <chr> "overall", "overall", "overall", "overall", "overall"…
#> $ strata_level     <chr> "overall", "overall", "overall", "overall", "overall"…
#> $ variable_name    <chr> "index", "index", "marker", "marker", "crude", "adjus…
#> $ variable_level   <chr> "first_pharmac", "first_pharmac", "first_pharmac", "f…
#> $ estimate_name    <chr> "count", "percentage", "count", "percentage", "point_…
#> $ estimate_type    <chr> "integer", "numeric", "integer", "numeric", "numeric"…
#> $ estimate_value   <chr> "1235", "64.4", "682", "35.6", "1.8108504398827", "1.…
#> $ additional_name  <chr> "overall", "overall", "overall", "overall", "overall"…
#> $ additional_level <chr> "overall", "overall", "overall", "overall", "overall"…
```

The obtained output has a summarised result format. In the later
vignette (**Step 3. Visualise results**) we will explore how to
visualise the results in a more intuitive way.

``` r

CDMConnector::cdmDisconnect(cdm = cdm)
```
