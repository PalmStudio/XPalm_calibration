"this code is use to make join all dataframes from observation and simulation in correspond date, site, tree id, progeny"

using CSV, DataFrames, Dates
using AlgebraOfGraphics, CairoMakie

# Please run `1-CIGE_calibration_database.jl` first to generate the CIGE.csv file
df_CIGE = CSV.read("2-results/calibration/CIGE/CIGE.csv", DataFrame)

const variable_labels = Dict(
    "bunch_fresh_biomass" => "Bunch fresh biomass (kg plant⁻¹)",
    "cumulated_n_leaf_emitted" => "Cumulative number of leaves emitted (plant⁻¹)",
    "bunch_dry_biomass" => "Bunch dry biomass (kg plant⁻¹)",
    "total_n_bunches_harvested" => "Total number of bunches harvested (plant⁻¹)",
    "Leaf_area_17" => "Leaf area 17 (m² plant⁻¹)",
    "avg_n_fruit_per_bunch" => "Average number of fruits (bunch⁻¹)",
    "fruit_dry_mass_per_bunch" => "Fruit dry mass (kg bunch⁻¹)",
    "fruit_fresh_mass_per_bunch" => "Fruit fresh mass (kg bunch⁻¹)",
    "bunch_dry_mass_per_bunch" => "Bunch dry mass (kg bunch⁻¹)",
    "bunch_fresh_mass_per_bunch" => "Bunch fresh mass (kg bunch⁻¹)",
    "stalk_dry_biomass_per_bunch" => "Stalk dry biomass (kg bunch⁻¹)",
    "stalk_fresh_biomass_per_bunch" => "Stalk fresh biomass (kg bunch⁻¹)",)

#plot cumulated FFB MAP 0 - 100

df_CIGE_species = combine( #here is we dont consider about the genotype thats why mostly we use the mean from all treeId to get the value of each tree
    groupby(df_CIGE, [:Site, :MAP]),
    :bunch_fresh_mass_total => (x -> fn_no_missings(x, mean)) => :bunch_fresh_biomass,) # in kg, #!FFB
FFB_0_to_100 = filter(row -> (0 <= row.MAP <= 100) && !ismissing(row.bunch_fresh_biomass), df_CIGE_species)[:, [:MAP, :Site, :bunch_fresh_biomass]]
transform!(groupby(FFB_0_to_100, :Site), :bunch_fresh_biomass => (x -> cumsum(x) .- first(cumsum(x))) => :cumulated_FFB)
p_ffb_cum = data(FFB_0_to_100) *
            mapping(:MAP, :cumulated_FFB => "Cumulated FFB (kg plant⁻¹)", color=:Site) *
            visual(Lines)
fig_FFB_cum = draw(p_ffb_cum; axis=(; xlabel="Month after planting"))
save("2-results/calibration/CIGE/Growth/FFB_cum (kg plant⁻¹).png", fig_FFB_cum)

#Plot FFB (kg plant⁻¹)
p_FFB = data(filter(row -> !ismissing(row.bunch_fresh_mass_total), df_CIGE)) *
        mapping(:MAP, :bunch_fresh_mass_total, color=:TreeId, col=:IdGenotype, row=:Site, group=:TreeId) *
        visual(Lines)
fig_FFB = draw(p_FFB; axis=(; xlabel="Month after planting", ylabel="FFB (kg plant⁻¹)"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
mkpath("2-results/calibration/CIGE/Growth")
save("2-results/calibration/CIGE/Growth/FFB (kg plant⁻¹).png", fig_FFB)

#plot mescarp oil content
p_DryMesocarpOilContent = data(filter(row -> !ismissing(row.DryMesocarpOilContent), df_CIGE)) *
                          mapping(:MAP, :DryMesocarpOilContent, color=:TreeId, col=:IdGenotype, row=:Site, group=:TreeId) *
                          visual(Lines)
fig_oilmesocarp = draw(p_DryMesocarpOilContent; axis=(; xlabel="Month after planting", ylabel="Dry Mesocarp Oil Content (% bunch⁻¹)"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/calibration/CIGE/Growth/DryMesocarpOilContent.png", fig_oilmesocarp)

#plot mescarp water content
p_MesocarpsSampleWC = data(filter(row -> !ismissing(row.MesocarpsSampleWC), df_CIGE)) * #!theres huge increase in PR
                      mapping(:MAP, :MesocarpsSampleWC, color=:TreeId, col=:IdGenotype, row=:Site, group=:TreeId) *
                      visual(Lines)

fig_MesocarpsSampleWC = draw(p_MesocarpsSampleWC; axis=(; xlabel="Month after planting", ylabel="Mesocarp water content (% bunch⁻¹)"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/calibration/CIGE/Growth/MesocarpsSampleWC.png", fig_MesocarpsSampleWC)

#plot number average number of fruit per bunch
p_nFruit = data(filter(row -> !ismissing(row.n_of_fruit_average), df_CIGE)) * #!GE03 and GE16 not available in PR and TOWE
           mapping(:MAP, :n_of_fruit_average, color=:TreeId, col=:IdGenotype, row=:Site, group=:TreeId) *
           visual(Lines)
fig_n_fruit = draw(p_nFruit; axis=(; xlabel="Month after planting", ylabel="Number of fruit (bunch⁻¹)"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/calibration/CIGE/n_of_fruit.png", fig_n_fruit)

#plot number of bunch
p_nBunch = data(filter(row -> !ismissing(row.n_of_bunch), df_CIGE)) *
           mapping(:MAP, :n_of_bunch, color=:TreeId, col=:IdGenotype, row=:Site, group=:TreeId) *
           visual(Lines)
fig_n_bunch = draw(p_nBunch; axis=(; xlabel="Month after planting", ylabel="Number of bunch"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/calibration/CIGE/n_of_bunch.png", fig_n_bunch)

#plot biomass fresh fruit per bunch
p_biomass_fresh_fruit = data(filter(row -> !ismissing(row.fruit_fresh_mass_per_bunch), df_CIGE)) *
                        mapping(:MAP, :fruit_fresh_mass_per_bunch, color=:TreeId, col=:IdGenotype, row=:Site) *
                        visual(Lines)
fig_biomass_fresh_fruit = draw(p_biomass_fresh_fruit; axis=(; xlabel="Month after planting", ylabel="Biomass fresh fruit"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/calibration/CIGE/biomass_fresh_fruit.png", fig_biomass_fresh_fruit)

#plot biomass dry fruit per bunch
p_biomass_dry_fruit = data(filter(row -> !ismissing(row.fruit_dry_mass_per_bunch), df_CIGE)) * #!GE03 is not available for all sites
                      mapping(:MAP, :fruit_dry_mass_per_bunch, color=:TreeId, col=:IdGenotype, row=:Site) *
                      visual(Lines)
fig_biomass_dry_fruit = draw(p_biomass_dry_fruit; axis=(; xlabel="Month after planting", ylabel="Biomass dry fruit"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/calibration/CIGE/fruit_dry_mass_per_bunch.png", fig_biomass_dry_fruit)

#plot stalk dry biomass per bunch
p_stalk_dry_biomass = data(filter(row -> !ismissing(row.stalk_dry_biomass_per_bunch), df_CIGE)) *#!GE03 is not available for all sites
                      mapping(:MAP, :stalk_dry_biomass_per_bunch, color=:TreeId, col=:IdGenotype, row=:Site) *
                      visual(Lines)
fig_stalk_dry_biomass = draw(p_stalk_dry_biomass; axis=(; xlabel="Month after planting", ylabel="Stalk dry biomass"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/calibration/CIGE/stalk_dry_biomass.png", fig_stalk_dry_biomass)

#plot stalk fresh biomass per bunch
p_stalk_fresh_biomass = data(filter(row -> !ismissing(row.stalk_fresh_biomass_per_bunch), df_CIGE)) * #!sudden increase in TOWE 2 tree
                        mapping(:MAP, :stalk_fresh_biomass_per_bunch, color=:TreeId, col=:IdGenotype, row=:Site) *
                        visual(Lines)
#cek4 = filter(row ->  !ismissing(row.stalk_fresh_biomass) && row.stalk_fresh_biomass > 15 && row.Site == "TOWE" && row.IdGenotype == "GE12", df_CIGE)
fig_stalk_fresh_biomass = draw(p_stalk_fresh_biomass; axis=(; xlabel="Month after planting", ylabel="Stalk fresh biomass"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/calibration/CIGE/stalk_fresh_biomass.png", fig_stalk_fresh_biomass)

#plot cumulated number of leaf emitted 
p_cum_n_Leaf = data(filter(row -> !ismissing(row.Cumulated_n_leaf_emitted), df_CIGE)) *
               mapping(:MAP, :Cumulated_n_leaf_emitted, color=:TreeId, col=:IdGenotype, row=:Site) *
               visual(Lines)
fig_cum_n_Leaf = draw(p_cum_n_Leaf; axis=(; xlabel="Month after planting", ylabel="Cumulated number of n leaf emitted"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/calibration/CIGE/Cumulated_n_leaf_emitted.png", fig_cum_n_Leaf)

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

#plot all plot together


#leaf 

#plot whole leaf fresh weight
p_WholeLeafFreshWeight = data(filter(row -> !ismissing(row.WholeLeafFreshWeight), df_CIGE)) *
                         mapping(:MAP, :WholeLeafFreshWeight, color=:PhytomerNumber, col=:IdGenotype, row=:Site, group=:TreeId) *
                         visual(Lines)
fig_WholeLeafFreshWeight = draw(p_WholeLeafFreshWeight; axis=(; xlabel="Month after planting", ylabel="Whole Leaf Fresh Weight"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/calibration/CIGE/WholeLeafFreshWeight.png", fig_WholeLeafFreshWeight)

#plot rachis length #!remove the PR GE16 <200
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

#plot rachis dry weight #!remove the high value in SMSE GE09, PR GE16, and low value in TOWE GE16
p_RachisDryWeight = data(filter(row -> !ismissing(row.RachisDryWeight), df_CIGE)) *
                    mapping(:MAP, :RachisDryWeight, color=:PhytomerNumber, col=:IdGenotype, row=:Site, group=:TreeId) *
                    visual(Lines)
fig_RachisDryWeight = draw(p_RachisDryWeight; axis=(; xlabel="Month after planting", ylabel="Rachis Dry Weight"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/calibration/CIGE/RachisDryWeight.png", fig_RachisDryWeight)

#plot rachis water content
p_RachisWC = data(filter(row -> !ismissing(row.RachisWC), df_CIGE)) * #!remove the row.RachisWC < 0.5 || row.RachisWC > 0.81
             mapping(:MAP, :RachisWC, color=:PhytomerNumber, col=:IdGenotype, row=:Site, group=:TreeId) *
             visual(Lines)
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
p_NumberOfLeaflets = data(filter(row -> !ismissing(row.NumberOfLeaflets), df_CIGE)) * #!delete PR <200
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

#average individual bunch mass all map between sites

df_avg_bunch = combine(groupby(df_CIGE, [:Site]), :bunch_fresh_mass_total => (x -> mean(filter(!ismissing, x) |> y -> filter(z -> z > 0.0, y))) => :bunch_biomass)

p_avg_bunch = data(filter(row -> !ismissing(row.bunch_fresh_mass_total), df_CIGE)) *
              mapping(:MAP, :bunch_fresh_mass_total, color=:TreeId, col=:IdGenotype, row=:Site, group=:TreeId) *
              visual(Lines)
fig_bunchMass = draw(p_avg_bunch; axis=(; xlabel="Month after planting", ylabel="Bunch Mass (kg)"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))

#!plot the avergae bunch water content
bunch_wc = combine(groupby(df_CIGE, [:Site]), :bunch_water_content => (x -> mean(skipmissing(x))) => :avg_bunch_water_content)
p_bunch_wc = data(bunch_wc) * mapping(:Site, :avg_bunch_water_content) * visual(BarPlot)

fig_bunch_wc = draw(
    p_bunch_wc;
    axis=(;
        xlabel="Site",
        ylabel="Average bunch water content (%)",
        yticks=0:0.05:0.5
    ),
    figure=(; size=(600, 400)),
    legend=(; position=:bottom)
)
save("2-results/calibration/1-report/5.avg_bunch_water_content.png", fig_bunch_wc)

#plot all together the cige plant scale into one figure
#! growth and production_cige
fig_prod = Figure(resolution=(1800, 1200))
prod1 = draw!(fig_prod[1, 1], p_FFB, axis=(; ylabel="FFB (kg plant⁻¹)", ylabelsize=20))
prod2 = draw!(fig_prod[2, 1], p_nBunch, axis=(; ylabel="Number of bunch (# plant⁻¹)", ylabelsize=20))
prod3 = draw!(fig_prod[3, 1], p_DryMesocarpOilContent, axis=(; ylabel="Dry mesocarp oil content (% plant⁻¹)", ylabelsize=20))
legend!(
    fig_prod[end+1, 1:1],
    prod1;
    orientation=:horizontal,
    nbanks=4,           # number of columns
    tellheight=true,
    labelsize=10
)
fig_prod
save("2-results/calibration/1-report/growth_production_combined.png", fig_prod)

#! growth and bunch related
fig_bunch = Figure(resolution=(1800, 2000))
bunch1 = draw!(fig_bunch[1, 1], p_nFruit, axis=(; ylabel="Number of fruits (bunch⁻¹)", ylabelsize=20))
bunch2 = draw!(fig_bunch[2, 1], p_biomass_fresh_fruit, axis=(; ylabel="Fruit fresh biomass (kg bunch⁻¹)", ylabelsize=20))
bunch3 = draw!(fig_bunch[3, 1], p_biomass_dry_fruit, axis=(; ylabel="Fruit dry biomass (kg bunch⁻¹)", ylabelsize=20))
bunch4 = draw!(fig_bunch[4, 1], p_stalk_dry_biomass, axis=(; ylabel="Stalk dry biomass (kg bunch⁻¹)", ylabelsize=20))
bunch5 = draw!(fig_bunch[5, 1], p_stalk_fresh_biomass, axis=(; ylabel="Stalk fresh biomass (kg bunch⁻¹)", ylabelsize=20))
legend!(
    fig_bunch[end+1, 1:1],
    bunch1;
    orientation=:horizontal,
    nbanks=4,           # number of columns
    tellheight=true,
    labelsize=10
)
fig_bunch
save("2-results/calibration/1-report/growth_bunch_combined.png", fig_bunch)

#!growth leaf phenology
fig_leaf = Figure(resolution=(1800, 1000))
leaf1 = draw!(fig_leaf[1, 1], p_cum_n_Leaf, axis=(; ylabel="Cumulated n of leaf emitted (plant⁻¹)", ylabelsize=20))
leaf2 = draw!(fig_leaf[2, 1], p_LeafArea, axis=(; ylabel="Leaf area (m² plant⁻¹)", ylabelsize=20))
# leaf3 = draw!(fig_leaf[3, 1], p_phyllochron_days_per_MAP, axis=(; ylabel="Time between new phyllochron (days)", ylabelsize=10))
# leaf4 = draw!(fig_leaf[4, 1], p_day_flowering_MAP, axis=(; ylabel="Time between flowering and harvest (days)", ylabelsize=10))
# leaf5 = draw!(fig_leaf[5, 1], p_days_harvest_MAP, axis=(; ylabel="Time between flowering and harvest (days)", ylabelsize=10))
legend!(
    fig_leaf[end+1, 1:1],
    leaf1;
    orientation=:horizontal,
    nbanks=4,           # number of columns
    tellheight=true,
    labelsize=10
)
fig_leaf
save("2-results/calibration/1-report/growth_leaves_combined.png", fig_leaf)

#!comparison between 2 scale
fig_scale = Figure(resolution=(1800, 1000))
prod1 = draw!(fig_scale[1, 1], p_FFB, axis=(; ylabel="FFB (kg plant⁻¹)", ylabelsize=20))
bunch1 = draw!(fig_scale[2, 1], p_nFruit, axis=(; ylabel="Number of fruits (bunch⁻¹)", ylabelsize=20))
legend!(
    fig_scale[end+1, 1:1],
    prod1;
    orientation=:horizontal,
    nbanks=4,           # number of columns
    tellheight=true,
    labelsize=10
)
fig_scale
save("2-results/calibration/1-report/FFB-nFruit.png", fig_scale)