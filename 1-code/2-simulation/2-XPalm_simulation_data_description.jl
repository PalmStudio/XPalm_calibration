"this code is use to make join all dataframes from simulation of XPalm with various climate input"

using CSV, DataFrames, Dates
using AlgebraOfGraphics, CairoMakie

#!please run the code # `1-code\2-simulation\1-sim_meteo.jl` first to generate the each simulation scale per MAP (.csv) files
#import the simulation dataframe
sim_plant_MAP = CSV.read("2-results/calibration/Simulation/dfs_plant_MAP.csv", DataFrame)
sim_female = CSV.read("2-results/calibration/Simulation/dfs_female.csv", DataFrame)
#sim_female_MAP = CSV.read("2-results/calibration/Simulation/dfs_female_MAP.csv", DataFrame)
sim_leaf_MAP = CSV.read("2-results/calibration/Simulation/dfs_leaf_MAP.csv", DataFrame)

mkpath("2-results/calibration/Simulation/plot_sim")

#! plot plant scale
#leaf area 
p_leaf_area = data(filter(x -> x.Leaf_area > 0, sim_plant_MAP)) *
              mapping(:MAP, :Leaf_area => "Leaf area (plant -1)", row=:Site) *
              visual(Lines)
fig_leaf_area = draw(p_leaf_area)
save("2-results/calibration/Simulation/plot_sim/cum_leaf_area_plant.png", fig_leaf_area)

#biomas bunch harvested
p_biomass_bunch_harvested = data(filter(x -> x.biomass_bunch_harvested_MAP > 0, sim_plant_MAP)) *
                            mapping(:MAP, :biomass_bunch_harvested_MAP => "biomass_bunch_harvested_MAP (plant -1)", row=:Site) *
                            visual(Lines)
fig_biomass_bunch_harvested = draw(p_biomass_bunch_harvested)
save("2-results/calibration/Simulation/plot_sim/biomass_bunch_harvested_plant.png", fig_biomass_bunch_harvested)

#biomas bunch harvested cum
p_biomass_bunch_harvested_cum = data(filter(x -> x.biomass_bunch_harvested_cum > 0, sim_plant_MAP)) *
                                mapping(:MAP, :biomass_bunch_harvested_cum => "biomass_bunch_harvested_cum (plant -1)", row=:Site) *
                                visual(Lines)
fig_biomass_bunch_harvested_cum = draw(p_biomass_bunch_harvested_cum)
save("2-results/calibration/Simulation/plot_sim/biomass_bunch_harvested_cum_plant.png", fig_biomass_bunch_harvested_cum)

#total n bunches harvested
p_n_bunches_harvested = data(filter(x -> x.total_n_bunches_harvested > 0, sim_plant_MAP)) *
                        mapping(:MAP, :total_n_bunches_harvested => "n_bunches_harvested_MAP (plant -1)", row=:Site) *
                        visual(Lines)
fig_n_bunches_harvested = draw(p_n_bunches_harvested)
save("2-results/calibration/Simulation/plot_sim/n_bunches_harvested_plant.png", fig_n_bunches_harvested)

#n bunches harvested cum
p_n_bunches_harvested_cum = data(filter(x -> x.n_bunches_harvested_cum > 0, sim_plant_MAP)) *
                            mapping(:MAP, :n_bunches_harvested_cum => "n_bunches_harvested_cum (plant -1)", row=:Site) *
                            visual(Lines)
fig_n_bunches_harvested_cum = draw(p_n_bunches_harvested_cum)
save("2-results/calibration/Simulation/plot_sim/n_bunches_harvested_cum_plant.png", fig_n_bunches_harvested_cum)

#phytomer_count
p_phytomer_count = data(filter(x -> x.phytomer_count > 0, sim_plant_MAP)) *
                   mapping(:MAP, :phytomer_count => "phytomer_count (plant -1)", row=:Site) *
                   visual(Lines)
fig_phytomer_count = draw(p_phytomer_count)
save("2-results/calibration/Simulation/plot_sim/phytomer_count_plant.png", fig_phytomer_count)


#diff_phytomer_emmitted
p_diff_phytomer_emmitted = data(filter(x -> x.diff_phytomer_emmitted > 0, sim_plant_MAP)) *
                           mapping(:MAP, :diff_phytomer_emmitted => "diff_phytomer_emmitted (plant -1)", row=:Site) *
                           visual(Lines)
fig_diff_phytomer_emmitted = draw(p_diff_phytomer_emmitted)
save("2-results/calibration/Simulation/plot_sim/diff_phytomer_emmitted_plant.png", fig_diff_phytomer_emmitted)

#!plot female scale
dfs_female_at_harvest = filter(x -> x.biomass_stalk_harvested > 0 && x.biomass_bunch_harvested > 0 && x.biomass_fruit_harvested > 0, sim_female)
df_yield_components = stack(rename(dfs_female_at_harvest, :biomass_stalk_harvested => :stalk, :biomass_bunch_harvested => :bunch, :biomass_fruit_harvested => :fruit), [:stalk, :bunch, :fruit], variable_name=:component, value_name=:biomass)

p = data(df_yield_components) *
    mapping(:MAP, :biomass => "Biomass at harvest (g bunch⁻¹)", color=:component, row=:Site) *
    visual(Lines)
draw(p)

p = data(dfs_female_at_harvest) *
    mapping(:MAP, :fruits_number_harvested => "Fruits per bunch at harvest (#)", row=:Site) *
    visual(Lines)
draw(p)

p = data(dfs_female_at_harvest) *
    mapping(:timestep, :biomass_bunch_harvested => "Bunch biomass at harvest (#)", row=:Site) *
    visual(Lines)
draw(p)

p = data(dfs_female_at_harvest) *
    mapping(:MAP, :final_potential_fruit_biomass => "Potential fruit biomass (g fruit⁻¹)", row=:Site) *
    visual(Lines)
draw(p)

p = data(dfs_female_at_harvest) *
    mapping(:MAP, :final_potential_biomass_oil_fruit => "Potential fruit oil biomass (g fruit⁻¹)", row=:Site) *
    visual(Lines)

#plot number of ftsw 

dfs_soil = CSV.read("2-results/calibration/Simulation/dfs_soil.csv", missingstring=["NA", "NaN"], DataFrame)
threshold_ftsw = 0.3
df_count_ftsw_stress = combine(groupby(dfs_soil, [:Site, :MAP]), :ftsw => (x -> sum(0.0 .< x .< threshold_ftsw)) => :n_ftsw)
plt_ftsw = data(df_count_ftsw_stress) *
           mapping(:MAP, :n_ftsw => "Number of FTSW (days < 0.3)", color=:Site) *
           visual(Lines)
fig_n_ftsw = draw(plt_ftsw)
save("2-results/calibration/1-Report/n_ftsw_MAP.png", fig_n_ftsw) #dynamic per MAP

#total among sites
df_total_ftsw = combine(groupby(df_count_ftsw_stress, :Site), :n_ftsw => sum => :total_n_ftsw)
plt_ftsw_total = data(df_total_ftsw) *
                 mapping(:Site, :total_n_ftsw => "Total FTSW (days < 0.3)", color=:Site) *
                 visual(BarPlot)  # <- use CairoMakie.Bar explicitly
fig_total_ftsw = draw(plt_ftsw_total)
save("2-results/calibration/1-Report/n_ftsw_total_per_site.png", fig_total_ftsw)