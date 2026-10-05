# A formatted visualization of temporal_symmetry objects.

It provides a formatted table with the contents of the
summariseTemporalSymmetry output.

## Usage

``` r
tableTemporalSymmetry(
  result,
  header = "variable_level",
  groupColumn = c("cdm_name", "index_name"),
  type = "gt",
  style = "default",
  hide = "variable_name"
)
```

## Arguments

- result:

  A temporal_symmetry object.

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

A formatted version of the temporal_symmetry object.

## Examples

``` r
# \donttest{
library(CohortSymmetry)
cdm <- mockCohortSymmetry()
cdm <- generateSequenceCohortSet(cdm = cdm,
                                 indexTable = "cohort_1",
                                 markerTable = "cohort_2",
                                 name = "joined_cohort")
res <- summariseTemporalSymmetry(cohort = cdm$joined_cohort)
#> `days` cast to character.
gtResult <- tableTemporalSymmetry(result = res)
CDMConnector::cdmDisconnect(cdm = cdm)
# }
```
