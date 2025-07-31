# This is a script to manually calibrate the XPalm model at the species level using CIGE data
using CSV, DataFrames, Dates
using Statistics
using AlgebraOfGraphics, CairoMakie
using XPalm
using YAML
using PlantMeteo

# Importing CIGE data
df_CIGE = CSV.read("2-results/calibration/CIGE/CIGE.csv", DataFrame)

function fn_no_missings(values, fn)
    if all(ismissing.(values))
        return missing
    else
        return fn(skipmissing(values))
    end
end

df_CIGE_species = combine( #here is we dont consider about the genotype thats why mostly we use the mean from all treeId to get the value of each tree
    groupby(df_CIGE, [:Site, :MAP]),
    :Cumulated_n_leaf_emitted => (x -> fn_no_missings(x, mean)) => :Cumulated_n_leaf_emitted, #!good
    :LeafArea => (x -> fn_no_missings(x, mean)) => :Leaf_area_17,
    :BunchMass => (x -> fn_no_missings(x, mean) .* 1e3) => :bunch_biomass, # in g,
    :biomass_dry_fruit => (x -> fn_no_missings(x, mean)) => :total_biomass_dry_fruit, #total in kg #!use mean to get the value from 1 tree, the sum will compute all tree
    :n_of_bunch => (x -> fn_no_missings(x, mean)) => :total_n_bunches_harvested
)

df_CIGE_site = combine(groupby(df_CIGE, [:Site]),
    :BunchMass => (x -> mean(filter(!ismissing, x) |> y -> filter(z -> z > 0.0, y))) => :avg_bunch_biomass)

#importing simulation data
dfs_plant_MAP = CSV.read("2-results/calibration/Simulation/dfs_plant_MAP.csv", DataFrame)
dfs_female = CSV.read("2-results/calibration/Simulation/dfs_female.csv", DataFrame)
dfs_female_MAP = CSV.read("2-results/calibration/Simulation/dfs_female_MAP.csv", DataFrame)
dfs_leaf_MAP = CSV.read("2-results/calibration/Simulation/dfs_leaf_MAP.csv", DataFrame)


#!Plant scale simulation
df_plant = innerjoin(dfs_plant_MAP, df_CIGE_species, on=[:Site, :MAP], makeunique=true, renamecols="_sim" => "_obs")

#plot total number of leaf/ phytomer emitted
df_plant_leaf_emit = transform(groupby(df_plant, [:Site]), :phytomer_count_sim => (x -> x .- first(x)) => :Cumulated_n_leaf_emitted_sim)
df_leaf_emit_long = stack(df_plant_leaf_emit, [:Cumulated_n_leaf_emitted_sim, :Cumulated_n_leaf_emitted_obs], variable_name=:type, value_name=:leaf_emitted)
p_leaf_emittted = data(df_leaf_emit_long) * mapping(:MAP, :leaf_emitted, row=:Site, color=:type) * visual(Lines)
fig_leaf_emitted = draw(p_leaf_emittted; axis=(; xlabel="Month after planting", ylabel="Number of leaves emitted since first observation"), figure=(; size=(1000, 600)), legend=(; position=:bottom))
save("2-results/calibration/XPalm/1.leaf_emitted.png", fig_leaf_emitted) #!dont change its good

#plot total number of bunch per plant
df_n_bunch_long = stack(df_plant, [:total_n_bunches_harvested_sim, :total_n_bunches_harvested_obs], variable_name=:type, value_name=:total_n_bunches_harvested)
p_n_bunch = data(df_n_bunch_long) * mapping(:MAP, :total_n_bunches_harvested, row=:Site, color=:type) * visual(Lines)
fig_n_bunch = draw(p_n_bunch; axis=(; xlabel="Month after planting", ylabel="Total number of bunch harvested (plant-1 MAP-1)"), figure=(; size=(1000, 600)), legend=(; position=:bottom))
save("2-results/calibration/XPalm/5.total_n_bunches_harvested (plant-1 MAP-1).png", fig_n_bunch)

#biomass dry fruit in the plant scale #!to recheck with the latest version of xpalm
df_fruit_dry_long = stack(df_plant, [:total_biomass_dry_fruit_sim, :total_biomass_dry_fruit_obs], variable_name=:type, value_name=:biomass_dry_fruit)
p_fruit_dry = data(df_fruit_dry_long) * mapping(:MAP, :biomass_dry_fruit, row=:Site, color=:type) * visual(Lines)
fig_fruit_dry = draw(p_fruit_dry; axis=(; xlabel="Month after planting", ylabel="Total biomass dry fruit (kg plant-1 MAP-1)"), figure=(; size=(1000, 600)), legend=(; position=:bottom))
save("2-results/calibration/XPalm/4.Total biomass dry fruit (kg plant-1 MAP-1).png", fig_fruit_dry)


#!Leaf scale simulation

df_leaf = innerjoin(dfs_leaf_MAP, df_CIGE_species, on=[:Site, :MAP], makeunique=true, renamecols="_sim" => "_obs")

#plot leaf area
df_leaf_area_17_long = stack(df_leaf, [:Leaf_area_17_sim, :Leaf_area_17_obs], variable_name=:type, value_name=:Leaf_area_17)
filter!(row -> !ismissing(row.Leaf_area_17), df_leaf_area_17_long)

p_leaf_area_17 = data(df_leaf_area_17_long) * mapping(:MAP, :Leaf_area_17, row=:Site, color=:type) * visual(Lines)
fig_leaf_area_17 = draw(p_leaf_area_17; axis=(; xlabel="Month after planting", ylabel="Leaf area at rank 17"), figure=(; size=(1000, 600)), legend=(; position=:bottom))
save("2-results/calibration/XPalm/2.leaf_area_rank_17.png", fig_leaf_area_17) #!i think its good

#!Female scale simulation
#average 1 bunch biomass all time (kg) #!good
df_female_site = combine(groupby(dfs_female_MAP, [:Site]),
    :bunch_biomass => (x -> mean(filter(x -> x > 0.0, x))) => :avg_bunch_biomass) #average individual bunch biomass each sites

df_avg_bunch = innerjoin(df_female_site, df_CIGE_site, on=[:Site], makeunique=true, renamecols="_sim" => "_obs")
df_avg_bunch_long = stack(df_avg_bunch, [:avg_bunch_biomass_sim, :avg_bunch_biomass_obs], variable_name=:type, value_name=:avg_biomass_bunch)
replace!(df_avg_bunch_long.type,
    "avg_bunch_biomass_obs" => "Observation",
    "avg_bunch_biomass_sim" => "Simulation"
)
p_avg_bunch_mass = data(df_avg_bunch_long) * mapping(:type, :avg_biomass_bunch, color=:type, col=:Site) * visual(BarPlot)
fig_avg_bunch_mass = draw(p_avg_bunch; axis=(; ylabel="Average 1 bunch biomass per site (kg)"), figure=(; size=(1000, 600)), legend=(; position=:bottom))
save("2-results/calibration/XPalm/3.avg_bunch_mass_site.png", fig_avg_bunch_mass)

#bunch biomass
df_bunch_biomass = innerjoin(df_female_MAP, df_CIGE_species, on=[:Site, :MAP], makeunique=true, renamecols="_sim" => "_obs")
df_bunch_biomass_long = stack(df_bunch_biomass, [:bunch_biomass_sim, :bunch_biomass_obs], variable_name=:type, value_name=:bunch_biomass)
p_bunch_biomass = data(df_bunch_biomass_long) * mapping(:MAP, :bunch_biomass, row=:Site, color=:type) * visual(Lines)
fig_bunch_biomass = draw(p_bunch_biomass; axis=(; xlabel="Month after planting", ylabel="Bunch biomass (g)"), figure=(; size=(1000, 600)), legend=(; position=:bottom))
save("2-results/calibration/XPalm/BunchMass.png", fig_bunch_biomass)
