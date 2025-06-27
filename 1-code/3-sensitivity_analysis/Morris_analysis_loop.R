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
df_raw_params <- read.csv("2-results/xpalm_parameters.csv", sep = ";")
df_raw_params <- df_raw_params[df_raw_params$sensitivity != "false" & !is.na(as.numeric(df_raw_params$low_boundary)) & !is.na(as.numeric(df_raw_params$high_boundary)), ]

## import outputs
res1_all <- fread("2-results/sensitivity/simulations_on_doe.csv")

SITE <- c("smse", "towe", "presco")
var <- colnames(res1_all)[-1]

all_res <- NULL
for (s in SITE) {
  for (v in var) {
    res <- res1_all %>%
      filter(site == s) %>%
      mutate(!!v := ifelse(is.na(.data[[v]]), 0, .data[[v]])) %>%
      arrange(doe) %>%
      mutate(y = .data[[v]]) %>%
      data.frame()


    out_res1_all <- tell(etude.morris, y = as.numeric(res$y))


    res_out_res1 <- data.frame(t(out_res1_all$ee))
    don_res1 <- data.frame(
      parameter = df_raw_params$variable,
      mu = apply(X = res_out_res1, MARGIN = 1, mean),
      mu_star = apply(
        X = abs(res_out_res1),
        MARGIN = 1, mean
      ),
      sd = apply(X = res_out_res1, MARGIN = 1, sd)
    )

    don_res1$category <- sub("\\|.*", "", df_raw_params$variable) # add the category based on the first branch of parameter
    don_res1$params <- str_extract(df_raw_params$variable, "[^|]+\\|[^|]+$") # add the 2 last branches of the parameter
    don_res1$Site <- s
    don_res1$var <- v
    all_res <- rbind(all_res, don_res1)
  }
}

# loop graphs
vars_list <- unique(all_res$var)
for (variables in vars_list) {
  data_plot <- all_res %>% filter(var == variables)

  p <- ggplot(data_plot, aes(x = mu_star, y = sd, color = category)) +
    geom_point() +
    geom_text_repel(
      aes(label = params),
      size = 3,
      data = data_plot %>% filter(mu_star > 0.0)
    ) +
    facet_grid(. ~ Site) +
    labs(x = "mu_star", y = "sd", title = paste("Sensitivity Analysis Results for", variables)) +
    theme(legend.position = "bottom")

  ggsave(
    filename = paste0("2-results/sensitivity/loop/plot_", variables, ".png"),
    plot = p,
    width = 20,
    height = 9,
    units = "in",
    dpi = 300
  )
}

# extract the column the first highest sd for each site and variable
sensitive_parameters <- all_res %>%
  group_by(Site, var) %>%
  slice_max(order_by = sd, n = 5, with_ties = FALSE) %>%
  ungroup() %>%
  arrange(var, Site, desc(sd)) %>% # this arranges nicely
  select(var, params, Site, category)
write.csv(sensitive_parameters, "2-results/sensitivity/sensitive_parameters.csv", row.names = FALSE)

# list fix list of sensitive parameters from params list among al sites, but delete if it is repeated
fix_sensitive_params <- sensitive_parameters %>%
  group_by(var) %>%
  select(params, category) %>%
  distinct() %>%
  arrange(var)
write.csv(fix_sensitive_params, "2-results/sensitivity/fix_sensitive_params.csv", row.names = FALSE)
