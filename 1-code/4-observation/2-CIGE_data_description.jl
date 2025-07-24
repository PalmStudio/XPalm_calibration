"this code is use to make join all dataframes from observation and simulation in correspond date, site, tree id, progeny"

using CSV, DataFrames, Dates
using AlgebraOfGraphics, CairoMakie


df_CIGE = CSV.read("2-results/calibration/CIGE/CIGE.csv", DataFrame)

#Plot BunchMass
p_bunchMass = data(filter(row -> !ismissing(row.BunchMass), df_CIGE)) *
              mapping(:MAP, :BunchMass, color=:TreeId, col=:IdGenotype, row=:Site, group=:TreeId) *
              visual(Lines)
fig_bunchMass = draw(p_bunchMass; axis=(; xlabel="Month after planting", ylabel="Bunch Mass (kg)"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
mkpath("2-results/calibration/CIGE")
save("2-results/calibration/CIGE/BunchMass.png", fig_bunchMass)

#plot mescarp oil content
p_DryMesocarpOilContent = data(filter(row -> !ismissing(row.DryMesocarpOilContent), df_CIGE)) *
                          mapping(:MAP, :DryMesocarpOilContent, color=:TreeId, col=:IdGenotype, row=:Site, group=:TreeId) *
                          visual(Lines)
fig_oilmesocarp = draw(p_DryMesocarpOilContent; axis=(; xlabel="Month after planting", ylabel="Dry Mesocarp Oil Content (%)"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/calibration/CIGE/DryMesocarpOilContent.png", fig_oilmesocarp)

#plot mescarp water content
p_MesocarpsSampleWC = data(filter(row -> !ismissing(row.MesocarpsSampleWC), df_CIGE)) * #!theres huge increase in PR
                      mapping(:MAP, :MesocarpsSampleWC, color=:TreeId, col=:IdGenotype, row=:Site, group=:TreeId) *
                      visual(Lines)

fig_MesocarpsSampleWC = draw(p_MesocarpsSampleWC; axis=(; xlabel="Month after planting", ylabel="Mesocarp water content (%)"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/calibration/CIGE/fig_MesocarpsSampleWC.png", fig_MesocarpsSampleWC)

#plot number of fruit
p_nFruit = data(filter(row -> !ismissing(row.n_of_fruit), df_CIGE)) * #!GE03 and GE16 not available in PR and TOWE
           mapping(:MAP, :n_of_fruit, color=:TreeId, col=:IdGenotype, row=:Site, group=:TreeId) *
           visual(Lines)
fig_n_fruit = draw(p_nFruit; axis=(; xlabel="Month after planting", ylabel="Number of fruit"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/calibration/CIGE/n_of_fruit.png", fig_n_fruit)

#plot biomass fresh fruit
p_biomass_fresh_fruit = data(filter(row -> !ismissing(row.biomass_fresh_fruit), df_CIGE)) *
                        mapping(:MAP, :biomass_fresh_fruit, color=:TreeId, col=:IdGenotype, row=:Site) *
                        visual(Lines)
fig_biomass_fresh_fruit = draw(p_biomass_fresh_fruit; axis=(; xlabel="Month after planting", ylabel="Biomass fresh fruit"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/calibration/CIGE/biomass_fresh_fruit.png", fig_biomass_fresh_fruit)

#plot biomass dry fruit
p_biomass_dry_fruit = data(filter(row -> !ismissing(row.biomass_dry_fruit), df_CIGE)) * #!GE03 is not available for all sites
                      mapping(:MAP, :biomass_dry_fruit, color=:TreeId, col=:IdGenotype, row=:Site) *
                      visual(Lines)
fig_biomass_dry_fruit = draw(p_biomass_dry_fruit; axis=(; xlabel="Month after planting", ylabel="Biomass dry fruit"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/calibration/CIGE/biomass_dry_fruit.png", fig_biomass_dry_fruit)

#plot stalk dry biomass
p_stalk_dry_biomass = data(filter(row -> !ismissing(row.stalk_dry_biomass), df_CIGE)) *#!GE03 is not available for all sites
                      mapping(:MAP, :stalk_dry_biomass, color=:TreeId, col=:IdGenotype, row=:Site) *
                      visual(Lines)
fig_stalk_dry_biomass = draw(p_stalk_dry_biomass; axis=(; xlabel="Month after planting", ylabel="Stalk dry biomass"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/calibration/CIGE/stalk_dry_biomass.png", fig_stalk_dry_biomass)

#plot stalk fresh biomass
p_stalk_fresh_biomass = data(filter(row -> !ismissing(row.stalk_fresh_biomass), df_CIGE)) * #!sudden increase in TOWE 2 tree
                        mapping(:MAP, :stalk_fresh_biomass, color=:TreeId, col=:IdGenotype, row=:Site) *
                        visual(Lines)
#cek4 = filter(row ->  !ismissing(row.stalk_fresh_biomass) && row.stalk_fresh_biomass > 15 && row.Site == "TOWE" && row.IdGenotype == "GE12", df_CIGE)
fig_stalk_fresh_biomass = draw(p_stalk_fresh_biomass; axis=(; xlabel="Month after planting", ylabel="Stalk fresh biomass"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/calibration/CIGE/stalk_fresh_biomass.png", fig_stalk_fresh_biomass)

#plot cumulated number of leaf emitted
p_cum_n_Fruit = data(filter(row -> !ismissing(row.Cumulated_n_leaf_emitted), df_CIGE)) *
                mapping(:MAP, :Cumulated_n_leaf_emitted, color=:TreeId, col=:IdGenotype, row=:Site) *
                visual(Lines)
fig_cum_n_fruit = draw(p_cum_n_Fruit; axis=(; xlabel="Month after planting", ylabel="Cumulated number of n leaf emitted"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/calibration/CIGE/Cumulated_n_leaf_emitted.png", fig_cum_n_fruit)

#plot phyllocron days per MAP
p_phyllochron_days_per_MAP = data(filter(row -> !ismissing(row.phyllochron_days_per_MAP), df_CIGE)) *
                             mapping(:MAP, :phyllochron_days_per_MAP, color=:TreeId, col=:IdGenotype, row=:Site) *
                             visual(Lines)
fig_phyllochron_days_per_MAP = draw(p_phyllochron_days_per_MAP; axis=(; xlabel="Month after planting", ylabel="phyllocron days per MAP"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/calibration/CIGE/phyllochron_days.png", fig_phyllochron_days_per_MAP)

#plot time between leaf emitted and flowering MAP
p_day_flowering_MAP = data(filter(row -> !ismissing(row.day_flowering_MAP), df_CIGE)) *
                      mapping(:MAP, :day_flowering_MAP, color=:TreeId, col=:IdGenotype, row=:Site) *
                      visual(Lines)
fig_day_flowering_MAP = draw(p_day_flowering_MAP; axis=(; xlabel="Month after planting", ylabel="Time between leaf emitted and flowering"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/calibration/CIGE/day_flowering.png", fig_day_flowering_MAP)

#plot time between flowering and harvest MAP
p_days_harvest_MAP = data(filter(row -> !ismissing(row.days_harvest_MAP), df_CIGE)) *
                     mapping(:MAP, :days_harvest_MAP, color=:TreeId, col=:IdGenotype, row=:Site) *
                     visual(Lines)
fig_days_harvest_MAP = draw(p_days_harvest_MAP; axis=(; xlabel="Month after planting", ylabel="Time between flowering and harvest"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/calibration/CIGE/days_harvest.png", fig_days_harvest_MAP)

#plot leaf area per phytomer
p_LeafArea = data(filter(row -> !ismissing(row.LeafArea), df_CIGE)) *
             mapping(:MAP, :LeafArea, color=:PhytomerNumber, col=:IdGenotype, row=:Site, group=:TreeId) *
             visual(Lines)
fig_LeafArea = draw(p_LeafArea; axis=(; xlabel="Month after planting", ylabel="Leaf Area"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/calibration/CIGE/LeafArea.png", fig_LeafArea)

#leaf 

#plot whole leaf fresh weight
p_WholeLeafFreshWeight = data(filter(row -> !ismissing(row.WholeLeafFreshWeight), df_CIGE)) *
                         mapping(:MAP, :WholeLeafFreshWeight, color=:PhytomerNumber, col=:IdGenotype, row=:Site, group=:TreeId) *
                         visual(Lines)
fig_WholeLeafFreshWeight = draw(p_WholeLeafFreshWeight; axis=(; xlabel="Month after planting", ylabel="Whole Leaf Fresh Weight"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/calibration/CIGE/WholeLeafFreshWeight.png", fig_WholeLeafFreshWeight)

#plot rachis length 
p_RachisLength = data(filter(row -> !ismissing(row.RachisLength), df_CIGE)) *
                 mapping(:MAP, :RachisLength, color=:PhytomerNumber, col=:IdGenotype, row=:Site, group=:TreeId) *
                 visual(Lines)
fig_RachisLength = draw(p_RachisLength; axis=(; xlabel="Month after planting", ylabel="Rachis Length"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/calibration/CIGE/RachisLength.png", fig_RachisLength)

#plot rachis fresh weight 
p_RachisFreshWeight = data(filter(row -> !ismissing(row.RachisFreshWeight), df_CIGE)) *
                      mapping(:MAP, :RachisFreshWeight, color=:PhytomerNumber, col=:IdGenotype, row=:Site, group=:TreeId) *
                      visual(Lines)
fig_RachisFreshWeight = draw(p_RachisFreshWeight; axis=(; xlabel="Month after planting", ylabel="Rachis Fresh Weight"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/calibration/CIGE/RachisFreshWeight.png", fig_RachisFreshWeight)

#plot rachis dry weight 
p_RachisDryWeight = data(filter(row -> !ismissing(row.RachisDryWeight), df_CIGE)) *
                    mapping(:MAP, :RachisDryWeight, color=:PhytomerNumber, col=:IdGenotype, row=:Site, group=:TreeId) *
                    visual(Lines)
fig_RachisDryWeight = draw(p_RachisDryWeight; axis=(; xlabel="Month after planting", ylabel="Rachis Dry Weight"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/calibration/CIGE/RachisDryWeight.png", fig_RachisDryWeight)

#plot rachis water content
p_RachisWC = data(filter(row -> !ismissing(row.RachisWC), df_CIGE)) *
             mapping(:MAP, :RachisWC, color=:PhytomerNumber, col=:IdGenotype, row=:Site, group=:TreeId) * #! theres too drop and fluctuated to be check
             visual(Lines)
#cek6 = filter(row -> !ismissing(row.RachisWC) && (row.RachisWC < 0.4 || row.RachisWC > 0.8), df_CIGE)
fig_RachisWC = draw(p_RachisWC; axis=(; xlabel="Month after planting", ylabel="Rachis Water Content"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/calibration/CIGE/RachisFreshWeight.png", fig_RachisWC)

#plot petiole length
p_PetioleLength = data(filter(row -> !ismissing(row.PetioleLength), df_CIGE)) *
                  mapping(:MAP, :PetioleLength, color=:PhytomerNumber, col=:IdGenotype, row=:Site, group=:TreeId) *
                  visual(Lines)
fig_PetioleLength = draw(p_PetioleLength; axis=(; xlabel="Month after planting", ylabel="Petiole Length"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/calibration/CIGE/PetioleLength.png", fig_PetioleLength)

#plot petiole fresh weight
p_PetioleFreshWeight = data(filter(row -> !ismissing(row.PetioleFreshWeight), df_CIGE)) *
                       mapping(:MAP, :PetioleFreshWeight, color=:PhytomerNumber, col=:IdGenotype, row=:Site, group=:TreeId) *
                       visual(Lines)
fig_PetioleFreshWeight = draw(p_PetioleFreshWeight; axis=(; xlabel="Month after planting", ylabel="Petiole Fresh Weight"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/calibration/CIGE/PetioleFreshWeight.png", fig_PetioleFreshWeight)

#plot petiole dry weight
p_PetioleDryWeight = data(filter(row -> !ismissing(row.PetioleDryWeight), df_CIGE)) *
                     mapping(:MAP, :PetioleDryWeight, color=:PhytomerNumber, col=:IdGenotype, row=:Site, group=:TreeId) *
                     visual(Lines)
fig_PetioleDryWeight = draw(p_PetioleDryWeight; axis=(; xlabel="Month after planting", ylabel="Petiole Dry Weight"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/calibration/CIGE/PetioleFreshWeight.png", fig_PetioleDryWeight)

#plot petiole water content
p_PetioleWC = data(filter(row -> !ismissing(row.PetioleWC), df_CIGE)) *
              mapping(:MAP, :PetioleWC, color=:PhytomerNumber, col=:IdGenotype, row=:Site, group=:TreeId) *
              visual(Lines)
fig_PetioleWC = draw(p_PetioleWC; axis=(; xlabel="Month after planting", ylabel="Petiole water content"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/calibration/CIGE/PetioleWC.png", fig_PetioleWC)

#plot number of leaflet 
p_NumberOfLeaflets = data(filter(row -> !ismissing(row.NumberOfLeaflets), df_CIGE)) *
                     mapping(:MAP, :NumberOfLeaflets, color=:PhytomerNumber, col=:IdGenotype, row=:Site, group=:TreeId) *
                     visual(Lines)
fig_NumberOfLeaflets = draw(p_NumberOfLeaflets; axis=(; xlabel="Month after planting", ylabel="Number of leaflet"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/calibration/CIGE/NumberOfLeaflets.png", fig_NumberOfLeaflets)

#plot leaflet fresh weight
p_LeafletsFreshWeight = data(filter(row -> !ismissing(row.LeafletsFreshWeight), df_CIGE)) *
                        mapping(:MAP, :LeafletsFreshWeight, color=:PhytomerNumber, col=:IdGenotype, row=:Site, group=:TreeId) *
                        visual(Lines)
fig_LeafletsFreshWeight = draw(p_LeafletsFreshWeight; axis=(; xlabel="Month after planting", ylabel="Leaflet fresh weight"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/calibration/CIGE/LeafletsFreshWeight.png", fig_LeafletsFreshWeight)

#plot leaflet dry weight
p_LeafletsDryWeight = data(filter(row -> !ismissing(row.LeafletsDryWeight), df_CIGE)) *
                      mapping(:MAP, :LeafletsDryWeight, color=:PhytomerNumber, col=:IdGenotype, row=:Site, group=:TreeId) *
                      visual(Lines)
fig_LeafletsDryWeight = draw(p_LeafletsDryWeight; axis=(; xlabel="Month after planting", ylabel="Leaflet dry weight"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/calibration/CIGE/LeafletsDryWeight.png", fig_LeafletsDryWeight)

#average leaflet area position
stack_leaflet_area = stack(df_CIGE,
    [:AverageleafletAreaBase, :AverageleafletAreaMidd, :AverageleafletAreaTop],
    variable_name=:position,
    value_name=:avg_leaflet)
dropmissing!(stack_leaflet_area, :avg_leaflet)
p_avg_leaflet_SMSE = data(filter(row -> row.Site == "SMSE", stack_leaflet_area)) *
                     mapping(:MAP, :avg_leaflet, color=:TreeId, row=:position, col=:IdGenotype) *
                     visual(Lines)
fig_AverageleafletArea = draw(p_avg_leaflet_SMSE; axis=(; xlabel="Month after planting", ylabel="Average leaflet area position"), figure=(; size=(1000, 800)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/calibration/CIGE/AverageleafletArea.png", fig_AverageleafletArea)
