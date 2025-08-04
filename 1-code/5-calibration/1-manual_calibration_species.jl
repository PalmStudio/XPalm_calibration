# This is a script to manually calibrate the XPalm model at the species level using CIGE data
using CSV, DataFrames, Dates
using Statistics
using AlgebraOfGraphics, CairoMakie
using XPalm
using YAML
using PlantMeteo

include(joinpath(@__DIR__, "../XPalmCalibration/XPalmCalibration.jl"))
using .XPalmCalibration

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
    :Cumulated_n_leaf_emitted => (x -> fn_no_missings(x, mean)) => :cumulated_n_leaf_emitted, #!done
    :LeafArea => (x -> fn_no_missings(x, mean)) => :Leaf_area_17, #average leaf area at rank 17 (plant -1) #!done
    :bunch_fresh_mass_total => (x -> fn_no_missings(x, mean)) => :bunch_fresh_biomass, # in kg, #!FFB
    :bunch_fresh_mass_average => (x -> fn_no_missings(x, mean)) => :bunch_fresh_mass_per_bunch, # in kg
    :bunch_dry_mass_total => (x -> fn_no_missings(x, mean)) => :bunch_dry_biomass, # in kg,
    :bunch_dry_mass_per_bunch => (x -> fn_no_missings(x, mean)) => :bunch_dry_mass_per_bunch, # in kg #! done
    :biomass_fresh_fruit_per_bunch => (x -> fn_no_missings(x, mean)) => :biomass_fresh_fruit_per_bunch, #average in kg
    :biomass_dry_fruit_per_bunch => (x -> fn_no_missings(x, mean)) => :biomass_dry_fruit_per_bunch, #average in kg
    :n_of_bunch => (x -> fn_no_missings(x, mean)) => :total_n_bunches_harvested,
    :n_of_fruit_total => (x -> fn_no_missings(x, mean)) => :total_n_fruit_harvested,
    :n_of_fruit_average => (x -> fn_no_missings(x, mean)) => :avg_n_fruit_per_bunch,
    :stalk_dry_biomass_per_bunch => (x -> fn_no_missings(x, mean)) => :stalk_dry_biomass_per_bunch, # in kg
    :stalk_fresh_biomass_per_bunch => (x -> fn_no_missings(x, mean)) => :stalk_fresh_biomass_per_bunch, # in kg
    :bunch_water_content => (x -> fn_no_missings(x, mean)) => :bunch_water_content # in fraction
)

df_CIGE_site = combine(groupby(df_CIGE, [:Site]), :bunch_fresh_mass_total => (x -> mean(filter(!ismissing, x) |> y -> filter(z -> z > 0.0, y))) => :avg_bunch_fresh_biomass)

# Simulations
meteos = import_meteo_cige("2-results/meteorology/meteo_smse_with_nursery.csv", "2-results/meteorology/meteo_presco_with_nursery.csv", "2-results/meteorology/meteo_towe_with_nursery.csv")

# Model outputs:
out_vars = Dict{String,Any}(
    "Scene" => (:lai, :ET0, :leaf_area),
    "Plant" => (:leaf_area, :biomass_bunch_harvested, :phytomer_count, :production_speed, :n_bunches_harvested_cum, :n_bunches_harvested, :biomass_bunch_harvested_cum, :biomass_fruit_harvested),
    "Leaf" => (:leaf_area, :biomass, :rank),
    "Female" => (:biomass_bunch_harvested, :biomass_fruit_harvested, :fruits_number_harvested, :biomass_stalk_harvested,),
)

simulation_before = nothing

# #compute the dry fruit mass (per plant)
# CC_Fruit = 0.4857     # Fruit carbon content (gC g-1 dry mass)
# water_content_mesocarp = 0.25  # Water content of the mesocarp
# dry_to_fresh_ratio = 1 / (1 - water_content_mesocarp)  # Based on the mesocarp water content of 0.3

# transform!(groupby(simulation_map.plant, [:Site, :MAP]), #!need to check
#     :biomass_fruit_harvested_MAP => ByRow(x -> ismissing(x) ? missing : x * 1e-3 / CC_Fruit) => :fruit_dry_biomass) #!3 fruit dry mass from all bunches (plat -1 -MAP -1)


begin
    params_default = YAML.load_file("1-code/5-calibration/xpalm_parameters_manual_calibration_1.yml")
    # Choosing the output variables to be saved:
    simulations = run_simulations_all_cige_sites(params_default, out_vars, meteos)
    simulation_map = integrate_simulation_by_map(simulations)

    name_previous = "previous"
    name_current = "current"
    if isnothing(simulation_before)
        simulation_before = simulation_map
    end

    df_plant = innerjoin(simulation_map.plant, simulation_before.plant, on=[:Site, :MAP], makeunique=true, renamecols="_sim_" * name_current => "_sim_" * name_previous)
    df_plant = innerjoin(df_plant, df_CIGE_species, on=[:Site, :MAP], makeunique=true, renamecols="" => "_obs")

    df_female = innerjoin(simulation_map.female, simulation_before.female, on=[:Site, :MAP], makeunique=true, renamecols="_sim_" * name_current => "_sim_" * name_previous)
    df_female = innerjoin(df_female, df_CIGE_species, on=[:Site, :MAP], makeunique=true, renamecols="" => "_obs")

    df_leaf = innerjoin(simulation_map.leaf, simulation_before.leaf, on=[:Site, :MAP], makeunique=true, renamecols="_sim_" * name_current => "_sim_" * name_previous)
    df_leaf = innerjoin(df_leaf, df_CIGE_species, on=[:Site, :MAP], makeunique=true, renamecols="" => "_obs")


    evaluate(df_plant, df_female, df_leaf, "2-results/calibration/XPalm")
    # XPalmCalibration.evaluate_phyllochron(df_plant) #plot leaf emitted
    simulation_before = simulation_map
    nothing
end

# ALl results are saved in the "2-results/calibration/XPalm" directory.






#! still need to integrate the plots below in the XPalmCalibration module for making them each time we call `evaluate`
dfs_plant_MAP = simulation_map.plant
dfs_leaf_MAP = simulation_map.leaf
dfs_female = simulation_map.female


#biomass dry fruit in the plant scale #!to recheck with the latest version of xpalm
df_fruit_dry_long = stack(df_plant, [:total_biomass_dry_fruit_sim, :total_biomass_dry_fruit_obs], variable_name=:type, value_name=:biomass_dry_fruit)
p_fruit_dry = data(df_fruit_dry_long) * mapping(:MAP, :biomass_dry_fruit, row=:Site, color=:type) * visual(Lines)
fig_fruit_dry = draw(p_fruit_dry; axis=(; xlabel="Month after planting", ylabel="Total biomass dry fruit (kg plant-1 MAP-1)"), figure=(; size=(1000, 600)), legend=(; position=:bottom))
save("2-results/calibration/XPalm/4.Total biomass dry fruit (kg plant-1 MAP-1).png", fig_fruit_dry)


#!Female scale simulation
#average 1 bunch biomass all time (kg) #!good
df_female_site = combine(groupby(dfs_female_MAP, [:Site]),
    :bunch_fresh_biomass => (x -> mean(filter(x -> x > 0.0, x))) => :avg_bunch_fresh_biomass) #average individual bunch biomass each sites

df_avg_bunch = innerjoin(df_female_site, df_CIGE_site, on=[:Site], makeunique=true, renamecols="_sim" => "_obs")
df_avg_bunch_long = stack(df_avg_bunch, [:avg_bunch_fresh_biomass_sim, :avg_bunch_fresh_biomass_obs], variable_name=:type, value_name=:avg_biomass_bunch)
replace!(df_avg_bunch_long.type,
    "avg_bunch_fresh_biomass_obs" => "Observation",
    "avg_bunch_fresh_biomass_sim" => "Simulation"
)
p_avg_bunch_mass = data(df_avg_bunch_long) * mapping(:type, :avg_biomass_bunch, color=:type, col=:Site) * visual(BarPlot)
fig_avg_bunch_mass = draw(p_avg_bunch; axis=(; ylabel="Average 1 bunch biomass per site (kg)"), figure=(; size=(1000, 600)), legend=(; position=:bottom))
save("2-results/calibration/XPalm/3.avg_bunch_mass_site.png", fig_avg_bunch_mass)


