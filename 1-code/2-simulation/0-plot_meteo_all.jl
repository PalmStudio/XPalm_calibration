"""
Plot all the meteo datasets from 3 sites (actual period and added by nursery period), which will be use as an input for the xpalm simulation
"""

using XPalm, DataFrames, YAML, CSV
using CairoMakie, AlgebraOfGraphics

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
draw(plt_temp; figure=(; title="Temperature"))

#plot Humidity

hum_vars = [:Rh, :Rh_min, :Rh_max]
hum_stacked = stack(df_meteo_long, hum_vars; variable_name=:variable, value_name=:value)
plt_hum = data(hum_stacked) *
          mapping(:date, :value, color=:site, row=:variable) *
          visual(Lines)
draw(plt_hum; figure=(; title="Humidity"))

#plot Radiation
rad_vars = [:Ri_PAR_f, :Rg]
rad_stacked = stack(df_meteo_long, rad_vars; variable_name=:variable, value_name=:value)
plt_rad = data(rad_stacked) *
          mapping(:date, :value, color=:site, row=:variable) *
          visual(Lines)
draw(plt_rad; figure=(; title="Radiation"))

#plot precipitations
prec_vars = [:Precipitations]
prec_stacked = stack(df_meteo_long, prec_vars; variable_name=:variable, value_name=:value)
plt_prec = data(prec_stacked) *
           mapping(:date, :value, color=:site, row=:variable) *
           visual(Lines)
draw(plt_prec; figure=(; title="Precipitations"))

#plot wind
wind_vars = [:Wind]
wind_stacked = stack(df_meteo_long, wind_vars; variable_name=:variable, value_name=:value)
plt_wind = data(wind_stacked) *
           mapping(:date, :value, color=:site, row=:variable) *
           visual(Lines)
draw(plt_wind; figure=(; title="Wind"))


#plot the climate conditions depending on the nursery and planting of the three sites
meteo_comb_smse = CSV.read("2-results/meteorology/meteo_smse_combined.csv", missingstrings=["NA", "NaN"], DataFrame)  # Indonesia
meteo_comb_towe = CSV.read("2-results/meteorology/meteo_towe_combined.csv", missingstrings=["NA", "NaN"], DataFrame)  # Benin
meteo_comb_presco = CSV.read("2-results/meteorology/meteo_presco_combined.csv", missingstrings=["NA", "NaN"], DataFrame)  # Nigeria

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

#plot combined Humidity (not beautiful, should divided by year only)
hum_vars_comb = [:Rh, :Rh_max, :Rh_min]
hum_stacked_comb.year = year.(hum_stacked_comb.date)
hum_stacked_comb.year_str = string.(hum_stacked_comb.year)
hum_stacked_comb.site_group = ifelse.(hum_stacked_comb.site .== "nursery", "nursery", string.(hum_stacked_comb.site))

plt_hum_comb = data(hum_stacked_comb) *
               mapping(:date, :value, color=:site_group, linestyle=:period, row=:variable) *
               visual(Lines)

fig = draw(plt_hum_comb)

