% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/summariseTemporalSymmetry.R
\name{summariseTemporalSymmetry}
\alias{summariseTemporalSymmetry}
\title{Summarise temporal symmetry}
\usage{
summariseTemporalSymmetry(cohort, cohortId = NULL, timescale = "month")
}
\arguments{
\item{cohort}{A cohort table in the cdm.}

\item{cohortId}{The Ids in the cohort that are to be included in the analyses.}

\item{timescale}{Timescale for the x axis of the plot (month, day, year).}
}
\value{
An aggregated table with difference in time (marker - index) and the relevant
counts.
}
\description{
Using generateSequenceCohortSet to obtain temporal symmetry (aggregated
counts) of two cohorts.
}
\examples{
\donttest{
library(CohortSymmetry)
cdm <- mockCohortSymmetry()
cdm <- generateSequenceCohortSet(cdm = cdm,
                                 name = "joined_cohorts",
                                 indexTable = "cohort_1",
                                 markerTable = "cohort_2")
temporal_symmetry <- summariseTemporalSymmetry(cohort = cdm$joined_cohorts)
CDMConnector::cdmDisconnect(cdm)
}

}
