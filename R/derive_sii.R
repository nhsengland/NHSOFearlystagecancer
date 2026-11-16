#' Create Slope Index of Inequality (SII) for Deprivation Gap metric
#'
#' Create the deprivation gap, a percentage point difference in early diagnosis
#' (ED) proportion, between the most and least deprived extremes as a Slope
#' Index of Inequality. This can be applied across any number of other factors
#' as specified with the `by` argument e.g., across ICBs and reporting period.
#' Note that the input early diagnosis proportion, and the output SII
#' proportions, are on the scale of 0 to 1, so you will want to multiply the
#' output `sii` by 100 for most presentation purposes.
#'
#' @details
#' The calculations are done as follows:
#'
#' \enumerate{
#' \item Scale deprivation quintile groups between 0 and 1. Each quintile is
#' assigned to the midpoint of the proportion of the population it represents.
#' For example, the first 20%, quintile 1, is placed at 0.1 (or 10%)
#'
#' \item Compute inverse variance of a binomial proportion to use as weighting
#' for each subgroup. For deprivation quintile _i_, its weighting \eqn{w_i} is
#' calculated from its early diagnosis proportion \eqn{p_i}, and count of staged
#' cases \eqn{n_i} as:
#'
#' \deqn{w_i = \frac{n_i}{p_i(1 - p_i)}}
#'
#' Note the reason early diagnosis is required as a proportion between 0 and 1
#' is for flow in calculating this weighting.
#'
#' \item Build the weighted linear regression models for each group specified in
#' `by`, through applying helper function [fit_sii()]. The linear model uses
#' scaled deprivation quintile predicting early diagnosis proportion, weighted
#' by the inverse variance.
#'
#' \item Take the SII as the coefficient of the scaled deprivation quintiles.
#' That is, by scaling from 0 to 1, the gradient of the slope gives us the
#' entire deprivation gap.
#' }
#'
#' @param ed_data A [data.frame] with columns containing:
#'  - The [numeric] early diagnosis proportion on the scale of 0 to 1.
#'  - The [integer] number of staged cases, the denominator of early diagnosis proportion.
#'  - The [character] string deprivation quintile.
#'  - Any other columns to group the data by.
#'
#' @param by A [character] vector naming columns in `ed_data` to group the data
#'   by, expected to be the reporting period and the geography.
#'
#' @param ed_prop_col The [character] string name of the column in `ed_data` for
#'   the early diagnosis proportion.
#' @param ed_denom_col The [character] string name of the column in `ed_data`
#'   for the early diagnosis proportion denominator i.e., number of staged
#'   cases.
#' @param depr_col The [character] string name of the column in `ed_data`
#'   specifying deprivation quintiles across which to measure inequality. The
#'   required labels are "1 - most deprived", "2", "3", "4", and "5 - least
#'   deprived".
#'
#' @return A data.frame with all columns specified in `by`, as well as values
#'   for the columns below for each of the groupings across `by`. This function
#'   use of nested data / list columns to keep the data and models grouped
#'   together. The main output is the `sii` column which
#'   contains the deprivation gap value.
#'
#' \describe{
#'   \item{data}{List of [data.frame]: containing ED figures and anything
#'     else in input `ed_data`}
#'   \item{sii_model}{List of [lm]: The full models as fit on `data`.}
#'   \item{sii_summary}{List of [summary.lm]: [summary()] of models in `sii_model`}
#'   \item{sii_coeffs}{List of [numeric] [matrix]: [coefficients()] of the
#'   `sii_model`}
#'   \item{sii_confint}{ List of [numeric] [matrix]: with 95% confidence intervals of
#'    coefficients of `sii_model`}
#'   \item{sii}{[Numeric]: SII value, taken as the gradient of the `sii_model`}
#'   \item{sii_std_err}{[Numeric]: Standard error of `sii`}
#'   \item{sii_lci_95}{[Numeric]: Lower 95% confidence interval for `sii`}
#'   \item{sii_uci_95}{[Numeric]: Upper 95% confidence interval for `sii`}
#' }
#'
#' @seealso [score_sii()] to follow with calculating the NHSOF group score.
#'
#' @examples
#' example_df <- data.frame(
#'   date = rep(as.Date("2026-02-01"), 5),
#'   icb_code = rep("ABC", 5),
#'   deprivation = c("1 - most deprived", "2", "3", "4", "5 - least deprived"),
#'   ed_prop = c(0.55, 0.58, 0.595, 0.606, 0.619),
#'   ed_denom = c(39546, 43663, 48796, 51117, 50739)
#' )
#'
#' example_result <- derive_sii(
#'   example_df,
#'   by = c("date", "icb_code"),
#'   ed_prop_col = "ed_prop",
#'   ed_denom_col = "ed_denom",
#'   depr_col = "deprivation"
#' )
#'
#' example_result[1, "sii"]
#'
#' @export
#' @importFrom dplyr mutate arrange all_of .data
#' @importFrom tidyr nest
#' @importFrom purrr map map_dbl
#' @importFrom stats confint
derive_sii <- function(ed_data,
                       by,
                       ed_prop_col,
                       ed_denom_col,
                       depr_col) {
  # 0. Validation ----

  stopifnot( is.data.frame(ed_data) )

  stopifnot( is.character(by) )
  stopifnot( all(by %in% names(ed_data)) )

  stopifnot( is.character(ed_prop_col) )
  stopifnot( ed_prop_col %in% names(ed_data) )

  stopifnot( is.character(ed_denom_col) )
  stopifnot( ed_denom_col %in% names(ed_data) )

  stopifnot( is.character(depr_col) )
  stopifnot( depr_col %in% names(ed_data) )

  stopifnot( is.numeric(ed_data[[ed_prop_col]]) )

  if ( !all(ed_data[[ed_prop_col]] >= 0 & ed_data[[ed_prop_col]] <= 1) ) {
    stop("Early diagnosis proportions must be on the 0 to 1 scale")
  }

  stopifnot( is.numeric(ed_data[[ed_denom_col]]))

  # 1. Apply scaled SII x-values ----

  # Scaled between 0 and 1 such that the slope will represent change in
  # proportion.

  # Scaled such that the given ED proportion is treated as an average of the
  # group. Where each quintile represents 20% of the population nationally,
  # the corresponding early diagnosis value is represented at 0.1 or 10%
  # SII is able to represent more extremely disadvantaged/advantaged
  # individuals--and presents a larger gap--than simple difference in ED% from
  # quintile 1 to quintile 5.

  sii_x_lookup <- c(
    "1 - most deprived"  = 0.1,
    "2"                  = 0.3,
    "3"                  = 0.5,
    "4"                  = 0.7,
    "5 - least deprived" = 0.9
  )

  ed_data <- ed_data |>
    mutate(sii_x = sii_x_lookup[ .data[[depr_col]] ]) |>
    arrange(sii_x)

  # 2. Compute inverse var weighting ----

  # Inverse of binomial proportion sample variance
  # 1 / var, where var = p(1 - p) / n

  ed_data <- ed_data |>
    mutate(
      p_times_1_minus_p = .data[[ed_prop_col]] * (1 - .data[[ed_prop_col]]),
      # inverse: n / p(1 - p)
      sii_weight = .data[[ed_denom_col]] / p_times_1_minus_p
    )

  # 3. Create linear models ----

  # Working with list columns to store more complex objects:

  # Collapse data for each grouping into a list column `data`
  # Create a list column of a linear model per grouping, fit on its data with
  # fit_sii()

  ed_data <- ed_data |>
    nest(.by = all_of(by)) |>
    mutate(sii_model = map(data, \(df) fit_sii(df, ed_prop_col = ed_prop_col)))

  # 4. Extract coefficients ----

  # Draw out values from the list of models
  # The SII value is the gradient of the scaled sii_x values

  ed_data <- ed_data |>
    mutate(
      sii_summary = map(sii_model, summary),
      sii_coeffs  = map(sii_summary, "coefficients"),
      sii_confint = map(sii_model, confint),

      sii         = map_dbl(sii_coeffs, \(x) x["sii_x", "Estimate"]),
      sii_std_err = map_dbl(sii_coeffs, \(x) x["sii_x", "Std. Error"]),

      sii_lci_95  = map_dbl(sii_confint, \(x) x["sii_x", "2.5 %"]),
      sii_uci_95  = map_dbl(sii_confint, \(x) x["sii_x", "97.5 %"])
    )

  ed_data
}
