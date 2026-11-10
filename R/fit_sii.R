#' Fits the SII's weighted least squares regression model
#'
#' A wrapper around [lm()] intended as a helper function for
#' [derive_deprivation_gap()]. See that function for details on the scaled
#' deprivation quintile and weighting. The SII is the gradient of line.
#'
#' @details
#'
#' Fit a line of the form
#' \deqn{
#'   y = \alpha + \beta x_i + \epsilon_i
#' }
#'
#' Which minimises:
#' \deqn{\sum{weights * \epsilon^2}}
#'
#' Such that the SII is taken as \eqn{\beta}. Or more fully given the expected
#' inputs:
#'
#' \deqn{
#'  \text{Early Diagnosis %} = \text{Intercept} + \text{SII} * \text{Scaled
#'  Deprivation} + \text{Error}
#' }
#'
#'
#' @param ed_data data.frame with columns specified by the following parameters:
#;
#' @param ed_prop_col String name of column in `ed_data` for the early diagnosis
#'   proportion.
#'
#' @param sii_x_col String name of the column in `ed_data` containing the scaled
#'   deprivation quintiles, by default denoted as `sii_x`.
#'
#' @param sii_weight_col String name of the column in `ed_data` containing the
#'   weights for the model.
#'
#' @return
#' A linear model ([lm]) object where the Slope Index of Inequality is the
#' coefficient of the `sii_x` variable.
#'
#' @importFrom stats as.formula lm
fit_sii <- function(ed_data,
                    ed_prop_col,
                    sii_x_col = "sii_x",
                    sii_weight_col = "sii_weight") {
  # Validation ----
  stopifnot( is.data.frame(ed_data) )

  stopifnot( sii_x_col %in% names(ed_data) )
  stopifnot( sii_weight_col %in% names(ed_data) )

  stopifnot( is.character(ed_prop_col) )
  stopifnot( ed_prop_col %in% names(ed_data) )

  # Model ----
  form <- as.formula(paste(ed_prop_col, "~ ", sii_x_col))

  lm(form, data = ed_data, weights = ed_data[[sii_weight_col]])
}
