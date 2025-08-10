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
    :fruit_fresh_mass_per_bunch => (x -> fn_no_missings(x, mean)) => :fruit_fresh_mass_per_bunch, #average in kg
    :fruit_dry_mass_per_bunch => (x -> fn_no_missings(x, mean)) => :fruit_dry_mass_per_bunch, #average in kg
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

#? Map dynamic plot into one figure
const variable_labels = Dict(
    "bunch_fresh_biomass" => "Bunch fresh biomass (kg plant⁻¹)",
    "cumulated_n_leaf_emitted" => "Cumulative number of leaves emitted (plant⁻¹)",
    "bunch_dry_biomass" => "Bunch dry biomass (kg plant⁻¹)",
    "total_n_bunches_harvested" => "Total number of bunches harvested (plant⁻¹)",
    "Leaf_area_17" => "Leaf area 17 (m² plant⁻¹)",
    "avg_n_fruit_per_bunch" => "Average number of fruits (bunch⁻¹)",
    "fruit_dry_mass_per_bunch" => "Fruit dry mass (kg bunch⁻¹)",
    "fruit_fresh_mass_per_bunch" => "Fruit fresh mass (kg bunch⁻¹)",
    "bunch_dry_mass_per_bunch" => "Bunch dry mass (kg bunch⁻¹)",
    "bunch_fresh_mass_per_bunch" => "Bunch fresh mass (kg bunch⁻¹)",
    "stalk_dry_biomass_per_bunch" => "Stalk dry biomass (kg bunch⁻¹)",
    "stalk_fresh_biomass_per_bunch" => "Stalk fresh biomass (kg bunch⁻¹)",
)

function dynamic_layer(df, variable_name; xlabel="Month after planting")
    ylabel = get(variable_labels, variable_name, variable_name)  # fallback to variable_name if not found
    df = XPalmCalibration.rename_variables_names(df, variable_name)
    df_long = stack(df, Not(:MAP, :Site), variable_name=:type, value_name=:value)
    filter!(row -> row.type != "observed" || !ismissing(row.value), df_long)
    p = data(df_long) * mapping(:MAP, :value, row=:Site, color=:type) * visual(Lines)
    return p, xlabel, ylabel
end

# Now call with labels dynamically:

p1, xlabel1, ylabel1 = dynamic_layer(df_comparison["plant"], "bunch_fresh_biomass")
p2, xlabel2, ylabel2 = dynamic_layer(df_comparison["plant"], "cumulated_n_leaf_emitted")
p3, xlabel3, ylabel3 = dynamic_layer(df_comparison["female"], "bunch_dry_biomass")
p4, xlabel4, ylabel4 = dynamic_layer(df_comparison["plant"], "total_n_bunches_harvested")
p5, xlabel5, ylabel5 = dynamic_layer(df_comparison["leaf"], "Leaf_area_17")
p6, xlabel6, ylabel6 = dynamic_layer(df_comparison["female"], "avg_n_fruit_per_bunch")
p7, xlabel7, ylabel7 = dynamic_layer(df_comparison["female"], "fruit_dry_mass_per_bunch")
p8, xlabel8, ylabel8 = dynamic_layer(df_comparison["female"], "fruit_fresh_mass_per_bunch")
p9, xlabel9, ylabel9 = dynamic_layer(df_comparison["female"], "bunch_dry_mass_per_bunch")
p10, xlabel10, ylabel10 = dynamic_layer(df_comparison["female"], "bunch_fresh_mass_per_bunch")
p11, xlabel11, ylabel11 = dynamic_layer(df_comparison["female"], "stalk_dry_biomass_per_bunch")
p12, xlabel12, ylabel12 = evaluate_generic_dynamic_drawable(df_comparison["female"], "stalk_fresh_biomass_per_bunch")

fig_dynamic = Figure(resolution=(4200, 2400))

subfig1 = draw!(fig_dynamic[1, 1], p1, axis=(; ylabel=ylabel1))
subfig2 = draw!(fig_dynamic[1, 2], p2, axis=(; ylabel=ylabel2))
subfig3 = draw!(fig_dynamic[1, 3], p3, axis=(; ylabel=ylabel3))
subfig4 = draw!(fig_dynamic[2, 1], p4, axis=(; ylabel=ylabel4))
subfig5 = draw!(fig_dynamic[2, 2], p5, axis=(; ylabel=ylabel5))
subfig6 = draw!(fig_dynamic[2, 3], p6, axis=(; ylabel=ylabel6))
subfig7 = draw!(fig_dynamic[3, 1], p7, axis=(; ylabel=ylabel7))
subfig8 = draw!(fig_dynamic[3, 2], p8, axis=(; ylabel=ylabel8))
subfig9 = draw!(fig_dynamic[3, 3], p9, axis=(; ylabel=ylabel9))
subfig10 = draw!(fig_dynamic[4, 1], p10, axis=(; ylabel=ylabel10))
subfig11 = draw!(fig_dynamic[4, 2], p11, axis=(; ylabel=ylabel11))
subfig12 = draw!(fig_dynamic[4, 3], p12, axis=(; ylabel=ylabel12))

legend!(
    fig_dynamic[end+1, 1:3],
    subfig1;
    orientation=:horizontal,
    tellheight=true
)

fig_dynamic

mkpath("2-results/calibration/1-Report")
save("2-results/calibration/1-Report/dynamic_line_all.png", fig_dynamic)

#? Compare simulations with different parameter values:
params_defaults = YAML.load_file("1-code/5-calibration/xpalm_parameters_manual_calibration_1.yml")
params_defaults = Dict{AbstractString,Any}(string(k) => v for (k, v) in params_defaults)
param_changed = deepcopy(params_defaults)
param_changed["reproduction"]["yield_formation"]["potential_fruit_number_at_maturity"] = 3000


df_comparison = run_simulation_all_cige_by_map(df_CIGE_species, [params_defaults, param_changed], meteos, out_vars)
# Evaluate the simulation against CIGE data
out_eval2 = evaluate(df_comparison["plant"], df_comparison["female"], df_comparison["leaf"], "2-results/calibration/XPalm2")

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
# var1_df = XPalmCalibration.rename_variables_names(df_comparison["plant"], "bunch_fresh_biomass")
# filter!(row -> !ismissing(row.observed), var1_df)
# var1_df = stack(var1_df, Not(:MAP, :Site, :observed), variable_name=:model, value_name=:simulation)
# var1_df.variable_name .= "FFB (kg plant⁻¹ MAP⁻¹)"

# var2_df = XPalmCalibration.rename_variables_names(df_comparison["plant"], "cumulated_n_leaf_emitted")
# filter!(row -> !ismissing(row.observed), var2_df)
# var2_df = stack(var2_df, Not(:MAP, :Site, :observed), variable_name=:model, value_name=:simulation)
# var2_df.variable_name .= "Cumulated Leaves (#)"


# var3_df = XPalmCalibration.rename_variables_names(df_comparison["plant"], "total_n_bunches_harvested")
# filter!(row -> !ismissing(row.observed), var3_df)
# var3_df = stack(var3_df, Not(:MAP, :Site, :observed), variable_name=:model, value_name=:simulation)
# var3_df.variable_name .= "Total Number of Bunches Harvested (plant⁻¹ MAP⁻¹)"

# df_comp = vcat(var1_df, var2_df, var3_df)


# p1 = mapping([0], [1]) * visual(ABLines, color=:slategray, linestyle=:dash) + data(var1_df) * mapping(:observed, :simulation => "", col=:Site, color=:model, row=:variable_name) * visual(Scatter);
# p2 = mapping([0], [1]) * visual(ABLines, color=:slategray, linestyle=:dash) + data(var2_df) * mapping(:observed => "", :simulation => "", col=:Site, color=:model, row=:variable_name) * visual(Scatter);
# p3 = mapping([0], [1]) * visual(ABLines, color=:slategray, linestyle=:dash) + data(var3_df) * mapping(:observed => "", :simulation => "", col=:Site, color=:model, row=:variable_name) * visual(Scatter)

# f = Figure(xlabel="Observation", ylabel="Simulation", resolution=(700, 600))
# draw!(f[1, 1:2], p1, scales(Color=(; legend=false)))
# draw!(f[2, 1], p2, scales(Color=(; legend=false)))
# draw!(f[2, 2], p3, scales(Color=(; legend=false)))

# f

function scatter_layer(df, variable_name)
    df = XPalmCalibration.rename_variables_names(df, variable_name)
    filter!(row -> !ismissing(row.observed), df)
    df = stack(df, Not(:MAP, :Site, :observed), variable_name=:model, value_name=:simulation)

    # Add the variable_name as a new column for faceting
    df.variable_name = fill(variable_name, nrow(df))

    obs_min = minimum(skipmissing(df.observed))
    obs_max = maximum(skipmissing(df.observed))
    sim_min = minimum(skipmissing(df.simulation))
    sim_max = maximum(skipmissing(df.simulation))

    min_axis = min(obs_min, sim_min)
    max_axis = max(obs_max, sim_max)

    layer = mapping([0], [1]) * visual(ABLines, color=:slategray, linestyle=:dash) +
            data(df) * mapping(:observed, :simulation, col=:Site, color=:model, row=:variable_name) * visual(Scatter)

    return layer, min_axis, max_axis
end

#? plot all scatter with parameter comparison in a single figure
layer1, min1, max1 = scatter_layer(df_comparison["plant"], "bunch_fresh_biomass")
layer2, min2, max2 = scatter_layer(df_comparison["plant"], "cumulated_n_leaf_emitted")
layer3, min3, max3 = scatter_layer(df_comparison["female"], "bunch_dry_biomass")
layer4, min4, max4 = scatter_layer(df_comparison["plant"], "total_n_bunches_harvested")
layer5, min5, max5 = scatter_layer(df_comparison["leaf"], "Leaf_area_17")
layer6, min6, max6 = scatter_layer(df_comparison["female"], "avg_n_fruit_per_bunch")
layer7, min7, max7 = scatter_layer(df_comparison["female"], "fruit_dry_mass_per_bunch")
layer8, min8, max8 = scatter_layer(df_comparison["female"], "fruit_fresh_mass_per_bunch")
layer9, min9, max9 = scatter_layer(df_comparison["female"], "bunch_dry_mass_per_bunch")
layer10, min10, max10 = scatter_layer(df_comparison["female"], "bunch_fresh_mass_per_bunch")
layer11, min11, max11 = scatter_layer(df_comparison["female"], "stalk_dry_biomass_per_bunch")
layer12, min12, max12 = scatter_layer(df_comparison["female"], "stalk_fresh_biomass_per_bunch")


p1 = layer1
p2 = layer2
p3 = layer3
p4 = layer4
p5 = layer5
p6 = layer6
p7 = layer7
p8 = layer8
p9 = layer9
p10 = layer10
p11 = layer11
p12 = layer12

fig_scatter = Figure(resolution=(2100, 1200))

scatter1 = draw!(fig_scatter[1, 1], p1, axis=(; aspect=1, limits=((min1, max1), (min1, max1))))

scatter2 = draw!(fig_scatter[1, 2], p2, axis=(; aspect=1, limits=((min2, max2), (min2, max2))))

scatter2 = draw!(fig_scatter[1, 3], p3, axis=(; aspect=1, limits=((min3, max3), (min3, max3))))

scatter4 = draw!(fig_scatter[2, 1], p4, axis=(; aspect=1, limits=((min4, max4), (min4, max4))))

scatter5 = draw!(fig_scatter[2, 2], p5, axis=(; aspect=1, limits=((min5, max5), (min5, max5))))

scatter6 = draw!(fig_scatter[2, 3], p6, axis=(; aspect=1, limits=((min6, max6), (min6, max6))))

scatter7 = draw!(fig_scatter[3, 1], p7, axis=(; aspect=1, limits=((min7, max7), (min7, max7))))

scatter8 = draw!(fig_scatter[3, 2], p8, axis=(; aspect=1, limits=((min8, max8), (min8, max8))))

scatter9 = draw!(fig_scatter[3, 3], p9, axis=(; aspect=1, limits=((min9, max9), (min9, max9))))

scatter10 = draw!(fig_scatter[4, 1], p10, axis=(; aspect=1, limits=((min10, max10), (min10, max10))))

scatter11 = draw!(fig_scatter[4, 2], p11, axis=(; aspect=1, limits=((min11, max11), (min11, max11))))

scatter12 = draw!(fig_scatter[4, 3], p12, axis=(; aspect=1, limits=((min12, max12), (min12, max12))))

legend!(
    fig_scatter[end+1, 1:3],
    scatter1;
    orientation=:horizontal,
    tellheight=true
)

fig_scatter

mkpath("2-results/calibration/1-Report")
save("2-results/calibration/1-Report/scatter_comparison_all.png", fig_scatter)

