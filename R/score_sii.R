#' Score the deprivation gap SII
#'
#' Assigns the NHS Oversight Framework deprivation gap score (1-4) based on the
#' Slope Index of Inequality (SII) relative to the mean SII for a comparison
#' group, that is all ICBs across England.
#'
#' Scores are determined using the SII estimate and its associated standard
#' error. The standard error reflects the statistical uncertainty in the
#' estimated deprivation gap and is influenced by both the strength of the
#' relationship between deprivation and early diagnosis and the number of
#' underlying cancer cases.
#'
#' The scoring bands are:
#'
#' \itemize{
#'   \item \strong{1}: Strong evidence for a smaller-than-average deprivation
#'   gap. More than 2 standard errors below the comparison-group mean SII.
#'
#'   \item \strong{2}: Some evidence for a smaller-than-average deprivation gap.
#'   Between 1 and 2 standard errors below the comparison-group mean SII.
#'
#'   \item \strong{3}: No evidence for a smaller-than-average deprivation gap.
#'   Within 1 standard error of the comparison-group mean SII.
#'
#'   \item \strong{4}: Evidence for a larger-than-average deprivation gap.
#'   More than 1 standard error above the comparison-group mean SII.
#' }
#'
#' @param sii_tbl A [data.frame] containing SII estimates and standard errors
#'   for all comparison-groups. For the Oversight Framework this must be all
#'   ICBs in England.
#' @param by A [character] vector of grouping columns over which the comparison
#'   mean SII should be calculated e.g., reporting date.
#' @param sii_col A [character] string, with the name of the column containing
#'   SII estimates. The default "sii" works with the result of [derive_sii()].
#' @param std_err_col A [character] string, with the name of the column
#'   containing SII standard errors. The default "sii_std_err" works with the
#'   result of [derive_sii()].
#'
#' @return
#' The input data frame with additional columns:
#' \describe{
#'   \item{sii_mean}{[numeric] mean SII within each grouping.}
#'   \item{sii_score}{[integer] NHS Oversight Framework score (1-4).}
#' }
#'
#' @export
#'
#' @examples
#'
#' example_df <- data.frame(
#'   date = rep(as.Date("2026-02-01"), 5),
#'   icb_code = rep("ABC", 5),
#'   deprivation = c("1 - most deprived", "2", "3", "4", "5 - least deprived"),
#'   ed_prop = c(0.55, 0.58, 0.595, 0.606, 0.619),
#'   ed_denom = c(39546, 43663, 48796, 51117, 50739)
#' )
#'
#' example_result <- example_df |>
#'   derive_sii(
#'     by = c("date", "icb_code"),
#'     ed_prop_col = "ed_prop",
#'     ed_denom_col = "ed_denom",
#'     depr_col = "deprivation"
#'   ) |>
#'   score_sii(by = "date")
#'
#' example_result[, c("icb_code", "sii", "sii_std_err", "sii_score")]
score_sii <- function(sii_tbl,
                      by,
                      sii_col = "sii",
                      std_err_col = "sii_std_err") {

  sii_tbl |>
    dplyr::mutate(
      sii_mean = mean(.data[[sii_col]], na.rm = TRUE),
      .by = dplyr::all_of(by)
    ) |>
    dplyr::mutate(
      sii_score = dplyr::case_when(
        .data[[sii_col]] <= sii_mean - (2 * .data[[std_err_col]]) ~ 1L,

        .data[[sii_col]] <= sii_mean - .data[[std_err_col]] &
          .data[[sii_col]] > sii_mean - (2 * .data[[std_err_col]]) ~ 2L,

        .data[[sii_col]] <= sii_mean + .data[[std_err_col]] &
          .data[[sii_col]] > sii_mean - .data[[std_err_col]] ~ 3L,

        .data[[sii_col]] > sii_mean + .data[[std_err_col]] ~ 4L
      )
    )
}
