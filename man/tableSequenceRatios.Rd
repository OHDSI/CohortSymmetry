% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/tableSequenceratios.R
\name{tableSequenceRatios}
\alias{tableSequenceRatios}
\title{A formatted visualization of sequence_symmetry objects.}
\usage{
tableSequenceRatios(
  result,
  header = "marker_cohort_name",
  groupColumn = "cdm_name",
  type = "gt",
  hide = "variable_level"
)
}
\arguments{
\item{result}{A sequence_symmetry object.}

\item{header}{A vector specifying the elements to include in the header.
See visOmopResults package for more information on how to use this parameter.}

\item{groupColumn}{Columns to use as group labels.
See visOmopResults package for more information on how to use this parameter.}

\item{type}{The desired format of the output table.}

\item{hide}{Columns to drop from the output table.}
}
\value{
A formatted version of the sequence_symmetry object.
}
\description{
It provides a formatted table with the contents of the summariseSequenceRatios
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
res <- summariseSequenceRatios(cohort = cdm$joined_cohort)
gtResult <- tableSequenceRatios(res)
CDMConnector::cdmDisconnect(cdm = cdm)
}

}
