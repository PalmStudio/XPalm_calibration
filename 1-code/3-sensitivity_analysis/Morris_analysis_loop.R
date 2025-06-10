### result simulation_copy.jl -> res_1

packs <- c("sensitivity", "lhs", "ggplot2", "dplyr", "ggrepel", "plotly", "data.table", "stringr")
InstIfNec <- function(pack) {
  if (!do.call(require, as.list(pack))) {
    do.call(install.packages, as.list(pack))
  }
  do.call(require, as.list(pack))
}
lapply(packs, InstIfNec)


load("2-results/sensitivity/etude_morris.RData")

## import outputs
res1_all <- fread("2-results/sensitivity/simulations_copy_test_all.csv")

SITE <- c("smse", "towe", "presco")
var <- "average_bunch_biomass_3_to_6"

all_res <- NULL
for (s in SITE) {
  for (v in var) {
    resSMSE <- res1_all %>%
      filter(site == s) %>%
      mutate(average_bunch_biomass_3_to_6 = ifelse(is.na(average_bunch_biomass_3_to_6), 0, average_bunch_biomass_3_to_6)) %>%
      arrange(doe) %>%
      mutate(y = get(v)) %>%
      data.frame()


    out_res1_all <- tell(etude.morris, y = as.numeric(resSMSE$y))


    res_out_res1 <- data.frame(t(out_res1_all$ee))
    don_res1 <- data.frame(parameter = df_raw_params$variable, mu = apply(X = res_out_res1, MARGIN = 1, mean), mu_star = apply(X = abs(res_out_res1), MARGIN = 1, mean), sd = apply(X = res_out_res1, MARGIN = 1, sd))

    don_res1$category <- sub("\\|.*", "", df_raw_params$variable) # add the category based on the first branch of parameter
    don_res1$params <- str_extract(df_raw_params$variable, "[^|]+\\|[^|]+$") # add the 2 last branches of the parameter
    don_res1$Site <- s
    don_res1$var <- v
    all_res <- rbind(all_res, don_res1)
  }
}

### ----graphs

all_res %>%
  ggplot(aes(x = mu_star, y = sd, color = category)) +
  geom_point() +
  geom_text_repel(
    data = subset(all_res, mu_star > 0.0),
    aes(label = params)
  ) +
  facet_grid(Site ~ var) +
  labs(x = "mu_star", y = "sd", title = "Sensitivity Analysis Results") +
  theme(legend.position = "bottom")
