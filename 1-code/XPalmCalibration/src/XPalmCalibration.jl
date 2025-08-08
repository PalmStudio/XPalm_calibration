module XPalmCalibration

using DataFrames, CSV, Statistics
using XPalm
using Dates
using PlantMeteo

# For the evaluation plots:
using AlgebraOfGraphics, CairoMakie


# Helper functions
include("fn_no_missings.jl")

include("simulation/run_simulations_all_sites.jl")
include("simulation/integrate_simulation_by_map.jl")
include("simulation/compare_simulations.jl")
include("meteo/import_meteo_cige.jl")

# Evaluation
include("rename_variables.jl")
include("evaluation/start_MAP.jl")
include("evaluation/generic_plot.jl")
include("evaluation/statistics.jl")

include("evaluation/1-phyllochron.jl")
include("evaluation/2-FFB.jl")
include("evaluation/3-bunch_dry_biomass.jl")
include("evaluation/4-bunch_number.jl")
include("evaluation/5-leaf_area.jl")
include("evaluation/6-avg_n_fruit_per_bunch.jl")
include("evaluation/7-fruit_dry_mass_per_bunch.jl")
include("evaluation/8-fruit_fresh_mass_per_bunch.jl")
include("evaluation/9-bunch_dry_mass_per_bunch.jl")
include("evaluation/10-bunch_fresh_mass_per_bunch.jl")
include("evaluation/11-stalk_dry_biomass_per_bunch.jl")
include("evaluation/12-stalk_fresh_biomass_per_bunch.jl")


include("evaluation/evaluation.jl")

export fn_no_missings
export run_simulations_all_cige_sites, run_simulation_all_cige_by_map
export integrate_simulation_by_map
export import_meteo_cige
export evaluate
end
