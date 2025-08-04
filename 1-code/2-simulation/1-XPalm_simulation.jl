# This is XPalm simulation for sites comparison to plot the considered parameters

using DataFrames, CSV, YAML, StatsBase, Dates
using CairoMakie, AlgebraOfGraphics, Statistics

current_pwd = @__DIR__
include(joinpath(current_pwd, "../XPalmCalibration/XPalmCalibration.jl"))
using .XPalmCalibration

# Making the simulation

# Loading the meteorology data
meteos = import_meteo_cige("2-results/meteorology/meteo_smse_with_nursery.csv", "2-results/meteorology/meteo_presco_with_nursery.csv", "2-results/meteorology/meteo_towe_with_nursery.csv")

# Importing the default parameters values
params_default = YAML.load_file("1-code/5-calibration/xpalm_parameters_manual_calibration_1.yml")

# Choosing the output variables to be saved:
out_vars = Dict{String,Any}(
    "Scene" => (:lai, :ET0, :leaf_area),
    "Plant" => (:leaf_area, :biomass_bunch_harvested, :phytomer_count, :production_speed, :n_bunches_harvested_cum, :n_bunches_harvested, :biomass_bunch_harvested_cum, :biomass_fruit_harvested),
    "Leaf" => (:leaf_area, :biomass, :rank),
    "Female" => (:biomass_bunch_harvested, :biomass_fruit_harvested, :fruits_number_harvested, :biomass_stalk_harvested,),
)

simulations = run_simulations_all_cige_sites(params_default, out_vars, meteos)

#dfs_scene = vcat([s["Scene"] for s in simulations]...)

mkpath("2-results/calibration/Simulation")

#!plant scale
dfs_plant = vcat([s["Plant"] for s in simulations]...)
sort!(dfs_plant, [:Site, :timestep])

dfs_plant_MAP = combine(
    groupby(dfs_plant, [:Site, :MAP]),
    :leaf_area => last => :Leaf_area, #total leaf area per month #!done
    :biomass_bunch_harvested => sum => :biomass_bunch_harvested_MAP, #total biomass bunch harvested
    :biomass_bunch_harvested_cum => last => :biomass_bunch_harvested_cum, #dynamic cumulated bunch biomass per MAP
    :biomass_fruit_harvested => sum => :biomass_fruit_harvested_MAP, #gr (?)
    :n_bunches_harvested => sum => :total_n_bunches_harvested, #total number bunch per MAP (fluctuated)
    :n_bunches_harvested_cum => last => :n_bunches_harvested_cum,#dynamic number bunch per MAP
    :phytomer_count => last => :phytomer_count, #total number of phytomer per MAP
    :phytomer_count => (x -> x[end] - x[1]) => :diff_phytomer_emmitted, #the difference phytomer emitted between MAP
)

#compute the dry fruit mass (per plant)
CC_Fruit = 0.4857     # Fruit carbon content (gC g-1 dry mass)
water_content_mesocarp = 0.25  # Water content of the mesocarp
dry_to_fresh_ratio = 1 / (1 - water_content_mesocarp)  # Based on the mesocarp water content of 0.3

transform!(groupby(dfs_plant_MAP, [:Site, :MAP]), #!need to check
    :biomass_fruit_harvested_MAP => ByRow(x -> ismissing(x) ? missing : x * 1e-3 / CC_Fruit) => :total_biomass_dry_fruit)

#!Leaf scale
dfs_leaf = vcat([s["Leaf"] for s in simulations]...)
sort!(dfs_leaf, [:Site, :timestep])
filter!(x -> x.rank == 17, dfs_leaf)
dfs_leaf_MAP = combine(groupby(dfs_leaf, [:Site, :MAP]), :leaf_area => last => :Leaf_area_17)
#!female scale
dfs_female = vcat([s["Female"] for s in simulations]...)
dfs_female_MAP = combine(
    groupby(dfs_female, [:Site, :MAP]),
    :biomass_bunch_harvested => (x -> mean(filter(x -> x > 0.0, x)) * 1e-3) => :bunch_dry_mass_per_bunch, #average individual bunch biomass in one MAP in kg
    :biomass_bunch_harvested => (x -> sum(filter(x -> x > 0.0, x)) * 1e-3) => :bunch_dry_biomass, #change to kg and total it (?)
    :biomass_fruit_harvested => (x -> mean(filter(x -> x > 0.0, x)) * 1e-3) => :biomass_dry_fruit_per_bunch, #change to kg and total it (?)
    :fruits_number_harvested => mean => :avg_n_fruit_per_bunch,
)

# df_female_MAP = combine(
#     groupby(dfs_female, [:Site, :MAP]),
#     :biomass_bunch_harvested => (x -> mean(filter(x -> x > 0.0, x)) * 1e-3) => :bunch_biomass, #average individual bunch biomass in one MAP in kg
#     :biomass_fruit_harvested => (x -> sum(filter(x -> x > 0.0, x)) * 1e-3) => :biomass_fruit_harvested_MAP, #change to kg and total it (?)
# )


CSV.write("2-results/calibration/Simulation/dfs_leaf_MAP.csv", dfs_leaf_MAP)
CSV.write("2-results/calibration/Simulation/dfs_plant_MAP.csv", dfs_plant_MAP)
CSV.write("2-results/calibration/Simulation/dfs_female.csv", dfs_female)