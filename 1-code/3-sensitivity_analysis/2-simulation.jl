using XPalm
using YAML, CSV, DataFrames
using Base.Threads
using Statistics

# Names of the sites:
sites = ["smse", "presco", "towe"]

# Import the meteo data:
meteos = Dict(i => CSV.read("2-results/meteo_$(i)_with_nursery.csv", DataFrame) for i in sites)

# Import the template YAML file:
template_yaml = "0-data/xpalm_parameters.yml"
# Load the template YAML file:
template_parameters = YAML.load_file(template_yaml; dicttype=Dict{Symbol,Any})

# Importing the design of experiment (DOE) for the sensitivity analysis:
doe = CSV.read("2-results/doe.csv", DataFrame)

# Set the initial water content to the field capacity, because those values are correlated:
col_H_0 = findfirst(x -> endswith(x, "initial_water_content"), names(doe))
col_H_FC = findfirst(x -> endswith(x, "field_capacity"), names(doe))
doe[:, col_H_0] .= doe[:, col_H_FC]
#! remember to remove the `initial_water_content` from the sensitivity analysis.
#! We could also fix the `field_capacity` to a constant value, and analyse the effect of the `initial_water_content` instead.

function set_nested!(dict::D, path::Vector{<:AbstractString}, value) where D<:AbstractDict
    d = dict
    for k in path[1:end-1]
        d = d[k]
    end
    d[path[end]] = value
end

function set_nested!(dict::D, path::Vector{<:AbstractString}, value) where D<:Dict{Symbol,Any}
    d = dict
    for k in path[1:end-1]
        d = d[Symbol(k)]
    end
    d[Symbol(path[end])] = value
end


# Set the parameters for each site:
latitude = Dict("smse" => 2.93416, "presco" => 6.137, "towe" => 7.00) # Towe should be 7.65 but there's a bug in the model
altitude = Dict("smse" => 15.5, "presco" => 15.5, "towe" => 15.5)

# Define the output variables:

out_vars = Dict(
    "Scene" => (:lai, :ET0),
    "Plant" => (:leaf_area, :biomass_bunch_harvested, :plant_age, :biomass_bunch_harvested_cum, :aPPFD, :carbon_assimilation, :n_bunches_harvested_cum),
    "Soil" => (:ftsw, :qty_H2O_C_Roots, :transpiration),
    "Leaf" => (:biomass,),
    "Female" => (:biomass_bunch_harvested, :plant_age)
)

# Run simulations for each DOE row in parallel and collect results safely:
const N = nrow(doe)
# N = 10
# simulations = Vector{Dict{String,DataFrame}}(undef, N)
simulations = Dict(site => Vector{Dict{String,Any}}(undef, N) for site in sites)

@time Threads.@threads for i in 1:N # 40s for 10 simulations on my machine, 10 threads
    row = doe[i, :]
    parameters = deepcopy(template_parameters)

    # Set the parameters to the values in the current simulation of the DOE:
    for (k, v) in pairs(row)
        parameter_path = split(string(k), "|")
        set_nested!(parameters, parameter_path, v)
    end
    # YAML.write_file("xpalm_parameters_$i.yml", parameters) # Un-comment to write the parameters to a YAML file

    simulations_sites = Dict{String,DataFrame}[]
    for site in sites # site = sites[1]
        parameters[:plot][:latitude] = latitude[site]
        parameters[:plot][:altitude] = altitude[site]

        sim = xpalm(meteos[site], DataFrame; vars=out_vars, palm=XPalm.Palm(initiation_age=0, parameters=parameters))

        max_ftsw = maximum(sim["Soil"].ftsw)

        plant_age = sim["Plant"].plant_age
        nursery_duration = 1.5 * 365
        age_3 = nursery_duration + 3 * 365
        age_6 = nursery_duration + 6 * 365
        index_age_3_to_6 = findall(x -> age_3 < x <= age_6, plant_age)
        df_female_biomass_3_to_6 = filter(x -> x.biomass_bunch_harvested > 0.0 && age_3 < x.plant_age <= age_6, sim["Female"])
        average_female_biomass_3_to_6 = mean(df_female_biomass_3_to_6.biomass_bunch_harvested)

        simulations[site][i] = Dict(
            "doe" => i, "site" => site,
            "max_ftsw" => max_ftsw,
            "min_ftsw" => minimum(sim["Soil"].ftsw),
            "max_qty_H2O_C_Roots" => maximum(sim["Soil"].qty_H2O_C_Roots),
            "min_qty_H2O_C_Roots" => minimum(sim["Soil"].qty_H2O_C_Roots),
            "n_bunches_harvested_cum_3_to_6" => sim["Plant"].n_bunches_harvested_cum[last(index_age_3_to_6)] - sim["Plant"].n_bunches_harvested_cum[first(index_age_3_to_6)],
            "average_bunch_biomass_3_to_6" => average_female_biomass_3_to_6,
            # Compute the variables we need to investigate for the sensitivity analysis
        )
    end
end

df_simulations = vcat([DataFrame(i) for i in values(simulations)]...)

CSV.write("2-results/simulations.csv", df_simulations)

# ~10s per row of doe, with 3 sites per row coming to 15000 days simulated in total, gives 
# 705.73 μs per day, or 0.257 s per year.

# meteo_all = vcat(meteos["smse"], meteos["presco"], meteos["towe"])
# dfs_all = leftjoin(simulations, meteo_all, on=[:Site, :date,])
# sort!(dfs_all, [:Site, :timestep])
