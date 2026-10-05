# A plot for the temporal symmetry of cohorts.

It provides a ggplot of the temporal symmetry of two or more cohorts.

## Usage

``` r
plotTemporalSymmetry(
  result,
  plotTitle = NULL,
  labs = c("Time (days)", "Individuals (N)"),
  xlim = c(-365, 365),
  colours = c("blue", "red"),
  scales = "free"
)
```

## Arguments

- result:

  Table output from summariseTemporalSymmetry.

- plotTitle:

  Title of the plot, if NULL no title will be plotted.

- labs:

  Axis labels for the plot.

- xlim:

  Limits for the x axis of the plot.

- colours:

  Colours for both parts of the plot, pre- and post- time 0.

- scales:

  Whether to set free y scales for the facet wrap when there are
  multiple plots (i.e. each plot has its own scaled y axis) or set them
  equal for all. Only accepts "free" for the former and "fixed" for the
  latter.

## Value

A plot for the temporal symmetry of cohorts.

## Examples

``` r
# \donttest{
library(CohortSymmetry)
cdm <- mockCohortSymmetry()
cdm <- generateSequenceCohortSet(cdm = cdm,
                                 indexTable = "cohort_1",
                                 markerTable = "cohort_2",
                                 name = "joined_cohort")
temporal_symmetry <- summariseTemporalSymmetry(cohort = cdm$joined_cohort)
#> `days` cast to character.
plotTemporalSymmetry(result = temporal_symmetry)

CDMConnector::cdmDisconnect(cdm = cdm)
# }
```
