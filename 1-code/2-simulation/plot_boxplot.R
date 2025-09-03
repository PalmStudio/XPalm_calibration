packs <- c("sensitivity", "lhs", "ggplot2", "dplyr", "ggrepel", "plotly", "data.table", "stringr")
InstIfNec <- function(pack) {
    if (!do.call(require, as.list(pack))) {
        do.call(install.packages, as.list(pack))
    }
    do.call(require, as.list(pack))
}
lapply(packs, InstIfNec)

library(ggplot2)
library(dplyr)
library(rstatix)
library(multcompView)
library(tidyr)
library(agricolae)

df_meteo_long_comb <- read.csv("2-results/meteorology/meteo_combined.csv") %>%
    select(site, MAP, Precipitations, Rg, Rh, T, Wind) %>%
    filter(MAP >= 0, MAP <= 100)

df_meteo_long_comb <- df_meteo_long_comb %>%
    pivot_longer(
        cols = c(Precipitations, Rg, Rh, T, Wind),
        names_to = "variable",
        values_to = "value"
    )

# Tukey
get_letters <- function(df, var_name) {
    df_sub <- df %>% filter(variable == var_name)
    model <- aov(value ~ site, data = df_sub)
    tukey <- HSD.test(model, "site", group = TRUE)

    out <- tukey$groups %>%
        mutate(
            site = rownames(.),
            variable = var_name
        )
    return(out)
}

letters_all <- lapply(
    unique(df_meteo_long_comb$variable),
    function(v) get_letters(df_meteo_long_comb, v)
) %>%
    bind_rows()

letters_all <- letters_all %>%
    rowwise() %>%
    mutate(y_pos = max(df_meteo_long_comb$value[df_meteo_long_comb$variable == variable &
        df_meteo_long_comb$site == site]) * 1.05)

site_colors <- c("PRESCO" = "darkblue", "SMSE" = "#ffc400", "TOWE" = "#327a32")

plot_and_save <- function(varname, title, ylabel) {
    df <- df_meteo_long_comb %>% filter(variable == varname)

    letters_df <- letters_all %>% filter(variable == varname)

    p <- ggplot(df, aes(x = site, y = value, fill = site)) +
        geom_boxplot(color = "black") + # black outlines for boxplots
        geom_text(
            data = letters_df,
            aes(x = site, y = y_pos, label = groups),
            inherit.aes = FALSE, size = 5
        ) +
        labs(
            title = title,
            x = "Site",
            y = ylabel
        ) +
        scale_fill_manual(values = site_colors) +
        theme_minimal() +
        theme(legend.position = "none")

    print(p)

    ggsave(
        filename = paste0("2-results/meteorology/boxplotR/", varname, "_boxplot.png"),
        plot = p, width = 7, height = 5
    )
}

plot_and_save("Precipitations", "Rainfall (mm)", "Average rainfall")
plot_and_save("T", "Temperature (°C)", "Average temperature")
plot_and_save("Rg", "Global Radiation (MJ/m²)", "Average global radiation")
plot_and_save("Rh", "Relative Humidity (%)", "Average relative humidity")
plot_and_save("Wind", "Wind (m/s)", "Average wind speed")


library(tidyverse)
library(agricolae)

# Load and filter data
df_meteo_long_comb <- read.csv("2-results/meteorology/meteo_combined.csv") %>%
    select(site, MAP, Precipitations, Rg, Rh, T, Wind) %>%
    filter(MAP >= 0, MAP <= 100) %>%
    pivot_longer(
        cols = c(Precipitations, Rg, Rh, T, Wind),
        names_to = "variable",
        values_to = "value"
    )

# Tukey test function
get_letters <- function(df, var_name) {
    df_sub <- df %>% filter(variable == var_name)
    model <- aov(value ~ site, data = df_sub)
    tukey <- HSD.test(model, "site", group = TRUE)

    out <- tukey$groups %>%
        mutate(
            site = rownames(.),
            variable = var_name
        )
    return(out)
}

# Run Tukey for all variables
letters_all <- lapply(
    unique(df_meteo_long_comb$variable),
    function(v) get_letters(df_meteo_long_comb, v)
) %>%
    bind_rows()

# Summary stats (mean & SE)
df_summary <- df_meteo_long_comb %>%
    group_by(site, variable) %>%
    summarise(
        mean = mean(value, na.rm = TRUE),
        se = sd(value, na.rm = TRUE) / sqrt(n()),
        .groups = "drop"
    )

# Colors
site_colors <- c("PRESCO" = "darkblue", "SMSE" = "#ffc400", "TOWE" = "#327a32")

# Plot function
plot_and_save <- function(varname, title, ylabel) {
    df <- df_meteo_long_comb %>% filter(variable == varname)
    df_sum <- df_summary %>% filter(variable == varname)
    letters_df <- letters_all %>% filter(variable == varname)

    p <- ggplot(df, aes(x = site, y = value, fill = site)) +
        geom_boxplot(color = "black", alpha = 0.6) + # boxplots
        geom_point(
            data = df_sum, aes(x = site, y = mean),
            color = "red", size = 3, shape = 18, inherit.aes = FALSE
        ) + # mean
        geom_errorbar(
            data = df_sum,
            aes(x = site, ymin = mean - se, ymax = mean + se),
            color = "red", width = 0.2, inherit.aes = FALSE
        ) + # SE
        geom_text(
            data = letters_df,
            aes(
                x = site,
                y = max(df$value[df$site == site], na.rm = TRUE) * 1.1,
                label = groups
            ),
            inherit.aes = FALSE, size = 5
        ) +
        labs(
            title = title,
            x = "Site",
            y = ylabel
        ) +
        scale_fill_manual(values = site_colors) +
        theme_minimal() +
        theme(legend.position = "none")

    print(p)

    ggsave(
        filename = paste0("2-results/meteorology/boxplotR/", varname, "_boxplot_meanSE.png"),
        plot = p, width = 7, height = 5
    )
}

# --- Example run ---
plot_and_save("Precipitations", "Rainfall (mm)", "Average rainfall")

# # Fix site names to lowercase to match your colors vector
# df_meteo_long_comb <- df_meteo_long_comb %>%
#     mutate(site = tolower(site))

# # Average by site and MAP
# avg_by_MAP <- df_meteo_long_comb %>%
#     group_by(site, MAP) %>%
#     summarise(
#         Precipitations = mean(Precipitations, na.rm = TRUE),
#         Rg = mean(Rg, na.rm = TRUE),
#         Rh = mean(Rh, na.rm = TRUE),
#         T = mean(T, na.rm = TRUE),
#         Wind = mean(Wind, na.rm = TRUE)
#     ) %>%
#     ungroup()

# # Convert to long format for plotting
# avg_long <- avg_by_MAP %>%
#     pivot_longer(
#         cols = c("Precipitations", "Rg", "Rh", "T", "Wind"),
#         names_to = "variable",
#         values_to = "avg_value"
#     )

# # Create output directory if not exists
# dir.create("2-results/meteorology/boxplotR", recursive = TRUE, showWarnings = FALSE)

# # Define site colors (keys lowercase)
# site_colors <- c("presco" = "#1f78b4", "smse" = "#ffd92f", "towe" = "#33a02c")

# # Plot and save function
# plot_and_save <- function(varname, title, ylabel) {
#     df <- avg_long %>% filter(variable == varname)

#     p <- ggplot(df, aes(x = site, y = avg_value, fill = site, color = site)) +
#         geom_boxplot() +
#         geom_jitter(width = 0.2, alpha = 0.6) +
#         labs(
#             title = title,
#             x = "Site",
#             y = ylabel
#         ) +
#         scale_fill_manual(values = site_colors) +
#         scale_color_manual(values = site_colors) +
#         theme_minimal() +
#         theme(legend.position = "none")

#     print(p)
#     ggsave(
#         filename = paste0("2-results/meteorology/boxplotR/", varname, "_boxplot.png"),
#         plot = p, width = 7, height = 5
#     )
# }

# # Run plots for each variable
# plot_and_save("Precipitations", "Rainfall (mm)", "Average rainfall")
# plot_and_save("T", "Temperature (°C)", "Average temperature")
# plot_and_save("Rg", "Global Radiation (MJ/m²)", "Average global radiation")
# plot_and_save("Rh", "Relative Humidity (%)", "Average relative humidity")
# plot_and_save("Wind", "Wind (m/s)", "Average wind speed")
