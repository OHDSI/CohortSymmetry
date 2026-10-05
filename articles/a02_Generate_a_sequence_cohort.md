# Step 1. Generate a sequence cohort

## Introduction

In this vignette we will explore the functionalities of
`generateSequenceCohort()`.

### Create a cdm object

The CohortSymmetry package is designed to work with data mapped to OMOP
CDM, so the first step is to create a mock database using the [omock
package](https://ohdsi.github.io/omock/). We will use the Eunomia
dataset within omock for the subsequent examples. There are other
synthetic datasets within omock that users can also use to get familiar
with CohortSymmetry before applying to their own database. See the
[omock vignette](https://ohdsi.github.io/omock/) for more details.

``` r

library(omock)
library(CohortSymmetry)

cdm <- mockCdmFromDataset(datasetName = "GiBleed")
```

### Instantiate two cohorts in the cdm reference

CohortSymmetry package requires that the cdm object contains two cohort
tables: the index cohort and the marker cohort. There are a lot of
different ways to create these cohorts, and it will depend on what the
index cohort and marker cohort represent. If one wants to generate two
drugs cohorts in cdm, we recommend using [CohortConstructor R
package](https://ohdsi.github.io/CohortConstructor/) however, the
[DrugUtilisation R
package](https://darwin-eu.github.io/DrugUtilisation/) can also be used.
However a user will need to specify the gap eras for each of the cohorts
i.e. a gap era set to 30 would collapse episodes together if they are
within 30 days of each other for example please see the individual
packages on how to implement this if required. Here is the example code
for CohortConstructor:

``` r

library(dplyr)
library(CodelistGenerator)
library(CohortConstructor)

aspirin_codelist <- CodelistGenerator::getDrugIngredientCodes(
  cdm = cdm,
  name = "aspirin",
  nameStyle = "{concept_name}"
)

cdm[["aspirin"]] <- CohortConstructor::conceptCohort(
  cdm = cdm,
  conceptSet = aspirin_codelist,
  exit = "event_end_date",
  name = "aspirin")


amoxicillin_codelist <- CodelistGenerator::getDrugIngredientCodes(
  cdm = cdm,
  name = "amoxicillin",
  nameStyle = "{concept_name}"
)

cdm[["amoxicillin"]] <- CohortConstructor::conceptCohort(
  cdm = cdm,
  conceptSet = amoxicillin_codelist,
  exit = "event_end_date",
  name = "amoxicillin")
```

Here is some example code for DrugUtilisation:

``` r

library(DrugUtilisation)

cdm <- DrugUtilisation::generateIngredientCohortSet(
  cdm = cdm, 
  name = "aspirin",
  ingredient = "aspirin")

cdm <- DrugUtilisation::generateIngredientCohortSet(
  cdm = cdm,
  name = "amoxicillin",
  ingredient = "amoxicillin")
```

## Generate a sequence cohort

In order to initiate the calculations, the two cohorts tables need to be
intersected using
[`generateSequenceCohortSet()`](https://ohdsi.github.io/CohortSymmetry/reference/generateSequenceCohortSet.md).
This process will output all the individuals who appear on both tables
subject to different parameters. Each parameter corresponds to a
specific requirement. The parameters for this function include
`cohortDateRange`, `daysPriorObservation`, `washoutWindow`,
`indexMarkerGap` and `combinationWindow`. Let’s go through examples to
see how each parameter works.

### No specific requirements

Let’s study the simplest case where no requirements are imposed. See
figure below to see an example of an analysis containing six different
participants.

![](1-NoRestrictions.png)

See that only the first event/episode (for both the index and the
marker) is included in the analysis. As there is no restriction criteria
and all the individuals have an episode in the index and the marker
cohort, all the subjects are included in the analysis. We can get a
sequence cohort without including any particular requirement like so:

``` r

cdm <- generateSequenceCohortSet(
  cdm = cdm,
  indexTable = "aspirin",
  markerTable = "amoxicillin",
  name = "intersect",
  cohortDateRange = as.Date(c(NA, NA)), 
  daysPriorObservation = 0, 
  washoutWindow = 0,
  indexMarkerGap = Inf, 
  combinationWindow = c(0,Inf)) 

cdm$intersect |> 
  dplyr::glimpse()
#> Rows: 1,510
#> Columns: 6
#> $ cohort_definition_id <int> 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1…
#> $ subject_id           <int> 4960, 3342, 2088, 5328, 4547, 5295, 4680, 4739, 4…
#> $ cohort_start_date    <date> 1909-06-16, 1910-02-02, 1910-02-14, 1910-02-26, …
#> $ cohort_end_date      <date> 1943-05-05, 1912-05-27, 1914-01-20, 1921-10-31, …
#> $ index_date           <date> 1909-06-16, 1910-02-02, 1910-02-14, 1910-02-26, …
#> $ marker_date          <date> 1943-05-05, 1912-05-27, 1914-01-20, 1921-10-31, …
```

#### Important Observations

See that the generated table has the format of an OMOP CDM cohort, but
it also includes two additional columns: the `index_date` and the
`marker_date`, which are the `cohort_start_date` of the index and marker
episode respectively. The cohort_start_date and the `cohort_end_date`
are defined as:

- **`cohort_start_date`**: earliest `cohort_start_date` between the
  index and the marker events.
- **`cohort_end_date`**: latest `cohort_start_date` between the index
  and the marker events.

The `cohort_definition_id` in the output is associated with the
`cohort_definition_id}` of the index table (`indexId`) and the
`cohort_definition_id` of the marker table (`markerId`). To see the
correspondence, one could do the following:

``` r

attr(cdm$intersect, "cohort_set")
#> # A tibble: 1 × 13
#>   cohort_definition_id cohort_name     index_id index_name marker_id marker_name
#> *                <int> <chr>              <int> <chr>          <int> <chr>      
#> 1                    1 index_aspirin_…        1 aspirin            1 amoxicillin
#> # ℹ 7 more variables: cohort_date_range <chr>, days_prior_observation <chr>,
#> #   washout_window <chr>, index_marker_gap <chr>, combination_window <chr>,
#> #   moving_average_restriction <chr>, nsr <dbl>
```

The user may also wish to subset the index table and marker table based
on their cohort_definition_id using `indexId` and `markerId`
respectively. For example, the following code only includes
`cohort_definidtion_id` $`= 1`$ from both the index and the marker
table.

``` r

cdm <- generateSequenceCohortSet(
  cdm = cdm,
  indexTable = "aspirin",
  markerTable = "amoxicillin",
  name = "intersect",
  cohortDateRange = as.Date(c(NA, NA)),
  indexId = 1,
  markerId = 1,
  daysPriorObservation = 0,
  washoutWindow = 0,
  indexMarkerGap = Inf,
  combinationWindow = c(0,Inf))
```

### Specified study period

We can restrict the study period of the analysis to only include
episodes or events happening during a specific period of time. See
figure below to see an example of an analysis containing six different
participants.

![](2-studyPeriod.png)

Notice that, by imposing a restriction on study period, some of the
participants might be excluded. For example, participant 4 is excluded
because the only index episode is outside of the study period whereas
participant 6 is included because he/she does have an index episode
within the study period.

The study period can be restricted using the `cohortDateRange` argument,
which is defined as:

`cohortDateRange = c(start_of_the_study_period, end_of_the_study_period)`

See an example of the usage below, where we have restricted the
`cohortDateRange` within 01/01/1950 until 01/01/1969.

``` r

cdm <- generateSequenceCohortSet(
  cdm = cdm,
  indexTable = "aspirin",
  markerTable = "amoxicillin",
  name = "intersect_study_period",
  daysPriorObservation = 0,
  washoutWindow = 0,
  indexMarkerGap = Inf,
  cohortDateRange = as.Date(c("1950-01-01","1969-01-01")))
```

### Specified study period and prior history requirement

We can also specify the minimum prior history that an individual has to
have before the start of the first event in the sequence. This just asks
“Does the person have enough prior observation history based on which
event occurred first?” It applies this on the sequence so this can be
applied to either index or marker event depending on which is first.
Individuals with not enough prior history will be excluded. See the
figure below, imagine the prior observation history is set to be 31
days, then participant 5 would be excluded because the first event
happening within the study period does not have more than (or equal to)
31 days of prior history:

![](3-PriorObservation.png)

The number of days of prior history required can be implemented using
the argument `daysPriorObservation`. See an example below:

``` r

cdm <- generateSequenceCohortSet(
  cdm = cdm,
  indexTable = "aspirin",
  markerTable = "amoxicillin",
  name = "intersect_prior_obs",
  cohortDateRange = as.Date(c("1950-01-01","1969-01-01")),
  daysPriorObservation = 365,
  washoutWindow = 0,
  indexMarkerGap = Inf)
```

### Specified study period, prior history requirement and washout period

We can also specify the minimum washout period required for an event or
episode to be included to restrict to incident users. In the following
figure, we exclude participant 6 as another episode took place within
the washout period. Washout period is applied to both the index and
marker respectively.

![](4-washoutPeriod.png)

This functionality can be implemented using the `washoutWindow`
argument. See an example below:

``` r

cdm <- generateSequenceCohortSet(
  cdm = cdm,
  indexTable = "aspirin",
  markerTable = "amoxicillin",
  name = "intersect_washout",
  cohortDateRange = as.Date(c("1950-01-01","1969-01-01")),
  daysPriorObservation = 365,
  washoutWindow = 365,
  indexMarkerGap = Inf)
```

### Specified study period, prior history requirement and combination window

We define the combination window as the minimum and the maximum days
between the start of the first event (either if is the index or the
marker) and the start of the next event. So a index and marker must be
within so many days of one another. In other words:

$`x =`$`second_episode(start_date)` $`-`$`first_episode(start_date)`;

`combinationWindow[1]` $`< x \leq`$`combinationWindow[2]`

See in the figure below an example, where we define
`combinationWindow = c(0,20)`. This means that the gap between the start
date of the second episode and the start of the first episode should be
larger than 0 and less or equal than 20. As participant 2 and 3 do not
fulfill this condition, they are excluded from the analysis.

![](5-combinationWindow_numbers.png)

In the
[`generateSequenceCohortSet()`](https://ohdsi.github.io/CohortSymmetry/reference/generateSequenceCohortSet.md)
function, this is implemented using the `combinationWindow` argument.
Notice that in the previous examples, as we did not want any combination
window requirement, we have set this argument to
`combinationWindow = c(0,Inf)`, but the default is
`combinationWindow = c(0, 365)`. In the following example, we explore
subject_id 80 and 187 to see the functionality of this argument. When
using no restriction for the combination window, both are included in
the **intersect_changed_cw** cohort:

``` r

cdm <- generateSequenceCohortSet(
  cdm = cdm,
  indexTable = "aspirin",
  markerTable = "amoxicillin",
  name = "intersect_changed_cw",
  cohortDateRange = as.Date(c("1950-01-01","1969-01-01")),
  daysPriorObservation = 365,
  washoutWindow = 365,
  indexMarkerGap = Inf,
  combinationWindow = c(0, Inf))

 cdm$intersect_changed_cw |>
   dplyr::filter(subject_id %in% c(80,187)) |>
   dplyr::mutate(combinationWindow = pmax(index_date, marker_date) - pmin(index_date, marker_date))
```

Furthermore, for the `combinationWindow` argument, a user can also set
the minimum window so `combinationWindow = c(7,365)` for example. This
allows for a blackout window/period to be applied as described in
[Hendrix et al. (2024)](https://pubmed.ncbi.nlm.nih.gov/38212730/). So
in other words if a user knows that the index and marker cannot occur
within 7 days of each other this can be set and by setting this it would
exclude sequences in which two events occur 7 days or fewer days apart,
while retaining sequences occuring 8-365 days apart.

### Specified study period, prior history requirement and index marker gap

We define the index-marker gap to refer to the maximum number of days
between the start of the second episode and the end of the first
episode. That means:

$`x =`$`second_episode(cohort_start_date)`
$`-`$`first_episode(cohort_end_date)`;

x $`\leq`$`indexMarkerGap`

See an example below, where all participants with an index-marker gap
higher than 30 days are excluded from the analysis and in this case this
is no one as participants 2-6 have already been excluded due to not
fufilling previous criteria and participant 1 fufills the index-marker
gap:

![](6-indexGap.png)

The default for `indexMarkerGap = Inf` meaning that no restriction is
imposed on the interval between the end of the first event and start of
the second. This is in line with established SSA methodology, as SSA
evaluates asymmetry in sequences rather than duration of concurrent
exposure.

However, this setting can be updated to implement a continued exposure
interval (CEI) used in prescription-cascade analyses. By setting this
parameter it specifies the maximum permitted interval between the end of
the first event and start of the second. For example [Hendrix et
al. (2024)](https://pubmed.ncbi.nlm.nih.gov/38212730/) applied a 4 month
CEI to account for uncertainty in the estimated end of medication
exposure. Analogous to this a`indexMarkerGap = 120` would be used for
this argument.

An example of the `indexGap` argument to impose this restriction, for
example is shown below:

``` r

cdm <- generateSequenceCohortSet(
  cdm = cdm,
  indexTable = "aspirin",
  markerTable = "amoxicillin",
  name = "intersect_",
  cohortDateRange = as.Date(c("1950-01-01","1969-01-01")),
  daysPriorObservation = 365,
  washoutWindow = 365,
  indexMarkerGap = 7)
```
