"""
Plot all the meteo datasets from 3 sites (actual period and added by nursery period), which will be use as an input for the xpalm simulation
"""

using XPalm, DataFrames, YAML, CSV
using CairoMakie, AlgebraOfGraphics, Colors

#plot the actual climate conditions of the three sites

meteo_smse = CSV.read("2-results/meteorology/meteo_smse_cleaned.csv", missingstring=["NA", "NaN"], DataFrame)  #Indonesia
meteo_towe = CSV.read("2-results/meteorology/meteo_towe_cleaned.csv", missingstring=["NA", "NaN"], DataFrame) #Benin
meteo_presco = CSV.read("2-results/meteorology/meteo_presco_cleaned.csv", missingstring=["NA", "NaN"], DataFrame) #Nigeria


sites = Dict(
    "SMSE" => meteo_smse,
    "PRESCO" => meteo_presco,
    "TOWE" => meteo_towe,
)

df_meteo_long = DataFrame()

for (sitename, df) in sites
    temp_df = copy(df)
    temp_df.site = fill(sitename, nrow(temp_df))
    df_meteo_long = vcat(df_meteo_long, temp_df; cols=:union)
end

#plot Temperature
temp_vars = [:T, :Tmin, :Tmax]
temp_stacked = stack(df_meteo_long, temp_vars; variable_name=:variable, value_name=:value)
plt_temp = data(temp_stacked) *
           mapping(:date, :value, color=:site, row=:variable) *
           visual(Lines)
fig_plt_temp = draw(plt_temp; figure=(; title="Temperature"))
save("2-results/meteorology/plot_temperature.png", fig_plt_temp)


#plot Humidity
hum_vars = [:Rh, :Rh_min, :Rh_max]
hum_stacked = stack(df_meteo_long, hum_vars; variable_name=:variable, value_name=:value)
plt_hum = data(hum_stacked) *
          mapping(:date, :value, color=:site, row=:variable) *
          visual(Lines)
fig_plt_hum = draw(plt_hum; figure=(; title="Humidity"))
save("2-results/meteorology/plot_humidity.png", fig_plt_hum)

#plot Radiation
rad_vars = [:Ri_PAR_f, :Rg]
rad_stacked = stack(df_meteo_long, rad_vars; variable_name=:variable, value_name=:value)
plt_rad = data(rad_stacked) *
          mapping(:date, :value, color=:site, row=:variable) *
          visual(Lines)
fig_plt_rad = draw(plt_rad; figure=(; title="Radiation"))
save("2-results/meteorology/plot_radiation.png", fig_plt_rad)

#plot precipitations
prec_vars = [:Precipitations]
prec_stacked = stack(df_meteo_long, prec_vars; variable_name=:variable, value_name=:value)
plt_prec = data(prec_stacked) *
           mapping(:date, :value, color=:site, row=:variable) *
           visual(Lines)
fig_plt_prec = draw(plt_prec; figure=(; title="Precipitations"))
save("2-results/meteorology/plot_precipitations.png", fig_plt_prec)

#plot wind
wind_vars = [:Wind]
wind_stacked = stack(df_meteo_long, wind_vars; variable_name=:variable, value_name=:value)
plt_wind = data(wind_stacked) *
           mapping(:date, :value, color=:site, row=:variable) *
           visual(Lines)
fig_plt_wind = draw(plt_wind; figure=(; title="Wind"))
save("2-results/meteorology/plot_wind.png", fig_plt_wind)


#plot the climate conditions depending on the nursery and planting of the three sites
meteo_comb_smse = CSV.read("2-results/meteorology/meteo_smse_with_nursery.csv", missingstrings=["NA", "NaN"], DataFrame)  # Indonesia
meteo_comb_towe = CSV.read("2-results/meteorology/meteo_towe_with_nursery.csv", missingstrings=["NA", "NaN"], DataFrame)  # Benin
meteo_comb_presco = CSV.read("2-results/meteorology/meteo_presco_with_nursery.csv", missingstrings=["NA", "NaN"], DataFrame)  # Nigeria

sites_comb = Dict(
    "SMSE" => meteo_comb_smse,
    "PRESCO" => meteo_comb_presco,
    "TOWE" => meteo_comb_towe,
)

df_meteo_long_comb = DataFrame()

for (sitename, df) in sites_comb
    temp_df = copy(df)
    temp_df.site = fill(sitename, nrow(temp_df))
    df_meteo_long_comb = vcat(df_meteo_long_comb, temp_df; cols=:union)
end

#plot Temperature
temp_vars = [:T, :Tmin, :Tmax]
temp_stacked_comb = stack(df_meteo_long_comb, temp_vars; variable_name=:variable, value_name=:value)
temp_stacked_comb.site_group = ifelse.(temp_stacked_comb.site .== "nursery", "nursery", string.(temp_stacked_comb.site))
temp_stacked_comb.period = coalesce.(temp_stacked_comb.period, "planting")  # Fill missing period values if any
plt_temp_comb_MAP = data(temp_stacked_comb) *
                    mapping(:MAP, :value, color=:site_group, linestyle=:period, row=:variable) *
                    visual(Lines)
fig_temp_comb_MAP = draw(plt_temp_comb_MAP; figure=(; title="Temperature with nursery"), axis=(; ylabel="°C"))
save("2-results/meteorology/plot_temperature_by_MAP.png", fig_temp_comb_MAP)

#plot Humidity
hum_vars = [:Rh, :Rh_min, :Rh_max]
hum_stacked_comb = stack(df_meteo_long_comb, hum_vars; variable_name=:variable, value_name=:value)
hum_stacked_comb.site_group = ifelse.(hum_stacked_comb.site .== "nursery", "nursery", string.(hum_stacked_comb.site))
hum_stacked_comb.period = coalesce.(hum_stacked_comb.period, "planting")  # Fill missing period values if any
plt_hum_comb_MAP = data(hum_stacked_comb) *
                   mapping(:MAP, :value, color=:site_group, linestyle=:period, row=:variable) *
                   visual(Lines)
fig_hum_comb_MAP = draw(plt_hum_comb_MAP; figure=(; title="Humidity with nursery"), axis=(; ylabel="%"))
save("2-results/meteorology/plot_humidity_by_MAP.png", fig_hum_comb_MAP)

#plot Radiation
rad_vars = [:Ri_PAR_f, :Rg]
rad_stacked_comb = stack(df_meteo_long_comb, rad_vars; variable_name=:variable, value_name=:value)
rad_stacked_comb.site_group = ifelse.(rad_stacked_comb.site .== "nursery", "nursery", string.(rad_stacked_comb.site))
rad_stacked_comb.period = coalesce.(rad_stacked_comb.period, "planting")  # Fill missing period values if any
plt_rad_comb_MAP = data(rad_stacked_comb) *
                   mapping(:MAP, :value, color=:site_group, linestyle=:period, row=:variable) *
                   visual(Lines)
fig_rad_comb_MAP = draw(plt_rad_comb_MAP; figure=(; title="Radiation with nursery"), axis=(; ylabel="MJ.m-2.day-1"))
save("2-results/meteorology/plot_radiation_by_MAP.png", fig_rad_comb_MAP)

#plot precipitations
prec_vars = [:Precipitations]
prec_stacked_comb = stack(df_meteo_long_comb, prec_vars; variable_name=:variable, value_name=:value)
prec_stacked_comb.site_group = ifelse.(prec_stacked_comb.site .== "nursery", "nursery", string.(prec_stacked_comb.site))
prec_stacked_comb.period = coalesce.(prec_stacked_comb.period, "planting")  # Fill missing period values if any
plt_prec_comb_MAP = data(prec_stacked_comb) *
                    mapping(:MAP, :value, color=:site_group, linestyle=:period, row=:variable) *
                    visual(Lines)
fig_prec_comb_MAP = draw(plt_prec_comb_MAP; figure=(; title="Precipitations with nursery"), axis=(; ylabel="mm"))
save("2-results/meteorology/plot_precipitation_by_MAP.png", fig_temp_comb_MAP)

#plot wind
wind_vars = [:Wind]
wind_stacked_comb = stack(df_meteo_long_comb, wind_vars; variable_name=:variable, value_name=:value)
wind_stacked_comb.site_group = ifelse.(wind_stacked_comb.site .== "nursery", "nursery", string.(wind_stacked_comb.site))
wind_stacked_comb.period = coalesce.(wind_stacked_comb.period, "planting")  # Fill missing period values if any
plt_wind_comb_MAP = data(wind_stacked_comb) *
                    mapping(:MAP, :value, color=:site_group, linestyle=:period, row=:variable) *
                    visual(Lines)
fig_wind_comb_MAP = draw(plt_wind_comb_MAP; figure=(; title="Wind with nursery"), axis=(; ylabel="m/s"))
save("2-results/meteorology/plot_wind_by_MAP.png", fig_wind_comb_MAP)

#plot climate all
climate_vars = [:T, :Ri_PAR_f, :Rg, :Rh, :Precipitations, :Wind]
climate_stacked_comb = stack(df_meteo_long_comb, climate_vars; variable_name=:variable, value_name=:value)

climate_vars = ["Precipitations", "Rg", "Rh", "Ri_PAR_f", "T", "Wind"]
labels = Dict(
    "T" => "Temperature (°C)",
    "Ri_PAR_f" => "PAR Radiation (µmol/m²/s)",
    "Rg" => "Global Radiation (MJ/m²)",
    "Rh" => "Relative Humidity (%)",
    "Precipitations" => "Rainfall (mm)",
    "Wind" => "Wind (m/s)"
)

sites = ["PRESCO", "SMSE", "TOWE"]
colors = Dict("PRESCO" => :blue, "SMSE" => :orange, "TOWE" => :green)


fig = Figure(resolution=(1600, 1200))

for (i, var) in enumerate(climate_vars)
    for (j, site) in enumerate(sites)
        df_plot = filter(row -> row.variable == var && row.site == site, climate_stacked_comb)

        ax = Axis(fig[i, j],
            xlabel=i == length(climate_vars) ? "MAP" : "",
            ylabel=j == 1 ? labels[var] : "",
            title=i == 1 ? site : ""
        )

        lines!(ax, df_plot.MAP, df_plot.value, color=colors[site])
    end
end

fig
save("2-results/meteorology/plot_climate_all.png", fig)