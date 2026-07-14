#' A plot for the sequence ratios.
#'
#' @description
#' It provides a ggplot of the sequence ratios of index and marker cohorts.
#'
#' @param result Table output from summariseSequenceRatios.
#' @param onlyASR If set to be TRUE then only adjusted SR will be plotted.
#' Otherwise if it is set to be FALSE then both adjusted and crude SR will be plotted.
#' @param plotTitle Title of the plot, if NULL no title will be included in the plot.
#' @param labs Axis labels for the plot.
#' @param colours Colours for sequence ratio.
#' @param facet The variable to facet by.
#' @param style Style used for the plot. Passed to `visOmopResults::themeVisOmop()`.
#'
#' @return A plot for the sequence ratios of index and marker cohorts.
#'
#' @export
#'
#' @examples
#' \donttest{
#' library(CohortSymmetry)
#' cdm <- mockCohortSymmetry()
#' cdm <- generateSequenceCohortSet(cdm = cdm,
#'                                  indexTable = "cohort_1",
#'                                  markerTable = "cohort_2",
#'                                  name = "joined_cohort")
#' sequence_ratio <- summariseSequenceRatios(cohort = cdm$joined_cohort)
#' plotSequenceRatios(result = sequence_ratio)
#' CDMConnector::cdmDisconnect(cdm = cdm)
#' }


plotSequenceRatios <- function(result,
                               onlyASR = FALSE,
                               plotTitle = NULL,
                               style = "default",
                               labs = c("Sequence Ratio", "Index Marker Pair"),
                               colours = NULL,
                               facet = NULL) {

  rlang::check_installed("visOmopResults")
  rlang::check_installed("ggplot2")

  result <- omopgenerics::validateResultArgument(result)
  omopgenerics::assertCharacter(plotTitle, length = 1, null = TRUE)
  omopgenerics::assertCharacter(labs, length = 2)
  omopgenerics::assertLogical(onlyASR, length = 1)

  if (!is.null(colours)) {
    if (onlyASR) {
      omopgenerics::assertCharacter(colours, length = 1)
    } else {
      omopgenerics::assertCharacter(colours, length = 2)
    }
  }

  result <- result |>
    visOmopResults::filterSettings(.data$result_type == "sequence_ratios")

  if (nrow(result) == 0) {
    cli::cli_warn("`result` object does not contain any `result_type == 'sequence_ratios'` information.")
    return(NULL)
  }

  data <- result |>
    omopgenerics::tidy() |>
    dplyr::mutate(
      pair = paste0(.data$index_cohort_name, "->", .data$marker_cohort_name)
    ) |>
    dplyr::filter(.data$variable_level == "sequence_ratio") |>
    dplyr::select(
      "pair", "variable_name", "point_estimate",
      "lower_CI", "upper_CI", "cdm_name",
      "cohort_date_range", "combination_window",
      "confidence_interval", "days_prior_observation",
      "index_marker_gap", "moving_average_restriction",
      "washout_window"
    )

  if (onlyASR) {
    data <- data |>
      dplyr::filter(.data$variable_name == "adjusted")

    p <- visOmopResults::scatterPlot(
      data,
      x = "pair",
      y = "point_estimate",
      line = FALSE,
      point = TRUE,
      ribbon = FALSE,
      ymin = "lower_CI",
      ymax = "upper_CI",
      facet = facet,
      colour = "variable_name"
    ) +
      ggplot2::ylab(labs[1]) +
      ggplot2::xlab(labs[2]) +
      ggplot2::labs(title = plotTitle) +
      ggplot2::coord_flip() +
      ggplot2::theme_bw() +
      ggplot2::geom_hline(yintercept = 1, linetype = 2) +
      ggplot2::scale_shape_manual(values = rep(19, 5)) +
      ggplot2::theme(
        panel.border = ggplot2::element_blank(),
        axis.line = ggplot2::element_line(),
        legend.title = ggplot2::element_blank(),
        plot.title = ggplot2::element_text(hjust = 0.5)
      ) +
      visOmopResults::themeVisOmop(style = style) +
      ggplot2::theme(
        panel.grid.major.y = ggplot2::element_blank()
      )

    if (style != "darwin") {
      p <- p +
        ggplot2::theme(
          strip.background = ggplot2::element_rect(
            colour = "black"
          ),
          panel.border = ggplot2::element_rect(
            colour = "black",
            fill = NA,
            linewidth = 0.5
          )
        )
    }

    if (!is.null(colours)) {
      p <- p + ggplot2::scale_colour_manual(values = c("adjusted" = colours))
    }

  } else {

    p <- visOmopResults::scatterPlot(
      data,
      x = "pair",
      y = "point_estimate",
      line = FALSE,
      point = TRUE,
      ribbon = FALSE,
      ymin = "lower_CI",
      ymax = "upper_CI",
      facet = facet,
      colour = "variable_name"
    )


    point_layers <- which(vapply(p$layers, function(x) inherits(x$geom, "GeomPoint"), logical(1)))

    ci_layers <- which(vapply(
      p$layers,
      function(x) inherits(x$geom, "GeomErrorbar") || inherits(x$geom, "GeomLinerange"),
      logical(1)
    ))

    # apply the same dodge to both
    dodge <- ggplot2::position_dodge(width = 0.15)

    if (length(point_layers) > 0) {
      p$layers[[point_layers[1]]]$position <- dodge
    }

    if (length(ci_layers) > 0) {
      for (i in ci_layers) {
        p$layers[[i]]$position <- dodge
      }
    }


    p <- p +
      ggplot2::ylab(labs[1]) +
      ggplot2::xlab(labs[2]) +
      ggplot2::labs(title = plotTitle) +
      ggplot2::coord_flip() +
      ggplot2::theme_bw() +
      ggplot2::geom_hline(yintercept = 1, linetype = 2) +
      ggplot2::scale_shape_manual(values = rep(19, 5)) +
      ggplot2::theme(
        panel.border = ggplot2::element_blank(),
        axis.line = ggplot2::element_line(),
        legend.title = ggplot2::element_blank(),
        plot.title = ggplot2::element_text(hjust = 0.5)
      ) +
      visOmopResults::themeVisOmop(style = style) +
      ggplot2::theme(
        panel.grid.major.y = ggplot2::element_blank()
      )

    if (style != "darwin") {
      p <- p +
        ggplot2::theme(
          strip.background = ggplot2::element_rect(
            colour = "black"
          ),
          panel.border = ggplot2::element_rect(
            colour = "black",
            fill = NA,
            linewidth = 0.5
          )
        )
    }


    if (!is.null(colours)) {
      p <- p + ggplot2::scale_colour_manual(
        values = c("adjusted" = colours[1], "crude" = colours[2])
      )
    }
  }

  p
}
