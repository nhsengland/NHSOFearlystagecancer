# Score the deprivation gap SII

Assigns the NHS Oversight Framework deprivation gap score (1-4) based on
the Slope Index of Inequality (SII) relative to the mean SII for a
comparison group, that is all ICBs across England.

## Usage

``` r
score_sii(sii_tbl, by, sii_col = "sii", std_err_col = "sii_std_err")
```

## Arguments

- sii_tbl:

  A [data.frame](https://rdrr.io/r/base/data.frame.html) containing SII
  estimates and standard errors for all comparison-groups. For the
  Oversight Framework this must be all ICBs in England.

- by:

  A [character](https://rdrr.io/r/base/character.html) vector of
  grouping columns over which the comparison mean SII should be
  calculated e.g., reporting date.

- sii_col:

  A [character](https://rdrr.io/r/base/character.html) string, with the
  name of the column containing SII estimates. The default "sii" works
  with the result of
  [`derive_sii()`](https://nhsengland.github.io/NHSOFearlystagecancer/reference/derive_sii.md).

- std_err_col:

  A [character](https://rdrr.io/r/base/character.html) string, with the
  name of the column containing SII standard errors. The default
  "sii_std_err" works with the result of
  [`derive_sii()`](https://nhsengland.github.io/NHSOFearlystagecancer/reference/derive_sii.md).

## Value

The input data frame with additional columns:

- sii_mean:

  [numeric](https://rdrr.io/r/base/numeric.html) mean SII within each
  grouping.

- sii_score:

  [integer](https://rdrr.io/r/base/integer.html) NHS Oversight Framework
  score (1-4).

## Details

Scores are determined using the SII estimate and its associated standard
error. The standard error reflects the statistical uncertainty in the
estimated deprivation gap and is influenced by both the strength of the
relationship between deprivation and early diagnosis and the number of
underlying cancer cases.

The scoring bands are:

- **1**: Strong evidence for a smaller-than-average deprivation gap.
  More than 2 standard errors below the comparison-group mean SII.

- **2**: Some evidence for a smaller-than-average deprivation gap.
  Between 1 and 2 standard errors below the comparison-group mean SII.

- **3**: No evidence for a smaller-than-average deprivation gap. Within
  1 standard error of the comparison-group mean SII.

- **4**: Evidence for a larger-than-average deprivation gap. More than 1
  standard error above the comparison-group mean SII.

## Examples

``` r

example_df <- data.frame(
  date = rep(as.Date("2026-02-01"), 5),
  icb_code = rep("ABC", 5),
  deprivation = c("1 - most deprived", "2", "3", "4", "5 - least deprived"),
  ed_prop = c(0.55, 0.58, 0.595, 0.606, 0.619),
  ed_denom = c(39546, 43663, 48796, 51117, 50739)
)

example_result <- example_df |>
  derive_sii(
    by = c("date", "icb_code"),
    ed_prop_col = "ed_prop",
    ed_denom_col = "ed_denom",
    depr_col = "deprivation"
  ) |>
  score_sii(by = "date")

example_result[, c("icb_code", "sii", "sii_std_err", "sii_score")]
#> # A tibble: 1 × 4
#>   icb_code    sii sii_std_err sii_score
#>   <chr>     <dbl>       <dbl>     <int>
#> 1 ABC      0.0804      0.0103         3
```
