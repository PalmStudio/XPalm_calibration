using XPalm
using YAML, CSV, DataFrames

# Import the meteo data:
meteos = Dict(i => CSV.read("2-results/meteo_$(i)_with_nursery.csv", DataFrame) for i in ["smse", "presco", "towe"])

# Import the template YAML file:
template_yaml = "0-data/xpalm_parameters.yml"
# Load the template YAML file:
template_parameters = YAML.load_file(template_yaml; dicttype=Dict{Symbol,Any})

# Importing the design of experiment (DOE) for the sensitivity analysis:
doe = CSV.read("2-results/doe.csv", DataFrame)

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
    "Plant" => (:leaf_area, :biomass_bunch_harvested, :plant_age, :biomass_bunch_harvested_cum, :aPPFD, :carbon_assimilation),
    "Soil" => (:ftsw, :qty_H2O_C_Roots, :transpiration),
    "Leaf" => (:biomass,),
)

# Make the simulations for each row of the DOE, for each site:
simulations = DataFrame[]
# for row in eachrow(doe[1:2, 1:5])
for row in eachrow(doe)
    parameters = copy(template_parameters)

    # Set the parameters to the values in the current simulation of the DOE:
    for (k, v) in pairs(row)
        parameter_path = split(string(k), "|")
        set_nested!(parameters, parameter_path, v)
    end
    # YAML.write_file("xpalm_parameters_$i.yml", parameters) # Un-comment to write the parameters to a YAML file

    simulations_sites = DataFrame[]
    for site in ["smse", "presco", "towe"]
        parameters[:plot][:latitude] = latitude[site]
        parameters[:plot][:altitude] = altitude[site]

        sim = xpalm(meteos[site], DataFrame; vars=out_vars, palm=XPalm.Palm(initiation_age=0, parameters=parameters))
        sim[!, "Site"] .= site
        sim[!, :date] = meteos[site].date[sim.timestep]
        push!(simulations_sites, sim)
    end

    # Adding the dates to the simulations:
    dfs_all = vcat(simulations_sites...)

    push!(simulations, dfs_all)
end

# meteo_all = vcat(meteos["smse"], meteos["presco"], meteos["towe"])
# dfs_all = leftjoin(simulations, meteo_all, on=[:Site, :date,])
# sort!(dfs_all, [:Site, :timestep])
