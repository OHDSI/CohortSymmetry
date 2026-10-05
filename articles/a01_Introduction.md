# Introduction to CohortSymmetry

CohortSymmetry provides tools to perform Sequence Symmetry Analysis
(SSA). Before using the package, it is highly recommended that this
method is tested beforehand against well-known positive and negative
controls. The details of SSA and the relevant controls could be found
using Pratt et al (2015).

The functions you will interact with are:

1.  [`generateSequenceCohortSet()`](https://ohdsi.github.io/CohortSymmetry/reference/generateSequenceCohortSet.md):
    this function will create a cohort with individuals present in both
    (the index and the marker) cohorts.

2.  [`summariseSequenceRatios()`](https://ohdsi.github.io/CohortSymmetry/reference/summariseSequenceRatios.md):
    this function will calculate sequence ratios.

3.  [`tableSequenceRatios()`](https://ohdsi.github.io/CohortSymmetry/reference/tableSequenceRatios.md)
    and
    [`plotSequenceRatios()`](https://ohdsi.github.io/CohortSymmetry/reference/plotSequenceRatios.md):
    these functions will help us to visualise the sequence ratio
    results.

4.  [`summariseTemporalSymmetry()`](https://ohdsi.github.io/CohortSymmetry/reference/summariseTemporalSymmetry.md):
    this function will produce aggregated results based on the time
    difference between two cohort start dates.

5.  [`plotTemporalSymmetry()`](https://ohdsi.github.io/CohortSymmetry/reference/plotTemporalSymmetry.md):
    this function will help us to visualise the results from
    summariseTemporalSymmetry().

Below, you will find an example analysis that offers a brief and
comprehensive overview of the package’s functionalities. More context
and further examples for each of these functions are provided in later
vignettes.

First, let’s load the relevant libraries.

``` r

library(omock)
library(CohortSymmetry)
library(visOmopResults)
library(dplyr)
```

The CohortSymmetry package works with data mapped to the OMOP CDM.
Hence, the initial step involves connecting to a database which is user
and database specific. As an example, we will be using omock package
which can call various synthetic databases. We will use the GIBleed data
to create two cohorts: the **index_cohort** and the **marker_cohort**.

``` r


cdm <- mockCdmFromDataset(datasetName = "GiBleed")

cdm <- DrugUtilisation::generateIngredientCohortSet(
  cdm = cdm, 
  name = "index",
  ingredient = "aspirin")

cdm <- DrugUtilisation::generateIngredientCohortSet(
  cdm = cdm,
  name = "marker",
  ingredient = c("amoxicillin"))
```

Once we have our data and created the index and marker cohorts, we can
use the
[`generateSequenceCohortSet()`](https://ohdsi.github.io/CohortSymmetry/reference/generateSequenceCohortSet.md)
function to find the intersection of the two cohorts. This function will
provide us with the individuals who appear in both cohorts, which will
be named **intersect** - another cohort in the cdm reference.

``` r

cdm <- generateSequenceCohortSet(
  cdm = cdm,
  indexTable = "index",
  markerTable = "marker",
  name = "intersect",
  combinationWindow = c(0, 365)
)
```

See below that the generated cohort follows the format of an OMOP CDM
cohort with the addition of two extra columns: *index_date* and
*marker_date*. These columns correspond to the *cohort_start_date* in
the **index_cohort** and the **marker_cohort**, respectively.

``` r

cdm$intersect |> 
  dplyr::glimpse()
#> Rows: 72
#> Columns: 6
#> $ cohort_definition_id <int> 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1…
#> $ subject_id           <int> 1536, 1340, 2801, 4121, 4867, 1054, 2813, 331, 34…
#> $ cohort_start_date    <date> 1912-08-25, 1912-10-22, 1923-06-17, 1925-09-28, …
#> $ cohort_end_date      <date> 1913-01-27, 1912-12-29, 1923-11-09, 1925-11-18, …
#> $ index_date           <date> 1912-08-25, 1912-10-22, 1923-11-09, 1925-11-18, …
#> $ marker_date          <date> 1913-01-27, 1912-12-29, 1923-06-17, 1925-09-28, …
```

Once we have the intersect cohort, you are able to explore the temporal
symmetry by using `summariseTemporalSymmetry`, `tableTemporalSymmetry`,
and
[`plotTemporalSymmetry()`](https://ohdsi.github.io/CohortSymmetry/reference/plotTemporalSymmetry.md):

``` r

temporal_symmetry <- summariseTemporalSymmetry(
  cohort = cdm$intersect, 
  days = 30)
```

The result can be viewed using table and plot functions.

``` r

tableTemporalSymmetry(result = temporal_symmetry)
```

[TABLE]

``` r

plotTemporalSymmetry(result = temporal_symmetry)
```

![](a01_Introduction_files/figure-html/unnamed-chunk-8-1.png)

Next, we will use the
[`summariseSequenceRatios()`](https://ohdsi.github.io/CohortSymmetry/reference/summariseSequenceRatios.md)
function to get the crude sequence ratios, adjusted sequence ratios, and
the corresponding confidence intervals.

``` r

sequence_ratio <- summariseSequenceRatios(cohort = cdm$intersect)
```

Finally, we can visualise the results using
[`tableSequenceRatios()`](https://ohdsi.github.io/CohortSymmetry/reference/tableSequenceRatios.md):

``` r

tableSequenceRatios(result = sequence_ratio)
```

[TABLE]

Or create a plot with the adjusted sequence ratios:

``` r

plotSequenceRatios(result = sequence_ratio)
```

![](a01_Introduction_files/figure-html/unnamed-chunk-11-1.png)

## As a diagram

Diagrammatically, the work flow using CohortSymmetry resembles the
following flow chat:

![](workflow.png)
