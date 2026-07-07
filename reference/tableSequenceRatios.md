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

- hide:

  Columns to drop from the output table.

## Value

A formatted version of the sequence_symmetry object.

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
                                 indexTable = "cohort_1",
                                 markerTable = "cohort_2",
                                 name = "joined_cohort")
#> Warning: restarting interrupted promise evaluation
res <- summariseSequenceRatios(cohort = cdm$joined_cohort)
#> Warning: For at least some combinations, index is always before marker or marker always
#> before index
#> -- 5 combinations of 8 had index always before marker
#> -- 5 combinations of 8 had marker always before index
gtResult <- tableSequenceRatios(res)
CDMConnector::cdmDisconnect(cdm = cdm)
# }
```
