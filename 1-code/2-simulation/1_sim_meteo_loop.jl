using XPalm, DataFrames, YAML, CSV
using CairoMakie, AlgebraOfGraphics

meteo_smse = DataFrame(CSV.File("xpalm_introduction/2-results/meteo_smse_cleaned.csv"; select = ["date", "T", "Tmin", "Tmax", "Wind", "Rh", "Rh_max", "Rh_min", "Precipitations", "Ri_PAR_f", "Rg"], missingstrings=["NA", "NaN"]))  #Indonesia
meteo_towe = DataFrame(CSV.File("xpalm_introduction/2-results/meteo_towe_cleaned.csv"; select = ["date", "T", "Tmin", "Tmax", "Wind", "Rh", "Rh_max", "Rh_min", "Precipitations", "Ri_PAR_f", "Rg"], missingstrings=["NA", "NaN"])) #Benin
meteo_presco = DataFrame(CSV.File("xpalm_introduction/2-results/meteo_presco_cleaned.csv"; select = ["date", "T", "Tmin", "Tmax", "Wind", "Rh", "Rh_max", "Rh_min", "Precipitations", "Ri_PAR_f", "Rg"], missingstrings=["NA", "NaN"])) #Nigeria

sites = Dict(
    "SMSE" => meteo_smse,
    "PRESCO" => meteo_presco,
    "TOWE" => meteo_towe,
)

df_meteo_long = DataFrame()

for (sitename, df) in sites
    temp_df = copy(df)  
    temp_df.site = fill(sitename, nrow(temp_df))  # ← FIXED HERE
    df_meteo_long = vcat(df_meteo_long, temp_df; cols=:union)
end

#plot Temperature (14052025)

temp_vars = [:T, :Tmin, :Tmax]
temp_stacked = stack(df_meteo_long, temp_vars; variable_name=:variable, value_name=:value)
plt_temp = data(temp_stacked) *
      mapping(:date, :value, color=:site, row=:variable) *
      visual(Lines)
draw(plt_temp; figure=(; title="Temperature"))

#plot Humidity (14052025)

hum_vars = [:Rh, :Rh_min, :Rh_max]
hum_stacked = stack(df_meteo_long, hum_vars; variable_name=:variable, value_name=:value)
plt_hum = data(hum_stacked) *
      mapping(:date, :value, color=:site, row=:variable) *
      visual(Lines)
draw(plt_hum; figure=(; title="Humidity"))

#plot Radiation (14052025)
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


####
## try the simulations with the cleaned data 

sites = Dict(
    "SMSE" => meteo_smse,
    "PRESCO" => meteo_presco,
    "TOWE" => meteo_towe,
)

simulations = DataFrame[]

parameters = YAML.load_file("xpalm_introduction/0-data/xpalm_parameters.yml"; dicttype=Dict{Symbol,Any}) 

for (site, meteo) in sites
    p = XPalm.Palm(parameters=parameters)
    result = xpalm(
        meteo,
        DataFrame,
        vars = Dict(
            "Scene" => (:lai,),
            "Plant" => (:leaf_area, :biomass_bunch_harvested, :biomass_bunch_harvested_cum, :plant_age), #
            "Soil" => (:ftsw,),
            "Leaf" => (:biomass,),
        ),
        palm = p
    )
    result[!, :date] = meteo.date[result.timestep]
    result[!, :Site] = fill(site, nrow(result))
    push!(simulations, result)
end

# Combine all results
combined_sim = vcat(simulations...)

# Plot LAI comparison across sites among dates 
plt_lai = data(filter(:organ => ==("Scene"), combined_sim)) *
    mapping(:date, :lai, color = :Site) *
    visual(Lines)
draw(plt_lai)

# Plot leaf_area comparison
plt_leaf_area = data(filter(:organ => ==("Plant"), combined_sim)) *
    mapping(:date, :leaf_area, color = :Site) *
    visual(Lines)
draw(plt_leaf_area)

# Plot bunch biomass harvested
plt_biomass_bunch = data(filter(:organ => ==("Plant"), combined_sim)) *
    mapping(:date, :biomass_bunch_harvested, color = :Site) *
    visual(Lines)
draw(plt_biomass_bunch)

# Plot ftsw - soil
plt_ftsw = data(filter(:organ => ==("Soil"), combined_sim)) *
    mapping(:date, :ftsw, color = :Site) *
    visual(Lines)
draw(plt_ftsw)

# Plot biomass - leaf
plt_biomass_leaf = data(filter(:organ => ==("Leaf"), combined_sim)) *
    mapping(:date, :biomass, color = :Site) *
    visual(Lines)
draw(plt_biomass_leaf)

plt_bunch_cum = data(filter(:organ => ==("Plant"), combined_sim)) *
    mapping(:date, :biomass_bunch_harvested_cum, color = :Site) *
    visual(Lines)
draw(plt_bunch_cum)

#start 
#create new average of leaf biomass per month, or only take one leaf for 6 months

#debug towe 
#precipitations

plt100 = data(meteo_towe) *
    mapping(:date, :Precipitations,) *
    visual(Lines)

draw(plt100; figure=(; title="Precipitations Towe"))

plt

##cumsum remi

using DataFrames, Statistics, AlgebraOfGraphics, CairoMakie

# Sort data by date just in case
sort!(meteo_towe, :date)

# Add a new column with cumulative sum of Precipitations
meteo_towe.cum_precip = cumsum(meteo_towe.Precipitations)

plt = data(meteo_towe) *
      mapping(:date, :cum_precip) *
      visual(Lines)

draw(plt; figure=(; title="Cumulative precip"))


#debug wind towe from wind smse

meteo_smse = DataFrame(CSV.File("xpalm_introduction/2-results/meteo_smse_cleaned.csv"; select = ["date", "T", "Tmin", "Tmax", "Wind", "Rh", "Rh_max", "Rh_min", "Precipitations", "Ri_PAR_f", "Rg"], missingstrings=["NA", "NaN"]))  #Indonesia
meteo_towe2 = DataFrame(CSV.File("xpalm_introduction/2-results/meteo_towe_cleaned2.csv"; select = ["date", "T", "Tmin", "Tmax", "Wind", "Rh", "Rh_max", "Rh_min", "Precipitations", "Ri_PAR_f", "Rg"], missingstrings=["NA", "NaN"])) #Benin
meteo_presco = DataFrame(CSV.File("xpalm_introduction/2-results/meteo_presco_cleaned.csv"; select = ["date", "T", "Tmin", "Tmax", "Wind", "Rh", "Rh_max", "Rh_min", "Precipitations", "Ri_PAR_f", "Rg"], missingstrings=["NA", "NaN"])) #Nigeria

sites2 = Dict(
    "SMSE" => meteo_smse,
    "PRESCO" => meteo_presco,
    "TOWE" => meteo_towe2,
)

df_meteo_long2 = DataFrame()

for (sitename, df) in sites2
    temp_df2 = copy(df)  
    temp_df2.site = fill(sitename, nrow(temp_df2))  # ← FIXED HERE
    df_meteo_long2 = vcat(df_meteo_long2, temp_df2; cols=:union)
end

#plot wind 2 (16052025)

temp_vars2 = [:Wind]
temp_stacked2 = stack(df_meteo_long2, temp_vars2; variable_name=:variable, value_name=:value)
plt_temp2 = data(temp_stacked2) *
      mapping(:date, :value, color=:site, row=:variable) *
      visual(Lines)
draw(plt_temp2; figure=(; title="wind"))