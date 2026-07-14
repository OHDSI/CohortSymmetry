#' A formatted visualization of sequence_symmetry objects.
#'
#' @description
#' It provides a formatted table with the contents of the summariseSequenceRatios
#' output.
#'
#' @param result A sequence_symmetry object.
#' @param header A vector specifying the elements to include in the header.
#' See visOmopResults package for more information on how to use this parameter.
#' @param groupColumn Columns to use as group labels.
#' See visOmopResults package for more information on how to use this parameter.
#' @param type The desired format of the output table.
#' @param hide Columns to drop from the output table.
#' @param style Style used for the table.
#'
#' @return A formatted version of the sequence_symmetry object.
#'
#' @export
#' @examples
#' \donttest{
#' library(CohortSymmetry)
#' cdm <- mockCohortSymmetry()
#' cdm <- generateSequenceCohortSet(cdm = cdm,
#'                                  indexTable = "cohort_1",
#'                                  markerTable = "cohort_2",
#'                                  name = "joined_cohort")
#' res <- summariseSequenceRatios(cohort = cdm$joined_cohort)
#' flexResult <- tableSequenceRatios(res)
#' CDMConnector::cdmDisconnect(cdm = cdm)
#' }
#'
tableSequenceRatios <- function(result,
                                header = "marker_cohort_name",
                                groupColumn = "cdm_name",
                                type = "flextable",
                                style = "default",
                                hide = "variable_level") {

  rlang::check_installed("visOmopResults")
  rlang::check_installed("flextable")
  rlang::check_installed("gt")

  # validate checks
  result <- omopgenerics::validateResultArgument(result)

 # check settings
  result <- result |>
    omopgenerics::filterSettings(
      .data$result_type == "sequence_ratios"
    )

  if (nrow(result) == 0) {
    cli::cli_warn("`result` object does not contain any `result_type == 'sequence_ratios'` information.")
    return(emptyResultTable(type))
  }


  ci <- omopgenerics::settings(result)$confidence_interval
  ci <- unique(ci[!is.na(ci)])[1]

  if (is.na(ci)) {
    ci <- 95
  }


  estimate_name <- c(
    "<count> (<percentage>%)",
    "<point_estimate> [<lower_CI> - <upper_CI>]"
  )

  names(estimate_name) <- c(
    "N (%)",
    sprintf("SR [CI %s%%]", ci)
  )

  # format table
  tab <- visOmopResults::visOmopTable(
    result = result,
    estimateName = estimate_name,
    header = header,
    groupColumn = groupColumn,
    type = type,
    hide = hide,
    style = style
  )
}
