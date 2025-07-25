"""
Plot all the meteo datasets from 3 sites (actual period and added by nursery period), which will be use as an input for the xpalm simulation
"""

using XPalm, DataFrames, YAML, CSV
using CairoMakie, AlgebraOfGraphics, Colors, Dates, StatsPlots, Statistics

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
meteo_comb_towe = CSV.read("2-results/meteorology/meteo_towe_with_nursery.csv", missingstrings=["NA", "NaN"], DataFrame)  # Nigeria
meteo_comb_presco = CSV.read("2-results/meteorology/meteo_presco_with_nursery.csv", missingstrings=["NA", "NaN"], DataFrame)  # Benin

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

climate_vars = ["Precipitations", "Rg", "Rh", "T", "Wind"]
climate_stacked_comb = stack(df_meteo_long_comb, climate_vars; variable_name=:variable, value_name=:value)
labels = Dict(
    "T" => "Temperature (°C)",
    "Rg" => "Global Radiation (MJ/m²)",
    "Rh" => "Relative Humidity (%)",
    "Precipitations" => "Rainfall (mm)",
    "Wind" => "Wind (m/s)"
)

sites = ["PRESCO", "SMSE", "TOWE"]
colors = Dict("PRESCO" => :blue, "SMSE" => :orange, "TOWE" => :green)
fig = Figure(resolution=(1600, 1200))

axes_per_var = [Axis[] for _ in climate_vars]

for (i, var) in enumerate(climate_vars)
    for (j, site) in enumerate(sites)
        df_plot = filter(row -> row.variable == var && row.site == site, climate_stacked_comb)

        ax = Axis(fig[i, j],
            xlabel=i == length(climate_vars) ? "MAP" : "",
            ylabel=j == 1 ? labels[var] : "",
            title=i == 1 ? site : ""
        )

        lines!(ax, df_plot.MAP, df_plot.value, color=colors[site])
        push!(axes_per_var[i], ax)
    end
end


for ax_row in axes_per_var
    linkaxes!(:y, ax_row...)
end

dummy_lines = [LineElement(color=colors[site]) for site in sites]
Legend(fig[end+1, 1:length(sites)],
    dummy_lines, sites,
    orientation=:horizontal, tellwidth=false, tellheight=true
)

fig
save("2-results/meteorology/plot_climate_all.png", fig, px_per_unit=3)

#make a boxplot for the climate variation
plt_facet = data(climate_stacked_comb) *
            mapping(:site, :value, color=:site, row=:variable) *
            visual(BoxPlot)

fig_facet = draw(plt_facet; axis=(ylabel="Value", xlabel="Site"))

fig_facet
save("2-results/meteorology/boxplot_climate_facet.png", fig_facet, px_per_unit=3)
# save("2-results/meteorology/plot_climate_all_2.png", fig)
# save("2-results/meteorology/plot_climate_all_3.png", fig) # change the first rainfall presco eror ith correspodnd month after
# save("2-results/meteorology/plot_climate_all_4.png", fig) # change the first climate all presco eror ith correspodnd month after

#compare before and after replacement (daily)
meteo_comb_presco_replace = CSV.read("2-results/meteorology/meteo_presco_with_nursery_replace_climate.csv", missingstrings=["NA", "NaN"], DataFrame)  # Nigeria replace the climate
meteo_comb_presco = CSV.read("2-results/meteorology/meteo_presco_with_nursery_before_replace.csv", missingstrings=["NA", "NaN"], DataFrame)  # Nigeria
meteo_comb_smse = CSV.read("2-results/meteorology/meteo_smse_with_nursery.csv", missingstrings=["NA", "NaN"], DataFrame)  # Indonesia
meteo_comb_towe = CSV.read("2-results/meteorology/meteo_towe_with_nursery.csv", missingstrings=["NA", "NaN"], DataFrame)  # Benin

climate_vars = ["Precipitations", "Rg", "Rh", "T", "Wind"]
sites_comb = Dict(
    "PRESCO_replace" => meteo_comb_presco_replace,
    "PRESCO" => meteo_comb_presco,
    "SMSE" => meteo_comb_smse,
    "TOWE" => meteo_comb_towe,
)

df_meteo_long_comb = DataFrame()

for (sitename, df) in sites_comb
    temp_df = copy(df)
    temp_df.site = fill(sitename, nrow(temp_df))
    df_meteo_long_comb = vcat(df_meteo_long_comb, temp_df; cols=:union)
end

climate_stacked_comb = stack(df_meteo_long_comb, climate_vars; variable_name=:variable, value_name=:value)

#plot the based on MAP
grouped_sites = Dict(
    "PRESCO Group" => ["PRESCO_replace", "PRESCO"],
    "SMSE" => ["SMSE"],
    "TOWE" => ["TOWE"]
)

# Custom colors per site
colors = Dict(
    "PRESCO_replace" => :blue,
    "PRESCO" => :lightblue,
    "TOWE" => :green,
    "SMSE" => :orange
)

linestyles = Dict(
    "PRESCO_replace" => :solid,
    "PRESCO" => :solid,
    "TOWE" => :solid,
    "SMSE" => :solid
)

labels = Dict(
    "T" => "Temperature (°C)",
    "Rg" => "Global Radiation (MJ/m²)",
    "Rh" => "Relative Humidity (%)",
    "Precipitations" => "Rainfall (mm)",
    "Wind" => "Wind (m/s)"
)

fig = Figure(resolution=(1600, 1200))
climate_plot_vars = climate_vars
axes_per_var = [Axis[] for _ in climate_plot_vars]

for (i, var) in enumerate(climate_plot_vars)
    j = 1
    for (groupname, sites) in grouped_sites
        ax = Axis(fig[i, j],
            #xlabel=i == length(climate_plot_vars) && j == 2 ? : "",  # show MAP only on middle column
            ylabel=j == 1 ? labels[var] : "",
            title=i == 1 ? groupname : ""
        )

        for site in sites
            df_plot = filter(row -> row.variable == var && row.site == site, climate_stacked_comb)
            lines!(ax, df_plot.MAP, df_plot.value;
                color=colors[site],
                linestyle=linestyles[site],
                linewidth=2,
                label=site
            )
        end

        axislegend(ax, position=:rb, framevisible=false)
        push!(axes_per_var[i], ax)
        j += 1
    end
end

# Link y-axes for same variable (row)
for ax_row in axes_per_var
    linkaxes!(:y, ax_row...)
end

fig #cek here
save("2-results/meteorology/comparison_climate_daily_all.png", fig)

#plot annual climate conditions of the three sites
df_meteo_long_comb.date = Date.(df_meteo_long_comb.date)
df_meteo_long_comb.year = year.(df_meteo_long_comb.date)

annual_meteo = combine(groupby(df_meteo_long_comb, [:site, :year]),
    :Precipitations => sum => :total_precip,
    :Rg => mean => :mean_Rg,
    :Rh => mean => :mean_Rh,
    :T => mean => :mean_T,
    :Wind => mean => :mean_Wind,
)

annual_meteo.year = Int.(annual_meteo.year)

climate_annual_vars = ["total_precip", "mean_Rg", "mean_Rh", "mean_T", "mean_Wind"]
rename_labels = Dict(
    "total_precip" => "Rainfall (mm)",
    "mean_Rg" => "Global Radiation (MJ/m²)",
    "mean_Rh" => "Relative Humidity (%)",
    "mean_T" => "Temperature (°C)",
    "mean_Wind" => "Wind (m/s)"
)

annual_stacked = stack(annual_meteo, climate_annual_vars; variable_name=:variable, value_name=:value)

# Group PRESCO and PRESCO_bf_replace into one box
grouped_sites = Dict(
    "PRESCO Group" => ["PRESCO", "PRESCO_replace"],
    "TOWE" => ["TOWE"],
    "SMSE" => ["SMSE"]
)

# Custom colors per site
colors = Dict(
    "PRESCO" => :lightblue,
    "PRESCO_replace" => :blue,
    "TOWE" => :green,
    "SMSE" => :orange
)

linestyles = Dict(
    "PRESCO" => :solid,
    "PRESCO_replace" => :solid,
    "TOWE" => :solid,
    "SMSE" => :solid
)

fig2 = Figure(resolution=(1600, 1200))
climate_plot_vars = climate_annual_vars
axes_per_var = [Axis[] for _ in climate_plot_vars]

for (i, var) in enumerate(climate_plot_vars)
    j = 1
    for (groupname, sites) in grouped_sites
        ax = Axis(fig2[i, j],
            xlabel=i == length(climate_plot_vars) ? "Year" : "",
            ylabel=j == 1 ? rename_labels[var] : "",
            title=i == 1 ? groupname : ""
        )

        for site in sites
            df_plot = filter(row -> row.variable == var && row.site == site, annual_stacked)
            lines!(ax, df_plot.year, df_plot.value;
                color=colors[site],
                linestyle=linestyles[site],
                linewidth=2,
                label=site
            )
        end

        axislegend(ax, position=:rb, framevisible=false)
        push!(axes_per_var[i], ax)
        j += 1
    end
end

# Link y-axes for same variable (row)
for ax_row in axes_per_var
    linkaxes!(:y, ax_row...)
end

fig2
save("2-results/meteorology/comparison_climate_annual_all.png", fig2, CairoMakie.px_per_unit=3)
#save("2-results/meteorology/plot_climate_annual_all.png", fig)
#save("2-results/meteorology/plot_climate_annual_all_before_fill_presco.png", fig)
