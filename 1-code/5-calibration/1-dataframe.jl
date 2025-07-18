"this code is use to make join all dataframes from observation and simulation in correspond date, site, tree id, progeny"

using CSV, DataFrames, Dates, CairoMakie
using GLM, StatsBase, Statistics
using AlgebraOfGraphics

#bunch component
mes_cum_biomass_oil = CSV.read("2-results/calibration/cumulated_biomass_oil_mes.csv", DataFrame, missingstring=["NA", "NaN"])
mes_cum_n_bunch = CSV.read("2-results/calibration/cumulated_n_bunch_mes.csv", DataFrame, missingstring=["NA", "NaN"])
mes_cum_n_fruit = CSV.read("2-results/calibration/cumulated_n_fruit_mes.csv", DataFrame, missingstring=["NA", "NaN"])
mes_cum_prod = CSV.read("2-results/calibration/cumulated_production_mes.csv", DataFrame, missingstring=["NA", "NaN"])
mes_cum_stalk_biomass = CSV.read("2-results/calibration/cumulated_stalk_biomass_mes.csv", DataFrame, missingstring=["NA", "NaN"])
mes_cum_LAI = CSV.read("2-results/calibration/cumulated_LAI_mes.csv", DataFrame, missingstring=["NA", "NaN"])
mes_cum_rachis_length = CSV.read("2-results/calibration/cumulated_rachis_length_mes.csv", DataFrame, missingstring=["NA", "NaN"])
mes_avg_leaflet_length = CSV.read("2-results/calibration/avg_leaflet_length_mes.csv", DataFrame, missingstring=["NA", "NaN"])
mes_cum_n_new_leaf_emitted = CSV.read("2-results/calibration/cum_n_new_leaf_emitted.csv", DataFrame, missingstring=["NA", "NaN"])
mes_flowering_time_Phytomer = CSV.read("2-results/calibration/time_leaf_flowering_phytomer.csv", DataFrame, missingstring=["NA", "NaN"]) #date is flowering date, MAP is flowering MAP
mes_flowering_time_IdGen = CSV.read("2-results/calibration/time_leaf_flowering_IdGenotype.csv", DataFrame, missingstring=["NA", "NaN"])

merged_bunch = outerjoin(mes_cum_biomass_oil,
    mes_cum_n_bunch,
    mes_cum_n_fruit,
    mes_cum_prod,
    mes_cum_stalk_biomass,
    mes_cum_LAI,
    mes_cum_rachis_length,
    mes_avg_leaflet_length,
    mes_cum_n_new_leaf_emitted,
    mes_time_between_leaf_flowering,
    mes_flowering_time_IdGen,
    on=[:TreeId, :Date, :MAP, :Site, :IdGenotype], makeunique=true)
sort!(merged_bunch, [:Site, :Date])