module XPalmCalibration

using DataFrames, CSV, Statistics
using XPalm
using Dates
using PlantMeteo

# For the evaluation plots:
using AlgebraOfGraphics, CairoMakie



include("simulation/run_simulations_all_sites.jl")
include("simulation/integrate_simulation_by_map.jl")
include("meteo/import_meteo_cige.jl")

# Evaluation
include("rename_variables.jl")
include("evaluation/generic_plot.jl")

include("evaluation/phyllochron.jl")
include("evaluation/bunch_number.jl")

include("evaluation/evaluation.jl")

export run_simulations_all_cige_sites
export integrate_simulation_by_map
export import_meteo_cige
export evaluate
end