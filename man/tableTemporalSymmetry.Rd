% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/tableTemporalSymmetry.R
\name{tableTemporalSymmetry}
\alias{tableTemporalSymmetry}
\title{A formatted visualization of temporal_symmetry objects.}
\usage{
tableTemporalSymmetry(
  result,
  header = "variable_level",
  groupColumn = c("cdm_name", "index_name"),
  type = "gt",
  hide = "variable_name"
)
}
\arguments{
\item{result}{A temporal_symmetry object.}

\item{header}{A vector specifying the elements to include in the header.
See visOmopResults package for more information on how to use this parameter.}

\item{groupColumn}{Columns to use as group labels.
See visOmopResults package for more information on how to use this parameter.}

\item{type}{The desired format of the output table.}

\item{hide}{Columns to drop from the output table.}
}
\value{
A formatted version of the temporal_symmetry object.
}
\description{
It provides a formatted table with the contents of the summariseTemporalSymmetry
output.
}
\examples{
\donttest{
library(CohortSymmetry)
cdm <- mockCohortSymmetry()
cdm <- generateSequenceCohortSet(cdm = cdm,
                                 indexTable = "cohort_1",
                                 markerTable = "cohort_2",
                                 name = "joined_cohort")
res <- summariseTemporalSymmetry(cohort = cdm$joined_cohort)
gtResult <- tableTemporalSymmetry(result = res)
CDMConnector::cdmDisconnect(cdm = cdm)
}

}
