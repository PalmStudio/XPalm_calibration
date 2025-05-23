# A script to generate a design of experiment (DoE) for the Morris method
# using the parameters defined in the xpalm_parameters.csv file.

library(sensitivity)

df_raw_params <- read.csv("2-results/xpalm_parameters.csv", sep = ";")
df_raw_params <- df_raw_params[!is.na(as.numeric(df_raw_params$low_boundary)) & !is.na(as.numeric(df_raw_params$high_boundary)), ]

set.seed(1)
RNGkind(kind = "L'Ecuyer-CMRG")

etude.morris <- morris(
  model = NULL,
  factors = df_raw_params$variable,
  r = 30, # number of Morris trajectories
  design = list(type = "oat", levels = 10, grid.jump = 2),
  binf = df_raw_params$low_boundary,
  bsup = df_raw_params$high_boundary,
  scale = TRUE
)

write.csv(etude.morris$X, "2-results/doe.csv", row.names = FALSE)
