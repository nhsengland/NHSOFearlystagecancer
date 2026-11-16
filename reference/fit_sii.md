# Fits an individual SII model

A wrapper around [`lm()`](https://rdrr.io/r/stats/lm.html) intended as a
helper function for
[`derive_sii()`](https://nhsengland.github.io/NHSOFearlystagecancer/reference/derive_sii.md).
See that function for details on the scaled deprivation quintile and
weighting. This creates a regression model through weighted least
squares, and the SII is the resulting gradient of line.

## Usage

``` r
fit_sii(
  ed_data,
  ed_prop_col,
  sii_x_col = "sii_x",
  sii_weight_col = "sii_weight"
)
```

## Arguments

- ed_data:

  data.frame with columns specified by the following parameters:

- ed_prop_col:

  String name of column in `ed_data` for the early diagnosis proportion.

- sii_x_col:

  String name of the column in `ed_data` containing the scaled
  deprivation quintiles, by default denoted as `sii_x`.

- sii_weight_col:

  String name of the column in `ed_data` containing the weights for the
  model.

## Value

A linear model ([lm](https://rdrr.io/r/stats/lm.html)) object where the
Slope Index of Inequality is the coefficient of the `sii_x` variable.

## Details

Fit a line of the form \$\$ y = \alpha + \beta x_i + \epsilon_i \$\$

Which minimises: \$\$\sum{weights \* \epsilon^2}\$\$

Such that the SII is taken as \\\beta\\. Or more fully given the
expected inputs:

\$\$ \text{Early Diagnosis %} = \text{Intercept} + \text{SII} \*
\text{Scaled Deprivation} + \text{Error} \$\$
