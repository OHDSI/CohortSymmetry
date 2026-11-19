# CohortSymmetry

# CohortSymmetry 0.4.0

## Breaking changes

- Renamed `generateSequenceCohortSet()` to `sequenceCohort()` and updated the associated argument names.
- Removed `movingAverageRestriction` as a user-facing argument in `sequenceCohort()`. It is now set internally to the upper bound of `combinationWindow`.
- `sequenceCohort()` now returns a cohort table instead of a CDM reference. Users should assign the returned cohort table
  to their CDM reference using `cdm$cohort_name <- sequenceCohort(...)`.
- Changed the default values of `sequencePriorObservation` and `indexMarkerWashout` in `sequenceCohort()` from 0 to 365 days. These changes introduce a minimum one-year prior observation requirement and a one-year washout period by default, which may affect cohort inclusion and subsequent sequence symmetry estimates
- Replaced the categorical time interval argument ("days", "months", "year") with a numeric days argument in summariseTemporalSymmetry() and plotTemporalSymmetry().


### Improvements

- Updated compatibility with the latest version of `visOmopResults`.
- Added support for the `style` argument in plotting and table functions.
- Updated documentation, tests, and vignettes to reflect changes to the package interface.
- Added GitHub Actions badges for test status and code coverage.
- Corrected typos in the README.
- Moved CDMConnector from Imports to Suggests to reduce required dependencies.
- Replaced CDMConnector date difference functions with equivalent functions from clock.


### Bug fixes

- Fixed an issue in tableSequenceRatio() where the incorrect confidence interval value was used.

# CohortSymmetry 0.3.1

- Added a `NEWS.md` file to track changes to the package.

# CohortSymmetry 0.3.0

- Current version on CRAN.
