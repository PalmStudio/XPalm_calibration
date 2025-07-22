"this code is use to make join all dataframes from observation and simulation in correspond date, site, tree id, progeny"

using CSV, DataFrames, Dates, CairoMakie
using GLM, StatsBase, Statistics
using AlgebraOfGraphics

# Tree scale
mes_cum_prod = CSV.read("2-results/calibration/cumulated_production_mes.csv", DataFrame, missingstring=["NA", "NaN"])
mes_LAI = CSV.read("2-results/calibration/LAI_mes.csv", DataFrame, missingstring=["NA", "NaN"])
mes_cum_n_new_leaf_emitted = CSV.read("2-results/calibration/cum_n_new_leaf_emitted.csv", DataFrame, missingstring=["NA", "NaN"])
mes_leaf_MAP = CSV.read("2-results/calibration/time_leaf_MAP.csv", DataFrame, missingstring=["NA", "NaN"])
mes_flowering_MAP = CSV.read("2-results/calibration/time_leaf_flowering_MAP.csv", DataFrame, missingstring=["NA", "NaN"])
mes_harvest_MAP = CSV.read("2-results/calibration/time_flowering_harvest_MAP.csv", DataFrame, missingstring=["NA", "NaN"])

merged_CIGE = outerjoin(
    mes_cum_prod,
    mes_LAI,
    mes_cum_n_new_leaf_emitted,
    mes_leaf_MAP,
    mes_flowering_MAP,
    mes_harvest_MAP,
    on=[:TreeId, :Date, :MAP, :Site, :IdGenotype],
    makeunique=true
)
sort!(merged_CIGE, [:TreeId, :Site, :Date])
select!(merged_CIGE, :Site, :IdGenotype, :TreeId, :Date, :MAP, :PhytomerNumber, :)