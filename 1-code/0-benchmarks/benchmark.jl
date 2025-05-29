using CSV, DataFrames, Dates, YAML
using XPalm
using BenchmarkTools

# Just to test how much time it takes to run the simulations:
meteos = Dict(i => CSV.read("2-results/meteo_$(i)_with_nursery.csv", DataFrame) for i in ["smse", "presco", "towe"])
template_yaml = "0-data/xpalm_parameters.yml"
# Load the template YAML file:
template_parameters = YAML.load_file(template_yaml; dicttype=Dict{Symbol,Any})

out_vars = Dict(
    "Scene" => (:lai, :ET0),
    "Plant" => (:leaf_area, :biomass_bunch_harvested, :plant_age, :biomass_bunch_harvested_cum, :aPPFD, :carbon_assimilation),
    "Soil" => (:ftsw, :qty_H2O_C_Roots, :transpiration),
    "Leaf" => (:biomass,),
)

function make_sim(parameters)
    simulations_sites = Dict{String,DataFrame}[]
    for site in ["smse", "presco", "towe"]
        sim = xpalm(meteos[site], DataFrame; vars=out_vars, palm=XPalm.Palm(initiation_age=0, parameters=parameters))
        push!(simulations_sites, sim)
    end
    return simulations_sites
end

@benchmark make_sim(template_parameters)

# PSE v0.12 (XPalm V0.2.0), first run:
# BenchmarkTools.Trial: 1 sample with 1 evaluation per sample.
#  Single result which took 27.341 s (9.59% GC) to evaluate,
#  with a memory estimate of 35.79 GiB, over 629880501 allocations.

# PSE v0.12 (XPalm V0.2.0), second run:
# BenchmarkTools.Trial: 1 sample with 1 evaluation per sample.
#  Single result which took 26.858 s (9.25% GC) to evaluate,
#  with a memory estimate of 35.71 GiB, over 629176931 allocations.

# PSE v0.13 (XPalm V0.3.0), first run:
# BenchmarkTools.Trial: 1 sample with 1 evaluation per sample.
#  Single result which took 12.870 s (15.13% GC) to evaluate,
#  with a memory estimate of 23.61 GiB, over 479384599 allocations.

# PSE v0.13 (XPalm V0.3.0), second run:
# BenchmarkTools.Trial: 1 sample with 1 evaluation per sample.
#  Single result which took 13.118 s (14.74% GC) to evaluate,
#  with a memory estimate of 23.62 GiB, over 479511987 allocations.