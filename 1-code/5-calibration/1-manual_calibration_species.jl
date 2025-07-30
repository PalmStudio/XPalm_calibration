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
    :Cumulated_n_leaf_emitted => (x -> fn_no_missings(x, mean)) => :Cumulated_n_leaf_emitted, #!good
    :LeafArea => (x -> fn_no_missings(x, mean)) => :Leaf_area_17,
    :BunchMass => (x -> fn_no_missings(x, mean) .* 1e3) => :bunch_biomass, # in g,
    :biomass_dry_fruit => (x -> fn_no_missings(x, mean) .* 1e3) => :biomass_dry_fruit
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

begin
    # Importing the default parameters values
    params_default = YAML.load_file("1-code/5-calibration/xpalm_parameters_manual_calibration_1.yml")

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
        "Scene" => (:lai, :ET0, :leaf_area),
        "Plant" => (:leaf_area, :biomass_bunch_harvested, :phytomer_count, :production_speed, :n_bunches_harvested_cum, :n_bunches_harvested, :biomass_bunch_harvested_cum,
            :biomass_fruit_harvested),
        # "Soil" => (:ftsw, :qty_H2O_C_Roots, :transpiration),
        "Leaf" => (:leaf_area, :biomass, :rank),
        #"Phytomer" => (:TT_flowering,),
        "Female" => (:biomass_bunch_harvested, :biomass_fruit_harvested, :fruits_number, :biomass_stalk_harvested, :biomass_fruits),
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
    :leaf_area => last => :Leaf_area, #total leaf area per month #!done
    :biomass_bunch_harvested => sum => :biomass_bunch_harvested_MAP, #total biomass bunch harvested
    :biomass_bunch_harvested_cum => last => :biomass_bunch_harvested_cum, #dynamic cumulated bunch biomass per MAP
    :biomass_fruit_harvested => sum => :biomass_fruit_harvested_MAP, #gr (?)
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

#!Plant scale simulation
df_plant = innerjoin(dfs_plant_MAP, df_CIGE_species, on=[:Site, :MAP], makeunique=true, renamecols="_sim" => "_obs")
transform!(groupby(df_plant, [:Site]), :phytomer_count_sim => (x -> x .- first(x)) => :Cumulated_n_leaf_emitted_sim)
#plot total number of leaf/ phytomer emitted
df_leaf_emit_long = stack(df_plant, [:Cumulated_n_leaf_emitted_sim, :Cumulated_n_leaf_emitted_obs], variable_name=:type, value_name=:leaf_emitted)
p_leaf_emittted = data(df_leaf_emit_long) * mapping(:MAP, :leaf_emitted, row=:Site, color=:type) * visual(Lines)
fig_leaf_emitted = draw(p_leaf_emittted; axis=(; xlabel="Month after planting", ylabel="Number of leaves emitted since first observation"), figure=(; size=(1000, 600)), legend=(; position=:bottom))
save("2-results/calibration/XPalm/1.leaf_emitted.png", fig_leaf_emitted) #!dont change its good



#!Leaf scale simulation
dfs_leaf = vcat([s["Leaf"] for s in simulations]...)
sort!(dfs_leaf, [:Site, :timestep])
filter!(x -> x.rank == 17, dfs_leaf)

dfs_leaf_MAP = combine(groupby(dfs_leaf, [:Site, :MAP]),
    :leaf_area => last => :Leaf_area_17)t

df_leaf = innerjoin(dfs_leaf_MAP, df_CIGE_species, on=[:Site, :MAP], makeunique=true, renamecols="_sim" => "_obs")

#plot leaf area
df_leaf_area_17_long = stack(df_leaf, [:Leaf_area_17_sim, :Leaf_area_17_obs], variable_name=:type, value_name=:Leaf_area_17)
filter!(row -> !ismissing(row.Leaf_area_17), df_leaf_area_17_long)

p_leaf_area_17 = data(df_leaf_area_17_long) * mapping(:MAP, :Leaf_area_17, row=:Site, color=:type) * visual(Lines)
fig_leaf_area_17 = draw(p_leaf_area_17; axis=(; xlabel="Month after planting", ylabel="Leaf area at rank 17"), figure=(; size=(1000, 600)), legend=(; position=:bottom))
save("2-results/calibration/XPalm/2.leaf_area_rank_17.png", fig_leaf_area_17) #!i think its good

#!Female scale simulation
dfs_female = vcat([s["Female"] for s in simulations]...)

p = data(filter(x -> x.biomass_bunch_harvested > 0, dfs_female)) *
    mapping(:MAP, :biomass_bunch_harvested, row=:Site) *
    visual(Scatter)
draw(p)

#bunch_biomass (g)
df_female_MAP = combine(
    groupby(dfs_female, [:Site, :MAP]),
    :biomass_bunch_harvested => (x -> mean(filter(x -> x > 0.0, x))) => :bunch_biomass,
    :biomass_fruit_harvested => (x -> mean(filter(x -> x > 0.0, x))) => :biomass_fruit_harvested_MAP, #gr (?)
)

p = data(filter(x -> x.biomass_fruit_harvested_MAP > 0, df_female_MAP)) *
    mapping(:MAP, :biomass_fruit_harvested_MAP, row=:Site) *
    visual(Scatter)
draw(p)

#biomass dry fruit in the plant scale #!need to confirm
CC_Fruit = 0.4857     # Fruit carbon content (gC g-1 dry mass)
water_content_mesocarp = 0.25  # Water content of the mesocarp
dry_to_fresh_ratio = 1 / (1 - water_content_mesocarp)  # Based on the mesocarp water content of 0.3

dfs_dry_MAP = combine(groupby(df_female_MAP, [:Site, :MAP]), #!need to check
    :biomass_fruit_harvested_MAP => (x -> x * 1e-3 / CC_Fruit) => :biomass_dry_fruit)

data(dfs_dry_MAP) * mapping(:MAP, :biomass_dry_fruit, color=:Site => nonnumeric) * visual(Scatter) |> draw()

df_dry_fruit_plant = innerjoin(dfs_dry_MAP, df_CIGE_species, on=[:Site, :MAP], makeunique=true, renamecols="_sim" => "_obs")
df_fruit_dry_long = stack(df_dry_fruit_plant, [:biomass_dry_fruit_sim, :biomass_dry_fruit_obs], variable_name=:type, value_name=:biomass_dry_fruit)
p_fruit_dry = data(df_fruit_dry_long) * mapping(:MAP, :biomass_dry_fruit, row=:Site, color=:type) * visual(Lines)
fig_fruit_dry = draw(p_fruit_dry; axis=(; xlabel="Month after planting", ylabel="Biomass dry fruit"), figure=(; size=(1000, 600)), legend=(; position=:bottom))
#save("2-results/calibration/XPalm/Biomass dry fruit.png", fig_fruit_dry=draw(p_fruit_dry; axis=(; xlabel="Month after planting", ylabel="Biomass dry fruit"), figure=(; size=(1000, 600)), legend=(; position=:bottom))

#bunch biomass
df_bunch_biomass = innerjoin(df_female_MAP, df_CIGE_species, on=[:Site, :MAP], makeunique=true, renamecols="_sim" => "_obs")
df_bunch_biomass_long = stack(df_bunch_biomass, [:bunch_biomass_sim, :bunch_biomass_obs], variable_name=:type, value_name=:bunch_biomass)
p_bunch_biomass = data(df_bunch_biomass_long) * mapping(:MAP, :bunch_biomass, row=:Site, color=:type) * visual(Lines)
fig_bunch_biomass = draw(p_bunch_biomass; axis=(; xlabel="Month after planting", ylabel="Bunch biomass (g)"), figure=(; size=(1000, 600)), legend=(; position=:bottom))
save("2-results/calibration/XPalm/BunchMass.png", fig_bunch_biomass)
