library(dplyr)

# create an org with random values for each letter of the alphabet
set.seed(5678)

icb_params <- data.frame(
  org_code = LETTERS,
  base     = runif(length(LETTERS), 0.54, 0.62),
  slope    = runif(length(LETTERS), 0.01, 0.08),
  noise_sd = runif(length(LETTERS), 0.003, 0.03)
)

icb_dummy_data <-
  expand.grid(
    org_code = LETTERS,
    depr_num = 1:5
  ) |>
  left_join(
    icb_params,
    by = "org_code"
  ) |>
  mutate(
    date = as.Date("2026-01-01"),

    deprivation = c(
      "1 - most deprived",
      "2",
      "3",
      "4",
      "5 - least deprived"
    )[depr_num],

    sii_x = c(0.1, 0.3, 0.5, 0.7, 0.9)[depr_num],

    ed_prop =
      base +
      slope * sii_x +
      rnorm(n(), sd = noise_sd),

    ed_denom =
      round(
        runif(n(), 200, 2500)
      )
  ) |>
  select(
    date,
    org_code,
    deprivation,
    ed_prop,
    ed_denom
  )

usethis::use_data(icb_dummy_data, overwrite = TRUE)
