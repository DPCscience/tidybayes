# Tests for ungather_draws
#
# Author: mjskay
###############################################################################

import::from(dplyr, `%>%`, inner_join, data_frame)
import::from(purrr, map_df)
library(tidyr)

context("ungather_draws")


test_that("ungather_draws works on a simple parameter with no dimensions", {
  data(RankCorr, package = "tidybayes")

  ref = data_frame(
      .chain = as.integer(1),
      .iteration = seq_len(nrow(RankCorr[[1]])),
      .draw = seq_len(nrow(RankCorr[[1]])),
      typical_r = as.vector(RankCorr[[1]][, "typical_r"])
    ) %>%
    bind_rows(data_frame(
      .chain = as.integer(2),
      .iteration = seq_len(nrow(RankCorr[[2]])),
      .draw = nrow(RankCorr[[2]]) + seq_len(nrow(RankCorr[[2]])),
      typical_r = as.vector(RankCorr[[2]][, "typical_r"])
    ))

  RankCorr %>%
    gather_draws(typical_r) %>%
    ungather_draws(typical_r) %>%
    expect_equal(ref)

  RankCorr %>%
    gather_draws(typical_r, b[i, j]) %>%
    ungather_draws(typical_r) %>%
    expect_equal(ref)
})


test_that("ungather_draws works on multiple parameters with different dimensions", {
  data(RankCorr, package = "tidybayes")

  result = RankCorr %>%
    gather_draws(b[i, j], c(u_tau, tau)[i]) %>%
    ungather_draws(b[i, j], c(u_tau, tau)[i])

  ref = RankCorr %>%
    tidy_draws() %>%
    select(.chain, .iteration, .draw, starts_with("b"), starts_with("tau"), starts_with("u_tau"))

  expect_equal(result[, order(names(result))], ref[, order(names(ref))])
})


test_that("ungather_draws(drop_indices = TRUE) drops draw indices", {
  data(RankCorr, package = "tidybayes")

  result = RankCorr %>%
    gather_draws(b[i, j], c(u_tau, tau)[i]) %>%
    ungather_draws(b[i, j], c(u_tau, tau)[i], drop_indices = TRUE)

  ref = RankCorr %>%
    tidy_draws() %>%
    select(starts_with("b"), starts_with("tau"), starts_with("u_tau"))

  expect_equal(result[, order(names(result))], ref[, order(names(ref))])
})


test_that("ungather_draws does not support wide dimension syntax (`|`)", {
  expect_error(ungather_draws(data.frame(), b[i ,j] | i),
    'ungather_draws does not support the wide dimension syntax \\(`\\|`\\).')
})

test_that("ungather_draws works with user-specified names", {
  data(line, package = "coda")

  ref = line %>%
    tidy_draws()

  result = line %>%
    gather_draws(alpha, beta, sigma) %>%
    to_broom_names() %>%
    ungather_draws(alpha, beta, sigma, variable = "term", value = "estimate")

  expect_equal(result, ref)
})

