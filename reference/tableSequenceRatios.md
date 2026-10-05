# A formatted visualization of sequence_symmetry objects.

It provides a formatted table with the contents of the
summariseSequenceRatios output.

## Usage

``` r
tableSequenceRatios(
  result,
  header = "marker_cohort_name",
  groupColumn = "cdm_name",
  type = "gt",
  style = "default",
  hide = "variable_level"
)
```

## Arguments

- result:

  A sequence_symmetry object.

- header:

  A vector specifying the elements to include in the header. See
  visOmopResults package for more information on how to use this
  parameter.

- groupColumn:

  Columns to use as group labels. See visOmopResults package for more
  information on how to use this parameter.

- type:

  The desired format of the output table.

- style:

  Style used for the table.

- hide:

  Columns to drop from the output table.

## Value

A formatted version of the sequence_symmetry object.

## Examples

``` r
# \donttest{
library(CohortSymmetry)
cdm <- mockCohortSymmetry()
cdm <- generateSequenceCohortSet(cdm = cdm,
                                 indexTable = "cohort_1",
                                 markerTable = "cohort_2",
                                 name = "joined_cohort")
res <- summariseSequenceRatios(cohort = cdm$joined_cohort)
#> Warning: For at least some combinations, index is always before marker or marker always
#> before index
#> -- 4 combinations of 7 had index always before marker
#> -- 4 combinations of 7 had marker always before index
gtResult <- tableSequenceRatios(res)
CDMConnector::cdmDisconnect(cdm = cdm)
# }
```
