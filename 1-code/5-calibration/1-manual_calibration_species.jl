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
    :BunchMass => (x -> fn_no_missings(x, mean) .* 1e3) => :bunch_biomass, # in g
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
        "Scene" => (:lai, :ET0),
        # "Plant" => (:leaf_area, :biomass_bunch_harvested, :plant_age, :biomass_bunch_harvested_cum, :aPPFD, :carbon_assimilation, :n_bunches_harvested_cum, :n_bunches_harvested, :Rm, :reserve, :yield_gap_oil, :biomass_oil_harvested),
        # "Soil" => (:ftsw, :qty_H2O_C_Roots, :transpiration),
        # "Leaf" => (:biomass,),
        # "Phytomer" => (:phytomer_count,),
        "Female" => (:biomass_bunch_harvested,),
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

dfs_scene = vcat([s["Scene"] for s in simulations]...)
p_lai = data(dfs_scene) *
        mapping(:MAP, :lai, row=:Site) *
        visual(Lines)
draw(p_lai)


dfs_female = vcat([s["Female"] for s in simulations]...)

p = data(filter(x -> x.biomass_bunch_harvested > 0, dfs_female)) *
    mapping(:MAP, :biomass_bunch_harvested, row=:Site) *
    visual(Scatter)
draw(p)

df_bunch_biomass_sim = combine(
    groupby(filter(x -> x.biomass_bunch_harvested > 0, dfs_female), [:Site, :MAP]),
    :biomass_bunch_harvested => (x -> mean(filter(x -> x > 0.0, x))) => :bunch_biomass,
    :date => last => :date,
    :planting_date => last => :planting_date
)

df_bunch_biomass = innerjoin(df_bunch_biomass_sim, df_CIGE_species, on=[:Site, :MAP], makeunique=true, renamecols="_sim" => "_obs")

df_bunch_biomass_long = stack(df_bunch_biomass, [:bunch_biomass_sim, :bunch_biomass_obs], variable_name=:type, value_name=:bunch_biomass)

p = data(df_bunch_biomass_long) * mapping(:MAP, :bunch_biomass, row=:Site, color=:type) * visual(Lines)
draw(p; axis=(; xlabel="Month after planting", ylabel="Bunch biomass (g)"), figure=(; size=(1000, 600)), legend=(; position=:bottom))