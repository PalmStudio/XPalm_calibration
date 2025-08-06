# This is a script to manually calibrate the XPalm model at the species level using CIGE data
using CSV, DataFrames, Dates
using Statistics
using AlgebraOfGraphics, CairoMakie
using YAML
using XPalmCalibration

# Importing CIGE data.
#! Please run the following script before running this one: 1-code/4-observation/1-CIGE_calibration_database.jl
df_CIGE = CSV.read("2-results/calibration/CIGE/CIGE.csv", DataFrame)

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
    :n_of_bunch => (x -> fn_no_missings(x, median)) => :total_n_bunches_harvested,
    :n_of_fruit_total => (x -> fn_no_missings(x, median)) => :total_n_fruit_harvested,
    :n_of_fruit_average => (x -> fn_no_missings(x, mean)) => :avg_n_fruit_per_bunch,
    :stalk_dry_biomass_per_bunch => (x -> fn_no_missings(x, mean)) => :stalk_dry_biomass_per_bunch, # in kg
    :stalk_fresh_biomass_per_bunch => (x -> fn_no_missings(x, mean)) => :stalk_fresh_biomass_per_bunch, # in kg
    :bunch_water_content => (x -> fn_no_missings(x, mean)) => :bunch_water_content, # in fraction
    :avg_stalk_water_content => (x -> fn_no_missings(x, mean)) => :stalk_water_content
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

# #compute the dry fruit mass (per plant)
# CC_Fruit = 0.4857     # Fruit carbon content (gC g-1 dry mass)
# water_content_mesocarp = 0.25  # Water content of the mesocarp
# dry_to_fresh_ratio = 1 / (1 - water_content_mesocarp)  # Based on the mesocarp water content of 0.3

# transform!(groupby(simulation_map.plant, [:Site, :MAP]), #!need to check
#     :biomass_fruit_harvested_MAP => ByRow(x -> ismissing(x) ? missing : x * 1e-3 / CC_Fruit) => :fruit_dry_biomass) #!3 fruit dry mass from all bunches (plat -1 -MAP -1)

#? Compare simulations with the CIGE data:
parameters = YAML.load_file("1-code/5-calibration/xpalm_parameters_manual_calibration_1.yml")
df_comparison = run_simulation_all_cige_by_map(df_CIGE_species, parameters, meteos, out_vars)
# Evaluate the simulation against CIGE data
out_eval = evaluate(df_comparison["plant"], df_comparison["female"], df_comparison["leaf"], "2-results/calibration/XPalm")

out_eval.ffb.statistics

#? Compare simulations with different parameter values:
params_defaults = YAML.load_file("1-code/5-calibration/xpalm_parameters_manual_calibration_1.yml")
params_defaults = Dict{AbstractString,Any}(string(k) => v for (k, v) in params_defaults)
param_changed = deepcopy(params_defaults)
param_changed["reproduction"]["sex_ratio"]["sex_ratio_min"] = 0.6
param_changed["reproduction"]["sex_ratio"]["sex_ratio_ref"] = 0.7
param_changed["reproduction"]["yield_formation"]["potential_fruit_number_at_maturity"] = 1000

df_comparison = run_simulation_all_cige_by_map(df_CIGE_species, [params_defaults, param_changed], meteos, out_vars)
# Evaluate the simulation against CIGE data
out_eval2 = evaluate(df_comparison["plant"], df_comparison["female"], df_comparison["leaf"], "2-results/calibration/XPalm")

#? Compare simulations with a reference simulation:
reference_parameters = YAML.load_file("1-code/5-calibration/xpalm_reference.yml")
reference_simulation = XPalmCalibration.run_simulations_all_cige_sites(reference_parameters, out_vars, meteos) |> XPalmCalibration.integrate_simulation_by_map
param_changed = YAML.load_file("1-code/5-calibration/xpalm_parameters_manual_calibration_1.yml")
param_changed2 = deepcopy(reference_parameters)
param_changed2["reproduction"]["sex_ratio"]["sex_ratio_min"] = 0.4

df_comparison = run_simulation_all_cige_by_map(reference_simulation, df_CIGE_species, [param_changed, param_changed2], meteos, out_vars; suffix=["sex_ratio_min: 0.5", "sex_ratio_min: 0.4"])
# Evaluate the simulation against CIGE data
evaluate(df_comparison["plant"], df_comparison["female"], df_comparison["leaf"], "2-results/calibration/XPalm")


# For plotting several variables in the same plot:
var1_df = XPalmCalibration.rename_variables_names(df_comparison["plant"], "bunch_fresh_biomass")
filter!(row -> !ismissing(row.observed), var1_df)
var1_df = stack(var1_df, Not(:MAP, :Site, :observed), variable_name=:model, value_name=:simulation)
var1_df.variable_name .= "FFB (kg plant⁻¹ MAP⁻¹)"

var2_df = XPalmCalibration.rename_variables_names(df_comparison["plant"], "cumulated_n_leaf_emitted")
filter!(row -> !ismissing(row.observed), var2_df)
var2_df = stack(var2_df, Not(:MAP, :Site, :observed), variable_name=:model, value_name=:simulation)
var2_df.variable_name .= "Cumulated Leaves (#)"
df_comp = vcat(var1_df, var2_df)

p1 = mapping([0], [1]) * visual(ABLines, color=:slategray, linestyle=:dash) + data(var1_df) * mapping(:observed => "", :simulation => "", col=:Site, color=:model) * visual(Scatter)
p2 = mapping([0], [1]) * visual(ABLines, color=:slategray, linestyle=:dash) + data(var2_df) * mapping(:observed => "", :simulation => "", col=:Site, color=:model) * visual(Scatter)
f = Figure(xlabel="Observation", ylabel="Simulation")
fg1 = draw!(f[1, 1], p1, scales(Color=(; legend=false)))
legend!(f[1, 2], fg1)
fg2 = draw!(f[2, 1], p2, scales(Color=(; legend=false)))
legend!(f[2, 2], fg2)
f