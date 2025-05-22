using XPalm
using YAML, CSV, DataFrames

# Import the meteo data:
meteo_smse = CSV.read("2-results/meteo_smse_cleaned.csv", missingstring=["NA", "NaN"], DataFrame) #Benin
#! Here we should import the meteo of the three sites and make a simulation for each site

parameters = YAML.load_file("0-data/xpalm_parameters.yml"; dicttype=Dict{Symbol,Any})

# Import the template YAML file:
template_yaml = "0-data/xpalm_parameters.yml"
# Load the template YAML file:
template_parameters = YAML.load_file(template_yaml; dicttype=Dict{String,Any})

# Importing the design of experiment (DOE) for the sensitivity analysis:
doe = CSV.read("2-results/1-doe.csv", DataFrame)
function set_nested!(dict::D, path::Vector{<:AbstractString}, value) where D<:AbstractDict
    d = dict
    for k in path[1:end-1]
        d = d[k]
    end
    d[path[end]] = value
end


for row in eachrow(doe)
    parameters = copy(template_parameters)
    # YAML.write_file("xpalm_parameters_$i.yml", p.parameters) # Un-comment to write the parameters to a YAML file
    for (k, v) in pairs(row)
        parameter_path = split(string(k), "|")
        set_nested!(parameters, parameter_path, v)
    end

    #! Pseudo-code for the simulation of each row:
    # Make the simulation for each site:
    # for site in ["smse", "towe", "presco"]
    #     meteo = CSV.read("2-results/meteo_$site.csv", missingstring=["NA", "NaN"], DataFrame)
    #     #! update the parameters to match the site

    #     p = XPalm.Palm(parameters=parameters)

    #     sim = xpalm(
    #         meteo,
    #         DataFrame,
    #         #! check for the outputs we need!
    #         vars=Dict(
    #             "Scene" => (:lai, :ET0),
    #             "Plant" => (:leaf_area, :biomass_bunch_harvested, :plant_age, :biomass_bunch_harvested_cum, :aPPFD, :carbon_assimilation),
    #             "Soil" => (:ftsw, :qty_H2O_C2_Roots, :transpiration),
    #             "Leaf" => (:biomass,),
    #         ),
    #         palm=p
    #     )
    #     sim[!, :date] = meteo.date[sim.timestep]
    # end
end

