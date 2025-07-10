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

res1_all <- fread("2-results/sensitivity/simulations_on_doe.csv") # original
# res2_all <- fread("2-results/sensitivity/simulations_on_doe_presco_2.csv") # multiple 2 iwnd presco
# res1_all <- fread("2-results/sensitivity/simulations_on_doe_presco_2.csv") # replace the wind by the correspond month after
# res1_all <- fread("2-results/sensitivity/simulations_on_doe_presco_4.csv") # replace the all climate by the correspond month after

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
    filename = paste0("2-results/sensitivity/loop/plot_", variables, ".png"), # loop5 is all the climate is replace by following month, loop is the original
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
  slice_max(order_by = mu_star, n = 5, with_ties = FALSE) %>%
  ungroup() %>%
  arrange(var, Site, desc(mu_star)) %>% # this arranges nicely
  select(var, params, Site, category)
write.csv(sensitive_parameters, "2-results/sensitivity/sensitive_parameters_mu_star.csv", row.names = FALSE)

# list fix list of sensitive parameters from params list among al sites, but delete if it is repeated
fix_sensitive_params <- sensitive_parameters %>%
  group_by(var) %>%
  select(params, category) %>%
  distinct() %>%
  arrange(var)
write.csv(fix_sensitive_params, "2-results/sensitivity/fix_sensitive_params_mu_star.csv", row.names = FALSE)



# make the heatmap
var_check <- c("cumulated_yield", "average_leaf_area_3_to_6", "average_bunch_weight_9_to_12")
site_check <- c("presco", "smse", "towe")
df_all <- data.frame()

# Loop through variables and sites to build full table
for (v in var_check) {
  for (s in site_check) {
    morris_result <- all_res %>%
      filter(var == v, Site == s) %>%
      select(parameter, params, mu_star) %>%
      mutate(
        composite_index = (mu_star - min(mu_star, na.rm = TRUE)) /
          (max(mu_star, na.rm = TRUE) - min(mu_star, na.rm = TRUE)),
        var = v,
        site = s
      ) %>%
      arrange(desc(composite_index)) %>%
      mutate(rank = row_number())

    df_all <- bind_rows(df_all, morris_result)
  }
}

# Loop again to plot and save per variable
for (v in var_check) {
  df_10 <- df_all %>%
    filter(var == v) %>%
    group_by(site) %>%
    filter(rank <= 10) %>%
    ungroup()

  map_v <- ggplot(df_10, aes(x = site, y = parameter, fill = composite_index)) +
    geom_tile(color = "white") +
    geom_text(aes(label = round(composite_index, 2)), size = 3) +
    scale_fill_gradient2(
      low = "blue", mid = "white", high = "darkred",
      midpoint = 0.5, limits = c(0, 1),
      name = "Composite\nIndex"
    ) +
    labs(
      x = "Site",
      y = "Parameter",
      title = paste("Top 10 Composite Sensitivity Index -", v)
    ) +
    theme_minimal(base_size = 11) +
    theme(
      axis.text.x = element_text(angle = 45, hjust = 1),
      panel.grid = element_blank(),
      strip.text = element_text(face = "bold")
    )

  ggsave(
    filename = paste0("2-results/sensitivity/heatmap_", v, ".png"),
    plot = map_v,
    bg = "white",
    width = 10,
    height = 6,
    dpi = 300
  )
}


# check how the effect is shows negative or positive?

res1_all <- fread("2-results/sensitivity/simulations_on_doe.csv")
res2_all <- fread("2-results/sensitivity/simulations_on_doe_presco_2.csv")

doe_table <- read.csv("2-results/sensitivity/doe.csv")
doe_table$doe <- 1:nrow(doe_table)

for (v in var_check) {
  res_filter <- res2_all %>%
    filter(site %in% site_check) %>%
    select(doe, site, all_of(v)) %>%
    left_join(doe_table %>% select(doe, `water.thickness_1`), by = "doe") %>%
    mutate(doe = factor(doe)) %>%
    filter(!is.na(water.thickness_1) & !is.na(.data[[v]]))

  p1 <- ggplot(res_filter, aes(x = water.thickness_1, y = .data[[v]])) +
    geom_point(color = "darkgreen") +
    geom_smooth(method = "lm", color = "red", linetype = "dashed") +
    geom_text_repel(aes(label = doe), size = 3, max.overlaps = 20) +
    facet_wrap(~site, scales = "free_y") +
    labs(
      title = paste("Effect of water|thickness_1 on", v, "(Increased Wind)"),
      x = "water|thickness_1",
      y = v
    ) +
    theme_minimal()

  ggsave(
    filename = paste0("2-results/sensitivity/plot_effect_faceted_", v, "_increase_wind.png"),
    plot = p1,
    bg = "white",
    width = 12,
    height = 6,
    units = "in",
    dpi = 300
  )

  # Original (no increased wind)
  res_filter_2 <- res1_all %>%
    filter(site %in% site_check) %>%
    select(doe, site, all_of(v)) %>%
    left_join(doe_table %>% select(doe, `water.thickness_1`), by = "doe") %>%
    mutate(doe = factor(doe)) %>%
    filter(!is.na(water.thickness_1) & !is.na(.data[[v]]))

  p2 <- ggplot(res_filter_2, aes(x = water.thickness_1, y = .data[[v]])) +
    geom_point(color = "darkgreen") +
    geom_smooth(method = "lm", color = "red", linetype = "dashed") +
    geom_text_repel(aes(label = doe), size = 3, max.overlaps = 20) +
    facet_wrap(~site, scales = "free_y") +
    labs(
      title = paste("Effect of water|thickness_1 on", v, "(Original Wind)"),
      x = "thickness_1",
      y = v
    ) +
    theme_minimal()

  ggsave(
    filename = paste0("2-results/sensitivity/plot_effect_faceted_", v, "_ori_wind.png"),
    plot = p2,
    bg = "white",
    width = 12,
    height = 6,
    units = "in",
    dpi = 300
  )
}
