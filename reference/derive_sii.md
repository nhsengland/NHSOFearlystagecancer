# Create Slope Index of Inequality (SII) for Deprivation Gap metric

Create the deprivation gap, a percentage point difference in early
diagnosis (ED) proportion, between the most and least deprived extremes
as a Slope Index of Inequality. This can be applied across any number of
other factors as specified with the `by` argument e.g., across ICBs and
reporting period. Note that the input early diagnosis proportion, and
the output SII proportions, are on the scale of 0 to 1, so you will want
to multiply the output `sii` by 100 for most presentation purposes.

## Usage

``` r
derive_sii(ed_data, by, ed_prop_col, ed_denom_col, depr_col)
```

## Arguments

- ed_data:

  A [data.frame](https://rdrr.io/r/base/data.frame.html) with columns
  containing:

  - The [numeric](https://rdrr.io/r/base/numeric.html) early diagnosis
    proportion on the scale of 0 to 1.

  - The [integer](https://rdrr.io/r/base/integer.html) number of staged
    cases, the denominator of early diagnosis proportion.

  - The [character](https://rdrr.io/r/base/character.html) string
    deprivation quintile.

  - Any other columns to group the data by.

- by:

  A [character](https://rdrr.io/r/base/character.html) vector naming
  columns in `ed_data` to group the data by, expected to be the
  reporting period and the geography.

- ed_prop_col:

  The [character](https://rdrr.io/r/base/character.html) string name of
  the column in `ed_data` for the early diagnosis proportion.

- ed_denom_col:

  The [character](https://rdrr.io/r/base/character.html) string name of
  the column in `ed_data` for the early diagnosis proportion denominator
  i.e., number of staged cases.

- depr_col:

  The [character](https://rdrr.io/r/base/character.html) string name of
  the column in `ed_data` specifying deprivation quintiles across which
  to measure inequality. The required labels are "1 - most deprived",
  "2", "3", "4", and "5 - least deprived".

## Value

A data.frame with all columns specified in `by`, as well as values for
the columns below for each of the groupings across `by`. This function
use of nested data / list columns to keep the data and models grouped
together. The main output is the `sii` column which contains the
deprivation gap value.

- data:

  List of [data.frame](https://rdrr.io/r/base/data.frame.html):
  containing ED figures and anything else in input `ed_data`

- sii_model:

  List of [lm](https://rdrr.io/r/stats/lm.html): The full models as fit
  on `data`.

- sii_summary:

  List of [summary.lm](https://rdrr.io/r/stats/summary.lm.html):
  [`summary()`](https://rdrr.io/r/base/summary.html) of models in
  `sii_model`

- sii_coeffs:

  List of [numeric](https://rdrr.io/r/base/numeric.html)
  [matrix](https://rdrr.io/r/base/matrix.html):
  [`coefficients()`](https://rdrr.io/r/stats/coef.html) of the
  `sii_model`

- sii_confint:

  List of [numeric](https://rdrr.io/r/base/numeric.html)
  [matrix](https://rdrr.io/r/base/matrix.html): with 95% confidence
  intervals of coefficients of `sii_model`

- sii:

  [Numeric](https://rdrr.io/r/base/numeric.html): SII value, taken as
  the gradient of the `sii_model`

- sii_std_err:

  [Numeric](https://rdrr.io/r/base/numeric.html): Standard error of
  `sii`

- sii_lci_95:

  [Numeric](https://rdrr.io/r/base/numeric.html): Lower 95% confidence
  interval for `sii`

- sii_uci_95:

  [Numeric](https://rdrr.io/r/base/numeric.html): Upper 95% confidence
  interval for `sii`

## Details

The calculations are done as follows:

1.  Scale deprivation quintile groups between 0 and 1. Each quintile is
    assigned to the midpoint of the proportion of the population it
    represents. For example, the first 20%, quintile 1, is placed at 0.1
    (or 10%)

2.  Compute inverse variance of a binomial proportion to use as
    weighting for each subgroup. For deprivation quintile *i*, its
    weighting \\w_i\\ is calculated from its early diagnosis proportion
    \\p_i\\, and count of staged cases \\n_i\\ as:

    \$\$w_i = \frac{n_i}{p_i(1 - p_i)}\$\$

    Note the reason early diagnosis is required as a proportion between
    0 and 1 is for flow in calculating this weighting.

3.  Build the weighted linear regression models for each group specified
    in `by`, through applying helper function
    [`fit_sii()`](https://nhsengland.github.io/NHSOFearlystagecancer/reference/fit_sii.md).
    The linear model uses scaled deprivation quintile predicting early
    diagnosis proportion, weighted by the inverse variance.

4.  Take the SII as the coefficient of the scaled deprivation quintiles.
    That is, by scaling from 0 to 1, the gradient of the slope gives us
    the entire deprivation gap.

## See also

[`score_sii()`](https://nhsengland.github.io/NHSOFearlystagecancer/reference/score_sii.md)
to follow with calculating the NHSOF group score.

## Examples

``` r
example_df <- data.frame(
  date = rep(as.Date("2026-02-01"), 5),
  icb_code = rep("ABC", 5),
  deprivation = c("1 - most deprived", "2", "3", "4", "5 - least deprived"),
  ed_prop = c(0.55, 0.58, 0.595, 0.606, 0.619),
  ed_denom = c(39546, 43663, 48796, 51117, 50739)
)

example_result <- derive_sii(
  example_df,
  by = c("date", "icb_code"),
  ed_prop_col = "ed_prop",
  ed_denom_col = "ed_denom",
  depr_col = "deprivation"
)

example_result[1, "sii"]
#> # A tibble: 1 × 1
#>      sii
#>    <dbl>
#> 1 0.0804
```
