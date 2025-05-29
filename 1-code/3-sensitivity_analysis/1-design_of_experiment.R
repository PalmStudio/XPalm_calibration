# A script to generate a design of experiment (DoE) for the Morris method
# using the parameters defined in the xpalm_parameters.csv file.

library(sensitivity)

# Import the parameters with their boundaries. The boundaries are set either as
# +/- 50% of the original value, fixed for 0-1 parameters, or defined by the
# literature review)
df_raw_params <- read.csv("2-results/xpalm_parameters.csv", sep = ";")

# Remove the rows that have sensitivity = false, or that have no boundaries defined
df_raw_params <- df_raw_params[df_raw_params$sensitivity != "false" & !is.na(as.numeric(df_raw_params$low_boundary)) & !is.na(as.numeric(df_raw_params$high_boundary)), ]

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
