#' Add SII plots to SII results
#'
#' Creates a ggplot visualisation for each row of a data frame produced by
#' [derive_sii()]. Each plot shows the observed early diagnosis proportions for
#' the five deprivation quintiles together with the fitted weighted regression
#' line used to calculate the Slope Index of Inequality (SII).
#'
#' Point size is proportional to the number of staged cancer cases within each
#' deprivation quintile, illustrating the weighting applied during regression.
#' The fitted line represents the relationship between deprivation and early
#' cancer diagnosis from which the SII is derived.
#'
#' The function adds a new list-column named `plot` containing a ggplot object
#' for each organisation or grouping.
#'
#' @param sii_tbl A data frame returned by [derive_sii()]. Must contain the
#'   columns `data` (nested deprivation-quintile data) and `sii_model`
#'   (fitted weighted regression model).
#' @param id Character string giving the column to use as the plot title.
#'
#' @return
#' The input data frame with an additional `plot` [list] column containing one
#' [ggplot] object per row.
#'
#' @export
#'
#' @importFrom dplyr mutate
#' @importFrom purrr pmap
#' @importFrom stats coef
#'
#' @examples
#' example_df <- data.frame(
#'   date = rep(as.Date("2026-02-01"), 5),
#'   org_code = rep("ABC", 5),
#'   deprivation = c(
#'     "1 - most deprived", "2", "3", "4", "5 - least deprived"
#'   ),
#'   ed_prop = c(0.55, 0.58, 0.595, 0.606, 0.619),
#'   ed_denom = c(39546, 43663, 48796, 51117, 50739)
#' )
#'
#' example_result <- example_df |>
#'   derive_sii(
#'     by = c("date", "org_code"),
#'     ed_prop_col = "ed_prop",
#'     ed_denom_col = "ed_denom",
#'     depr_col = "deprivation"
#'   ) |>
#'   plot_sii(id = "org_code")
#'
#' # View the generated plot
#' example_result$plot[[1]]
plot_sii <- function(sii_tbl, id) {

  all_ed_prop <- unlist(purrr::map(sii_tbl$data, "ed_prop")) * 100
  all_ed_denom <- unlist(purrr::map(sii_tbl$data, "ed_denom"))

  y_limits <- range(pretty(all_ed_prop))
  y_breaks <- pretty(all_ed_prop)
  size_max <- max(all_ed_denom)

  sii_tbl |>
    dplyr::mutate(
      plot = purrr::pmap(
        list(
          data,
          sii_model,
          .data[[id]]
        ),
        function(dat, mod, group_name) {

          ggplot2::ggplot(
            dat,
            ggplot2::aes(sii_x, ed_prop * 100)
          ) +
            ggplot2::geom_point(
              ggplot2::aes(size = ed_denom),
              shape = 16,
              color = "#003087"
            ) +
            ggplot2::geom_abline(
              intercept = stats::coef(mod)[1] * 100,
              slope = stats::coef(mod)[2] * 100,
              colour = "orange",
              linewidth = 1
            ) +
            ggplot2::labs(
              title = group_name,
              x = "Scaled Deprivation Quintile",
              y = "ED proportion (%)",
              size = "Number of cases"
            ) +
            ggplot2::scale_x_continuous(
              limits = c(0, 1),
              breaks = c(0, 0.1, 0.3, 0.5, 0.7, 0.9, 1),
              expand = c(0, 0)
            ) +
            ggplot2::scale_y_continuous(
              limits = y_limits,
              breaks = y_breaks
            ) +
            ggplot2::scale_size_area(
              max_size = 10,
              limits = c(0, size_max)
            ) +
            ggplot2::theme_minimal()

        }
      )
    )
}
