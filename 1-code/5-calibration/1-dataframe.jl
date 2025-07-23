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

#plot mescarp water content
p_MesocarpsSampleWC = data(filter(row -> !ismissing(row.MesocarpsSampleWC), merged_CIGE)) * #!theres huge increase in PR
                      mapping(:MAP, :MesocarpsSampleWC, color=:TreeId, col=:IdGenotype, row=:Site, group=:TreeId) *
                      visual(Lines)
#cek3 = filter(row -> !ismissing(row.MesocarpsSampleWC) && row.Site == "PR" && row.MesocarpsSampleWC .> 0.8, merged_CIGE)
fig_MesocarpsSampleWC = draw(p_MesocarpsSampleWC; axis=(; xlabel="Month after planting", ylabel="Mesocarp water content (%)"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/calibration/CIGE/fig_MesocarpsSampleWC.png", fig_MesocarpsSampleWC)

#plot number of fruit
p_nFruit = data(filter(row -> !ismissing(row.n_of_fruit) && !(row.IdGenotype in ["GE03", "GE16"]), merged_CIGE)) * #!GE03 and GE16 not available should be delete before
           mapping(:MAP, :n_of_fruit, color=:TreeId, col=:IdGenotype, row=:Site, group=:TreeId) *
           visual(Lines)
fig_n_fruit = draw(p_nFruit; axis=(; xlabel="Month after planting", ylabel="Number of fruit"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/calibration/CIGE/n_of_fruit.png", fig_n_fruit)

#plot cumulated number of leaf emitted
p_cum_n_Fruit = data(filter(row -> !ismissing(row.Cumulated_n_leaf_emitted), merged_CIGE)) *
                mapping(:MAP, :Cumulated_n_leaf_emitted, color=:TreeId, col=:IdGenotype, row=:Site) *
                visual(Lines)
fig_cum_n_fruit = draw(p_cum_n_Fruit; axis=(; xlabel="Month after planting", ylabel="Cumulated number of n leaf emitted"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/calibration/CIGE/Cumulated_n_leaf_emitted.png", fig_cum_n_fruit)

#plot biomass fresh fruit
p_biomass_fresh_fruit = data(filter(row -> !ismissing(row.biomass_fresh_fruit), merged_CIGE)) *
                        mapping(:MAP, :biomass_fresh_fruit, color=:TreeId, col=:IdGenotype, row=:Site) *
                        visual(Lines)
fig_biomass_fresh_fruit = draw(p_biomass_fresh_fruit; axis=(; xlabel="Month after planting", ylabel="Biomass fresh fruit"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/calibration/CIGE/biomass_fresh_fruit.png", fig_biomass_fresh_fruit)

#plot biomass dry fruit
p_biomass_dry_fruit = data(filter(row -> !ismissing(row.biomass_dry_fruit) && !(row.IdGenotype == "GE03"), merged_CIGE)) * #!GE03 not available should be delete before
                      mapping(:MAP, :biomass_dry_fruit, color=:TreeId, col=:IdGenotype, row=:Site) *
                      visual(Lines)
fig_biomass_dry_fruit = draw(p_biomass_dry_fruit; axis=(; xlabel="Month after planting", ylabel="Biomas dry fruit"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/calibration/CIGE/biomass_dry_fruit.png", fig_biomass_dry_fruit)

#plot stalk dry biomass
p_stalk_dry_biomass = data(filter(row -> !ismissing(row.stalk_dry_biomass) && !(row.IdGenotype == "GE03"), merged_CIGE)) * #!GE03 not available should be delete before
                      mapping(:MAP, :stalk_dry_biomass, color=:TreeId, col=:IdGenotype, row=:Site) *
                      visual(Lines) #! consider to delete the stalk here row.TreeId == "TOWE_POGP37_2_GE12_4_28" && row.MAP=89 && row.IdGenotype= GE12 && row.Date == "2019-11-05"
#cek = filter(row -> row.TreeId == "TOWE_POGP37_2_GE12_4_28" && row.MAP == 89, merged_CIGE)
fig_stalk_dry_biomass = draw(p_stalk_dry_biomass; axis=(; xlabel="Month after planting", ylabel="Stalk dry biomass"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/calibration/CIGE/stalk_dry_biomass.png", fig_stalk_dry_biomass)

#plot stalk fresh biomass
p_stalk_fresh_biomass = data(filter(row -> !ismissing(row.stalk_fresh_biomass), merged_CIGE)) * #!sudden increase in TOWE 2 tree
                        mapping(:MAP, :stalk_fresh_biomass, color=:TreeId, col=:IdGenotype, row=:Site) *
                        visual(Lines)
#cek4 = filter(row ->  !ismissing(row.stalk_fresh_biomass) && row.stalk_fresh_biomass > 15 && row.Site == "TOWE" && row.IdGenotype == "GE12", merged_CIGE)
fig_stalk_fresh_biomass = draw(p_stalk_fresh_biomass; axis=(; xlabel="Month after planting", ylabel="Stalk fresh biomass"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/calibration/CIGE/stalk_fresh_biomass.png", fig_stalk_fresh_biomass)

#plot phyllocron days per MAP
p_phyllochron_days_per_MAP = data(filter(row -> !ismissing(row.phyllochron_days_per_MAP), merged_CIGE)) *
                             mapping(:MAP, :phyllochron_days_per_MAP, color=:TreeId, col=:IdGenotype, row=:Site) *
                             visual(Lines)
fig_phyllochron_days_per_MAP = draw(p_phyllochron_days_per_MAP; axis=(; xlabel="Month after planting", ylabel="phyllocron days per MAP"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/calibration/CIGE/phyllochron_days.png", fig_phyllochron_days_per_MAP)

#plot time between leaf emitted and flowering MAP
p_day_flowering_MAP = data(filter(row -> !ismissing(row.day_flowering_MAP), merged_CIGE)) *
                      mapping(:MAP, :day_flowering_MAP, color=:TreeId, col=:IdGenotype, row=:Site) *
                      visual(Lines)
fig_day_flowering_MAP = draw(p_day_flowering_MAP; axis=(; xlabel="Month after planting", ylabel="Time between leaf emitted and flowering"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/calibration/CIGE/day_flowering.png", fig_day_flowering_MAP)

#plot time between flowering and harvest MAP #! to check  TOWE_POGP37_1_GE16_19_9 the value is 45, sudden drop also sudden increse exist
p_days_harvest_MAP = data(filter(row -> !ismissing(row.days_harvest_MAP), merged_CIGE)) *
                     mapping(:MAP, :days_harvest_MAP, color=:TreeId, col=:IdGenotype, row=:Site) *
                     visual(Lines)
#cek2 = filter(row -> !ismissing(row.days_harvest_MAP) && row.days_harvest_MAP < 100 && row.IdGenotype == "GE16", merged_CIGE)
fig_days_harvest_MAP = draw(p_days_harvest_MAP; axis=(; xlabel="Month after planting", ylabel="Time between flowering and harvest"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/calibration/CIGE/days_harvest.png", fig_days_harvest_MAP)

#plot leaf area per phytomer
p_LeafArea = data(filter(row -> !ismissing(row.LeafArea), merged_CIGE)) *
             mapping(:MAP, :LeafArea, color=:PhytomerNumber, col=:IdGenotype, row=:Site, group=:TreeId) *
             visual(Lines)
fig_LeafArea = draw(p_LeafArea; axis=(; xlabel="Month after planting", ylabel="Leaf Area"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/calibration/CIGE/LeafArea.png", fig_LeafArea)

#plot rachis length per phytomer
p_RachisLength = data(filter(row -> !ismissing(row.RachisLength), merged_CIGE)) *
                 mapping(:MAP, :RachisLength, color=:PhytomerNumber, col=:IdGenotype, row=:Site, group=:TreeId) *
                 visual(Lines)
fig_RachisLength = draw(p_RachisLength; axis=(; xlabel="Month after planting", ylabel="Rachis Length"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/calibration/CIGE/RachisLength.png", fig_RachisLength)

#plot number of leaflet per phytomer
p_NumberOfLeaflets = data(filter(row -> !ismissing(row.NumberOfLeaflets), merged_CIGE)) *
                     mapping(:MAP, :NumberOfLeaflets, color=:PhytomerNumber, col=:IdGenotype, row=:Site, group=:TreeId) *
                     visual(Lines)
fig_NumberOfLeaflets = draw(p_NumberOfLeaflets; axis=(; xlabel="Month after planting", ylabel="Number of leaflet"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/calibration/CIGE/NumberOfLeaflets.png", fig_NumberOfLeaflets)

