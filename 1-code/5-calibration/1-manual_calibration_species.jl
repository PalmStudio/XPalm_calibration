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

df_CIGE_species = combine(
    groupby(df_CIGE, [:Site, :MAP]),
    :BunchMass => (x -> fn_no_missings(x, mean) .* 1e3) => :bunch_biomass, # in g,
)

# Making the simulation

# Loading the meteorology data
meteos = Dict(
    "SMSE" => CSV.read("2-results/meteorology/meteo_smse_with_nursery.csv", DataFrame),
    "PR" => CSV.read("2-results/meteorology/meteo_presco_with_nursery.csv", DataFrame),
    "TOWE" => CSV.read("2-results/meteorology/meteo_towe_with_nursery.csv", DataFrame)
)

# Removing the year-month, and arranging the columns:
for (site, meteo) in meteos
    select!(meteo, :date, :MAP, :T, :Tmin, :Tmax, :Wind, :Rh, :Rh_max, :Rh_min, :Precipitations, :Ri_PAR_f, :Rg)
end

# Transform the meteo dataframe in Weather object for speed:
meteos = Dict(site => Weather(meteo) for (site, meteo) in meteos)

# Importing the default parameters values
params_default = YAML.load_file("1-code/5-calibration/xpalm_parameters_manual_calibration_1.yml")

begin
    params_SMSE = copy(params_default)
    params_SMSE["plot"]["latitude"] = 2.93416
    params_SMSE["plot"]["altitude"] = 15.5

    params_PR = copy(params_default)
    params_PR["plot"]["latitude"] = 6.137
    params_PR["plot"]["altitude"] = 15.5

    params_TOWE = copy(params_default)
    params_TOWE["plot"]["latitude"] = 7.00
    params_TOWE["plot"]["altitude"] = 15.5

    params = Dict("SMSE" => params_SMSE, "PR" => params_PR, "TOWE" => params_TOWE,)
    out_vars = Dict{String,Any}(
        #"Scene" => (:lai, :ET0, :leaf_area),
        "Plant" => (:leaf_area, :biomass_bunch_harvested, :phytomer_count, :production_speed, :n_bunches_harvested_cum, :n_bunches_harvested, :biomass_bunch_harvested_cum),
        # "Soil" => (:ftsw, :qty_H2O_C_Roots, :transpiration),
        "Leaf" => (:biomass,),
        #"Phytomer" => (:TT_flowering,),
        "Female" => (:biomass_bunch_harvested, :biomass_fruit_harvested, :fruits_number, :biomass_stalk_harvested),
        # "Male" => (:biomass,),
        # "Internode" => (:biomass,),
    )


    simulations = Dict{String,DataFrame}[]
    for (site, m) in meteos
        palm = XPalm.Palm(parameters=params[site])
        df = xpalm(m, DataFrame, vars=out_vars, palm=palm)
        for (k, v) in df
            v[!, "Site"] .= site
            # Add :date column by matching timestep
            v[!, :date] = m.date[v.timestep]

            planting_date = site == "SMSE" ? Date("2011-01-01") :
                            site == "PR" ? Date("2010-05-01") :
                            site == "TOWE" ? Date("2012-06-01") : missing
            v[!, :planting_date] .= planting_date
            v[!, :MAP] = m.MAP[v.timestep]
        end
        push!(simulations, df)
    end
end

#dfs_scene = vcat([s["Scene"] for s in simulations]...)
dfs_plant = vcat([s["Plant"] for s in simulations]...)
sort!(dfs_plant, [:Site, :timestep])

dfs_plant_MAP = combine(
    groupby(dfs_plant, [:Site, :MAP]),
    :leaf_area => sum => :Leaf_area,
    :biomass_bunch_harvested => sum => :biomass_bunch_harvested_MAP, #total biomass bunch harvested
    :biomass_bunch_harvested_cum => last => :biomass_bunch_harvested_cum, #dynamic cumulated bunch biomass per MAP
    :n_bunches_harvested => sum => :n_bunches_harvested_MAP, #total number bunch per MAP (fluctuated)
    :n_bunches_harvested_cum => last => :n_bunches_harvested_cum,#dynamic number bunch per MAP
    :phytomer_count => last => :phytomer_count, #total number of phytomer per MAP
    :phytomer_count => (x -> x[end] - x[1]) => :diff_phytomer_emmitted, #the difference phytomer emitted between MAP
)

#plot simulation plant
#leaf area 
p_leaf_area = data(filter(x -> x.Leaf_area > 0, dfs_plant_MAP)) *
              mapping(:MAP, :Leaf_area, row=:Site) *
              visual(Lines)
fig_leaf_area = draw(p_leaf_area)
save("2-results/simulations/plot_sim/cum_leaf_area.png", fig_leaf_area)

#biomas bunch harvested
p_biomass_bunch_harvested = data(filter(x -> x.biomass_bunch_harvested_MAP > 0, dfs_plant_MAP)) *
                            mapping(:MAP, :biomass_bunch_harvested_MAP, row=:Site) *
                            visual(Lines)
fig_biomass_bunch_harvested = draw(p_biomass_bunch_harvested)
save("2-results/simulations/plot_sim/biomass_bunch_harvested.png", fig_biomass_bunch_harvested)

#biomas bunch harvested cum
p_biomass_bunch_harvested_cum = data(filter(x -> x.biomass_bunch_harvested_cum > 0, dfs_plant_MAP)) *
                                mapping(:MAP, :biomass_bunch_harvested_cum, row=:Site) *
                                visual(Lines)
fig_biomass_bunch_harvested_cum = draw(p_biomass_bunch_harvested_cum)
save("2-results/simulations/plot_sim/biomass_bunch_harvested_cum.png", fig_biomass_bunch_harvested_cum)

#total n bunches harvested
p_n_bunches_harvested = data(filter(x -> x.n_bunches_harvested_MAP > 0, dfs_plant_MAP)) *
                        mapping(:MAP, :n_bunches_harvested_MAP, row=:Site) *
                        visual(Lines)
fig_n_bunches_harvested = draw(p_n_bunches_harvested)
save("2-results/simulations/plot_sim/n_bunches_harvested.png", fig_n_bunches_harvested)

#n bunches harvested cum
p_n_bunches_harvested_cum = data(filter(x -> x.n_bunches_harvested_cum > 0, dfs_plant_MAP)) *
                            mapping(:MAP, :n_bunches_harvested_cum, row=:Site) *
                            visual(Lines)
fig_n_bunches_harvested_cum = draw(p_n_bunches_harvested_cum)
save("2-results/simulations/plot_sim/n_bunches_harvested_cum.png", fig_n_bunches_harvested_cum)

#phytomer_count
p_phytomer_count = data(filter(x -> x.phytomer_count > 0, dfs_plant_MAP)) *
                   mapping(:MAP, :phytomer_count, row=:Site) *
                   visual(Lines)
fig_phytomer_count = draw(p_phytomer_count)
save("2-results/simulations/plot_sim/phytomer_count.png", fig_phytomer_count)


#diff_phytomer_emmitted
p_diff_phytomer_emmitted = data(filter(x -> x.diff_phytomer_emmitted > 0, dfs_plant_MAP)) *
                           mapping(:MAP, :diff_phytomer_emmitted, row=:Site) *
                           visual(Lines)
fig_diff_phytomer_emmitted = draw(p_diff_phytomer_emmitted)
save("2-results/simulations/plot_sim/diff_phytomer_emmitted.png", fig_diff_phytomer_emmitted)

#!Plant
#extract only needed variable (20072025)
df_CIGE_plant = combine(
    groupby(df_CIGE, [:Site, :TreeId, :MAP]),
    :BunchMass => (x -> fn_no_missings(x, mean) .* 1e3) => :bunch_biomass, # in g
    :Cumulated_n_leaf_emitted => :Cumulated_n_leaf_emitted
)

df_plant = innerjoin(dfs_plant_MAP, df_CIGE_plant, on=[:Site, :MAP], makeunique=true, renamecols="_sim" => "_obs")

#plot total number of leaf/ phytomer emitted
df_leaf_emit_long = stack(df_plant, [:phytomer_count_sim, :Cumulated_n_leaf_emitted_obs], variable_name=:type, value_name=:leaf_emitted)

p_leaf_emittted = data(df_leaf_emit_long) * mapping(:MAP, :leaf_emitted, row=:Site, color=:type) * visual(Lines)
fig_leaf_emitted = draw(p_leaf_emittted; axis=(; xlabel="Month after planting", ylabel="Leaf_emitted"), figure=(; size=(1000, 600)), legend=(; position=:bottom))
save("2-results/calibration/XPalm/leaf_emitted.png", fig_leaf_emitted)


#!Female
dfs_female = vcat([s["Female"] for s in simulations]...)

p = data(filter(x -> x.biomass_bunch_harvested > 0, dfs_female)) *
    mapping(:MAP, :biomass_bunch_harvested, row=:Site) *
    visual(Scatter)
draw(p)

#bunch_biomass (g)
df_bunch_biomass_sim = combine(
    groupby(filter(x -> x.biomass_bunch_harvested > 0, dfs_female), [:Site, :MAP]),
    :biomass_bunch_harvested => (x -> mean(filter(x -> x > 0.0, x))) => :bunch_biomass,
    :date => last => :date,
    :planting_date => last => :planting_date
)

df_bunch_biomass = innerjoin(df_bunch_biomass_sim, df_CIGE_species, on=[:Site, :MAP], makeunique=true, renamecols="_sim" => "_obs")

df_bunch_biomass_long = stack(df_bunch_biomass, [:bunch_biomass_sim, :bunch_biomass_obs], variable_name=:type, value_name=:bunch_biomass)

p_bunch_biomass = data(df_bunch_biomass_long) * mapping(:MAP, :bunch_biomass, row=:Site, color=:type) * visual(Lines)
fig_bunch_biomass = draw(p_bunch_biomass; axis=(; xlabel="Month after planting", ylabel="Bunch biomass (g)"), figure=(; size=(1000, 600)), legend=(; position=:bottom))
save("2-results/calibration/XPalm/BunchMass.png", fig_bunch_biomass)

