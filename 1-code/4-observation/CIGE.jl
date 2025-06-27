#This code is to compute and data the field data from CIGE to compare with the model results afterwards

using CSV, DataFrames, Dates, CairoMakie
using GLM, StatsBase, Statistics
using AlgebraOfGraphics

# Data from CIGE
df_bunch_component = CSV.read("0-data/BunchComponent_CIGE.csv", DataFrame, missingstring=["NA", "NaN"])
df_leaf_growth = CSV.read("0-data/LeafGrowth_CIGE.csv", DataFrame, missingstring=["NA", "NaN"])
df_phenology = CSV.read("0-data/Pheno_CIGE.csv", DataFrame, missingstring=["NA", "NaN"])
df_stem_growth = CSV.read("0-data/StemGrowth_CIGE.csv", DataFrame, missingstring=["NA", "NaN"])

genotype = [ #considered genotype
        "GE02",
        "GE03",
        "GE06",
        "GE09",
        "GE12",
        "GE16"
]

#add year after planting
function year_planting!(df::DataFrame, map_col::Symbol)
        df.Year = (df[!, map_col] .÷ 12) .+ 1
        return df
end

year_planting!(df_bunch_component, :HarvestMAP)
year_planting!(df_leaf_growth, :MAP)
year_planting!(df_stem_growth, :MAP)

#special case for dataframe df_phenology
function mondf(d2::Date, d1::Date)
        return (year(d2) - year(d1)) * 12 + (month(d2) - month(d1))
end

function year_planting_2!(df::DataFrame)
        n = nrow(df)
        year_col = Vector{Union{Int,Missing}}(undef, n)

        last_valid_hmonth = missing
        last_year = missing

        for i in 1:n
                pdate = df.PlantingDate[i]
                hmonth = df.HarvestMonth[i]
                abmonth = df.AbortedMonth[i]
                asmonth = df.AppearedSpatheMonth[i]

                if hmonth !== missing
                        event_month = hmonth
                        last_valid_hmonth = hmonth
                elseif abmonth !== missing || asmonth !== missing
                        event_month = last_valid_hmonth
                else
                        event_month = missing
                end

                # if asmonth missing, take the value from previous row
                if event_month !== missing && pdate !== missing
                        map_month = mondf(event_month, pdate)
                        this_year = floor(Int, map_month / 12) + 1
                        year_col[i] = this_year
                        last_year = this_year
                else
                        year_col[i] = last_year
                end
        end

        df.Year = year_col
        return df
end

year_planting_2!(df_phenology)

"Bunch Component"
filter_bunch = filter(row -> row.IdGenotype in genotype, df_bunch_component)
group_bunch_treeId = groupby(filter_bunch, [:TreeId, :HarvestMAP, :Site])

#Cumulated production each tree 
comb_prod = combine(group_bunch_treeId, :BunchMass => (x -> sum(skipmissing(x))) => :Production, :IdGenotype => unique => :IdGenotype)
clean_prod = dropmissing(comb_prod, :Production)
cum_prod = transform(groupby(clean_prod, [:TreeId]), :Production => (x -> cumsum(skipmissing(x))) => :CumulatedProduction)
prod_tree = data(cum_prod) *
            mapping(:HarvestMAP, :CumulatedProduction, color=:TreeId, col=:IdGenotype, row=:Site) *
            visual(Lines)
fig_prod_tree = draw(prod_tree; axis=(; xlabel="Month after planting", ylabel="Cumulated yield (kg)"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/sensitivity/CIGE/prod_tree.png", fig_prod_tree)

#number of bunch per tree
n_of_bunch = combine(group_bunch_treeId, :BunchMass => (x -> count(!ismissing, x)) => :n_of_bunch, :IdGenotype => unique => :IdGenotype)
clean_n_bunch = dropmissing(n_of_bunch, :n_of_bunch)
cum_n_bunch = transform(groupby(clean_n_bunch, [:TreeId]), :n_of_bunch => (x -> cumsum(skipmissing(x))) => :Cumulated_n_bunch)
n_bunch_tree = data(cum_n_bunch) *
               mapping(:HarvestMAP, :Cumulated_n_bunch, col=:IdGenotype, row=:Site, color=:TreeId) *
               visual(Lines)
fig_n_bunch_tree = draw(n_bunch_tree; axis=(; xlabel="Month after planting", ylabel="Number of bunch"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/sensitivity/CIGE/n_bunch_tree.png", fig_n_bunch_tree)

#number of fruit yearly = number of fertile fruit + number of non-fertile fruit
n_of_fruit = transform(filter_bunch, [:NumberOfFertilFruits, :NumberOfUnfertilFruits] => ((f, n) -> ifelse.(ismissing.(f) .| ismissing.(n), missing, f .+ n)) => :n_of_fruit)
sum_of_fruit = combine(groupby(n_of_fruit, [:TreeId, :HarvestMAP, :Site]), :n_of_fruit => (x -> sum(skipmissing(x))) => :sum_of_fruit, :IdGenotype => unique => :IdGenotype)
clean_sum_fruit = dropmissing(sum_of_fruit, :sum_of_fruit)
cum_n_fruit = transform(groupby(clean_sum_fruit, [:TreeId]), :sum_of_fruit => (x -> cumsum(skipmissing(x))) => :Cumulated_n_fruit)
fruit_tree = data(cum_n_fruit) *
             mapping(:HarvestMAP, :Cumulated_n_fruit, color=:TreeId, col=:IdGenotype, row=:Site) *
             visual(Lines)
fig_fruit_tree = draw(fruit_tree; axis=(; xlabel="Month after planting", ylabel="Total number of fruit (tree/year)"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3)) #GE03 and GE16 in presco and TOwE is not take into account of number of fruit 
save("2-results/sensitivity/CIGE/n_fruit_tree.png", fig_fruit_tree)

#productivity

#productivity = innerjoin(comb_prod, n_of_bunch, sum_of_fruit, on=[:Year, :TreeId, :Site, :IdGenotype])

#genotype_prod = [ #considered genotype
#"GE02",
#"GE06",
#"GE09",
#"GE12",
#]

#filter_prod = filter(row -> row.IdGenotype in genotype_prod, productivity)

#mod_int_1 = lm(@formula(YearlyProduction ~ n_of_bunch * IdGenotype + sum_of_fruit * IdGenotype), filter_prod)
#println(mod_int_1)

#stalk biomass per tree yearly
stalk_biomass = transform(filter_bunch, [:peduncleDryWeight, :SpikeletsDryWeight] => ((p, s) -> ifelse.(ismissing.(p) .| ismissing.(s), missing, p .+ s)) => :stalk_biomass)
sum_stalk_biomass = combine(groupby(stalk_biomass, [:TreeId, :HarvestMAP, :Site]), :stalk_biomass => (x -> sum(skipmissing(x))) => :Stalk_biomass, :IdGenotype => unique => :IdGenotype)
clean_sum_stalk_biomass = dropmissing(sum_stalk_biomass, :Stalk_biomass)
sbiomass_tree = data(clean_sum_stalk_biomass) *
                mapping(:HarvestMAP, :Stalk_biomass, color=:TreeId, col=:IdGenotype, row=:Site) *
                visual(Lines)
fig_sbiomass_tree = draw(sbiomass_tree; axis=(; xlabel="Month after planting", ylabel="Biomass stalk"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3)) #GE03 and GE16 isnt avail too
save("2-results/sensitivity/CIGE/stalk_biomass.png", fig_sbiomass_tree)

#biomass oil per tree
comb_biomass_oil = combine(group_bunch_treeId, :DryMesocarpOilContent => (x -> sum(skipmissing(x))) => :Biomass_oil, :IdGenotype => unique => :IdGenotype)
clean_biomass_oil = dropmissing(comb_biomass_oil, :Biomass_oil)
obiomass_tree = data(clean_biomass_oil) *
                mapping(:HarvestMAP, :Biomass_oil, color=:TreeId, col=:IdGenotype, row=:Site) *
                visual(Lines)
fig_biomass_oil = draw(obiomass_tree; axis=(; xlabel="Month after planting", ylabel="Biomass oil content (%)"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/sensitivity/CIGE/biomass_oil.png", fig_biomass_oil)

"Morphology"
filter_leaf = filter(row -> row.IdGenotype in genotype, df_leaf_growth)
group_leaf_treeId = groupby(filter_leaf, [:TreeId, :MAP, :Site])

#leaf area index over time
comb_LAI = combine(group_leaf_treeId, :LAI => (x -> sum(skipmissing(x))) => :LAI_MAP, :IdGenotype => unique => :IdGenotype)
clean_LAI = dropmissing(comb_LAI, :LAI_MAP)
cum_LAI = transform(groupby(clean_LAI, [:TreeId]), :LAI_MAP => (x -> cumsum(skipmissing(x))) => :Cumulated_LAI)
lai_tree = data(cum_LAI) *
           mapping(:MAP, :Cumulated_LAI, color=:TreeId, col=:IdGenotype, row=:Site) *
           visual(Lines)
fig_LAI_tree = draw(lai_tree; axis=(; xlabel="Month after planting", ylabel="Leaf area index (m2)"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/sensitivity/CIGE/LAI_tree.png", fig_LAI_tree)

#rachis length
comb_rachis = combine(group_leaf_treeId, :RachisLength => (x -> sum(skipmissing(x))) => :RachisLengthMAP, :IdGenotype => unique => :IdGenotype)
clean_rachis = dropmissing(comb_rachis, :RachisLengthMAP)
rachis_tree = data(clean_rachis) *
              mapping(:MAP, :RachisLengthMAP, color=:TreeId, col=:IdGenotype, row=:Site) *
              visual(Lines)
fig_rachis_tree = draw(rachis_tree; axis=(; xlabel="Month after planting", ylabel="Rachis length (cm)"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/sensitivity/CIGE/LAI_tree.png", fig_rachis_tree)

#Leaflet length
comb_leaflet = transform(group_leaf_treeId)
comb_leaflet.avg_leaflet_length = mean.(eachrow(select(comb_leaflet, [:AverageLeafletSampleLengthBase, :AverageLeafletSampleLengthMidd, :AverageLeafletSampleLengthTop])))
clean_avg_length = dropmissing(comb_leaflet, :avg_leaflet_length)
avg_leaflet_length = data(clean_avg_length) *
                     mapping(:MAP, :avg_leaflet_length, color=:TreeId, col=:IdGenotype, row=:Site) *
                     visual(Lines)
fig_avg_leaflet_length_tree = draw(avg_leaflet_length; axis=(; xlabel="Month after planting", ylabel="Leaflet length (cm)"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/sensitivity/CIGE/avg_leaflet_length_tree.png", fig_avg_leaflet_length_tree)

#leaflet width
comb_leaflet.avg_leaflet_width = mean.(eachrow(select(comb_leaflet, [:AverageLeafletSampleWidthBase, :AverageLeafletSampleWidthMidd, :AverageLeafletSampleWidthTop])))
clean_avg_width = dropmissing(comb_leaflet, :avg_leaflet_width)
avg_leaflet_width = data(clean_avg_width) *
                    mapping(:MAP, :avg_leaflet_width, color=:TreeId, col=:IdGenotype, row=:Site) *
                    visual(Lines)
fig_avg_leaflet_width = draw(avg_leaflet_width; axis=(; xlabel="Month after planting", ylabel="Leaflet width (cm)"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=5, nbanks=3))
save("2-results/sensitivity/CIGE/avg_leaflet_length_tree.png", fig_avg_leaflet_width)


"stem growth"
filter_stem = filter(row -> row.IdGenotype in genotype, df_stem_growth)
group_stem_treeId = groupby(filter_stem, [:TreeId, :MAP, :Site])

#stem height
comb_sheight = combine(group_stem_treeId, :Height => (x -> sum(skipmissing(x))) => :stem_height_MAP, :IdGenotype => unique => :IdGenotype)
clean_sheight = dropmissing(comb_sheight, :stem_height_MAP)
sheight_tree = data(clean_sheight) *
               mapping(:MAP, :stem_height_MAP, color=:TreeId, col=:IdGenotype, row=:Site) *
               visual(Lines)
fig_sheight_tree = draw(sheight_tree; axis=(; xlabel="Month after planting", ylabel="Stem height (m)"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/sensitivity/CIGE/stem_height_tree.png", fig_sheight_tree)

#stem girth
stem_girth = combine(group_stem_treeId, :BottomPeriphery => (x -> sum(skipmissing(x))) => :Bottom_Girth,
        :OneAndHalfMeterPeriphery => (x -> sum(skipmissing(x))) => :OneAndHalfMeter_Girth,
        :TwoMeterPeriphery => (x -> sum(skipmissing(x))) => :TwoMeter_Girth, :IdGenotype => unique => :IdGenotype)

stack_girth = stack(stem_girth, [:Bottom_Girth, :OneAndHalfMeter_Girth, :TwoMeter_Girth],
        variable_name=:Position,
        value_name=:Girth)
stack_girth.Position = replace.(string.(stack_girth.Position), "_Girth" => "")

clean_stack_girth = dropmissing(stack_girth, :Girth)

#girth smse
position_girth_smse = data(filter(row -> row.Site == "SMSE", clean_stack_girth)) *
                      mapping(:MAP, :Girth, color=:TreeId, row=:Position, col=:IdGenotype) *
                      visual(Lines)
fig_girth_smse = draw(position_girth_smse; axis=(; xlabel="Month after planting", ylabel="Stem girth (m) SMSE"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/sensitivity/CIGE/girth_smse_tree.png", fig_girth_smse)

#girth presco
position_girth_presco = data(filter(row -> row.Site == "PR", clean_stack_girth)) *
                        mapping(:MAP, :Girth, color=:TreeId, row=:Position, col=:IdGenotype) *
                        visual(Lines)
fig_girth_presco = draw(position_girth_presco; axis=(; xlabel="Month after planting", ylabel="Stem girth (m) PRESCO"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/sensitivity/CIGE/girth_presco_tree.png", fig_girth_presco)

#girth towe
position_girth_towe = data(filter(row -> row.Site == "TOWE", clean_stack_girth)) *
                      mapping(:MAP, :Girth, color=:TreeId, row=:Position, col=:IdGenotype) *
                      visual(Lines)
fig_girth_towe = draw(position_girth_towe; axis=(; xlabel="Month after planting", ylabel="Stem girth (m) TOWE"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/sensitivity/CIGE/girth_towe_tree.png", fig_girth_towe)

#avg girth
stem_girth.avg_girth = mean.(eachrow(select(stem_girth, [:Bottom_Girth, :OneAndHalfMeter_Girth, :TwoMeter_Girth])))
clean_stem_girth = dropmissing(stem_girth, :avg_girth)
avg_girth = data(clean_stem_girth) *
            mapping(:MAP, :avg_girth, color=:TreeId, col=:IdGenotype, row=:Site) *
            visual(Lines)
fig_avg_girth = draw(avg_girth; axis=(; xlabel="Month after planting", ylabel="Average stem girth (m)"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/sensitivity/CIGE/avg_girth_tree.png", fig_avg_girth)


"phenology"
filter_phenology = filter(row -> row.IdGenotype in genotype, df_phenology)
group_pheno_phytomer = groupby(filter_phenology, [:PhytomerNumber, :RankOneLeafMAP, :Site])
group_pheno_treeId = groupby(filter_phenology, [:TreeId, :RankOneLeafMAP, :Site])
group_pheno_IdGenotype = groupby(filter_phenology, [:IdGenotype, :RankOneLeafMAP, :Site])

#cumulative number of newleaf emitted per tree
n_count_tree = combine(group_pheno_treeId, :RankOneLeafMAP => (x -> count(!ismissing, x)) => :n_leaf_emitted, :IdGenotype => unique => :IdGenotype)
clean_n_leaf = dropmissing(n_count_tree, :RankOneLeafMAP)
cum_n_leaf = transform(groupby(clean_n_leaf, [:TreeId]), :n_leaf_emitted => (x -> cumsum(skipmissing(x))) => :Cumulated_n_leaf_emitted)
cum_n_leaf_tree = data(cum_n_leaf) *
                  mapping(:RankOneLeafMAP, :Cumulated_n_leaf_emitted, color=:TreeId, col=:IdGenotype, row=:Site) *
                  visual(Lines)
fig_cum_n_leaf_tree = draw(cum_n_leaf_tree; axis=(; xlabel="Month after planting", ylabel="Total leaf emitted"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3)) #GE03 and GE16 in presco and TOwE is not take into account of number of fruit 
save("2-results/sensitivity/CIGE/n_leaf_emitted_tree.png", fig_cum_n_leaf_tree)

#average number of new leaf emitted per progeny
n_count_genotype = combine(group_pheno_IdGenotype, :RankOneLeafMAP => (x -> count(!ismissing, x)) => :n_leaf_emitted_genotype)
clean_n_leaf_genotype = dropmissing(n_count_genotype, :RankOneLeafMAP)
avg_n_leaf_emitted = transform(groupby(clean_n_leaf_genotype, [:IdGenotype]), :n_leaf_emitted_genotype => mean => :avg_n_leaf_emitted_genotype)
avg_n_leaf = data(cum_n_leaf) *
             mapping(:RankOneLeafMAP, :Cumulated_n_leaf_emitted, color=:IdGenotype, row=:Site) *
             visual(Lines)
fig_avg_n_leaf = draw(avg_n_leaf; axis=(; xlabel="Month after planting", ylabel="Average number of leaf emitted (tree-1.month-1)"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/sensitivity/CIGE/avg_n_leaf_emitted_progeny.png", fig_avg_n_leaf)

#time between leaf emission and flowering per phytomer, per year, per site
comb_phytomer_flowering = transform(group_pheno_phytomer, [:FloweringMAP, :RankOneLeafMAP] => ((f, r) -> ifelse.(ismissing.(f) .| ismissing.(r), missing, f .- r)) => :month_flowering)
clean_phytomer_flowering = dropmissing(comb_phytomer_flowering, :month_flowering)
phytomer_flowering = data(clean_phytomer_flowering) *
                     mapping(:FloweringMAP, :month_flowering, color=:PhytomerNumber, row=:Site) * #upper boundary
                     visual(Lines)
fig_phytomer_flowering = draw(phytomer_flowering; axis=(; xlabel="Month after planting", ylabel="Flowering time per phytomer (month)"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/sensitivity/CIGE/flowering_phytomer.png", fig_phytomer_flowering)

#time between leaf emission and flowering per Tree, per year, per site
comb_treeId_flowering = transform(group_pheno_treeId, [:FloweringMAP, :RankOneLeafMAP] => ((f, r) -> ifelse.(ismissing.(f) .| ismissing.(r), missing, f .- r)) => :month_flowering)
clean_treeId_flowering = dropmissing(comb_treeId_flowering, :month_flowering)
treeId_flowering = data(clean_treeId_flowering) *
                   mapping(:FloweringMAP, :month_flowering, color=:TreeId, row=:Site) * #upper boundary
                   visual(Lines)
fig_treeId_flowering = draw(treeId_flowering; axis=(; xlabel="Month after planting", ylabel="Flowering time per tree (month)"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/sensitivity/CIGE/flowering_tree.png", fig_treeId_flowering)

#time between leaf emission and flowering per progeny, per year, per site
comb_IdGenotype_flowering = transform(group_pheno_IdGenotype, [:FloweringMAP, :RankOneLeafMAP] => ((f, r) -> ifelse.(ismissing.(f) .| ismissing.(r), missing, f .- r)) => :month_flowering)
clean_IdGenotype_flowering = dropmissing(comb_treeId_flowering, :month_flowering)
IdGenotype_flowering = data(clean_IdGenotype_flowering) *
                       mapping(:FloweringMAP, axis=(; xlabel="Month after planting", ylabel="Flowering time per progeny (month)"), :month_flowering, color=:IdGenotype, row=:Site) * #upper boundary
                       visual(Lines)
fig_IdGenotype_flowering = draw(IdGenotype_flowering; figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/sensitivity/CIGE/flowering_genotype.png", fig_IdGenotype_flowering)

#time between flowering and Harvest per phytomer, per year, per site
comb_phytomer_harvest = transform(group_pheno_phytomer, [:HarvestMAP, :FloweringMAP] => ((h, f) -> ifelse.(ismissing.(h) .| ismissing.(f), missing, h .- f)) => :month_harvest)
clean_phytomer_harvest = dropmissing(comb_phytomer_harvest, :month_harvest)
phytomer_harvest = data(clean_phytomer_harvest) *
                   mapping(:month_harvest, :HarvestMAP, color=:PhytomerNumber, row=:Site) * #upper boundary
                   visual(Lines)
fig_phytomer_harvest = draw(phytomer_harvest; axis=(; xlabel="Month after planting", ylabel="Harvest time per phytomer (month)"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/sensitivity/CIGE/harvest_phytomer.png", fig_phytomer_harvest)

#time between flowering and Harvest per treeId, per year, per site
comb_treeId_harvest = transform(group_pheno_treeId, [:HarvestMAP, :FloweringMAP] => ((h, f) -> ifelse.(ismissing.(h) .| ismissing.(f), missing, h .- f)) => :month_harvest)
clean_treeId_harvest = dropmissing(comb_treeId_harvest, :month_harvest)
treeId_harvest = data(clean_treeId_harvest) *
                 mapping(:month_harvest, :HarvestMAP, color=:TreeId, row=:Site) * #upper boundary
                 visual(Lines)
fig_treeId_harvest = draw(treeId_harvest; axis=(; xlabel="Month after planting", ylabel="Harvest time per tree (month)"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/sensitivity/CIGE/harvest_tree.png", fig_treeId_harvest)

#time between flowering and Harvest per IdGenotype, per year, per site
comb_IdGenotype_harvest = transform(group_pheno_IdGenotype, [:HarvestMAP, :FloweringMAP] => ((h, f) -> ifelse.(ismissing.(h) .| ismissing.(f), missing, h .- f)) => :month_harvest)
clean_IdGenotype_harvest = dropmissing(comb_IdGenotype_harvest, :month_harvest)
IdGenotype_harvest = data(clean_IdGenotype_harvest) *
                     mapping(:month_harvest, :HarvestMAP, color=:IdGenotype, row=:IdGenotype, col=:Site) * #upper boundary
                     visual(Lines)
fig_IdGenotype_harvest = draw(IdGenotype_harvest; axis=(; xlabel="Month after planting", ylabel="Harvest time per genotype (month)"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/sensitivity/CIGE/harvest_genotype.png", fig_IdGenotype_harvest)