test_that("test summariseTemporalSymmetry", {

  cdm <- mockCohortSymmetry()

  cdm <- generateSequenceCohortSet(
    cdm = cdm,
    name = "joined_cohorts",
    indexTable = "cohort_1",
    markerTable = "cohort_2"
  )

  temporal_symmetry <-
    summariseTemporalSymmetry(cohort = cdm$joined_cohorts,
                              days = 30)

  expect_true(all(
    names(temporal_symmetry) %in% c(
      "result_id",
      "cdm_name",
      "group_name",
      "group_level",
      "strata_name",
      "strata_level",
      "variable_name",
      "variable_level",
      "estimate_name",
      "estimate_type",
      "estimate_value",
      "additional_name",
      "additional_level"
    )
  ))

  temporal_symmetry <-
    summariseTemporalSymmetry(cohort = cdm$joined_cohorts,
                              days = 30)

  expect_true(all(!is.na(
    temporal_symmetry$estimate_value |> unique()
  )))

  days <- 30

  time <-
    cdm$joined_cohorts %>% dplyr::filter(cohort_definition_id == 1) %>%
    dplyr::mutate(time = as.numeric(
      clock::date_count_between(.data$index_date, .data$marker_date, precision = "day")
    )) |>
    dplyr::mutate(
      time = dplyr::case_when(
        .data$time < 0 ~
          floor(.data$time / .env$days) * .env$days,
        .data$time > 0 ~
          ceiling(.data$time / .env$days) * .env$days,
        TRUE ~ 0
      )) |>
    dplyr::pull(time)

  time2 <-
    temporal_symmetry %>% dplyr::filter(group_level == "cohort_1 &&& cohort_1") |> dplyr::pull(variable_level) |> as.double()

  expect_true(all(sum(time) == sum(time2)))

})

test_that("test cohortId",{
  skip_on_cran()
  cdm <- mockCohortSymmetry()
  cdm <- generateSequenceCohortSet(
    cdm = cdm,
    name = "joined_cohorts",
    indexTable = "cohort_1",
    markerTable = "cohort_2"
  )

    result <- summariseTemporalSymmetry(cohort = cdm$joined_cohorts,
                                        cohortId = 1)

  expect_equal(omopgenerics::settings(result) %>%
                 nrow()|>
                 as.numeric(), 1)

  expect_true((result %>%
                 dplyr::select(group_level) %>%
                 dplyr::distinct(group_level) %>%
                 dplyr::pull(group_level)) == "cohort_1 &&& cohort_1")

})

test_that("input validation",{
  skip_on_cran()
  cdm <- mockCohortSymmetry()
  cdm <- generateSequenceCohortSet(
    cdm = cdm,
    name = "joined_cohorts",
    indexTable = "cohort_1",
    markerTable = "cohort_2"
  )

  expect_no_error(
    summariseTemporalSymmetry(cohort = cdm$joined_cohorts)
  )

  expect_no_error(
    summariseTemporalSymmetry(cohort = cdm$joined_cohorts,
                              cohortId = 1)
  )

  expect_error(
   summariseTemporalSymmetry(cohort = cdm$joined_cohorts,
                             days = "30")
  )

  expect_no_error(
    summariseTemporalSymmetry(cohort = cdm$joined_cohorts,
                              days = 365)
  )

  expect_no_error(
    summariseTemporalSymmetry(cohort = cdm$joined_cohorts,
                              days = 60)
  )

  expect_error(
    summariseTemporalSymmetry(cohort = cdm$joined_cohorts,
                              cohortId = "one")
  )

  expect_error(
    summariseTemporalSymmetry(cohort = cdm$joined_cohorts,
                              cohortId = "1")
  )


})
