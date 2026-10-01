############################# Age stratification ####################################
ageGroup = list(c(0, 20), c(21, 40), c(41, 60), c(61, 80))

ageGrDf <- data.frame(do.call(rbind, ageGroup)) %>%
  dplyr::mutate(age_group = paste0(.data$X1, ";", .data$X2))

cdm$cohort1_temp <-
cdm$cohort1 %>%
  PatientProfiles::addAge(cdm = cdm, indexDate = "cohort_start_date", ageGroup = ageGroup) %>%
  dplyr::group_by(cohort_definition_id, subject_id, age_group) %>%
  dbplyr::window_order(cohort_start_date) %>%
  dplyr::filter(dplyr::row_number()==1) %>%
  dplyr::ungroup() %>%
  dbplyr::window_order() %>%
  dplyr::compute()

cdm$cohort2_temp <-
cdm$cohort2 %>%
  PatientProfiles::addAge(cdm = cdm, indexDate = "cohort_start_date", ageGroup = ageGroup) %>%
  dplyr::group_by(cohort_definition_id, subject_id, age_group) %>%
  dbplyr::window_order(cohort_start_date) %>%
  dplyr::filter(dplyr::row_number()==1) %>%
  dplyr::ungroup() %>%
  dbplyr::window_order() %>%
  dplyr::compute()

group1 <- cdm$cohort1_temp %>% dplyr::select(age_group) %>% dplyr::distinct() %>% dplyr::pull()
group2 <- cdm$cohort2_temp %>% dplyr::select(age_group) %>% dplyr::distinct() %>% dplyr::pull()

groups <- intersect(group1, group2)

results <- list()
for (group in (groups)){
  cdm$cohort1_temp2 <- cdm$cohort1_temp %>%
    dplyr::filter(age_group == group)
  cdm$cohort2_temp2 <- cdm$cohort2_temp %>%
    dplyr::filter(age_group == group)
  cdm <- generateSequenceCohortSet(cdm = cdm,
                                        indexTable = "cohort1_temp2",
                                        markerTable = "cohort2_temp2")
  results[[group]] <- getSequenceRatios(cdm, "joined_cohorts") %>%
    dplyr::mutate(age_group = group)
}

results <- Reduce(dplyr::union_all, results)
#######################################################################################

############################# Sex stratification ####################################
sex  = c("Both", "Male", "Female")
cdm$cohort1_temp <-
  cdm$cohort1 %>%
  PatientProfiles::addSex(cdm = cdm) %>%
  dplyr::group_by(cohort_definition_id, subject_id, sex) %>%
  dbplyr::window_order(cohort_start_date) %>%
  dplyr::filter(dplyr::row_number()==1) %>%
  dplyr::ungroup() %>%
  dbplyr::window_order() %>%
  dplyr::compute()

cdm$cohort2_temp <-
  cdm$cohort2 %>%
  PatientProfiles::addSex(cdm = cdm) %>%
  dplyr::group_by(cohort_definition_id, subject_id, sex) %>%
  dbplyr::window_order(cohort_start_date) %>%
  dplyr::filter(dplyr::row_number()==1) %>%
  dplyr::ungroup() %>%
  dbplyr::window_order() %>%
  dplyr::compute()

results <- list()

if("Both" %in% sex){
  cdm <- generateSequenceCohortSet(cdm = cdm,
                           indexTable = "cohort1",
                           markerTable = "cohort2")
results[["Both"]] <- getSequenceRatios(cdm = cdm,
                                       outcomeTable = "joined_cohorts") %>%
  dplyr::mutate(sex = "Both")
}

if("Male" %in% sex){
  cdm$cohort1_temp2 <- cdm$cohort1_temp %>%
    dplyr::filter(sex == "Male")
  cdm$cohort2_temp2 <- cdm$cohort2_temp %>%
    dplyr::filter(sex == "Male")
  cdm <- generateSequenceCohortSet(cdm = cdm,
                           indexTable = "cohort1_temp2",
                           markerTable = "cohort2_temp2")
  results[["Male"]] <- getSequenceRatios(cdm, "joined_cohorts") %>%
    dplyr::mutate(sex = "Male")
}

if("Male" %in% sex){
  cdm$cohort1_temp2 <- cdm$cohort1_temp %>%
    dplyr::filter(sex == "Male")
  cdm$cohort2_temp2 <- cdm$cohort2_temp %>%
    dplyr::filter(sex == "Male")
  cdm <- generateSequenceCohortSet(cdm = cdm,
                           indexTable = "cohort1_temp2",
                           markerTable = "cohort2_temp2")
  results[["Male"]] <- getSequenceRatios(cdm, "joined_cohorts") %>%
    dplyr::mutate(sex = "Male")
}

if("Female" %in% sex){
  cdm$cohort1_temp2 <- cdm$cohort1_temp %>%
    dplyr::filter(sex == "Female")
  cdm$cohort2_temp2 <- cdm$cohort2_temp %>%
    dplyr::filter(sex == "Female")
  cdm <- generateSequenceCohortSet(cdm = cdm,
                           indexTable = "cohort1_temp2",
                           markerTable = "cohort2_temp2")
  results[["Female"]] <- getSequenceRatios(cdm, "joined_cohorts") %>%
    dplyr::mutate(sex = "Female")
}

results <- Reduce(dplyr::union_all, results)
#######################################################################################
### previous CohortSymmetry getHistogram()
getHistogram <- function (pssa_output, time_scale = "weeks"){
  # added in additional columns that calculate gap in days/weeks/months etc
  table <- pssa_output[[1]]
  prep <- table %>%
    dplyr::mutate(gap_days = as.integer(.data$dateMarkerDrug - .data$dateIndexDrug)) %>%
    dplyr::mutate(gap_weeks = round((.data$gap_days / 7),2)) %>%
    dplyr::mutate(gap_months = round((.data$gap_days / 31),2)) %>%
    dplyr::mutate(drug_initiation_order = ifelse(.data$dateMarkerDrug > .data$dateIndexDrug, "Index -> Marker", "Marker -> Index"))
  # %>%
  #   filter(gap_weeks <= 52) %>%
  #   filter(gap_weeks >= - 52) # saw a paper where they only look at 1 year either side


  #calculate the number of bins so we have a nice distribution
  if( (nrow(prep)%%2) == 0) {
    bins <- nrow(prep)
  } else {
    bins <- nrow(prep) + 1 # basically add 1 if the number is odd
  }

  if(time_scale == "weeks") {

    #max and min values for breaks for axis
    max_val <- plyr::round_any(max(prep$gap_weeks), 10, f = ceiling)
    min_val <- plyr::round_any(min(prep$gap_weeks), 10, f = floor)

    p <- ggplot2::ggplot(prep, ggplot2::aes(x=.data$gap_weeks, color=.data$drug_initiation_order, fill=.data$drug_initiation_order)) +
      ggplot2::geom_histogram(bins = bins) +
      ggplot2::geom_hline(yintercept = 0, colour="white", size=0.5) + # this removes the green line at the bottom
      ggplot2::geom_vline(xintercept = 0, linewidth = 1, color = "red", linetype ="dashed") +
      #labs(title = paste0("Time difference between the initiation of index and marker drugs"))+
      ggplot2::scale_y_continuous(expand = c(0, 0)) + # this removed the gap between the y axis and bottom on the bars so now they rest flush on the axis
      ggplot2::scale_x_continuous(breaks=seq(min_val, max_val, 8)) + # creates set breaks in your time axis
      ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust=1),
                     panel.background = ggplot2::element_blank() ,
                     axis.line = ggplot2::element_line(colour = "black", size = 0.6) ,
                     panel.grid.major = ggplot2::element_line(color = "grey", size = 0.2, linetype = "dashed"),
                     legend.key = ggplot2::element_rect(fill = "transparent", colour = "transparent")) +
      ggplot2::theme(plot.title = ggplot2::element_text(hjust = 0.5)) +
      ggplot2::xlab("Weeks before and after index drug initiation") + ggplot2::ylab("Number of Patients")

    return(p)

  } else if(time_scale == "days") {

    max_val <- plyr::round_any(max(prep$gap_days), 10, f = ceiling)
    min_val <- plyr::round_any(min(prep$gap_days), 10, f = floor)

    p <- ggplot2::ggplot(prep, ggplot2::aes(x=.data$gap_days, color=.data$drug_initiation_order, fill=.data$drug_initiation_order)) +
      ggplot2::geom_histogram(bins = bins) +
      ggplot2::geom_hline(yintercept=0, colour="white", size=0.5) +
      ggplot2::geom_vline(xintercept = 0, linewidth = 1, color = "red", linetype ="dashed") +
      #labs(title = paste0("Time difference between the initiation of index and marker drugs"))+
      ggplot2::scale_y_continuous(expand = c(0, 0)) +
      ggplot2::scale_x_continuous(breaks=seq(min_val, max_val, 60)) + # creates set breaks in your time axis
      ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust=1),
                     panel.background = ggplot2::element_blank() ,
                     axis.line = ggplot2::element_line(colour = "black", size = 0.6) ,
                     panel.grid.major = ggplot2::element_line(color = "grey", size = 0.2, linetype = "dashed"),
                     legend.key = ggplot2::element_rect(fill = "transparent", colour = "transparent")) +
      ggplot2::theme(plot.title = ggplot2::element_text(hjust = 0.5)) +
      ggplot2::xlab("Days before and after index drug initiation") + ggplot2::ylab("Number of Patients")

    return(p)

  }  else if(time_scale == "months") {

    max_val <- plyr::round_any(max(prep$gap_months), 10, f = ceiling)
    min_val <- plyr::round_any(min(prep$gap_months), 10, f = floor)

    p <- ggplot2::ggplot(prep, ggplot2::aes(x=.data$gap_months, color=.data$drug_initiation_order, fill=.data$drug_initiation_order)) +
      ggplot2::geom_histogram(bins = bins) +
      ggplot2::geom_hline(yintercept=0, colour="white", size=0.5) +
      ggplot2::geom_vline(xintercept = 0, linewidth = 1, color = "red", linetype ="dashed") +
      #labs(title = paste0("Time difference between the initiation of index and marker drugs"))+
      ggplot2::scale_y_continuous(expand = c(0, 0)) +
      ggplot2::scale_x_continuous(breaks=seq(min_val, max_val, 3)) + # creates set breaks in your time axis
      ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust=1),
                     panel.background = ggplot2::element_blank() ,
                     axis.line = ggplot2::element_line(colour = "black", size = 0.6) ,
                     panel.grid.major = ggplot2::element_line(color = "grey", size = 0.2, linetype = "dashed"),
                     legend.key = ggplot2::element_rect(fill = "transparent", colour = "transparent")) +
      ggplot2::theme(plot.title = ggplot2::element_text(hjust = 0.5)) +
      ggplot2::xlab("Months before and after index drug initiation") + ggplot2::ylab("Number of Patients")

    return(p)

  }
}
##### my fix
library(CohortSymmetry)
cdm <- mockCohortSymmetry()
cdm <- generateSequenceCohortSet(cdm = cdm,
                                                 indexTable = "cohort_1",
                                                 indexId = 1,
                                                 markerTable = "cohort_2",
                                                 markerId = 3,
                                                 name = "joined_cohort")

res <- summariseSequenceRatio(cdm = cdm,
                                              sequenceTable = "joined_cohort")

gtResult <- tableSequenceRatios(res)

plotSequenceRatio(cdm = cdm,
                                  joinedTable = "joined_cohort",
                                  sequenceRatio = res,
                                  onlyaSR = T)

CDMConnector::cdmDisconnect(cdm = cdm)

##############################################################################################################

########################################
# CODE to produce figures for vignette #
########################################

library(ggplot2)
library(dplyr)
library(tibble)
library(patchwork)

# FIGURE 1 no restrictions #############################

# ============================================================
# 1. Subjects and observation periods
# ============================================================

subjects <- 1:6

# Distance of index/marker lines from the subject ID
line_offset <- 0.12

# Height of grey observation-period blocks
block_height <- 0.32

# Amount to move inclusion ticks upwards
tick_offset <- 0.08

# Dashed observation-time lines
obs <- bind_rows(
  data.frame(
    id = subjects,
    y = subjects - line_offset,
    xmin = c(0, 0, 20, 0, 22, 0),
    xmax = c(100, 85, 100, 76, 84, 100)
  ),
  data.frame(
    id = subjects,
    y = subjects + line_offset,
    xmin = c(0, 0, 20, 0, 22, 0),
    xmax = c(100, 85, 100, 76, 84, 100)
  )
)

# ============================================================
# 2. Index periods
# ============================================================

index_periods <- bind_rows(

  # Subject 1
  data.frame(id = 1, xmin = 15, xmax = 22, included = TRUE),
  data.frame(id = 1, xmin = 52, xmax = 64, included = FALSE),

  # Subject 2
  data.frame(id = 2, xmin = 20, xmax = 27, included = TRUE),

  # Subject 3
  data.frame(id = 3, xmin = 57, xmax = 70, included = TRUE),
  data.frame(id = 3, xmin = 75, xmax = 80, included = FALSE),

  # Subject 4
  data.frame(id = 4, xmin = 5, xmax = 18, included = TRUE),

  # Subject 5
  data.frame(id = 5, xmin = 26, xmax = 39, included = TRUE),
  data.frame(id = 5, xmin = 45, xmax = 57, included = FALSE),

  # Subject 6
  data.frame(id = 6, xmin = 8, xmax = 19, included = TRUE),
  data.frame(id = 6, xmin = 22, xmax = 27, included = FALSE)
) %>%
  mutate(
    y = id - line_offset
  )

# ============================================================
# 3. Marker periods
# ============================================================

marker_periods <- bind_rows(

  # Subject 1
  data.frame(id = 1, xmin = 25, xmax = 32, included = TRUE),
  data.frame(id = 1, xmin = 78, xmax = 86, included = FALSE),

  # Subject 2
  data.frame(id = 2, xmin = 40, xmax = 47, included = TRUE),

  # Subject 3
  data.frame(id = 3, xmin = 26, xmax = 46, included = TRUE),

  # Subject 4
  data.frame(id = 4, xmin = 32, xmax = 44, included = TRUE),

  # Subject 5
  data.frame(id = 5, xmin = 61, xmax = 77, included = TRUE),

  # Subject 6
  data.frame(id = 6, xmin = 40, xmax = 52, included = TRUE)
) %>%
  mutate(
    y = id + line_offset
  )

# Split included/excluded periods
included_index <- filter(index_periods, included)
excluded_index <- filter(index_periods, !included)

included_marker <- filter(marker_periods, included)
excluded_marker <- filter(marker_periods, !included)

# ============================================================
# 4. Function to draw an interval with end caps
# ============================================================

draw_interval <- function(data, colour, width = 4) {

  list(

    # Main horizontal line
    geom_segment(
      data = data,
      aes(
        x = xmin,
        xend = xmax,
        y = y,
        yend = y
      ),
      linewidth = width / 2,
      colour = colour,
      lineend = "butt",
      inherit.aes = FALSE
    ),

    # Left cap
    geom_segment(
      data = data,
      aes(
        x = xmin,
        xend = xmin,
        y = y - 0.09,
        yend = y + 0.09
      ),
      linewidth = 1.2,
      colour = colour,
      inherit.aes = FALSE
    ),

    # Right cap
    geom_segment(
      data = data,
      aes(
        x = xmax,
        xend = xmax,
        y = y - 0.09,
        yend = y + 0.09
      ),
      linewidth = 1.2,
      colour = colour,
      inherit.aes = FALSE
    )
  )
}

# ============================================================
# 5. Start and end of observation periods
# ============================================================

start_obs <- data.frame(
  id = c(3, 5),
  xmin = c(18, 20),
  xmax = c(20.5, 22.5),
  ymin = c(3 - block_height, 5 - block_height),
  ymax = c(3 + block_height, 5 + block_height)
)

end_obs <- data.frame(
  id = c(2, 4, 5),
  xmin = c(82.5, 74.5, 82.5),
  xmax = c(85, 77, 85),
  ymin = c(2 - block_height, 4 - block_height, 5 - block_height),
  ymax = c(2 + block_height, 4 + block_height, 5 + block_height)
)

# ============================================================
# 6. Main figure
# ============================================================

p <- ggplot() +

  # Observation time
  geom_segment(
    data = obs,
    aes(
      x = xmin,
      xend = xmax,
      y = y,
      yend = y
    ),
    colour = "grey25",
    linewidth = 0.8,
    linetype = "dashed"
  ) +

  # Start of observation period
  geom_rect(
    data = start_obs,
    aes(
      xmin = xmin,
      xmax = xmax,
      ymin = ymin,
      ymax = ymax
    ),
    fill = "grey40",
    colour = NA
  ) +

  # End of observation period
  geom_rect(
    data = end_obs,
    aes(
      xmin = xmin,
      xmax = xmax,
      ymin = ymin,
      ymax = ymax
    ),
    fill = "grey40",
    colour = NA
  ) +

  # Index periods
  draw_interval(
    included_index,
    "#F8766D",
    width = 4
  ) +

  draw_interval(
    excluded_index,
    "#F8B6AE",
    width = 4
  ) +

  # Marker periods
  draw_interval(
    included_marker,
    "#19B5B9",
    width = 4
  ) +

  draw_interval(
    excluded_marker,
    "#9DDDE0",
    width = 4
  ) +

  # Inclusion checkmarks
  # Slightly shifted upwards
  annotate(
    "text",
    x = 106,
    y = subjects - tick_offset,
    label = "\u2713",
    colour = "#7CB342",
    size = 8,
    fontface = "bold"
  ) +

  # Include heading
  annotate(
    "text",
    x = 106,
    y = 0.15,
    label = "Include",
    size = 4.5,
    fontface = "plain"
  ) +

  # Study-period boundaries
  geom_segment(
    aes(
      x = 0,
      xend = 0,
      y = 0.55,
      yend = 6.45
    ),
    linewidth = 0.8
  ) +

  geom_segment(
    aes(
      x = 100,
      xend = 100,
      y = 0.55,
      yend = 6.45
    ),
    linewidth = 0.8
  ) +

  # Axes
  scale_y_reverse(
    breaks = subjects,
    labels = subjects,
    limits = c(6.8, 0.00),
    expand = expansion(mult = c(0, 0))
  ) +

  scale_x_continuous(
    limits = c(0, 112),
    breaks = NULL,
    expand = expansion(mult = c(0, 0))
  ) +

  labs(
    x = NULL,
    y = "Individual"
  ) +

  theme_minimal(
    base_size = 14
  ) +

  theme(
    panel.grid = element_blank(),
    axis.title.x = element_blank(),
    axis.title.y = element_text(
      size = 14,
      margin = margin(r = 12)
    ),
    axis.text.y = element_text(size = 12),
    axis.text.x = element_blank(),
    axis.ticks = element_blank(),
    plot.margin = margin(15, 35, 10, 15)
  ) +

  coord_cartesian(
    xlim = c(0, 112),
    ylim = c(6.8, 0.00),
    clip = "off"
  ) +

  # Time label
  annotate(
    "text",
    x = 50,
    y = 6.65,
    label = "Time (Days)",
    size = 5
  )

# ============================================================
# 7. Legend
# ============================================================

left_symbol_start  <- 7
left_symbol_end    <- 12
left_text          <- 14

right_symbol_start <- 49
right_symbol_end   <- 54
right_text         <- 56

key <- ggplot() +

  # ----------------------------------------------------------
# Row 1: Included index episode / Included marker episode
# ----------------------------------------------------------

annotate(
  "segment",
  x = left_symbol_start,
  xend = left_symbol_end,
  y = 3,
  yend = 3,
  colour = "#F8766D",
  linewidth = 2
) +

  annotate(
    "text",
    x = left_text,
    y = 3,
    label = "Included index episode",
    hjust = 0,
    size = 4
  ) +

  annotate(
    "segment",
    x = right_symbol_start,
    xend = right_symbol_end,
    y = 3,
    yend = 3,
    colour = "#19B5B9",
    linewidth = 2
  ) +

  annotate(
    "text",
    x = right_text,
    y = 3,
    label = "Included marker episode",
    hjust = 0,
    size = 4
  ) +

  # ----------------------------------------------------------
# Row 2: Excluded index episode / Excluded marker episode
# ----------------------------------------------------------

annotate(
  "segment",
  x = left_symbol_start,
  xend = left_symbol_end,
  y = 2,
  yend = 2,
  colour = "#F8B6AE",
  linewidth = 2
) +

  annotate(
    "text",
    x = left_text,
    y = 2,
    label = "Excluded index episode",
    hjust = 0,
    size = 4
  ) +

  annotate(
    "segment",
    x = right_symbol_start,
    xend = right_symbol_end,
    y = 2,
    yend = 2,
    colour = "#9DDDE0",
    linewidth = 2
  ) +

  annotate(
    "text",
    x = right_text,
    y = 2,
    label = "Excluded marker episode",
    hjust = 0,
    size = 4
  ) +

  # ----------------------------------------------------------
# Row 3: Start/end observation / Observation time
# ----------------------------------------------------------

annotate(
  "rect",
  xmin = left_symbol_start + 1.5,
  xmax = left_symbol_start + 3.5,
  ymin = 0.65,
  ymax = 1.35,
  fill = "grey40",
  colour = NA
) +

  annotate(
    "text",
    x = left_text,
    y = 1,
    label = "Start/end of observation",
    hjust = 0,
    size = 4
  ) +

  annotate(
    "segment",
    x = right_symbol_start,
    xend = right_symbol_end,
    y = 1,
    yend = 1,
    colour = "grey25",
    linewidth = 0.8,
    linetype = "dashed"
  ) +

  annotate(
    "text",
    x = right_text,
    y = 1,
    label = "Observation time",
    hjust = 0,
    size = 4
  ) +

  # ----------------------------------------------------------
# Legend coordinate system
# ----------------------------------------------------------

scale_x_continuous(
  limits = c(0, 100),
  expand = expansion(mult = c(0, 0))
) +

  scale_y_continuous(
    limits = c(0.4, 3.6),
    expand = expansion(mult = c(0, 0))
  ) +

  theme_void() +

  theme(
    plot.margin = margin(5, 15, 5, 15)
  )

# ============================================================
# 8. Combine main figure and legend
# ============================================================

final_plot <- p / key +
  plot_layout(
    heights = c(4.5, 1.35)
  )

# ============================================================
# 9. Print final figure
# ============================================================

final_plot

ggsave(
  filename = "1-NoRestrictions.png",
  plot = final_plot,
  width = 180,
  height = 150,
  units = "mm",
  dpi = 600,
  bg = "white"
)



# FIGURE 2 study period restrictions #############################

library(ggplot2)
library(dplyr)
library(tibble)
library(patchwork)

# ============================================================
# FIGURE 2
# Study period shown explicitly within the observation period
# ============================================================

# ============================================================
# 1. Subjects and observation periods
# ============================================================

subjects <- 1:6

# Study period
study_start <- 10
study_end   <- 90

# Distance of index/marker lines from the subject ID
line_offset <- 0.12

# Height of grey observation-period blocks
block_height <- 0.32

# Amount to move inclusion ticks/cross upwards
tick_offset <- 0.08

# Observation time
obs <- bind_rows(

  # Index observation line
  data.frame(
    id = subjects,
    y = subjects - line_offset,
    xmin = c(0, 0, 20, 0, 22, 0),
    xmax = c(100, 85, 100, 76, 84, 100)
  ),

  # Marker observation line
  data.frame(
    id = subjects,
    y = subjects + line_offset,
    xmin = c(0, 0, 20, 0, 22, 0),
    xmax = c(100, 85, 100, 76, 84, 100)
  )
)

# ============================================================
# 2. Index periods
# ============================================================

index_periods <- bind_rows(

  # Subject 1
  data.frame(id = 1, xmin = 15, xmax = 22, included = TRUE),
  data.frame(id = 1, xmin = 52, xmax = 64, included = FALSE),

  # Subject 2
  data.frame(id = 2, xmin = 20, xmax = 27, included = TRUE),

  # Subject 3
  data.frame(id = 3, xmin = 57, xmax = 70, included = TRUE),
  data.frame(id = 3, xmin = 75, xmax = 80, included = FALSE),

  # Subject 4
  # Index episode starts before the study period
  data.frame(id = 4, xmin = 5, xmax = 18, included = FALSE),

  # Subject 5
  data.frame(id = 5, xmin = 26, xmax = 39, included = TRUE),
  data.frame(id = 5, xmin = 45, xmax = 57, included = FALSE),

  # Subject 6
  # First index episode starts before the study period
  data.frame(id = 6, xmin = 8, xmax = 19, included = FALSE),
  # Second index episode occurs within the study period
  data.frame(id = 6, xmin = 22, xmax = 27, included = TRUE)
) %>%
  mutate(
    y = id - line_offset
  )

# ============================================================
# 3. Marker periods
# ============================================================

marker_periods <- bind_rows(

  # Subject 1
  data.frame(id = 1, xmin = 25, xmax = 32, included = TRUE),
  data.frame(id = 1, xmin = 78, xmax = 86, included = FALSE),

  # Subject 2
  data.frame(id = 2, xmin = 40, xmax = 47, included = TRUE),

  # Subject 3
  data.frame(id = 3, xmin = 26, xmax = 46, included = TRUE),

  # Subject 4
  data.frame(id = 4, xmin = 32, xmax = 44, included = TRUE),

  # Subject 5
  data.frame(id = 5, xmin = 61, xmax = 77, included = TRUE),

  # Subject 6
  data.frame(id = 6, xmin = 40, xmax = 52, included = TRUE)
) %>%
  mutate(
    y = id + line_offset
  )

# Split included/excluded periods
included_index <- filter(index_periods, included)
excluded_index <- filter(index_periods, !included)

included_marker <- filter(marker_periods, included)
excluded_marker <- filter(marker_periods, !included)

# ============================================================
# 4. Function to draw an interval with end caps
# ============================================================

draw_interval <- function(data, colour, width = 4) {

  list(

    # Main horizontal line
    geom_segment(
      data = data,
      aes(
        x = xmin,
        xend = xmax,
        y = y,
        yend = y
      ),
      linewidth = width / 2,
      colour = colour,
      lineend = "butt",
      inherit.aes = FALSE
    ),

    # Left cap
    geom_segment(
      data = data,
      aes(
        x = xmin,
        xend = xmin,
        y = y - 0.09,
        yend = y + 0.09
      ),
      linewidth = 1.2,
      colour = colour,
      inherit.aes = FALSE
    ),

    # Right cap
    geom_segment(
      data = data,
      aes(
        x = xmax,
        xend = xmax,
        y = y - 0.09,
        yend = y + 0.09
      ),
      linewidth = 1.2,
      colour = colour,
      inherit.aes = FALSE
    )
  )
}

# ============================================================
# 5. Start and end of observation periods
# ============================================================

start_obs <- data.frame(
  id = c(3, 5),
  xmin = c(18, 20),
  xmax = c(20.5, 22.5),
  ymin = c(3 - block_height, 5 - block_height),
  ymax = c(3 + block_height, 5 + block_height)
)

end_obs <- data.frame(
  id = c(2, 4, 5),
  xmin = c(82.5, 74.5, 82.5),
  xmax = c(85, 77, 85),
  ymin = c(
    2 - block_height,
    4 - block_height,
    5 - block_height
  ),
  ymax = c(
    2 + block_height,
    4 + block_height,
    5 + block_height
  )
)

# ============================================================
# 6. Split observation time into included/excluded segments
# ============================================================

split_observation <- function(data, study_start, study_end) {

  data %>%
    rowwise() %>%
    do({

      d <- .
      pieces <- list()

      # Before study period
      if (d$xmin < study_start) {

        pieces[[length(pieces) + 1]] <- data.frame(
          id = d$id,
          y = d$y,
          xmin = d$xmin,
          xmax = min(d$xmax, study_start),
          included = FALSE
        )
      }

      # During study period
      inside_start <- max(d$xmin, study_start)
      inside_end <- min(d$xmax, study_end)

      if (inside_start < inside_end) {

        pieces[[length(pieces) + 1]] <- data.frame(
          id = d$id,
          y = d$y,
          xmin = inside_start,
          xmax = inside_end,
          included = TRUE
        )
      }

      # After study period
      if (d$xmax > study_end) {

        pieces[[length(pieces) + 1]] <- data.frame(
          id = d$id,
          y = d$y,
          xmin = max(d$xmin, study_end),
          xmax = d$xmax,
          included = FALSE
        )
      }

      bind_rows(pieces)

    }) %>%
    ungroup()
}

obs_split <- split_observation(
  obs,
  study_start = study_start,
  study_end = study_end
)

included_obs <- filter(obs_split, included)
excluded_obs <- filter(obs_split, !included)

# ============================================================
# 7. Main figure
# ============================================================

p <- ggplot() +

  # ----------------------------------------------------------
# Excluded observation time
# ----------------------------------------------------------

geom_segment(
  data = excluded_obs,
  aes(
    x = xmin,
    xend = xmax,
    y = y,
    yend = y
  ),
  colour = "grey75",
  linewidth = 0.8,
  linetype = "dashed"
) +

  # ----------------------------------------------------------
# Included observation time
# ----------------------------------------------------------

geom_segment(
  data = included_obs,
  aes(
    x = xmin,
    xend = xmax,
    y = y,
    yend = y
  ),
  colour = "grey25",
  linewidth = 0.8,
  linetype = "dashed"
) +

  # ----------------------------------------------------------
# Start of observation period
# ----------------------------------------------------------

geom_rect(
  data = start_obs,
  aes(
    xmin = xmin,
    xmax = xmax,
    ymin = ymin,
    ymax = ymax
  ),
  fill = "grey40",
  colour = NA
) +

  # ----------------------------------------------------------
# End of observation period
# ----------------------------------------------------------

geom_rect(
  data = end_obs,
  aes(
    xmin = xmin,
    xmax = xmax,
    ymin = ymin,
    ymax = ymax
  ),
  fill = "grey40",
  colour = NA
) +

  # ----------------------------------------------------------
# Index periods
# ----------------------------------------------------------

draw_interval(
  included_index,
  "#F8766D",
  width = 4
) +

  draw_interval(
    excluded_index,
    "#F8B6AE",
    width = 4
  ) +

  # ----------------------------------------------------------
# Marker periods
# ----------------------------------------------------------

draw_interval(
  included_marker,
  "#19B5B9",
  width = 4
) +

  draw_interval(
    excluded_marker,
    "#9DDDE0",
    width = 4
  ) +

  # ----------------------------------------------------------
# Inclusion checkmarks
# Individuals 1, 2, 3, 5 and 6
# ----------------------------------------------------------

annotate(
  "text",
  x = 106,
  y = c(1, 2, 3, 5, 6) - tick_offset,
  label = "\u2713",
  colour = "#7CB342",
  size = 8,
  fontface = "bold"
) +

  # ----------------------------------------------------------
# Exclusion cross
# Individual 4
# ----------------------------------------------------------

annotate(
  "text",
  x = 106,
  y = 4 - tick_offset,
  label = "\u2717",
  colour = "#D32F2F",
  size = 8,
  fontface = "bold"
) +

  # ----------------------------------------------------------
# Include heading
# ----------------------------------------------------------

annotate(
  "text",
  x = 106,
  y = 0.15,
  label = "Include",
  size = 4.5,
  fontface = "plain"
) +

  # ----------------------------------------------------------
# Outer boundaries
# ----------------------------------------------------------

geom_segment(
  aes(
    x = 0,
    xend = 0,
    y = 0.55,
    yend = 6.45
  ),
  linewidth = 0.8,
  colour = "grey15"
) +

  geom_segment(
    aes(
      x = 100,
      xend = 100,
      y = 0.55,
      yend = 6.45
    ),
    linewidth = 0.8,
    colour = "grey15"
  ) +

  # ----------------------------------------------------------
# Study-period boundaries
# ----------------------------------------------------------

geom_segment(
  aes(
    x = study_start,
    xend = study_start,
    y = 0.55,
    yend = 6.45
  ),
  linewidth = 0.8,
  colour = "grey55"
) +

  geom_segment(
    aes(
      x = study_end,
      xend = study_end,
      y = 0.55,
      yend = 6.45
    ),
    linewidth = 0.8,
    colour = "grey55"
  ) +

  # ----------------------------------------------------------
# Study-period labels
# ----------------------------------------------------------

annotate(
  "text",
  x = study_start,
  y = 6.90,
  label = "Start of the\nstudy period",
  hjust = 0.5,
  vjust = 0.5,
  colour = "grey55",
  size = 3.7
) +

  annotate(
    "text",
    x = study_end,
    y = 6.90,
    label = "End of the\nstudy period",
    hjust = 0.5,
    vjust = 0.5,
    colour = "grey55",
    size = 3.7
  ) +

  # ----------------------------------------------------------
# Axes
# ----------------------------------------------------------

scale_y_reverse(
  breaks = subjects,
  labels = subjects,
  limits = c(7.10, 0.00),
  expand = expansion(mult = c(0, 0))
) +

  scale_x_continuous(
    limits = c(0, 112),
    breaks = NULL,
    expand = expansion(mult = c(0, 0))
  ) +

  labs(
    x = NULL,
    y = "Individual"
  ) +

  theme_minimal(
    base_size = 14
  ) +

  theme(
    panel.grid = element_blank(),
    axis.title.x = element_blank(),
    axis.title.y = element_text(
      size = 14,
      margin = margin(r = 12)
    ),
    axis.text.y = element_text(size = 12),
    axis.text.x = element_blank(),
    axis.ticks = element_blank(),
    plot.margin = margin(15, 35, 35, 15)
  ) +

  coord_cartesian(
    xlim = c(0, 112),
    ylim = c(7.10, 0.00),
    clip = "off"
  ) +

  # Time label
  annotate(
    "text",
    x = 50,
    y = 7.02,
    label = "Time (Days)",
    size = 5
  )

# ============================================================
# 8. Legend
# ============================================================

left_symbol_start  <- 7
left_symbol_end    <- 12
left_text          <- 14

right_symbol_start <- 49
right_symbol_end   <- 54
right_text         <- 56

key <- ggplot() +

  # Included index episode
  annotate(
    "segment",
    x = left_symbol_start,
    xend = left_symbol_end,
    y = 3,
    yend = 3,
    colour = "#F8766D",
    linewidth = 2
  ) +

  annotate(
    "text",
    x = left_text,
    y = 3,
    label = "Included index episode",
    hjust = 0,
    size = 4
  ) +

  # Included marker episode
  annotate(
    "segment",
    x = right_symbol_start,
    xend = right_symbol_end,
    y = 3,
    yend = 3,
    colour = "#19B5B9",
    linewidth = 2
  ) +

  annotate(
    "text",
    x = right_text,
    y = 3,
    label = "Included marker episode",
    hjust = 0,
    size = 4
  ) +

  # Excluded index episode
  annotate(
    "segment",
    x = left_symbol_start,
    xend = left_symbol_end,
    y = 2,
    yend = 2,
    colour = "#F8B6AE",
    linewidth = 2
  ) +

  annotate(
    "text",
    x = left_text,
    y = 2,
    label = "Excluded index episode",
    hjust = 0,
    size = 4
  ) +

  # Excluded marker episode
  annotate(
    "segment",
    x = right_symbol_start,
    xend = right_symbol_end,
    y = 2,
    yend = 2,
    colour = "#9DDDE0",
    linewidth = 2
  ) +

  annotate(
    "text",
    x = right_text,
    y = 2,
    label = "Excluded marker episode",
    hjust = 0,
    size = 4
  ) +

  # Start/end of observation
  annotate(
    "rect",
    xmin = left_symbol_start + 1.5,
    xmax = left_symbol_start + 3.5,
    ymin = 0.65,
    ymax = 1.35,
    fill = "grey40",
    colour = NA
  ) +

  annotate(
    "text",
    x = left_text,
    y = 1,
    label = "Start/end of observation",
    hjust = 0,
    size = 4
  ) +

  # Observation time
  annotate(
    "segment",
    x = right_symbol_start,
    xend = right_symbol_end,
    y = 1,
    yend = 1,
    colour = "grey25",
    linewidth = 0.8,
    linetype = "dashed"
  ) +

  annotate(
    "text",
    x = right_text,
    y = 1,
    label = "Observation time",
    hjust = 0,
    size = 4
  ) +

  scale_x_continuous(
    limits = c(0, 100),
    expand = expansion(mult = c(0, 0))
  ) +

  scale_y_continuous(
    limits = c(0.4, 3.6),
    expand = expansion(mult = c(0, 0))
  ) +

  theme_void() +

  theme(
    plot.margin = margin(5, 15, 5, 15)
  )

# ============================================================
# 9. Combine main figure and legend
# ============================================================

final_plot <- p / key +
  plot_layout(
    heights = c(4.5, 1.35)
  )

# ============================================================
# 10. Print figure
# ============================================================

final_plot

ggsave(
  filename = "2-studyPeriod.png",
  plot = final_plot,
  width = 180,
  height = 150,
  units = "mm",
  dpi = 600,
  bg = "white"
)


#################################################################################
# ============================================================
# FIGURE 3
# Prior history requirement
# ============================================================

library(ggplot2)
library(dplyr)
library(tibble)
library(patchwork)

# ============================================================
# 1. Subjects and observation periods
# ============================================================

subjects <- 1:6

# Study period
study_start <- 10
study_end   <- 90

# Distance of index/marker lines from the subject ID
line_offset <- 0.12

# Height of grey observation-period blocks
block_height <- 0.32

# Amount to move inclusion ticks/cross upwards
tick_offset <- 0.08

# Prior history requirement
prior_history_requirement <- 31

# ============================================================
# 2. Observation time
# ============================================================

obs <- bind_rows(

  # Index observation line
  data.frame(
    id = subjects,
    y = subjects - line_offset,
    xmin = c(0, 0, 20, 0, 22, 0),
    xmax = c(100, 85, 100, 76, 84, 100)
  ),

  # Marker observation line
  data.frame(
    id = subjects,
    y = subjects + line_offset,
    xmin = c(0, 0, 20, 0, 22, 0),
    xmax = c(100, 85, 100, 76, 84, 100)
  )
)

# ============================================================
# 3. Index periods
# ============================================================

index_periods <- bind_rows(

  # Subject 1
  data.frame(id = 1, xmin = 15, xmax = 22, included = TRUE),
  data.frame(id = 1, xmin = 52, xmax = 64, included = FALSE),

  # Subject 2
  data.frame(id = 2, xmin = 20, xmax = 27, included = TRUE),

  # Subject 3
  data.frame(id = 3, xmin = 57, xmax = 70, included = TRUE),
  data.frame(id = 3, xmin = 75, xmax = 80, included = FALSE),

  # Subject 4
  data.frame(id = 4, xmin = 5, xmax = 18, included = FALSE),

  # Subject 5
  data.frame(id = 5, xmin = 26, xmax = 39, included = TRUE),
  data.frame(id = 5, xmin = 45, xmax = 57, included = FALSE),

  # Subject 6
  data.frame(id = 6, xmin = 8, xmax = 19, included = FALSE),
  data.frame(id = 6, xmin = 22, xmax = 27, included = TRUE)
) %>%
  mutate(
    y = id - line_offset
  )

# ============================================================
# 4. Marker periods
# ============================================================

marker_periods <- bind_rows(

  # Subject 1
  data.frame(id = 1, xmin = 25, xmax = 32, included = TRUE),
  data.frame(id = 1, xmin = 78, xmax = 86, included = FALSE),

  # Subject 2
  data.frame(id = 2, xmin = 40, xmax = 47, included = TRUE),

  # Subject 3
  data.frame(id = 3, xmin = 26, xmax = 46, included = TRUE),

  # Subject 4
  data.frame(id = 4, xmin = 32, xmax = 44, included = TRUE),

  # Subject 5
  data.frame(id = 5, xmin = 61, xmax = 77, included = TRUE),

  # Subject 6
  data.frame(id = 6, xmin = 40, xmax = 52, included = TRUE)
) %>%
  mutate(
    y = id + line_offset
  )

# Split included/excluded periods
included_index <- filter(index_periods, included)
excluded_index <- filter(index_periods, !included)

included_marker <- filter(marker_periods, included)
excluded_marker <- filter(marker_periods, !included)

# ============================================================
# 5. Function to draw an interval with end caps
# ============================================================

draw_interval <- function(data, colour, width = 4) {

  list(

    geom_segment(
      data = data,
      aes(
        x = xmin,
        xend = xmax,
        y = y,
        yend = y
      ),
      linewidth = width / 2,
      colour = colour,
      lineend = "butt",
      inherit.aes = FALSE
    ),

    geom_segment(
      data = data,
      aes(
        x = xmin,
        xend = xmin,
        y = y - 0.09,
        yend = y + 0.09
      ),
      linewidth = 1.2,
      colour = colour,
      inherit.aes = FALSE
    ),

    geom_segment(
      data = data,
      aes(
        x = xmax,
        xend = xmax,
        y = y - 0.09,
        yend = y + 0.09
      ),
      linewidth = 1.2,
      colour = colour,
      inherit.aes = FALSE
    )
  )
}

# ============================================================
# 6. Start and end of observation periods
# ============================================================

start_obs <- data.frame(
  id = c(3, 5),
  xmin = c(18, 20),
  xmax = c(20.5, 22.5),
  ymin = c(3 - block_height, 5 - block_height),
  ymax = c(3 + block_height, 5 + block_height)
)

end_obs <- data.frame(
  id = c(2, 4, 5),
  xmin = c(82.5, 74.5, 82.5),
  xmax = c(85, 77, 85),
  ymin = c(
    2 - block_height,
    4 - block_height,
    5 - block_height
  ),
  ymax = c(
    2 + block_height,
    4 + block_height,
    5 + block_height
  )
)

# ============================================================
# 7. Split observation time into included/excluded segments
# ============================================================

split_observation <- function(data, study_start, study_end) {

  data %>%
    rowwise() %>%
    do({

      d <- .
      pieces <- list()

      # Before study period
      if (d$xmin < study_start) {

        pieces[[length(pieces) + 1]] <- data.frame(
          id = d$id,
          y = d$y,
          xmin = d$xmin,
          xmax = min(d$xmax, study_start),
          included = FALSE
        )
      }

      # During study period
      inside_start <- max(d$xmin, study_start)
      inside_end <- min(d$xmax, study_end)

      if (inside_start < inside_end) {

        pieces[[length(pieces) + 1]] <- data.frame(
          id = d$id,
          y = d$y,
          xmin = inside_start,
          xmax = inside_end,
          included = TRUE
        )
      }

      # After study period
      if (d$xmax > study_end) {

        pieces[[length(pieces) + 1]] <- data.frame(
          id = d$id,
          y = d$y,
          xmin = max(d$xmin, study_end),
          xmax = d$xmax,
          included = FALSE
        )
      }

      bind_rows(pieces)

    }) %>%
    ungroup()
}

obs_split <- split_observation(
  obs,
  study_start = study_start,
  study_end = study_end
)

included_obs <- filter(obs_split, included)
excluded_obs <- filter(obs_split, !included)

# ============================================================
# 8. Main figure
# ============================================================

p <- ggplot() +

  # Excluded observation time
  geom_segment(
    data = excluded_obs,
    aes(
      x = xmin,
      xend = xmax,
      y = y,
      yend = y
    ),
    colour = "grey75",
    linewidth = 0.8,
    linetype = "dashed"
  ) +

  # Included observation time
  geom_segment(
    data = included_obs,
    aes(
      x = xmin,
      xend = xmax,
      y = y,
      yend = y
    ),
    colour = "grey25",
    linewidth = 0.8,
    linetype = "dashed"
  ) +

  # Start of observation period
  geom_rect(
    data = start_obs,
    aes(
      xmin = xmin,
      xmax = xmax,
      ymin = ymin,
      ymax = ymax
    ),
    fill = "grey40",
    colour = NA
  ) +

  # End of observation period
  geom_rect(
    data = end_obs,
    aes(
      xmin = xmin,
      xmax = xmax,
      ymin = ymin,
      ymax = ymax
    ),
    fill = "grey40",
    colour = NA
  ) +

  # ----------------------------------------------------------
# Prior history: participant 3
# 35 days
# Bracket: 21 to 26
# ----------------------------------------------------------

annotate(
  "segment",
  x = 21,
  xend = 26,
  y = 2.68,
  yend = 2.68,
  colour = "grey65",
  linewidth = 0.5
) +

  annotate(
    "segment",
    x = 21,
    xend = 21,
    y = 2.68,
    yend = 2.75,
    colour = "grey65",
    linewidth = 0.5
  ) +

  annotate(
    "segment",
    x = 26,
    xend = 26,
    y = 2.68,
    yend = 2.75,
    colour = "grey65",
    linewidth = 0.5
  ) +

  annotate(
    "text",
    x = 23.5,
    y = 2.50,
    label = "35",
    colour = "grey55",
    size = 2.7
  ) +

  # ----------------------------------------------------------
# Prior history: participant 5
# 15 days
# Bracket: 22.75 to 26
# ----------------------------------------------------------

annotate(
  "segment",
  x = 22.75,
  xend = 26,
  y = 4.68,
  yend = 4.68,
  colour = "grey65",
  linewidth = 0.5
) +

  annotate(
    "segment",
    x = 22.75,
    xend = 22.75,
    y = 4.68,
    yend = 4.75,
    colour = "grey65",
    linewidth = 0.5
  ) +

  annotate(
    "segment",
    x = 26,
    xend = 26,
    y = 4.68,
    yend = 4.75,
    colour = "grey65",
    linewidth = 0.5
  ) +

  annotate(
    "text",
    x = 24.375,
    y = 4.50,
    label = "15",
    colour = "grey55",
    size = 2.7
  ) +

  # Index periods
  draw_interval(
    included_index,
    "#F8766D",
    width = 4
  ) +

  draw_interval(
    excluded_index,
    "#F8B6AE",
    width = 4
  ) +

  # Marker periods
  draw_interval(
    included_marker,
    "#19B5B9",
    width = 4
  ) +

  draw_interval(
    excluded_marker,
    "#9DDDE0",
    width = 4
  ) +

  # Inclusion checkmarks
  annotate(
    "text",
    x = 106,
    y = c(1, 2, 3, 6) - tick_offset,
    label = "\u2713",
    colour = "#7CB342",
    size = 8,
    fontface = "bold"
  ) +

  # Exclusion crosses
  annotate(
    "text",
    x = 106,
    y = c(4, 5) - tick_offset,
    label = "\u2717",
    colour = "#D32F2F",
    size = 8,
    fontface = "bold"
  ) +

  # Include heading
  annotate(
    "text",
    x = 106,
    y = 0.15,
    label = "Include",
    size = 4.5,
    fontface = "plain"
  ) +

  # Outer boundaries
  geom_segment(
    aes(
      x = 0,
      xend = 0,
      y = 0.55,
      yend = 6.45
    ),
    linewidth = 0.8,
    colour = "grey15"
  ) +

  geom_segment(
    aes(
      x = 100,
      xend = 100,
      y = 0.55,
      yend = 6.45
    ),
    linewidth = 0.8,
    colour = "grey15"
  ) +

  # Study-period boundaries
  geom_segment(
    aes(
      x = study_start,
      xend = study_start,
      y = 0.55,
      yend = 6.45
    ),
    linewidth = 0.8,
    colour = "grey55"
  ) +

  geom_segment(
    aes(
      x = study_end,
      xend = study_end,
      y = 0.55,
      yend = 6.45
    ),
    linewidth = 0.8,
    colour = "grey55"
  ) +

  # Study-period labels
  annotate(
    "text",
    x = study_start,
    y = 6.90,
    label = "Start of the\nstudy period",
    hjust = 0.5,
    vjust = 0.5,
    colour = "grey55",
    size = 3.7
  ) +

  annotate(
    "text",
    x = study_end,
    y = 6.90,
    label = "End of the\nstudy period",
    hjust = 0.5,
    vjust = 0.5,
    colour = "grey55",
    size = 3.7
  ) +

  # Axes
  scale_y_reverse(
    breaks = subjects,
    labels = subjects,
    limits = c(7.10, 0.00),
    expand = expansion(mult = c(0, 0))
  ) +

  scale_x_continuous(
    limits = c(0, 112),
    breaks = NULL,
    expand = expansion(mult = c(0, 0))
  ) +

  labs(
    x = NULL,
    y = "Individual"
  ) +

  theme_minimal(
    base_size = 14
  ) +

  theme(
    panel.grid = element_blank(),
    axis.title.x = element_blank(),
    axis.title.y = element_text(
      size = 14,
      margin = margin(r = 12)
    ),
    axis.text.y = element_text(size = 12),
    axis.text.x = element_blank(),
    axis.ticks = element_blank(),
    plot.margin = margin(15, 35, 35, 15)
  ) +

  coord_cartesian(
    xlim = c(0, 112),
    ylim = c(7.10, 0.00),
    clip = "off"
  ) +

  # Time label
  annotate(
    "text",
    x = 50,
    y = 7.02,
    label = "Time (Days)",
    size = 5
  )

# ============================================================
# 9. Legend
# ============================================================

left_symbol_start  <- 7
left_symbol_end    <- 12
left_text          <- 14

right_symbol_start <- 49
right_symbol_end   <- 54
right_text         <- 56

key <- ggplot() +

  # Included index episode
  annotate(
    "segment",
    x = left_symbol_start,
    xend = left_symbol_end,
    y = 3,
    yend = 3,
    colour = "#F8766D",
    linewidth = 2
  ) +

  annotate(
    "text",
    x = left_text,
    y = 3,
    label = "Included index episode",
    hjust = 0,
    size = 4
  ) +

  # Included marker episode
  annotate(
    "segment",
    x = right_symbol_start,
    xend = right_symbol_end,
    y = 3,
    yend = 3,
    colour = "#19B5B9",
    linewidth = 2
  ) +

  annotate(
    "text",
    x = right_text,
    y = 3,
    label = "Included marker episode",
    hjust = 0,
    size = 4
  ) +

  # Excluded index episode
  annotate(
    "segment",
    x = left_symbol_start,
    xend = left_symbol_end,
    y = 2,
    yend = 2,
    colour = "#F8B6AE",
    linewidth = 2
  ) +

  annotate(
    "text",
    x = left_text,
    y = 2,
    label = "Excluded index episode",
    hjust = 0,
    size = 4
  ) +

  # Excluded marker episode
  annotate(
    "segment",
    x = right_symbol_start,
    xend = right_symbol_end,
    y = 2,
    yend = 2,
    colour = "#9DDDE0",
    linewidth = 2
  ) +

  annotate(
    "text",
    x = right_text,
    y = 2,
    label = "Excluded marker episode",
    hjust = 0,
    size = 4
  ) +

  # Start/end of observation
  annotate(
    "rect",
    xmin = left_symbol_start + 1.5,
    xmax = left_symbol_start + 3.5,
    ymin = 0.65,
    ymax = 1.35,
    fill = "grey40",
    colour = NA
  ) +

  annotate(
    "text",
    x = left_text,
    y = 1,
    label = "Start/end of observation",
    hjust = 0,
    size = 4
  ) +

  # Observation time
  annotate(
    "segment",
    x = right_symbol_start,
    xend = right_symbol_end,
    y = 1,
    yend = 1,
    colour = "grey25",
    linewidth = 0.8,
    linetype = "dashed"
  ) +

  annotate(
    "text",
    x = right_text,
    y = 1,
    label = "Observation time",
    hjust = 0,
    size = 4
  ) +

  scale_x_continuous(
    limits = c(0, 100),
    expand = expansion(mult = c(0, 0))
  ) +

  scale_y_continuous(
    limits = c(0.4, 3.6),
    expand = expansion(mult = c(0, 0))
  ) +

  theme_void() +

  theme(
    plot.margin = margin(5, 15, 5, 15)
  )

# ============================================================
# 10. Combine main figure and legend
# ============================================================

final_plot <- p / key +
  plot_layout(
    heights = c(4.5, 1.35)
  )

# ============================================================
# 11. Print final figure
# ============================================================

final_plot

ggsave(
  filename = "3-PriorObservation.png",
  plot = final_plot,
  width = 180,
  height = 150,
  units = "mm",
  dpi = 600,
  bg = "white"
)



####################################################
# ============================================================
# FIGURE 4
# Prior history + washout requirement
# ============================================================

library(ggplot2)
library(dplyr)
library(tibble)
library(patchwork)

# ============================================================
# 1. Subjects and observation periods
# ============================================================

subjects <- 1:6

# Study period
study_start <- 10
study_end   <- 90

# Distance of index/marker lines from the subject ID
line_offset <- 0.12

# Height of grey observation-period blocks
block_height <- 0.32

# Amount to move inclusion ticks/cross upwards
tick_offset <- 0.08

# Prior history requirement
prior_history_requirement <- 31

# Washout period colour
washout_colour <- "#0057B8"

# ============================================================
# 2. Observation time
# ============================================================

obs <- bind_rows(

  # Index observation line
  data.frame(
    id = subjects,
    y = subjects - line_offset,
    xmin = c(0, 0, 20, 0, 22, 0),
    xmax = c(100, 85, 100, 76, 84, 100)
  ),

  # Marker observation line
  data.frame(
    id = subjects,
    y = subjects + line_offset,
    xmin = c(0, 0, 20, 0, 22, 0),
    xmax = c(100, 85, 100, 76, 84, 100)
  )
)

# ============================================================
# 3. Index periods
# ============================================================

index_periods <- bind_rows(

  # Subject 1
  data.frame(id = 1, xmin = 15, xmax = 22, included = TRUE),
  data.frame(id = 1, xmin = 52, xmax = 64, included = FALSE),

  # Subject 2
  data.frame(id = 2, xmin = 20, xmax = 27, included = TRUE),

  # Subject 3
  data.frame(id = 3, xmin = 57, xmax = 70, included = TRUE),
  data.frame(id = 3, xmin = 75, xmax = 80, included = FALSE),

  # Subject 4
  data.frame(id = 4, xmin = 5, xmax = 18, included = FALSE),

  # Subject 5
  data.frame(id = 5, xmin = 26, xmax = 39, included = TRUE),
  data.frame(id = 5, xmin = 45, xmax = 57, included = FALSE),

  # Subject 6
  data.frame(id = 6, xmin = 8, xmax = 19, included = FALSE),
  data.frame(id = 6, xmin = 22, xmax = 27, included = TRUE)

) %>%
  mutate(
    y = id - line_offset
  )

# ============================================================
# 4. Marker periods
# ============================================================

marker_periods <- bind_rows(

  # Subject 1
  data.frame(id = 1, xmin = 25, xmax = 32, included = TRUE),
  data.frame(id = 1, xmin = 78, xmax = 86, included = FALSE),

  # Subject 2
  data.frame(id = 2, xmin = 40, xmax = 47, included = TRUE),

  # Subject 3
  data.frame(id = 3, xmin = 26, xmax = 46, included = TRUE),

  # Subject 4
  data.frame(id = 4, xmin = 32, xmax = 44, included = TRUE),

  # Subject 5
  data.frame(id = 5, xmin = 61, xmax = 77, included = TRUE),

  # Subject 6
  data.frame(id = 6, xmin = 40, xmax = 52, included = TRUE)

) %>%
  mutate(
    y = id + line_offset
  )

# Split included/excluded periods
included_index <- filter(index_periods, included)
excluded_index <- filter(index_periods, !included)

included_marker <- filter(marker_periods, included)
excluded_marker <- filter(marker_periods, !included)

# ============================================================
# 5. Function to draw an interval with end caps
# ============================================================

draw_interval <- function(data, colour, width = 4) {

  list(

    # Main horizontal line
    geom_segment(
      data = data,
      aes(
        x = xmin,
        xend = xmax,
        y = y,
        yend = y
      ),
      linewidth = width / 2,
      colour = colour,
      lineend = "butt",
      inherit.aes = FALSE
    ),

    # Left cap
    geom_segment(
      data = data,
      aes(
        x = xmin,
        xend = xmin,
        y = y - 0.09,
        yend = y + 0.09
      ),
      linewidth = 1.2,
      colour = colour,
      inherit.aes = FALSE
    ),

    # Right cap
    geom_segment(
      data = data,
      aes(
        x = xmax,
        xend = xmax,
        y = y - 0.09,
        yend = y + 0.09
      ),
      linewidth = 1.2,
      colour = colour,
      inherit.aes = FALSE
    )
  )
}

# ============================================================
# 6. Start and end of observation periods
# ============================================================

start_obs <- data.frame(
  id = c(3, 5),
  xmin = c(18, 20),
  xmax = c(20.5, 22.5),
  ymin = c(3 - block_height, 5 - block_height),
  ymax = c(3 + block_height, 5 + block_height)
)

end_obs <- data.frame(
  id = c(2, 4, 5),
  xmin = c(82.5, 74.5, 82.5),
  xmax = c(85, 77, 85),
  ymin = c(
    2 - block_height,
    4 - block_height,
    5 - block_height
  ),
  ymax = c(
    2 + block_height,
    4 + block_height,
    5 + block_height
  )
)

# ============================================================
# 7. Split observation time into included/excluded segments
# ============================================================

split_observation <- function(data, study_start, study_end) {

  data %>%
    rowwise() %>%
    do({

      d <- .
      pieces <- list()

      # Before study period
      if (d$xmin < study_start) {

        pieces[[length(pieces) + 1]] <- data.frame(
          id = d$id,
          y = d$y,
          xmin = d$xmin,
          xmax = min(d$xmax, study_start),
          included = FALSE
        )
      }

      # During study period
      inside_start <- max(d$xmin, study_start)
      inside_end <- min(d$xmax, study_end)

      if (inside_start < inside_end) {

        pieces[[length(pieces) + 1]] <- data.frame(
          id = d$id,
          y = d$y,
          xmin = inside_start,
          xmax = inside_end,
          included = TRUE
        )
      }

      # After study period
      if (d$xmax > study_end) {

        pieces[[length(pieces) + 1]] <- data.frame(
          id = d$id,
          y = d$y,
          xmin = max(d$xmin, study_end),
          xmax = d$xmax,
          included = FALSE
        )
      }

      bind_rows(pieces)

    }) %>%
    ungroup()
}

obs_split <- split_observation(
  obs,
  study_start = study_start,
  study_end = study_end
)

included_obs <- filter(obs_split, included)
excluded_obs <- filter(obs_split, !included)

# ============================================================
# 8. Washout periods
# ============================================================

# Washout is shown for participants who are being assessed
# against the washout criterion at this stage.
#
# Participants 4 and 5 were already excluded by previous
# criteria and therefore have no washout period.
#
# Participant 6 is shown with a washout period because this
# criterion is what excludes them.

washout_length <- 5

washout_periods <- bind_rows(

  # ----------------------------------------------------------
  # Participant 1
  # ----------------------------------------------------------

  data.frame(
    id = 1,
    xmin = 15 - washout_length,
    xmax = 15,
    y = 1 - line_offset
  ),

  data.frame(
    id = 1,
    xmin = 25 - washout_length,
    xmax = 25,
    y = 1 + line_offset
  ),

  # ----------------------------------------------------------
  # Participant 2
  # ----------------------------------------------------------

  data.frame(
    id = 2,
    xmin = 20 - washout_length,
    xmax = 20,
    y = 2 - line_offset
  ),

  data.frame(
    id = 2,
    xmin = 40 - washout_length,
    xmax = 40,
    y = 2 + line_offset
  ),

  # ----------------------------------------------------------
  # Participant 3
  # ----------------------------------------------------------

  data.frame(
    id = 3,
    xmin = 57 - washout_length,
    xmax = 57,
    y = 3 - line_offset
  ),

  data.frame(
    id = 3,
    xmin = 26 - washout_length,
    xmax = 26,
    y = 3 + line_offset
  ),

  # ----------------------------------------------------------
  # Participant 6
  # ----------------------------------------------------------

  data.frame(
    id = 6,
    xmin = 22 - washout_length,
    xmax = 22,
    y = 6 - line_offset
  ),

  data.frame(
    id = 6,
    xmin = 40 - washout_length,
    xmax = 40,
    y = 6 + line_offset
  )
)

# ============================================================
# 9. Make participant 6's included index episode pale red
# ============================================================

included_index_plot <- included_index %>%
  mutate(
    colour = "#F8B6AE"
  )

included_index_regular <- included_index_plot %>%
  filter(id != 6)

included_index_6 <- included_index_plot %>%
  filter(id == 6)

# ============================================================
# 10. Main figure
# ============================================================

p <- ggplot() +

  # ----------------------------------------------------------
# Excluded observation time
# ----------------------------------------------------------

geom_segment(
  data = excluded_obs,
  aes(
    x = xmin,
    xend = xmax,
    y = y,
    yend = y
  ),
  colour = "grey75",
  linewidth = 0.8,
  linetype = "dashed"
) +

  # ----------------------------------------------------------
# Included observation time
# ----------------------------------------------------------

geom_segment(
  data = included_obs,
  aes(
    x = xmin,
    xend = xmax,
    y = y,
    yend = y
  ),
  colour = "grey25",
  linewidth = 0.8,
  linetype = "dashed"
) +

  # ----------------------------------------------------------
# Start of observation period
# ----------------------------------------------------------

geom_rect(
  data = start_obs,
  aes(
    xmin = xmin,
    xmax = xmax,
    ymin = ymin,
    ymax = ymax
  ),
  fill = "grey40",
  colour = NA
) +

  # ----------------------------------------------------------
# End of observation period
# ----------------------------------------------------------

geom_rect(
  data = end_obs,
  aes(
    xmin = xmin,
    xmax = xmax,
    ymin = ymin,
    ymax = ymax
  ),
  fill = "grey40",
  colour = NA
) +

  # ----------------------------------------------------------
# Index periods
# ----------------------------------------------------------

# Regular included index episodes
draw_interval(
  included_index_regular,
  "#F8766D",
  width = 4
) +

  # Participant 6 included index episode now excluded
  # and therefore shown in pale red
  draw_interval(
    included_index_6,
    "#F8B6AE",
    width = 4
  ) +

  # Previously excluded index episodes
  draw_interval(
    excluded_index,
    "#F8B6AE",
    width = 4
  ) +

  # ----------------------------------------------------------
# Marker periods
# ----------------------------------------------------------

draw_interval(
  included_marker,
  "#19B5B9",
  width = 4
) +

  draw_interval(
    excluded_marker,
    "#9DDDE0",
    width = 4
  ) +

  # ----------------------------------------------------------
# Prior history: participant 3
# 35 days
# Bracket: 21 to 26
# ----------------------------------------------------------

annotate(
  "segment",
  x = 21,
  xend = 26,
  y = 2.68,
  yend = 2.68,
  colour = "grey65",
  linewidth = 0.5
) +

  annotate(
    "segment",
    x = 21,
    xend = 21,
    y = 2.68,
    yend = 2.75,
    colour = "grey65",
    linewidth = 0.5
  ) +

  annotate(
    "segment",
    x = 26,
    xend = 26,
    y = 2.68,
    yend = 2.75,
    colour = "grey65",
    linewidth = 0.5
  ) +

  annotate(
    "text",
    x = 23.5,
    y = 2.50,
    label = "35",
    colour = "grey55",
    size = 2.7
  ) +

  # ----------------------------------------------------------
# Prior history: participant 5
# 15 days
# Bracket: 22.75 to 26
# ----------------------------------------------------------

annotate(
  "segment",
  x = 22.75,
  xend = 26,
  y = 4.68,
  yend = 4.68,
  colour = "grey65",
  linewidth = 0.5
) +

  annotate(
    "segment",
    x = 22.75,
    xend = 22.75,
    y = 4.68,
    yend = 4.75,
    colour = "grey65",
    linewidth = 0.5
  ) +

  annotate(
    "segment",
    x = 26,
    xend = 26,
    y = 4.68,
    yend = 4.75,
    colour = "grey65",
    linewidth = 0.5
  ) +

  annotate(
    "text",
    x = 24.375,
    y = 4.50,
    label = "15",
    colour = "grey55",
    size = 2.7
  ) +

  # ----------------------------------------------------------
# Washout periods
# Solid blue line
# Left marker only
# ----------------------------------------------------------

geom_segment(
  data = washout_periods,
  aes(
    x = xmin,
    xend = xmax,
    y = y,
    yend = y
  ),
  colour = washout_colour,
  linewidth = 1.1
) +

  geom_segment(
    data = washout_periods,
    aes(
      x = xmin,
      xend = xmin,
      y = y - 0.08,
      yend = y + 0.08
    ),
    colour = washout_colour,
    linewidth = 1
  ) +

  # ----------------------------------------------------------
# Inclusion checkmarks
# Individuals 1, 2 and 3
# ----------------------------------------------------------

annotate(
  "text",
  x = 106,
  y = c(1, 2, 3) - tick_offset,
  label = "\u2713",
  colour = "#7CB342",
  size = 8,
  fontface = "bold"
) +

  # ----------------------------------------------------------
# Exclusion crosses
# Individuals 4, 5 and 6
# ----------------------------------------------------------

annotate(
  "text",
  x = 106,
  y = c(4, 5, 6) - tick_offset,
  label = "\u2717",
  colour = "#D32F2F",
  size = 8,
  fontface = "bold"
) +

  # ----------------------------------------------------------
# Include heading
# ----------------------------------------------------------

annotate(
  "text",
  x = 106,
  y = 0.15,
  label = "Include",
  size = 4.5,
  fontface = "plain"
) +

  # ----------------------------------------------------------
# Outer boundaries
# ----------------------------------------------------------

geom_segment(
  aes(
    x = 0,
    xend = 0,
    y = 0.55,
    yend = 6.45
  ),
  linewidth = 0.8,
  colour = "grey15"
) +

  geom_segment(
    aes(
      x = 100,
      xend = 100,
      y = 0.55,
      yend = 6.45
    ),
    linewidth = 0.8,
    colour = "grey15"
  ) +

  # ----------------------------------------------------------
# Study-period boundaries
# ----------------------------------------------------------

geom_segment(
  aes(
    x = study_start,
    xend = study_start,
    y = 0.55,
    yend = 6.45
  ),
  linewidth = 0.8,
  colour = "grey55"
) +

  geom_segment(
    aes(
      x = study_end,
      xend = study_end,
      y = 0.55,
      yend = 6.45
    ),
    linewidth = 0.8,
    colour = "grey55"
  ) +

  # ----------------------------------------------------------
# Study-period labels
# ----------------------------------------------------------

annotate(
  "text",
  x = study_start,
  y = 6.90,
  label = "Start of the\nstudy period",
  hjust = 0.5,
  vjust = 0.5,
  colour = "grey55",
  size = 3.7
) +

  annotate(
    "text",
    x = study_end,
    y = 6.90,
    label = "End of the\nstudy period",
    hjust = 0.5,
    vjust = 0.5,
    colour = "grey55",
    size = 3.7
  ) +

  # ----------------------------------------------------------
# Axes
# ----------------------------------------------------------

scale_y_reverse(
  breaks = subjects,
  labels = subjects,
  limits = c(7.10, 0.00),
  expand = expansion(mult = c(0, 0))
) +

  scale_x_continuous(
    limits = c(0, 112),
    breaks = NULL,
    expand = expansion(mult = c(0, 0))
  ) +

  labs(
    x = NULL,
    y = "Individual"
  ) +

  theme_minimal(
    base_size = 14
  ) +

  theme(
    panel.grid = element_blank(),
    axis.title.x = element_blank(),
    axis.title.y = element_text(
      size = 14,
      margin = margin(r = 12)
    ),
    axis.text.y = element_text(size = 12),
    axis.text.x = element_blank(),
    axis.ticks = element_blank(),
    plot.margin = margin(15, 35, 35, 15)
  ) +

  coord_cartesian(
    xlim = c(0, 112),
    ylim = c(7.10, 0.00),
    clip = "off"
  ) +

  # Time label
  annotate(
    "text",
    x = 50,
    y = 7.02,
    label = "Time (Days)",
    size = 5
  )

# ============================================================
# 11. Legend
# ============================================================

left_symbol_start  <- 7
left_symbol_end    <- 12
left_text          <- 14

right_symbol_start <- 49
right_symbol_end   <- 54
right_text         <- 56

key <- ggplot() +

  # Included index episode
  annotate(
    "segment",
    x = left_symbol_start,
    xend = left_symbol_end,
    y = 3,
    yend = 3,
    colour = "#F8766D",
    linewidth = 2
  ) +

  annotate(
    "text",
    x = left_text,
    y = 3,
    label = "Included index episode",
    hjust = 0,
    size = 4
  ) +

  # Included marker episode
  annotate(
    "segment",
    x = right_symbol_start,
    xend = right_symbol_end,
    y = 3,
    yend = 3,
    colour = "#19B5B9",
    linewidth = 2
  ) +

  annotate(
    "text",
    x = right_text,
    y = 3,
    label = "Included marker episode",
    hjust = 0,
    size = 4
  ) +

  # Excluded index episode
  annotate(
    "segment",
    x = left_symbol_start,
    xend = left_symbol_end,
    y = 2,
    yend = 2,
    colour = "#F8B6AE",
    linewidth = 2
  ) +

  annotate(
    "text",
    x = left_text,
    y = 2,
    label = "Excluded index episode",
    hjust = 0,
    size = 4
  ) +

  # Excluded marker episode
  annotate(
    "segment",
    x = right_symbol_start,
    xend = right_symbol_end,
    y = 2,
    yend = 2,
    colour = "#9DDDE0",
    linewidth = 2
  ) +

  annotate(
    "text",
    x = right_text,
    y = 2,
    label = "Excluded marker episode",
    hjust = 0,
    size = 4
  ) +

  # Start/end of observation
  annotate(
    "rect",
    xmin = left_symbol_start + 1.5,
    xmax = left_symbol_start + 3.5,
    ymin = 0.65,
    ymax = 1.35,
    fill = "grey40",
    colour = NA
  ) +

  annotate(
    "text",
    x = left_text,
    y = 1,
    label = "Start/end of observation",
    hjust = 0,
    size = 4
  ) +

  # Observation time
  annotate(
    "segment",
    x = right_symbol_start,
    xend = right_symbol_end,
    y = 1,
    yend = 1,
    colour = "grey25",
    linewidth = 0.8,
    linetype = "dashed"
  ) +

  annotate(
    "text",
    x = right_text,
    y = 1,
    label = "Observation time",
    hjust = 0,
    size = 4
  ) +

  scale_x_continuous(
    limits = c(0, 100),
    expand = expansion(mult = c(0, 0))
  ) +

  scale_y_continuous(
    limits = c(0.4, 3.6),
    expand = expansion(mult = c(0, 0))
  ) +

  theme_void() +

  theme(
    plot.margin = margin(5, 15, 5, 15)
  )

# ============================================================
# 12. Combine main figure and legend
# ============================================================

final_plot <- p / key +
  plot_layout(
    heights = c(4.5, 1.35)
  )

# ============================================================
# 13. Print final plot
# ============================================================

final_plot

ggsave(
  filename = "4-washoutPeriod.png",
  plot = final_plot,
  width = 180,
  height = 150,
  units = "mm",
  dpi = 600,
  bg = "white"
)








#################################################################
# ============================================================
# FIGURE 5
# Prior history + combination window
# ============================================================

library(ggplot2)
library(dplyr)
library(tibble)
library(patchwork)

# ============================================================
# 1. Subjects and observation periods
# ============================================================

subjects <- 1:6

# Study period
study_start <- 10
study_end   <- 90

# Distance of index/marker lines from the subject ID
line_offset <- 0.12

# Height of grey observation-period blocks
block_height <- 0.32

# Amount to move inclusion ticks/cross upwards
tick_offset <- 0.08

# Prior history requirement
prior_history_requirement <- 31

# Combination window colour
combination_window_colour <- "#7CB342"

# ============================================================
# 2. Observation time
# ============================================================

obs <- bind_rows(

  # Index observation line
  data.frame(
    id = subjects,
    y = subjects - line_offset,
    xmin = c(0, 0, 20, 0, 22, 0),
    xmax = c(100, 85, 100, 76, 84, 100)
  ),

  # Marker observation line
  data.frame(
    id = subjects,
    y = subjects + line_offset,
    xmin = c(0, 0, 20, 0, 22, 0),
    xmax = c(100, 85, 100, 76, 84, 100)
  )
)

# ============================================================
# 3. Index periods
# ============================================================

index_periods <- bind_rows(

  # Subject 1
  data.frame(id = 1, xmin = 15, xmax = 22, included = TRUE),
  data.frame(id = 1, xmin = 52, xmax = 64, included = FALSE),

  # Subject 2
  data.frame(id = 2, xmin = 20, xmax = 27, included = TRUE),

  # Subject 3
  data.frame(id = 3, xmin = 57, xmax = 70, included = TRUE),
  data.frame(id = 3, xmin = 75, xmax = 80, included = FALSE),

  # Subject 4
  data.frame(id = 4, xmin = 5, xmax = 18, included = FALSE),

  # Subject 5
  data.frame(id = 5, xmin = 26, xmax = 39, included = TRUE),
  data.frame(id = 5, xmin = 45, xmax = 57, included = FALSE),

  # Subject 6
  data.frame(id = 6, xmin = 8, xmax = 19, included = FALSE),
  data.frame(id = 6, xmin = 22, xmax = 27, included = TRUE)

) %>%
  mutate(
    y = id - line_offset
  )

# ============================================================
# 4. Marker periods
# ============================================================

marker_periods <- bind_rows(

  # Subject 1
  data.frame(id = 1, xmin = 25, xmax = 32, included = TRUE),
  data.frame(id = 1, xmin = 78, xmax = 86, included = FALSE),

  # Subject 2
  data.frame(id = 2, xmin = 40, xmax = 47, included = TRUE),

  # Subject 3
  data.frame(id = 3, xmin = 26, xmax = 46, included = TRUE),

  # Subject 4
  data.frame(id = 4, xmin = 32, xmax = 44, included = TRUE),

  # Subject 5
  data.frame(id = 5, xmin = 61, xmax = 77, included = TRUE),

  # Subject 6
  data.frame(id = 6, xmin = 40, xmax = 52, included = TRUE)

) %>%
  mutate(
    y = id + line_offset
  )

# Split included/excluded periods
included_index <- filter(index_periods, included)
excluded_index <- filter(index_periods, !included)

included_marker <- filter(marker_periods, included)
excluded_marker <- filter(marker_periods, !included)

# ============================================================
# 5. Function to draw an interval with end caps
# ============================================================

draw_interval <- function(data, colour, width = 4) {

  list(

    # Main horizontal line
    geom_segment(
      data = data,
      aes(
        x = xmin,
        xend = xmax,
        y = y,
        yend = y
      ),
      linewidth = width / 2,
      colour = colour,
      lineend = "butt",
      inherit.aes = FALSE
    ),

    # Left cap
    geom_segment(
      data = data,
      aes(
        x = xmin,
        xend = xmin,
        y = y - 0.09,
        yend = y + 0.09
      ),
      linewidth = 1.2,
      colour = colour,
      inherit.aes = FALSE
    ),

    # Right cap
    geom_segment(
      data = data,
      aes(
        x = xmax,
        xend = xmax,
        y = y - 0.09,
        yend = y + 0.09
      ),
      linewidth = 1.2,
      colour = colour,
      inherit.aes = FALSE
    )
  )
}

# ============================================================
# 6. Start and end of observation periods
# ============================================================

start_obs <- data.frame(
  id = c(3, 5),
  xmin = c(18, 20),
  xmax = c(20.5, 22.5),
  ymin = c(3 - block_height, 5 - block_height),
  ymax = c(3 + block_height, 5 + block_height)
)

end_obs <- data.frame(
  id = c(2, 4, 5),
  xmin = c(82.5, 74.5, 82.5),
  xmax = c(85, 77, 85),
  ymin = c(
    2 - block_height,
    4 - block_height,
    5 - block_height
  ),
  ymax = c(
    2 + block_height,
    4 + block_height,
    5 + block_height
  )
)

# ============================================================
# 7. Split observation time into included/excluded segments
# ============================================================

split_observation <- function(data, study_start, study_end) {

  data %>%
    rowwise() %>%
    do({

      d <- .
      pieces <- list()

      # Before study period
      if (d$xmin < study_start) {

        pieces[[length(pieces) + 1]] <- data.frame(
          id = d$id,
          y = d$y,
          xmin = d$xmin,
          xmax = min(d$xmax, study_start),
          included = FALSE
        )
      }

      # During study period
      inside_start <- max(d$xmin, study_start)
      inside_end <- min(d$xmax, study_end)

      if (inside_start < inside_end) {

        pieces[[length(pieces) + 1]] <- data.frame(
          id = d$id,
          y = d$y,
          xmin = inside_start,
          xmax = inside_end,
          included = TRUE
        )
      }

      # After study period
      if (d$xmax > study_end) {

        pieces[[length(pieces) + 1]] <- data.frame(
          id = d$id,
          y = d$y,
          xmin = max(d$xmin, study_end),
          xmax = d$xmax,
          included = FALSE
        )
      }

      bind_rows(pieces)

    }) %>%
    ungroup()
}

obs_split <- split_observation(
  obs,
  study_start = study_start,
  study_end = study_end
)

included_obs <- filter(obs_split, included)
excluded_obs <- filter(obs_split, !included)

# ============================================================
# 8. Combination windows
# ============================================================

# The combination window is only evaluated for individuals
# who remain included after the prior-history requirement.
#
# Participant 1 remains included.
# Participants 2 and 3 are excluded at this stage.
#
# Participants 4, 5 and 6 were already excluded previously.

combination_window <- bind_rows(

  # ----------------------------------------------------------
  # Participant 1
  # ----------------------------------------------------------

  data.frame(
    id = 1,
    xmin = 15,
    xmax = 25,
    y = 1 + line_offset,
    result = "< 20"
  ),

  # ----------------------------------------------------------
  # Participant 2
  # ----------------------------------------------------------

  data.frame(
    id = 2,
    xmin = 20,
    xmax = 40,
    y = 2 + line_offset,
    result = "> 20"
  ),

  # ----------------------------------------------------------
  # Participant 3
  # ----------------------------------------------------------

  data.frame(
    id = 3,
    xmin = 26,
    xmax = 57,
    y = 3 - line_offset,
    result = "> 20"
  )
)

# ============================================================
# 9. Main figure
# ============================================================

p <- ggplot() +

  # ----------------------------------------------------------
# Excluded observation time
# ----------------------------------------------------------

geom_segment(
  data = excluded_obs,
  aes(
    x = xmin,
    xend = xmax,
    y = y,
    yend = y
  ),
  colour = "grey75",
  linewidth = 0.8,
  linetype = "dashed"
) +

  # ----------------------------------------------------------
# Included observation time
# ----------------------------------------------------------

geom_segment(
  data = included_obs,
  aes(
    x = xmin,
    xend = xmax,
    y = y,
    yend = y
  ),
  colour = "grey25",
  linewidth = 0.8,
  linetype = "dashed"
) +

  # ----------------------------------------------------------
# Start of observation period
# ----------------------------------------------------------

geom_rect(
  data = start_obs,
  aes(
    xmin = xmin,
    xmax = xmax,
    ymin = ymin,
    ymax = ymax
  ),
  fill = "grey40",
  colour = NA
) +

  # ----------------------------------------------------------
# End of observation period
# ----------------------------------------------------------

geom_rect(
  data = end_obs,
  aes(
    xmin = xmin,
    xmax = xmax,
    ymin = ymin,
    ymax = ymax
  ),
  fill = "grey40",
  colour = NA
) +

  # ----------------------------------------------------------
# Prior history: participant 3
# 35 days
# Bracket: 21 to 26
# ----------------------------------------------------------

annotate(
  "segment",
  x = 21,
  xend = 26,
  y = 2.68,
  yend = 2.68,
  colour = "grey65",
  linewidth = 0.5
) +

  annotate(
    "segment",
    x = 21,
    xend = 21,
    y = 2.68,
    yend = 2.75,
    colour = "grey65",
    linewidth = 0.5
  ) +

  annotate(
    "segment",
    x = 26,
    xend = 26,
    y = 2.68,
    yend = 2.75,
    colour = "grey65",
    linewidth = 0.5
  ) +

  annotate(
    "text",
    x = 23.5,
    y = 2.50,
    label = "35",
    colour = "grey55",
    size = 2.7
  ) +

  # ----------------------------------------------------------
# Prior history: participant 5
# 15 days
# Bracket: 22.75 to 26
# ----------------------------------------------------------

annotate(
  "segment",
  x = 22.75,
  xend = 26,
  y = 4.68,
  yend = 4.68,
  colour = "grey65",
  linewidth = 0.5
) +

  annotate(
    "segment",
    x = 22.75,
    xend = 22.75,
    y = 4.68,
    yend = 4.75,
    colour = "grey65",
    linewidth = 0.5
  ) +

  annotate(
    "segment",
    x = 26,
    xend = 26,
    y = 4.68,
    yend = 4.75,
    colour = "grey65",
    linewidth = 0.5
  ) +

  annotate(
    "text",
    x = 24.375,
    y = 4.50,
    label = "15",
    colour = "grey55",
    size = 2.7
  ) +

  # ----------------------------------------------------------
# Combination window
# ----------------------------------------------------------

geom_segment(
  data = combination_window,
  aes(
    x = xmin,
    xend = xmax,
    y = y,
    yend = y
  ),
  colour = combination_window_colour,
  linewidth = 1
) +

  # Left marker only
  geom_segment(
    data = combination_window,
    aes(
      x = xmin,
      xend = xmin,
      y = y - 0.08,
      yend = y + 0.08
    ),
    colour = combination_window_colour,
    linewidth = 1
  ) +

  # ----------------------------------------------------------
# Combination window labels
# Same size as prior-history numbers
# ----------------------------------------------------------

# Participant 1
annotate(
  "text",
  x = 20,
  y = 1.24,
  label = "< 20",
  colour = combination_window_colour,
  size = 2.7
) +

  # Participant 2
  annotate(
    "text",
    x = 30,
    y = 2.25,
    label = "> 20",
    colour = combination_window_colour,
    size = 2.7
  ) +

  # Participant 3
  annotate(
    "text",
    x = 41.5,
    y = 2.70,
    label = "> 20",
    colour = combination_window_colour,
    size = 2.7
  ) +

  # ----------------------------------------------------------
# Index periods
# ----------------------------------------------------------

draw_interval(
  included_index,
  "#F8766D",
  width = 4
) +

  draw_interval(
    excluded_index,
    "#F8B6AE",
    width = 4
  ) +

  # ----------------------------------------------------------
# Marker periods
# ----------------------------------------------------------

draw_interval(
  included_marker,
  "#19B5B9",
  width = 4
) +

  draw_interval(
    excluded_marker,
    "#9DDDE0",
    width = 4
  ) +

  # ----------------------------------------------------------
# Inclusion checkmark
# Participant 1
# ----------------------------------------------------------

annotate(
  "text",
  x = 106,
  y = 1 - tick_offset,
  label = "\u2713",
  colour = "#7CB342",
  size = 8,
  fontface = "bold"
) +

  # ----------------------------------------------------------
# Exclusion crosses
# Participants 2, 3, 4, 5 and 6
# ----------------------------------------------------------

annotate(
  "text",
  x = 106,
  y = c(2, 3, 4, 5, 6) - tick_offset,
  label = "\u2717",
  colour = "#D32F2F",
  size = 8,
  fontface = "bold"
) +

  # ----------------------------------------------------------
# Include heading
# ----------------------------------------------------------

annotate(
  "text",
  x = 106,
  y = 0.15,
  label = "Include",
  size = 4.5,
  fontface = "plain"
) +

  # ----------------------------------------------------------
# Outer boundaries
# ----------------------------------------------------------

geom_segment(
  aes(
    x = 0,
    xend = 0,
    y = 0.55,
    yend = 6.45
  ),
  linewidth = 0.8,
  colour = "grey15"
) +

  geom_segment(
    aes(
      x = 100,
      xend = 100,
      y = 0.55,
      yend = 6.45
    ),
    linewidth = 0.8,
    colour = "grey15"
  ) +

  # ----------------------------------------------------------
# Study-period boundaries
# ----------------------------------------------------------

geom_segment(
  aes(
    x = study_start,
    xend = study_start,
    y = 0.55,
    yend = 6.45
  ),
  linewidth = 0.8,
  colour = "grey55"
) +

  geom_segment(
    aes(
      x = study_end,
      xend = study_end,
      y = 0.55,
      yend = 6.45
    ),
    linewidth = 0.8,
    colour = "grey55"
  ) +

  # ----------------------------------------------------------
# Study-period labels
# ----------------------------------------------------------

annotate(
  "text",
  x = study_start,
  y = 6.90,
  label = "Start of the\nstudy period",
  hjust = 0.5,
  vjust = 0.5,
  colour = "grey55",
  size = 3.7
) +

  annotate(
    "text",
    x = study_end,
    y = 6.90,
    label = "End of the\nstudy period",
    hjust = 0.5,
    vjust = 0.5,
    colour = "grey55",
    size = 3.7
  ) +

  # ----------------------------------------------------------
# Axes
# ----------------------------------------------------------

scale_y_reverse(
  breaks = subjects,
  labels = subjects,
  limits = c(7.10, 0.00),
  expand = expansion(mult = c(0, 0))
) +

  scale_x_continuous(
    limits = c(0, 112),
    breaks = NULL,
    expand = expansion(mult = c(0, 0))
  ) +

  labs(
    x = NULL,
    y = "Individual"
  ) +

  theme_minimal(
    base_size = 14
  ) +

  theme(
    panel.grid = element_blank(),
    axis.title.x = element_blank(),
    axis.title.y = element_text(
      size = 14,
      margin = margin(r = 12)
    ),
    axis.text.y = element_text(size = 12),
    axis.text.x = element_blank(),
    axis.ticks = element_blank(),
    plot.margin = margin(15, 35, 35, 15)
  ) +

  coord_cartesian(
    xlim = c(0, 112),
    ylim = c(7.10, 0.00),
    clip = "off"
  ) +

  # Time label
  annotate(
    "text",
    x = 50,
    y = 7.02,
    label = "Time (Days)",
    size = 5
  )

# ============================================================
# 10. Legend
# ============================================================

left_symbol_start  <- 7
left_symbol_end    <- 12
left_text          <- 14

right_symbol_start <- 49
right_symbol_end   <- 54
right_text         <- 56

key <- ggplot() +

  # Included index episode
  annotate(
    "segment",
    x = left_symbol_start,
    xend = left_symbol_end,
    y = 3,
    yend = 3,
    colour = "#F8766D",
    linewidth = 2
  ) +

  annotate(
    "text",
    x = left_text,
    y = 3,
    label = "Included index episode",
    hjust = 0,
    size = 4
  ) +

  # Included marker episode
  annotate(
    "segment",
    x = right_symbol_start,
    xend = right_symbol_end,
    y = 3,
    yend = 3,
    colour = "#19B5B9",
    linewidth = 2
  ) +

  annotate(
    "text",
    x = right_text,
    y = 3,
    label = "Included marker episode",
    hjust = 0,
    size = 4
  ) +

  # Excluded index episode
  annotate(
    "segment",
    x = left_symbol_start,
    xend = left_symbol_end,
    y = 2,
    yend = 2,
    colour = "#F8B6AE",
    linewidth = 2
  ) +

  annotate(
    "text",
    x = left_text,
    y = 2,
    label = "Excluded index episode",
    hjust = 0,
    size = 4
  ) +

  # Excluded marker episode
  annotate(
    "segment",
    x = right_symbol_start,
    xend = right_symbol_end,
    y = 2,
    yend = 2,
    colour = "#9DDDE0",
    linewidth = 2
  ) +

  annotate(
    "text",
    x = right_text,
    y = 2,
    label = "Excluded marker episode",
    hjust = 0,
    size = 4
  ) +

  # Start/end of observation
  annotate(
    "rect",
    xmin = left_symbol_start + 1.5,
    xmax = left_symbol_start + 3.5,
    ymin = 0.65,
    ymax = 1.35,
    fill = "grey40",
    colour = NA
  ) +

  annotate(
    "text",
    x = left_text,
    y = 1,
    label = "Start/end of observation",
    hjust = 0,
    size = 4
  ) +

  # Observation time
  annotate(
    "segment",
    x = right_symbol_start,
    xend = right_symbol_end,
    y = 1,
    yend = 1,
    colour = "grey25",
    linewidth = 0.8,
    linetype = "dashed"
  ) +

  annotate(
    "text",
    x = right_text,
    y = 1,
    label = "Observation time",
    hjust = 0,
    size = 4
  ) +

  scale_x_continuous(
    limits = c(0, 100),
    expand = expansion(mult = c(0, 0))
  ) +

  scale_y_continuous(
    limits = c(0.4, 3.6),
    expand = expansion(mult = c(0, 0))
  ) +

  theme_void() +

  theme(
    plot.margin = margin(5, 15, 5, 15)
  )

# ============================================================
# 11. Combine main figure and legend
# ============================================================

final_plot <- p / key +
  plot_layout(
    heights = c(4.5, 1.35)
  )

# ============================================================
# 12. Print final plot
# ============================================================

final_plot

ggsave(
  filename = "5-combinationWindow_numbers.png",
  plot = final_plot,
  width = 180,
  height = 150,
  units = "mm",
  dpi = 600,
  bg = "white"
)


######################################################
# ============================================================
# FIGURE 6
# Prior history + index-marker gap
# ============================================================

library(ggplot2)
library(dplyr)
library(tibble)
library(patchwork)

# ============================================================
# 1. Subjects and observation periods
# ============================================================

subjects <- 1:6

# Study period
study_start <- 10
study_end   <- 90

# Distance of index/marker lines from the subject ID
line_offset <- 0.12

# Height of grey observation-period blocks
block_height <- 0.32

# Amount to move inclusion ticks/cross upwards
tick_offset <- 0.08

# Prior history requirement
prior_history_requirement <- 31

# Index-marker gap criterion
index_marker_gap <- 30

# Index-marker gap colour
index_marker_gap_colour <- "#B8860B"

# ============================================================
# 2. Observation time
# ============================================================

obs <- bind_rows(

  # Index observation line
  data.frame(
    id = subjects,
    y = subjects - line_offset,
    xmin = c(0, 0, 20, 0, 22, 0),
    xmax = c(100, 85, 100, 76, 84, 100)
  ),

  # Marker observation line
  data.frame(
    id = subjects,
    y = subjects + line_offset,
    xmin = c(0, 0, 20, 0, 22, 0),
    xmax = c(100, 85, 100, 76, 84, 100)
  )
)

# ============================================================
# 3. Index periods
# ============================================================

index_periods <- bind_rows(

  # Subject 1
  data.frame(
    id = 1,
    xmin = 15,
    xmax = 22,
    included = TRUE
  ),

  data.frame(
    id = 1,
    xmin = 52,
    xmax = 64,
    included = FALSE
  ),

  # Subject 2
  data.frame(
    id = 2,
    xmin = 20,
    xmax = 27,
    included = TRUE
  ),

  # Subject 3
  data.frame(
    id = 3,
    xmin = 57,
    xmax = 70,
    included = TRUE
  ),

  data.frame(
    id = 3,
    xmin = 75,
    xmax = 80,
    included = FALSE
  ),

  # Subject 4
  data.frame(
    id = 4,
    xmin = 5,
    xmax = 18,
    included = FALSE
  ),

  # Subject 5
  data.frame(
    id = 5,
    xmin = 26,
    xmax = 39,
    included = TRUE
  ),

  data.frame(
    id = 5,
    xmin = 45,
    xmax = 57,
    included = FALSE
  ),

  # Subject 6
  data.frame(
    id = 6,
    xmin = 8,
    xmax = 19,
    included = FALSE
  ),

  data.frame(
    id = 6,
    xmin = 22,
    xmax = 27,
    included = TRUE
  )
) %>%
  mutate(
    y = id - line_offset
  )

# ============================================================
# 4. Marker periods
# ============================================================

marker_periods <- bind_rows(

  # Subject 1
  data.frame(
    id = 1,
    xmin = 25,
    xmax = 32,
    included = TRUE
  ),

  data.frame(
    id = 1,
    xmin = 78,
    xmax = 86,
    included = FALSE
  ),

  # Subject 2
  data.frame(
    id = 2,
    xmin = 40,
    xmax = 47,
    included = TRUE
  ),

  # Subject 3
  data.frame(
    id = 3,
    xmin = 26,
    xmax = 46,
    included = TRUE
  ),

  # Subject 4
  data.frame(
    id = 4,
    xmin = 32,
    xmax = 44,
    included = TRUE
  ),

  # Subject 5
  data.frame(
    id = 5,
    xmin = 61,
    xmax = 77,
    included = TRUE
  ),

  # Subject 6
  data.frame(
    id = 6,
    xmin = 40,
    xmax = 52,
    included = TRUE
  )
) %>%
  mutate(
    y = id + line_offset
  )

# Split included/excluded periods
included_index <- filter(index_periods, included)
excluded_index <- filter(index_periods, !included)

included_marker <- filter(marker_periods, included)
excluded_marker <- filter(marker_periods, !included)

# ============================================================
# 5. Function to draw an interval with end caps
# ============================================================

draw_interval <- function(data, colour, width = 4) {

  list(

    # Main horizontal line
    geom_segment(
      data = data,
      aes(
        x = xmin,
        xend = xmax,
        y = y,
        yend = y
      ),
      linewidth = width / 2,
      colour = colour,
      lineend = "butt",
      inherit.aes = FALSE
    ),

    # Left cap
    geom_segment(
      data = data,
      aes(
        x = xmin,
        xend = xmin,
        y = y - 0.09,
        yend = y + 0.09
      ),
      linewidth = 1.2,
      colour = colour,
      inherit.aes = FALSE
    ),

    # Right cap
    geom_segment(
      data = data,
      aes(
        x = xmax,
        xend = xmax,
        y = y - 0.09,
        yend = y + 0.09
      ),
      linewidth = 1.2,
      colour = colour,
      inherit.aes = FALSE
    )
  )
}

# ============================================================
# 6. Start and end of observation periods
# ============================================================

start_obs <- data.frame(
  id = c(3, 5),
  xmin = c(18, 20),
  xmax = c(20.5, 22.5),
  ymin = c(
    3 - block_height,
    5 - block_height
  ),
  ymax = c(
    3 + block_height,
    5 + block_height
  )
)

end_obs <- data.frame(
  id = c(2, 4, 5),
  xmin = c(82.5, 74.5, 82.5),
  xmax = c(85, 77, 85),
  ymin = c(
    2 - block_height,
    4 - block_height,
    5 - block_height
  ),
  ymax = c(
    2 + block_height,
    4 + block_height,
    5 + block_height
  )
)

# ============================================================
# 7. Split observation time into included/excluded segments
# ============================================================

split_observation <- function(data, study_start, study_end) {

  data %>%
    rowwise() %>%
    do({

      d <- .
      pieces <- list()

      # Before study period
      if (d$xmin < study_start) {

        pieces[[length(pieces) + 1]] <- data.frame(
          id = d$id,
          y = d$y,
          xmin = d$xmin,
          xmax = min(d$xmax, study_start),
          included = FALSE
        )
      }

      # During study period
      inside_start <- max(d$xmin, study_start)
      inside_end <- min(d$xmax, study_end)

      if (inside_start < inside_end) {

        pieces[[length(pieces) + 1]] <- data.frame(
          id = d$id,
          y = d$y,
          xmin = inside_start,
          xmax = inside_end,
          included = TRUE
        )
      }

      # After study period
      if (d$xmax > study_end) {

        pieces[[length(pieces) + 1]] <- data.frame(
          id = d$id,
          y = d$y,
          xmin = max(d$xmin, study_end),
          xmax = d$xmax,
          included = FALSE
        )
      }

      bind_rows(pieces)

    }) %>%
    ungroup()
}

obs_split <- split_observation(
  obs,
  study_start = study_start,
  study_end = study_end
)

included_obs <- filter(obs_split, included)
excluded_obs <- filter(obs_split, !included)

# ============================================================
# 8. Index-marker gap
# ============================================================

# The vignette example uses an index-marker gap of 10 days.
#
# Definition:
#
#   start of second episode - end of first episode
#
# Only participant 1 is considered here because participants
# 2-6 have already been excluded at earlier stages.
#
# The lines are intentionally slightly shorter than the
# physical gap so they do not overlap with the episode bars.

index_marker_gap_data <- bind_rows(

  # Index row
  data.frame(
    id = 1,
    xmin = 22.5,
    xmax = 24.5,
    y = 1 - line_offset
  ),

  # Marker row
  data.frame(
    id = 1,
    xmin = 22.5,
    xmax = 24.5,
    y = 1 + line_offset
  )
)

# ============================================================
# 9. Main figure
# ============================================================

p <- ggplot() +

  # ----------------------------------------------------------
# Excluded observation time
# ----------------------------------------------------------

geom_segment(
  data = excluded_obs,
  aes(
    x = xmin,
    xend = xmax,
    y = y,
    yend = y
  ),
  colour = "grey75",
  linewidth = 0.8,
  linetype = "dashed"
) +

  # ----------------------------------------------------------
# Included observation time
# ----------------------------------------------------------

geom_segment(
  data = included_obs,
  aes(
    x = xmin,
    xend = xmax,
    y = y,
    yend = y
  ),
  colour = "grey25",
  linewidth = 0.8,
  linetype = "dashed"
) +

  # ----------------------------------------------------------
# Start of observation period
# ----------------------------------------------------------

geom_rect(
  data = start_obs,
  aes(
    xmin = xmin,
    xmax = xmax,
    ymin = ymin,
    ymax = ymax
  ),
  fill = "grey40",
  colour = NA
) +

  # ----------------------------------------------------------
# End of observation period
# ----------------------------------------------------------

geom_rect(
  data = end_obs,
  aes(
    xmin = xmin,
    xmax = xmax,
    ymin = ymin,
    ymax = ymax
  ),
  fill = "grey40",
  colour = NA
) +

  # ----------------------------------------------------------
# Prior history: participant 3
# 35 days
# ----------------------------------------------------------

annotate(
  "segment",
  x = 21,
  xend = 26,
  y = 2.68,
  yend = 2.68,
  colour = "grey65",
  linewidth = 0.5
) +

  annotate(
    "segment",
    x = 21,
    xend = 21,
    y = 2.68,
    yend = 2.75,
    colour = "grey65",
    linewidth = 0.5
  ) +

  annotate(
    "segment",
    x = 26,
    xend = 26,
    y = 2.68,
    yend = 2.75,
    colour = "grey65",
    linewidth = 0.5
  ) +

  annotate(
    "text",
    x = 23.5,
    y = 2.50,
    label = "35",
    colour = "grey55",
    size = 2.7
  ) +

  # ----------------------------------------------------------
# Prior history: participant 5
# 15 days
# ----------------------------------------------------------

annotate(
  "segment",
  x = 22.75,
  xend = 26,
  y = 4.68,
  yend = 4.68,
  colour = "grey65",
  linewidth = 0.5
) +

  annotate(
    "segment",
    x = 22.75,
    xend = 22.75,
    y = 4.68,
    yend = 4.75,
    colour = "grey65",
    linewidth = 0.5
  ) +

  annotate(
    "segment",
    x = 26,
    xend = 26,
    y = 4.68,
    yend = 4.75,
    colour = "grey65",
    linewidth = 0.5
  ) +

  annotate(
    "text",
    x = 24.375,
    y = 4.50,
    label = "15",
    colour = "grey55",
    size = 2.7
  ) +

  # ----------------------------------------------------------
# Index periods
# ----------------------------------------------------------

draw_interval(
  included_index,
  "#F8766D",
  width = 4
) +

  draw_interval(
    excluded_index,
    "#F8B6AE",
    width = 4
  ) +

  # ----------------------------------------------------------
# Marker periods
# ----------------------------------------------------------

draw_interval(
  included_marker,
  "#19B5B9",
  width = 4
) +

  draw_interval(
    excluded_marker,
    "#9DDDE0",
    width = 4
  ) +

  # ----------------------------------------------------------
# Index-marker gap
# Mustard lines on both index and marker rows
# No endpoint bars
# ----------------------------------------------------------

geom_segment(
  data = index_marker_gap_data,
  aes(
    x = xmin,
    xend = xmax,
    y = y,
    yend = y
  ),
  colour = index_marker_gap_colour,
  linewidth = 1.1
) +

  # ----------------------------------------------------------
# Index-marker gap value
# Vignette example = 10
# ----------------------------------------------------------

annotate(
  "text",
  x = 23.5,
  y = 1.25,
  label = "10",
  colour = index_marker_gap_colour,
  size = 2.7
) +

  # ----------------------------------------------------------
# Inclusion checkmark
# Participant 1 remains included
# ----------------------------------------------------------

annotate(
  "text",
  x = 106,
  y = 1 - tick_offset,
  label = "\u2713",
  colour = "#7CB342",
  size = 8,
  fontface = "bold"
) +

  # ----------------------------------------------------------
# Exclusion crosses
# Participants 2-6
# ----------------------------------------------------------

annotate(
  "text",
  x = 106,
  y = c(2, 3, 4, 5, 6) - tick_offset,
  label = "\u2717",
  colour = "#D32F2F",
  size = 8,
  fontface = "bold"
) +

  # ----------------------------------------------------------
# Include heading
# ----------------------------------------------------------

annotate(
  "text",
  x = 106,
  y = 0.15,
  label = "Include",
  size = 4.5,
  fontface = "plain"
) +

  # ----------------------------------------------------------
# Outer boundaries
# ----------------------------------------------------------

geom_segment(
  aes(
    x = 0,
    xend = 0,
    y = 0.55,
    yend = 6.45
  ),
  linewidth = 0.8,
  colour = "grey15"
) +

  geom_segment(
    aes(
      x = 100,
      xend = 100,
      y = 0.55,
      yend = 6.45
    ),
    linewidth = 0.8,
    colour = "grey15"
  ) +

  # ----------------------------------------------------------
# Study-period boundaries
# ----------------------------------------------------------

geom_segment(
  aes(
    x = study_start,
    xend = study_start,
    y = 0.55,
    yend = 6.45
  ),
  linewidth = 0.8,
  colour = "grey55"
) +

  geom_segment(
    aes(
      x = study_end,
      xend = study_end,
      y = 0.55,
      yend = 6.45
    ),
    linewidth = 0.8,
    colour = "grey55"
  ) +

  # ----------------------------------------------------------
# Study-period labels
# ----------------------------------------------------------

annotate(
  "text",
  x = study_start,
  y = 6.90,
  label = "Start of the\nstudy period",
  hjust = 0.5,
  vjust = 0.5,
  colour = "grey55",
  size = 3.7
) +

  annotate(
    "text",
    x = study_end,
    y = 6.90,
    label = "End of the\nstudy period",
    hjust = 0.5,
    vjust = 0.5,
    colour = "grey55",
    size = 3.7
  ) +

  # ----------------------------------------------------------
# Axes
# ----------------------------------------------------------

scale_y_reverse(
  breaks = subjects,
  labels = subjects,
  limits = c(7.10, 0.00),
  expand = expansion(mult = c(0, 0))
) +

  scale_x_continuous(
    limits = c(0, 112),
    breaks = NULL,
    expand = expansion(mult = c(0, 0))
  ) +

  labs(
    x = NULL,
    y = "Individual"
  ) +

  theme_minimal(
    base_size = 14
  ) +

  theme(
    panel.grid = element_blank(),
    axis.title.x = element_blank(),
    axis.title.y = element_text(
      size = 14,
      margin = margin(r = 12)
    ),
    axis.text.y = element_text(size = 12),
    axis.text.x = element_blank(),
    axis.ticks = element_blank(),
    plot.margin = margin(15, 35, 35, 15)
  ) +

  coord_cartesian(
    xlim = c(0, 112),
    ylim = c(7.10, 0.00),
    clip = "off"
  ) +

  # Time label
  annotate(
    "text",
    x = 50,
    y = 7.02,
    label = "Time (Days)",
    size = 5
  )

# ============================================================
# 10. Legend
# ============================================================

left_symbol_start  <- 7
left_symbol_end    <- 12
left_text          <- 14

right_symbol_start <- 49
right_symbol_end   <- 54
right_text         <- 56

key <- ggplot() +

  # Included index episode
  annotate(
    "segment",
    x = left_symbol_start,
    xend = left_symbol_end,
    y = 3,
    yend = 3,
    colour = "#F8766D",
    linewidth = 2
  ) +

  annotate(
    "text",
    x = left_text,
    y = 3,
    label = "Included index episode",
    hjust = 0,
    size = 4
  ) +

  # Included marker episode
  annotate(
    "segment",
    x = right_symbol_start,
    xend = right_symbol_end,
    y = 3,
    yend = 3,
    colour = "#19B5B9",
    linewidth = 2
  ) +

  annotate(
    "text",
    x = right_text,
    y = 3,
    label = "Included marker episode",
    hjust = 0,
    size = 4
  ) +

  # Excluded index episode
  annotate(
    "segment",
    x = left_symbol_start,
    xend = left_symbol_end,
    y = 2,
    yend = 2,
    colour = "#F8B6AE",
    linewidth = 2
  ) +

  annotate(
    "text",
    x = left_text,
    y = 2,
    label = "Excluded index episode",
    hjust = 0,
    size = 4
  ) +

  # Excluded marker episode
  annotate(
    "segment",
    x = right_symbol_start,
    xend = right_symbol_end,
    y = 2,
    yend = 2,
    colour = "#9DDDE0",
    linewidth = 2
  ) +

  annotate(
    "text",
    x = right_text,
    y = 2,
    label = "Excluded marker episode",
    hjust = 0,
    size = 4
  ) +

  # Start/end of observation
  annotate(
    "rect",
    xmin = left_symbol_start + 1.5,
    xmax = left_symbol_start + 3.5,
    ymin = 0.65,
    ymax = 1.35,
    fill = "grey40",
    colour = NA
  ) +

  annotate(
    "text",
    x = left_text,
    y = 1,
    label = "Start/end of observation",
    hjust = 0,
    size = 4
  ) +

  # Observation time
  annotate(
    "segment",
    x = right_symbol_start,
    xend = right_symbol_end,
    y = 1,
    yend = 1,
    colour = "grey25",
    linewidth = 0.8,
    linetype = "dashed"
  ) +

  annotate(
    "text",
    x = right_text,
    y = 1,
    label = "Observation time",
    hjust = 0,
    size = 4
  ) +

  scale_x_continuous(
    limits = c(0, 100),
    expand = expansion(mult = c(0, 0))
  ) +

  scale_y_continuous(
    limits = c(0.4, 3.6),
    expand = expansion(mult = c(0, 0))
  ) +

  theme_void() +

  theme(
    plot.margin = margin(5, 15, 5, 15)
  )

# ============================================================
# 11. Combine main figure and legend
# ============================================================

final_plot <- p / key +
  plot_layout(
    heights = c(4.5, 1.35)
  )

# ============================================================
# 12. Print final plot
# ============================================================

final_plot


ggsave(
  filename = "6-indexGap.png",
  plot = final_plot,
  width = 180,
  height = 150,
  units = "mm",
  dpi = 600,
  bg = "white"
)



