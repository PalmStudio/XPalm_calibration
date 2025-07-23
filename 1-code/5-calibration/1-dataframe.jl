"this code is use to make join all dataframes from observation and simulation in correspond date, site, tree id, progeny"

using CSV, DataFrames, Dates, CairoMakie
using GLM, StatsBase, Statistics
using AlgebraOfGraphics, CairoMakie

# Tree scale
mes_cum_prod = CSV.read("2-results/calibration/cumulated_production_mes.csv", DataFrame)
mes_cum_n_new_leaf_emitted = CSV.read("2-results/calibration/cum_n_new_leaf_emitted.csv", DataFrame)
mes_leaf_MAP = CSV.read("2-results/calibration/time_leaf_MAP.csv", DataFrame)
mes_flowering_MAP = CSV.read("2-results/calibration/time_leaf_flowering_MAP.csv", DataFrame)
mes_harvest_MAP = CSV.read("2-results/calibration/time_flowering_harvest_MAP.csv", DataFrame)
mes_leaf = CSV.read("2-results/calibration/data_leaf_rank_17.csv", DataFrame)
mes_stem = CSV.read("2-results/calibration/data_stem.csv", DataFrame)


merged_CIGE = outerjoin(
    mes_cum_prod,
    mes_cum_n_new_leaf_emitted,
    mes_leaf_MAP,
    mes_flowering_MAP,
    mes_harvest_MAP,
    mes_leaf,
    mes_stem,
    on=[:TreeId, :Date, :MAP, :Site, :IdGenotype],
    makeunique=true
)
sort!(merged_CIGE, [:TreeId, :Date, :MAP, :Site])
CSV.write("2-results/calibration/CIGE.csv", merged_CIGE)
#Plot BunchMass
p_bunchMass = data(filter(row -> !ismissing(row.BunchMass), merged_CIGE)) *
              mapping(:MAP, :BunchMass, color=:TreeId, col=:IdGenotype, row=:Site, group=:TreeId) *
              visual(Lines)
fig_bunchMass = draw(p_bunchMass; axis=(; xlabel="Month after planting", ylabel="Bunch Mass (kg)"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
mkpath("2-results/calibration/CIGE")
save("2-results/calibration/CIGE/BunchMass.png", fig_bunchMass)

#plot mescarp oil content
p_DryMesocarpOilContent = data(filter(row -> !ismissing(row.DryMesocarpOilContent), merged_CIGE)) *
                          mapping(:MAP, :DryMesocarpOilContent, color=:TreeId, col=:IdGenotype, row=:Site, group=:TreeId) *
                          visual(Lines)
fig_oilmesocarp = draw(p_DryMesocarpOilContent; axis=(; xlabel="Month after planting", ylabel="Dry Mesocarp Oil Content (%)"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/calibration/CIGE/DryMesocarpOilContent.png", fig_oilmesocarp)

#plot number of fruit
p_nFruit = data(filter(row -> !ismissing(row.n_of_fruit) && !(row.IdGenotype in ["GE03", "GE16"]), merged_CIGE)) *
           mapping(:MAP, :n_of_fruit, color=:TreeId, col=:IdGenotype, row=:Site, group=:TreeId) *
           visual(Lines)
fig_n_fruit = draw(p_nFruit; axis=(; xlabel="Month after planting", ylabel="Number of fruit"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/calibration/CIGE/DryMesocarpOilContent.png", fig_n_fruit)

#plot cumulated number of leaf emitted
p_cum_n_Fruit = data(filter(row -> !ismissing(row.Cumulated_n_leaf_emitted), merged_CIGE)) *
                mapping(:MAP, :Cumulated_n_leaf_emitted, color=:TreeId, col=:IdGenotype, row=:Site) *
                visual(Lines)
fig_cum_n_fruit = draw(p_cum_n_Fruit; axis=(; xlabel="Month after planting", ylabel="Cumulated number of n leaf emitted"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/calibration/CIGE/DryMesocarpOilContent.png", fig_cum_n_fruit)
