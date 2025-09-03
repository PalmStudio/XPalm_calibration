# This is a script to manually calibrate the XPalm model at the species level using CIGE data
using CSV, DataFrames, Dates
using Statistics
using AlgebraOfGraphics, CairoMakie, CategoricalArrays
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
    :n_of_fruit_average => (x -> fn_no_missings(x, mean)) => :avg_n_fruit_per_bunch,
    :stalk_dry_biomass_per_bunch => (x -> fn_no_missings(x, mean)) => :stalk_dry_biomass_per_bunch, # in kg
    :stalk_fresh_biomass_per_bunch => (x -> fn_no_missings(x, mean)) => :stalk_fresh_biomass_per_bunch, # in kg
    :bunch_water_content => (x -> fn_no_missings(x, mean)) => :bunch_water_content, # in fraction
    :avg_stalk_water_content => (x -> fn_no_missings(x, mean)) => :stalk_water_content,
)

#!cumulated FFB 50 - 100 MAP
FFB_50_to_100 = filter(row -> (50 <= row.MAP <= 100) && !ismissing(row.bunch_fresh_biomass), df_CIGE_species)[:, [:MAP, :Site, :bunch_fresh_biomass]]
transform!(groupby(FFB_50_to_100, :Site), :bunch_fresh_biomass => (x -> cumsum(x) .- first(cumsum(x))) => :cumulated_FFB)
select!(FFB_50_to_100, Not(:bunch_fresh_biomass))
leftjoin!(df_CIGE_species, FFB_50_to_100, on=[:Site, :MAP])

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
out_eval = evaluate(df_comparison["plant"], df_comparison["female"], df_comparison["leaf"], "2-results/calibration/1-Report/Model_evaluation")

out_eval.ffb.statistics

#? Map dynamic plot into one figure
const variable_labels = Dict(
    "bunch_fresh_biomass" => "FFB (kg plant⁻¹)",
    "cumulated_n_leaf_emitted" => "Cumulative n of leaves emitted (plant⁻¹)",
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


# Now call with labels dynamically:
p1, xlabel1, ylabel1 = dynamic_layer(df_comparison["plant"], "bunch_fresh_biomass", variable_labels)
p2, xlabel2, ylabel2 = scatter_layer(df_comparison["plant"], "cumulated_n_leaf_emitted", variable_labels)
p3, xlabel3, ylabel3 = dynamic_layer(df_comparison["female"], "bunch_dry_biomass", variable_labels)
p4, xlabel4, ylabel4 = dynamic_layer(df_comparison["plant"], "total_n_bunches_harvested", variable_labels)
p5, xlabel5, ylabel5 = scatter_layer(df_comparison["leaf"], "Leaf_area_17", variable_labels)
p6, xlabel6, ylabel6 = dynamic_layer(df_comparison["female"], "avg_n_fruit_per_bunch", variable_labels)
p7, xlabel7, ylabel7 = dynamic_layer(df_comparison["female"], "fruit_dry_mass_per_bunch", variable_labels)
p8, xlabel8, ylabel8 = dynamic_layer(df_comparison["female"], "fruit_fresh_mass_per_bunch", variable_labels)
p9, xlabel9, ylabel9 = dynamic_layer(df_comparison["female"], "bunch_dry_mass_per_bunch", variable_labels)
p10, xlabel10, ylabel10 = dynamic_layer(df_comparison["female"], "bunch_fresh_mass_per_bunch", variable_labels)
p11, xlabel11, ylabel11 = dynamic_layer(df_comparison["female"], "stalk_dry_biomass_per_bunch", variable_labels)
p12, xlabel12, ylabel12 = dynamic_layer(df_comparison["female"], "stalk_fresh_biomass_per_bunch", variable_labels)
#fig bunch component
#bunch, stalk and fruit dry weight
fig_bunch_dry = Figure(resolution=(1800, 1200))
subfig6 = draw!(fig_bunch_dry[1, 1:3], p6, axis=(; ylabel=ylabel6, ylabelsize=20))
subfig9 = draw!(fig_bunch_dry[2, 1], p9, axis=(; ylabel=ylabel9, ylabelsize=20))
subfig7 = draw!(fig_bunch_dry[2, 2], p7, axis=(; ylabel=ylabel7, ylabelsize=20))
subfig11 = draw!(fig_bunch_dry[2, 3], p11, axis=(; ylabel=ylabel11, ylabelsize=20))
legend!(
    fig_bunch_dry[end+1, 1:3],
    subfig9;
    orientation=:horizontal,
    tellheight=true, labelsize=20
)
fig_bunch_dry
save("2-results/calibration/1-report/evaluation_bunch_dry_component.png", fig_bunch_dry)

#scatter phyllocron vs leaf area 17
layer2, min2, max2 = scatter_layer(df_comparison["plant"], "cumulated_n_leaf_emitted", variable_labels)
layer5, min5, max5 = scatter_layer(df_comparison["leaf"], "Leaf_area_17", variable_labels)
fig_pheno = Figure(resolution=(700, 750))
subfig2 = draw!(fig_pheno[1, 1], layer2, axis=(; aspect=1, ylabelsize=16, limits=((min2, max2), (min2, max2))))
subfig5 = draw!(fig_pheno[2, 1], layer5, axis=(; aspect=1, ylabelsize=16, limits=((min5, max5), (min5, max5))))
legend!(
    fig_pheno[end+1, 1],
    subfig2;
    orientation=:horizontal,
    tellheight=true, labelsize=16
)
fig_pheno
save("2-results/calibration/1-report/evaluation_pheno.png", fig_pheno)

fig_bunch_component = Figure(resolution=(1800, 1500))
subfig10 = draw!(fig_bunch_component[2, 2], p10, axis=(; ylabel=ylabel10, ylabelsize=20))

subfig8 = draw!(fig_bunch_component[1, 4], p8, axis=(; ylabel=ylabel8, ylabelsize=20))

subfig12 = draw!(fig_bunch_component[2, 4], p12, axis=(; ylabel=ylabel12, ylabelsize=20))
legend!(
    fig_bunch_component[end+1, 1:4],
    subfig6;
    orientation=:horizontal,
    tellheight=true, labelsize=20
)
fig_bunch_component
save("2-results/calibration/1-report/evaluation_bunch_component.png", fig_bunch_component)



#yield component
fig_yield = Figure(resolution=(1500, 800))
subfig1 = draw!(fig_yield[1, 1], p1, axis=(; ylabel=ylabel1, ylabelsize=16))
subfig3 = draw!(fig_yield[1, 2], p3, axis=(; ylabel=ylabel3, ylabelsize=16))
#subfig4 = draw!(fig_yield[2, 1:2], p4, axis=(; ylabel=ylabel4, ylabelsize=16))
legend!(
    fig_yield[end+1, 1:2],
    subfig1;
    orientation=:horizontal,
    tellheight=true, labelsize=20
)
fig_yield
save("2-results/calibration/1-report/evaluation_yield.png", fig_yield)

#!Plot highligted FFB 50 to 100 MAP

# Create the layer plot
p1, xlabel1, ylabel1 = dynamic_layer(df_comparison["plant"], "bunch_fresh_biomass", variable_labels)
fig = Figure(resolution=(1500, 800))
figgrid = draw!(fig[1, 2], p1, axis=(; xlabel=xlabel1, ylabel=ylabel1, ylabelsize=20)) # Draw the AlgebraOfGraphics layer into the figure, with axis options
for ax_entry in vec(figgrid)
    ax = ax_entry.axis
    y_min = ax.finallimits[].origin[2]
    y_max = ax.finallimits[].origin[2] + ax.finallimits[].widths[2]
    x1, x2 = 50, 100
    points = Point2f[(x1, y_min), (x2, y_min), (x2, y_max), (x1, y_max)]
    poly!(ax, points, color=(:green, 0.15), strokewidth=0)
end
subfig3 = draw!(fig[1, 1], p3, axis=(; ylabel=ylabel3, ylabelsize=16))
legend!(
    fig[end+1, 1:2],
    figgrid;
    orientation=:horizontal,
    tellheight=true, labelsize=16
)
display(fig)
save("2-results/calibration/1-report/FFB_vs_dry_highligted.png", fig)

#? Compare simulations with different parameter values:
params_defaults = YAML.load_file("1-code/5-calibration/xpalm_parameters_manual_calibration_1.yml")
params_defaults = Dict{AbstractString,Any}(string(k) => v for (k, v) in params_defaults)
param_changed = deepcopy(params_defaults)
param_changed["reproduction"]["yield_formation"]["potential_fruit_number_at_maturity"] = 3000


df_comparison = run_simulation_all_cige_by_map(df_CIGE_species, [params_defaults, param_changed], meteos, out_vars)
# Evaluate the simulation against CIGE data
out_eval1 = evaluate(df_comparison["plant"], df_comparison["female"], df_comparison["leaf"], "2-results/calibration/XPalm_1")

#? Compare simulations with a reference simulation:
reference_parameters = YAML.load_file("1-code/5-calibration/xpalm_reference.yml")
reference_simulation = XPalmCalibration.run_simulations_all_cige_sites(reference_parameters, out_vars, meteos) |> XPalmCalibration.integrate_simulation_by_map
#param_changed = YAML.load_file("1-code/5-calibration/xpalm_parameters_manual_calibration_1.yml")
param_changed2 = deepcopy(reference_parameters)
param_changed2["reproduction"]["yield_formation"]["potential_fruit_number_at_maturity"] = 3000

df_comparison = run_simulation_all_cige_by_map(reference_simulation, df_CIGE_species, [param_changed2], meteos, out_vars; suffix=["potential_fruit_number_at_maturity: 3000"])
# Evaluate the simulation against CIGE data
out_eval_2 = evaluate(df_comparison["plant"], df_comparison["female"], df_comparison["leaf"], "2-results/calibration/XPalm")

# Extract female data
df_female = df_comparison["female"]
df_plot = select(df_female, :Site, :MAP,
    :avg_n_fruit_per_bunch_obs,
    :avg_n_fruit_per_bunch_sim_reference_simulation,
    Symbol("avg_n_fruit_per_bunch_sim_potential_fruit_number_at_maturity: 3000")
)

# Convert to long format
df_long = stack(df_plot, Not([:Site, :MAP]), variable_name=:type, value_name=:value)

# Rename the types for legend clarity
rename_dict = Dict(
    "avg_n_fruit_per_bunch_obs" => "Observed",
    "avg_n_fruit_per_bunch_sim_reference_simulation" => "potential_fruit_number_at_maturity: 2000",
    "avg_n_fruit_per_bunch_sim_potential_fruit_number_at_maturity: 3000" => "potential_fruit_number_at_maturity: 3000"
)

df_long.type = CategoricalArray([rename_dict[string(t)] for t in df_long.type])

# Determine the factor levels order
levels_order = levels(df_long.type)

# Define colors in the same order as levels
colors_vector = [
    :blue,    # Observed
    :orange,  # potential_fruit_number_at_maturity: 2000
    :green    # potential_fruit_number_at_maturity: 3000
]

# Create the plot
p = data(df_long) * mapping(:MAP, :value, row=:Site, color=:type) * visual(Lines)

# Draw with scales for color (vector order matches levels)
fig = draw(p, scales(Color=(; palette=colors_vector)),
    axis=(; xlabel="Month after planting", ylabel="avg_n_fruit_per_bunch (bunch⁻¹ MAP⁻¹)"),
    figure=(; size=(1000, 600)),
    legend=(; position=:bottom)
)
save("2-results/calibration/1-report/evaluation_n_fruit_per_bunch_comparison.png", fig)

# For plotting several variables in the same plot:
# var1_df = XPalmCalibration.rename_variables_names(df_comparison["plant"], "bunch_fresh_biomass")
# filter!(row -> !ismissing(row.observed), var1_df)
# var1_df = stack(var1_df, Not(:MAP, :Site, :observed), variable_name=:model, value_name=:simulation)
# var1_df.variable_name .= "FFB (kg plant⁻¹ MAP⁻¹)"

# var2_df = XPalmCalibration.rename_variables_names(df_comparison["plant"], "cumulated_n_leaf_emitted")
# filter!(row -> !ismissing(row.observed), var2_df)
# var2_df = stack(var2_df, Not(:MAP, :Site, :observed), variable_name=:model, value_name=:simulation)
# var2_df.variable_name .= "Cumulated Leaves (#)"



# df_comp = vcat(var1_df, var2_df, var3_df)


# p1 = mapping([0], [1]) * visual(ABLines, color=:slategray, linestyle=:dash) + data(var1_df) * mapping(:observed, :simulation => "", col=:Site, color=:model, row=:variable_name) * visual(Scatter);
# p2 = mapping([0], [1]) * visual(ABLines, color=:slategray, linestyle=:dash) + data(var2_df) * mapping(:observed => "", :simulation => "", col=:Site, color=:model, row=:variable_name) * visual(Scatter);
# p3 = mapping([0], [1]) * visual(ABLines, color=:slategray, linestyle=:dash) + data(var3_df) * mapping(:observed => "", :simulation => "", col=:Site, color=:model, row=:variable_name) * visual(Scatter)

# f = Figure(xlabel="Observation", ylabel="Simulation", resolution=(700, 600))
# draw!(f[1, 1:2], p1, scales(Color=(; legend=false)))
# draw!(f[2, 1], p2, scales(Color=(; legend=false)))
# draw!(f[2, 2], p3, scales(Color=(; legend=false)))

# f

#? plot all scatter with parameter comparison in a single figure
layer1, min1, max1 = scatter_layer(df_comparison["plant"], "bunch_fresh_biomass", variable_labels)
layer2, min2, max2 = scatter_layer(df_comparison["plant"], "cumulated_n_leaf_emitted", variable_labels)
layer3, min3, max3 = scatter_layer(df_comparison["female"], "bunch_dry_biomass", variable_labels)
layer4, min4, max4 = scatter_layer(df_comparison["plant"], "total_n_bunches_harvested", variable_labels)
layer5, min5, max5 = scatter_layer(df_comparison["leaf"], "Leaf_area_17", variable_labels)
layer6, min6, max6 = scatter_layer(df_comparison["female"], "avg_n_fruit_per_bunch", variable_labels)
layer7, min7, max7 = scatter_layer(df_comparison["female"], "fruit_dry_mass_per_bunch", variable_labels)
layer8, min8, max8 = scatter_layer(df_comparison["female"], "fruit_fresh_mass_per_bunch", variable_labels)
layer9, min9, max9 = scatter_layer(df_comparison["female"], "bunch_dry_mass_per_bunch", variable_labels)
layer10, min10, max10 = scatter_layer(df_comparison["female"], "bunch_fresh_mass_per_bunch", variable_labels)
layer11, min11, max11 = scatter_layer(df_comparison["female"], "stalk_dry_biomass_per_bunch", variable_labels)
layer12, min12, max12 = scatter_layer(df_comparison["female"], "stalk_fresh_biomass_per_bunch", variable_labels)

#scatter bunch biomass
scatter_bunch_biomass = Figure(resolution=(700, 600))
scatter3 = draw!(scatter_bunch_biomass[1, 1], layer3, axis=(; aspect=1, ylabelsize=16, limits=((min3, max3), (min3, max3))))
scatter1 = draw!(scatter_bunch_biomass[2, 1], layer1, axis=(; aspect=1, ylabelsize=16, limits=((min1, max1), (min1, max1))))
legend!(
    scatter_bunch_biomass[end+1, 1:1],
    scatter1;
    orientation=:horizontal,
    tellheight=true
)
scatter_bunch_biomass
save("2-results/calibration/1-report/1.calibration_bunch_biomass.png", scatter_bunch_biomass)

#bunch dry mass per bunch vs number of fruit per bunch
scatter_n_fruit_bunch = Figure(resolution=(700, 600))
scatter9 = draw!(scatter_n_fruit_bunch[1, 1], layer9, axis=(; aspect=1, ylabelsize=10, limits=((min9, max9), (min9, max9))))
scatter6 = draw!(scatter_n_fruit_bunch[2, 1], layer6, axis=(; aspect=1, ylabelsize=10, limits=((min6, max6), (min6, max6))))
legend!(
    scatter_n_fruit_bunch[end+1, 1:1],
    scatter9;
    orientation=:horizontal,
    tellheight=true
)
scatter_n_fruit_bunch
save("2-results/calibration/1-report/2.bunch_n_fruit.png", scatter_n_fruit_bunch)


#plot scatter FFB
fig_FFB = Figure(resolution=(1050, 600))
layer1, min1, max1 = scatter_SITE(df_comparison["plant"], "bunch_fresh_biomass", variable_labels)
p1 = layer1
scatter1 = draw!(fig_FFB[1, 1], p1, axis=(; aspect=1, limits=((min1, max1), (min1, max1))))
legend!(
    fig_FFB[end+1, 1:1],
    scatter1;
    orientation=:horizontal,
    tellheight=true
)

fig_FFB
save("2-results/calibration/1-report/3.scatter_FFB_by_site.png", fig_FFB)


#plot lines FFB
fig_FFB = Figure(resolution=(1050, 600))
layer1, min1, max1 = dynamic_layer(df_comparison["plant"], "bunch_fresh_biomass", variable_labels)
p1 = layer1
scatter1 = draw!(fig_FFB[1, 1], p1, axis=(; aspect=1, limits=((min1, max1), (min1, max1))))
legend!(
    fig_FFB[end+1, 1:1],
    scatter1;
    orientation=:horizontal,
    tellheight=true
)

fig_FFB
save("2-results/calibration/1-report/3.scatter_FFB_by_site.png", fig_FFB)

out_eval_2.ffb.statistics
stats_ref1 = filter(row -> row.Site == "All", out_eval_2.ffb.statistics)

# 8×7 DataFrame
#  Row │ Site    model                              RMSE     nRMSE    Bias     nBias    EF      
#      │ String  String                             Float64  Float64  Float64  Float64  Float64
# ─────┼────────────────────────────────────────────────────────────────────────────────────────
#    1 │ PR      potential_fruit_number_at_maturi…    16.07     0.58  -2.1254    -0.08    -4.45
#    2 │ PR      reference_simulation                 13.66     0.5   -5.5426    -0.2     -2.94
#    3 │ SMSE    potential_fruit_number_at_maturi…    17.39     0.36  -5.23      -0.11    -1.07
#    4 │ SMSE    reference_simulation                 16.11     0.34  -9.093     -0.19    -0.77
#    5 │ TOWE    potential_fruit_number_at_maturi…    11.38     0.4    0.4656     0.02    -2.16
#    6 │ TOWE    reference_simulation                  9.13     0.32  -1.8028    -0.06    -1.04
#    7 │ All     potential_fruit_number_at_maturi…    15.42     0.31  -2.4999    -0.05    -1.21
#    8 │ All     reference_simulation                 13.55     0.27  -5.7529    -0.11    -0.7


#  Row │ Site    model                              RMSE     nRMSE    Bias     nBias    EF      
#      │ String  String                             Float64  Float64  Float64  Float64  Float64
# ─────┼────────────────────────────────────────────────────────────────────────────────────────
#    1 │ All     potential_fruit_number_at_maturi…    15.42     0.31  -2.4999    -0.05    -1.21
#    2 │ All     reference_simulation                 13.55     0.27  -5.7529    -0.11    -0.7

# #? plot all scatter with parameter comparison in a single figure
# layer1, min1, max1 = scatter_layer(df_comparison["plant"], "bunch_fresh_biomass")
# layer2, min2, max2 = scatter_layer(df_comparison["plant"], "cumulated_n_leaf_emitted")
# layer3, min3, max3 = scatter_layer(df_comparison["female"], "bunch_dry_biomass")
# layer4, min4, max4 = scatter_layer(df_comparison["plant"], "total_n_bunches_harvested")
# layer5, min5, max5 = scatter_layer(df_comparison["leaf"], "Leaf_area_17")
# layer6, min6, max6 = scatter_layer(df_comparison["female"], "avg_n_fruit_per_bunch")
# layer7, min7, max7 = scatter_layer(df_comparison["female"], "fruit_dry_mass_per_bunch")
# layer8, min8, max8 = scatter_layer(df_comparison["female"], "fruit_fresh_mass_per_bunch")
# layer9, min9, max9 = scatter_layer(df_comparison["female"], "bunch_dry_mass_per_bunch")
# layer10, min10, max10 = scatter_layer(df_comparison["female"], "bunch_fresh_mass_per_bunch")
# layer11, min11, max11 = scatter_layer(df_comparison["female"], "stalk_dry_biomass_per_bunch")
# layer12, min12, max12 = scatter_layer(df_comparison["female"], "stalk_fresh_biomass_per_bunch")


# p1 = layer1
# p2 = layer2
# p3 = layer3
# p4 = layer4
# p5 = layer5
# p6 = layer6
# p7 = layer7
# p8 = layer8
# p9 = layer9
# p10 = layer10
# p11 = layer11
# p12 = layer12

# fig_scatter = Figure(resolution=(2100, 1200))

# scatter1 = draw!(fig_scatter[1, 1], p1, axis=(; aspect=1, limits=((min1, max1), (min1, max1))))

# scatter2 = draw!(fig_scatter[1, 2], p2, axis=(; aspect=1, limits=((min2, max2), (min2, max2))))

# scatter2 = draw!(fig_scatter[1, 3], p3, axis=(; aspect=1, limits=((min3, max3), (min3, max3))))

# scatter4 = draw!(fig_scatter[2, 1], p4, axis=(; aspect=1, limits=((min4, max4), (min4, max4))))

# scatter5 = draw!(fig_scatter[2, 2], p5, axis=(; aspect=1, limits=((min5, max5), (min5, max5))))

# scatter6 = draw!(fig_scatter[2, 3], p6, axis=(; aspect=1, limits=((min6, max6), (min6, max6))))

# scatter7 = draw!(fig_scatter[3, 1], p7, axis=(; aspect=1, limits=((min7, max7), (min7, max7))))

# scatter8 = draw!(fig_scatter[3, 2], p8, axis=(; aspect=1, limits=((min8, max8), (min8, max8))))

# scatter9 = draw!(fig_scatter[3, 3], p9, axis=(; aspect=1, limits=((min9, max9), (min9, max9))))

# scatter10 = draw!(fig_scatter[4, 1], p10, axis=(; aspect=1, limits=((min10, max10), (min10, max10))))

# scatter11 = draw!(fig_scatter[4, 2], p11, axis=(; aspect=1, limits=((min11, max11), (min11, max11))))

# scatter12 = draw!(fig_scatter[4, 3], p12, axis=(; aspect=1, limits=((min12, max12), (min12, max12))))

# legend!(
#     fig_scatter[end+1, 1:3],
#     scatter1;
#     orientation=:horizontal,
#     tellheight=true
# )

# fig_scatter