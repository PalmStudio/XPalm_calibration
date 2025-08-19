# this code is used to plot the sensitivity analysis of morris method's results with the heatmap of most sensitive parameters for each variables among sites#

# please run first the 2-simulation.jl
packs <- c("sensitivity", "lhs", "ggplot2", "dplyr", "ggrepel", "plotly", "data.table", "stringr")
InstIfNec <- function(pack) {
    if (!do.call(require, as.list(pack))) {
        do.call(install.packages, as.list(pack))
    }
    do.call(require, as.list(pack))
}
lapply(packs, InstIfNec)

# Read input data
# res1_all <- fread("2-results/sensitivity/simulations_on_doe.csv")
res1_all <- fread("2-results/sensitivity/simulations_on_doe.csv") # run 1-code/3-sensitivity_analysis/2-simulation.jl
SITE <- c("smse", "towe", "presco")
var <- colnames(res1_all)[-1] # assuming 'doe' is the first column

# Load Morris design and parameter definitions
load("2-results/sensitivity/etude_morris.RData") # run 1-code/3-sensitivity_analysis/1-design_of_experiment.R
df_raw_params <- read.csv("2-results/xpalm_parameters.csv", sep = ";") %>%
    filter(sensitivity != "false") %>%
    filter(!is.na(as.numeric(low_boundary)), !is.na(as.numeric(high_boundary)))

# Compute Morris mu_star and organize results
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
            mu = apply(res_out_res1, 1, mean),
            mu_star = apply(abs(res_out_res1), 1, mean),
            sd = apply(res_out_res1, 1, sd)
        )

        don_res1$category <- sub("\\|.*", "", df_raw_params$variable) # main branch
        don_res1$params <- str_extract(df_raw_params$variable, "[^|]+\\|[^|]+$") # last two branches
        don_res1$Site <- s
        don_res1$var <- v

        all_res <- bind_rows(all_res, don_res1)
    }
}

# Average yield ton/ha/year
var_check <- c("average_yield_3_to_6", "average_yield_6_to_9", "average_yield_9_to_12")
short_labels <- c("age 3 - 6", "age 6 - 9", "age 9 - 12")
names(short_labels) <- var_check # map original var names

site_check <- c("presco", "smse", "towe")
df_all <- data.frame()

# Normalize mu_star and compute ranks
for (v in var_check) {
    for (s in site_check) {
        morris_result <- all_res %>%
            filter(var == v, Site == s) %>%
            select(parameter, category, mu_star) %>%
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

# Extract top 10 per site and variable
df_10 <- df_all %>%
    group_by(site, var) %>%
    slice_max(order_by = composite_index, n = 10, with_ties = FALSE) %>%
    ungroup()

# Add label column instead of modifying 'var'
df_10 <- df_10 %>%
    mutate(var_label = short_labels[var]) # shorter x labels

# Ensure proper factor level ordering for x-axis
var_labels <- short_labels[var_check]
df_10$var_label <- factor(df_10$var_label, levels = short_labels)

# Plot with rectangular horizontal tiles
map_all <- ggplot(df_10, aes(x = var_label, y = parameter, fill = composite_index)) +
    geom_tile(color = "white", width = 1.0, height = 0.4) +
    geom_text(aes(label = round(composite_index, 2)), size = 3) +
    scale_fill_gradient2(
        low = "blue", mid = "white", high = "darkred",
        midpoint = 0.5, limits = c(0, 1),
        name = expression(mu[rel])
    ) +
    labs(
        x = "Average yield (t/ha/year)",
        y = "Parameter",
        title = "Sensitive parameters"
    ) +
    facet_wrap(~site, scales = "free_y") +
    theme_minimal(base_size = 11) +
    theme(
        axis.text.x = element_text(size = 10, angle = 0, vjust = 0.5),
        axis.text.y = element_text(size = 5),
        panel.grid = element_blank(),
        strip.text = element_text(face = "bold", size = 12)
    )

# Save the fixed
ggsave(
    # filename = "2-results/sensitivity/heatmap_average_leaf_area_edit_presco.png",
    filename = "2-results/sensitivity//heatmap/1.heatmap_average_yield_in_range.png",
    plot = map_all,
    bg = "white",
    width = 12,
    height = 6,
    dpi = 300
)

# Cumulated yield
var_cumulated_yield <- c("cumulated_yield")
label_cum_yield <- c("cumulated_yield" = "")
names(label_cum_yield)
site <- c("presco", "smse", "towe")
df_cumulated_yield <- data.frame()

# Normalize mu_star and compute ranks
for (v in var_cumulated_yield) {
    for (s in site) {
        morris_result <- all_res %>%
            filter(var == v, Site == s) %>%
            select(parameter, category, mu_star) %>%
            mutate(
                composite_index = (mu_star - min(mu_star, na.rm = TRUE)) /
                    (max(mu_star, na.rm = TRUE) - min(mu_star, na.rm = TRUE)),
                var = v,
                site = s
            ) %>%
            arrange(desc(composite_index)) %>%
            mutate(rank = row_number())

        df_cumulated_yield <- bind_rows(df_cumulated_yield, morris_result)
    }
}

# Extract top 10 per site and variable
df_10_cumulated_yield <- df_cumulated_yield %>%
    group_by(site, var) %>%
    slice_max(order_by = composite_index, n = 10, with_ties = FALSE) %>%
    ungroup()

# Add label column instead of modifying 'var'
df_10_cumulated_yield <- df_10_cumulated_yield %>%
    mutate(var_label = label_cum_yield[var]) # shorter x labels

# Plot with rectangular horizontal tiles
map_all <- ggplot(df_10_cumulated_yield, aes(x = var_label, y = parameter, fill = composite_index)) +
    geom_tile(color = "white", width = 1.0, height = 0.4) +
    geom_text(aes(label = round(composite_index, 2)), size = 3) +
    scale_fill_gradient2(
        low = "blue", mid = "white", high = "darkred",
        midpoint = 0.5, limits = c(0, 1),
        name = expression(mu[rel])
    ) +
    labs(
        x = "Cumulated yield",
        y = "Parameter",
        title = "Sensitive parameters"
    ) +
    facet_wrap(~site, scales = "free_y") +
    theme_minimal(base_size = 11) +
    theme(
        # axis.text.x = element_text(size = 10, angle = 0, vjust = 0.5),
        # axis.text.y = element_text(size = 5),
        panel.grid = element_blank(),
        strip.text = element_text(face = "bold", size = 12)
    )

# Save the fixed
ggsave(
    filename = "2-results/sensitivity//heatmap/1.heatmap_cumulated yield.png",
    plot = map_all,
    bg = "white",
    width = 12,
    height = 6,
    dpi = 300
)


# average leaf area
var_check <- c("average_leaf_area_3_to_6", "average_leaf_area_6_to_9", "average_leaf_area_9_to_12")
short_labels <- c("age 3 - 6", "age 6 - 9", "age 9 - 12")
names(short_labels) <- var_check # map original var names

site_check <- c("presco", "smse", "towe")
df_all <- data.frame()

# Normalize mu_star and compute ranks
for (v in var_check) {
    for (s in site_check) {
        morris_result <- all_res %>%
            filter(var == v, Site == s) %>%
            select(parameter, category, mu_star) %>%
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

# Extract top 10 per site and variable
df_10 <- df_all %>%
    group_by(site, var) %>%
    slice_max(order_by = composite_index, n = 10, with_ties = FALSE) %>%
    ungroup()

# Add label column instead of modifying 'var'
df_10 <- df_10 %>%
    mutate(var_label = short_labels[var]) # shorter x labels

# Ensure proper factor level ordering for x-axis
var_labels <- short_labels[var_check]
df_10$var_label <- factor(df_10$var_label, levels = short_labels)

# Plot with rectangular horizontal tiles
map_all <- ggplot(df_10, aes(x = var_label, y = parameter, fill = composite_index)) +
    geom_tile(color = "white", width = 1.0, height = 0.4) +
    geom_text(aes(label = round(composite_index, 2)), size = 3) +
    scale_fill_gradient2(
        low = "blue", mid = "white", high = "darkred",
        midpoint = 0.5, limits = c(0, 1),
        name = expression(mu[rel])
    ) +
    labs(
        x = "Average leaf area",
        y = "Parameter",
        title = "Most sensitive parameters among sites"
    ) +
    facet_wrap(~site, scales = "free_y") +
    theme_minimal(base_size = 11) +
    theme(
        axis.text.x = element_text(size = 10, angle = 0, vjust = 0.5),
        axis.text.y = element_text(size = 5),
        panel.grid = element_blank(),
        strip.text = element_text(face = "bold", size = 12)
    )

# Save the fixed
ggsave(
    # filename = "2-results/sensitivity/heatmap_average_leaf_area_edit_presco.png",
    filename = "2-results/sensitivity//heatmap/2.heatmap_average_leaf_area.png",
    plot = map_all,
    bg = "white",
    width = 12,
    height = 6,
    dpi = 300
)

# transpiration
var_check <- c("transpiration_3_to_6", "transpiration_6_to_9", "transpiration_9_to_12")
short_labels <- c("age 3 - 6", "age 6 - 9", "age 9 - 12")
names(short_labels) <- var_check # map original var names

site_check <- c("presco", "smse", "towe")
df_all <- data.frame()

# Normalize mu_star and compute ranks
for (v in var_check) {
    for (s in site_check) {
        morris_result <- all_res %>%
            filter(var == v, Site == s) %>%
            select(parameter, category, mu_star) %>%
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

# Extract top 10 per site and variable
df_10 <- df_all %>%
    group_by(site, var) %>%
    slice_max(order_by = composite_index, n = 10, with_ties = FALSE) %>%
    ungroup()

# Add label column instead of modifying 'var'
df_10 <- df_10 %>%
    mutate(var_label = short_labels[var]) # shorter x labels

# Ensure proper factor level ordering for x-axis
var_labels <- short_labels[var_check]
df_10$var_label <- factor(df_10$var_label, levels = short_labels)

# Plot with rectangular horizontal tiles
map_all <- ggplot(df_10, aes(x = var_label, y = parameter, fill = composite_index)) +
    geom_tile(color = "white", width = 1.0, height = 0.4) +
    geom_text(aes(label = round(composite_index, 2)), size = 3) +
    scale_fill_gradient2(
        low = "blue", mid = "white", high = "darkred",
        midpoint = 0.5, limits = c(0, 1),
        name = expression(mu[rel])
    ) +
    labs(
        x = "Transpiration",
        y = "Parameter",
        title = "Sensitive parameters"
    ) +
    facet_wrap(~site, scales = "free_y") +
    theme_minimal(base_size = 11) +
    theme(
        axis.text.x = element_text(size = 10, angle = 0, vjust = 0.5),
        axis.text.y = element_text(size = 5),
        panel.grid = element_blank(),
        strip.text = element_text(face = "bold", size = 12)
    )

# Save the fixed
ggsave(
    # filename = "2-results/sensitivity/heatmap_average_leaf_area_edit_presco.png",
    filename = "2-results/sensitivity//heatmap/3.transpiration.png",
    plot = map_all,
    bg = "white",
    width = 12,
    height = 6,
    dpi = 300
)


# quantity of water
var_check <- c("max_qty_H2O_C_Roots", "max_ftsw", "min_qty_H2O_C_Roots", "min_ftsw")
short_labels <- c("max water", "max ftsw", "min water", "min ftsw")
names(short_labels) <- var_check # map original var names

site_check <- c("presco", "smse", "towe")
df_all <- data.frame()

# Normalize mu_star and compute ranks
for (v in var_check) {
    for (s in site_check) {
        morris_result <- all_res %>%
            filter(var == v, Site == s) %>%
            select(parameter, category, mu_star) %>%
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

# Extract top 10 per site and variable
df_10 <- df_all %>%
    group_by(site, var) %>%
    slice_max(order_by = composite_index, n = 10, with_ties = FALSE) %>%
    ungroup()

# Add label column instead of modifying 'var'
df_10 <- df_10 %>%
    mutate(var_label = short_labels[var]) # shorter x labels

# Ensure proper factor level ordering for x-axis
var_labels <- short_labels[var_check]
df_10$var_label <- factor(df_10$var_label, levels = short_labels)

# Plot with rectangular horizontal tiles
map_all <- ggplot(df_10, aes(x = var_label, y = parameter, fill = composite_index)) +
    geom_tile(color = "white", width = 1.0, height = 0.4) +
    geom_text(aes(label = round(composite_index, 2)), size = 3) +
    scale_fill_gradient2(
        low = "blue", mid = "white", high = "darkred",
        midpoint = 0.5, limits = c(0, 1),
        name = expression(mu[rel])
    ) +
    labs(
        x = "Soil water",
        y = "Parameter",
        title = "Sensitive parameters"
    ) +
    facet_wrap(~site, scales = "free_y") +
    theme_minimal(base_size = 11) +
    theme(
        axis.text.x = element_text(size = 10, angle = 0, vjust = 0.5),
        axis.text.y = element_text(size = 5),
        panel.grid = element_blank(),
        strip.text = element_text(face = "bold", size = 12)
    )

# Save the fixed
ggsave(
    # filename = "2-results/sensitivity/heatmap_average_leaf_area_edit_presco.png",
    filename = "2-results/sensitivity//heatmap/3. Soil water.png",
    plot = map_all,
    bg = "white",
    width = 15,
    height = 6,
    dpi = 300
)


# reproductive organ (n male, n female)
var_check <- c("average_n_bunches_harvested_3_to_6", "average_n_bunches_harvested_6_to_9", "average_n_bunches_harvested_9_to_12", "n_males")
short_labels <- c("age 3 - 6", "age 6 - 9", "age 9 - 12", "n males")
names(short_labels) <- var_check # map original var names

site_check <- c("presco", "smse", "towe")
df_all <- data.frame()

# Normalize mu_star and compute ranks
for (v in var_check) {
    for (s in site_check) {
        morris_result <- all_res %>%
            filter(var == v, Site == s) %>%
            select(parameter, category, mu_star) %>%
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

# Extract top 10 per site and variable
df_10 <- df_all %>%
    group_by(site, var) %>%
    slice_max(order_by = composite_index, n = 10, with_ties = FALSE) %>%
    ungroup()

# Add label column instead of modifying 'var'
df_10 <- df_10 %>%
    mutate(var_label = short_labels[var]) # shorter x labels

# Ensure proper factor level ordering for x-axis
var_labels <- short_labels[var_check]
df_10$var_label <- factor(df_10$var_label, levels = short_labels)

# Plot with rectangular horizontal tiles
map_all <- ggplot(df_10, aes(x = var_label, y = parameter, fill = composite_index)) +
    geom_tile(color = "white", width = 1.0, height = 0.4) +
    geom_text(aes(label = round(composite_index, 2)), size = 3) +
    scale_fill_gradient2(
        low = "blue", mid = "white", high = "darkred",
        midpoint = 0.5, limits = c(0, 1),
        name = expression(mu[rel])
    ) +
    labs(
        x = "Number of reproductive organ",
        y = "Parameter",
        title = "Sensitive parameters"
    ) +
    facet_wrap(~site, scales = "free_y") +
    theme_minimal(base_size = 11) +
    theme(
        axis.text.x = element_text(size = 10, angle = 0, vjust = 0.5),
        axis.text.y = element_text(size = 5),
        panel.grid = element_blank(),
        strip.text = element_text(face = "bold", size = 12)
    )

# Save the fixed
ggsave(
    # filename = "2-results/sensitivity/heatmap_average_leaf_area_edit_presco.png",
    filename = "2-results/sensitivity//heatmap/4.number female and male.png",
    plot = map_all,
    bg = "white",
    width = 15,
    height = 6,
    dpi = 300
)
