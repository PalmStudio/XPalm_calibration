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
rename!(df_bunch_component, :HarvestMAP => :MAP)
year_planting!(df_leaf_growth, :MAP)
year_planting!(df_stem_growth, :MAP)

#special case for dataframe df_phenology because there is no any MAP column
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
group_bunch_treeId = groupby(filter_bunch, [:TreeId, :MAP, :Site])

#Cumulated production each tree 
comb_prod = combine(group_bunch_treeId, :BunchMass => (x -> sum(skipmissing(x))) => :Production, :IdGenotype => first => :IdGenotype, :HarvestDate => unique => :Date)
clean_prod = dropmissing(comb_prod, :Production)
cum_prod = transform(groupby(clean_prod, [:TreeId]), :Production => (x -> cumsum(skipmissing(x))) => :CumulatedProduction_mes)
# remove the late tree (delete the tree that just grow >50 MAP)
first_prod_map = combine(groupby(cum_prod, :TreeId)) do subdf
        valid_rows = filter(:CumulatedProduction_mes => x -> x > 0, subdf)
        if nrow(valid_rows) == 0
                return (TreeId=subdf.TreeId[1], start_month=Inf)
        else
                return (TreeId=subdf.TreeId[1], start_month=minimum(valid_rows.MAP))
        end
end
valid_trees = filter(:start_month => x -> x ≤ 70, first_prod_map).TreeId
cum_prod_cleaned = filter(:TreeId => x -> x in valid_trees, cum_prod)
CSV.write("2-results/calibration/cumulated_production_mes.csv", cum_prod_cleaned)
prod_tree = data(cum_prod_cleaned) *
            mapping(:MAP, :CumulatedProduction_mes, color=:TreeId, col=:IdGenotype, row=:Site) *
            visual(Lines)
fig_prod_tree = draw(prod_tree; axis=(; xlabel="Month after planting", ylabel="Cumulated yield (kg)"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/sensitivity/CIGE/prod_tree.png", fig_prod_tree)

#number of bunch per tree
n_of_bunch = combine(group_bunch_treeId, :BunchMass => (x -> count(!ismissing, x)) => :n_of_bunch, :IdGenotype => first => :IdGenotype, :HarvestDate => unique => :Date)
clean_n_bunch = dropmissing(n_of_bunch, :n_of_bunch)
cum_n_bunch = transform(groupby(clean_n_bunch, [:TreeId]), :n_of_bunch => (x -> cumsum(skipmissing(x))) => :Cumulated_n_bunch_mes)
# remove the late tree (delete the tree that just n bunch grow >50 MAP)
first_n_bunch_map = combine(groupby(cum_n_bunch, :TreeId)) do subdf
        valid_rows = filter(:Cumulated_n_bunch_mes => x -> x > 0, subdf)
        if nrow(valid_rows) == 0
                return (TreeId=subdf.TreeId[1], start_month=Inf)
        else
                return (TreeId=subdf.TreeId[1], start_month=minimum(valid_rows.MAP))
        end
end
valid_trees_bunch = filter(:start_month => x -> x ≤ 70, first_n_bunch_map).TreeId
cum_n_bunch_cleaned = filter(:TreeId => x -> x in valid_trees_bunch, cum_n_bunch)
CSV.write("2-results/calibration/cumulated_n_bunch_mes.csv", cum_n_bunch_cleaned)
n_bunch_tree = data(cum_n_bunch_cleaned) *
               mapping(:MAP, :Cumulated_n_bunch_mes, col=:IdGenotype, row=:Site, color=:TreeId) *
               visual(Lines)
fig_n_bunch_tree = draw(n_bunch_tree; axis=(; xlabel="Month after planting", ylabel="Number of bunch"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/sensitivity/CIGE/n_bunch_tree.png", fig_n_bunch_tree)

#number of fruit yearly = number of fertile fruit + number of non-fertile fruit 
n_of_fruit = transform(filter_bunch, [:NumberOfFertilFruits, :NumberOfUnfertilFruits] => ((f, n) -> ifelse.(ismissing.(f) .| ismissing.(n), missing, f .+ n)) => :n_of_fruit)
sum_of_fruit = combine(groupby(n_of_fruit, [:TreeId, :MAP, :Site]), :n_of_fruit => (x -> sum(skipmissing(x))) => :sum_of_fruit, :IdGenotype => first => :IdGenotype, :HarvestDate => unique => :Date)
clean_sum_fruit = dropmissing(sum_of_fruit, :sum_of_fruit)
cum_n_fruit = transform(groupby(clean_sum_fruit, [:TreeId]), :sum_of_fruit => (x -> cumsum(skipmissing(x))) => :Cumulated_n_fruit_mes)
#remove the late tree (delete the tree that just n bunch grow >50 MAP, remain only 4 progeny)
first_n_fruit_map = combine(groupby(cum_n_fruit, :TreeId)) do subdf
        valid_rows = filter(:Cumulated_n_fruit_mes => x -> x > 0, subdf)
        if nrow(valid_rows) == 0
                return (TreeId=subdf.TreeId[1], start_month=Inf)
        else
                return (TreeId=subdf.TreeId[1], start_month=minimum(valid_rows.MAP))
        end
end
valid_trees_fruit = filter(:start_month => x -> x ≤ 70, first_n_fruit_map).TreeId
cum_n_fruit_cleaned = filter(:TreeId => x -> x in valid_trees_fruit, cum_n_fruit)
CSV.write("2-results/calibration/cumulated_n_fruit_mes.csv", cum_n_fruit_cleaned)
fruit_tree = data(cum_n_fruit_cleaned) *
             mapping(:MAP, :Cumulated_n_fruit_mes, color=:TreeId, col=:IdGenotype, row=:Site) *
             visual(Lines)
fig_fruit_tree = draw(fruit_tree; axis=(; xlabel="Month after planting", ylabel="Total number of fruit (tree/year)"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3)) #GE03 and GE16 in presco and TOwE is not take into account of number of fruit 
save("2-results/sensitivity/CIGE/n_fruit_tree.png", fig_fruit_tree)

#stalk biomass per tree yearly
stalk_biomass = transform(filter_bunch, [:peduncleDryWeight, :SpikeletsDryWeight] => ((p, s) -> ifelse.(ismissing.(p) .| ismissing.(s), missing, p .+ s)) => :stalk_biomass)
sum_stalk_biomass = combine(groupby(stalk_biomass, [:TreeId, :MAP, :Site]), :stalk_biomass => (x -> sum(skipmissing(x))) => :Stalk_biomass, :IdGenotype => first => :IdGenotype, :HarvestDate => unique => :Date)
clean_sum_stalk_biomass = dropmissing(sum_stalk_biomass, :Stalk_biomass)
cum_stalk_biomass = transform(groupby(clean_sum_stalk_biomass, [:TreeId]), :Stalk_biomass => (x -> cumsum(skipmissing(x))) => :Cumulated_stalk_biomass_mes)
first_stalk_biomass = combine(groupby(cum_stalk_biomass, :TreeId)) do subdf
        valid_rows = filter(:Cumulated_stalk_biomass_mes => x -> x > 0, subdf)
        if nrow(valid_rows) == 0
                return (TreeId=subdf.TreeId[1], start_month=Inf)
        else
                return (TreeId=subdf.TreeId[1], start_month=minimum(valid_rows.MAP))
        end
end
valid_trees_stalk = filter(:start_month => x -> x ≤ 70, first_stalk_biomass).TreeId
cum_stalk_biomass_cleaned = filter(:TreeId => x -> x in valid_trees_stalk, cum_stalk_biomass)
CSV.write("2-results/calibration/cumulated_stalk_biomass_mes.csv", cum_stalk_biomass_cleaned)
sbiomass_tree = data(cum_stalk_biomass_cleaned) *
                mapping(:MAP, :Cumulated_stalk_biomass_mes, color=:TreeId, col=:IdGenotype, row=:Site) *
                visual(Lines)
fig_sbiomass_tree = draw(sbiomass_tree; axis=(; xlabel="Month after planting", ylabel="Biomass stalk"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3)) #GE03 and GE16 isnt avail too
save("2-results/sensitivity/CIGE/cum_stalk_biomass.png", fig_sbiomass_tree)

#biomass oil per tree
comb_biomass_oil = combine(group_bunch_treeId, :DryMesocarpOilContent => (x -> sum(skipmissing(x))) => :Biomass_oil, :IdGenotype => first => :IdGenotype, :HarvestDate => unique => :Date)
clean_biomass_oil = dropmissing(comb_biomass_oil, :Biomass_oil)
cum_biomass_oil = transform(groupby(clean_biomass_oil, [:TreeId]), :Biomass_oil => (x -> cumsum(skipmissing(x))) => :Cumulated_biomass_oil_mes)
first_biomass_oil = combine(groupby(cum_biomass_oil, :TreeId)) do subdf
        valid_rows = filter(:Cumulated_biomass_oil_mes => x -> x > 0, subdf)
        if nrow(valid_rows) == 0
                return (TreeId=subdf.TreeId[1], start_month=Inf)
        else
                return (TreeId=subdf.TreeId[1], start_month=minimum(valid_rows.MAP))
        end
end
valid_trees_oil = filter(:start_month => x -> x ≤ 70, first_biomass_oil).TreeId
cum_biomass_oil_cleaned = filter(:TreeId => x -> x in valid_trees_oil, cum_biomass_oil)
CSV.write("2-results/calibration/cumulated_biomass_oil_mes.csv", cum_biomass_oil_cleaned)
obiomass_tree = data(cum_biomass_oil_cleaned) *
                mapping(:MAP, :Cumulated_biomass_oil_mes, color=:TreeId, col=:IdGenotype, row=:Site) *
                visual(Lines)
fig_biomass_oil = draw(obiomass_tree; axis=(; xlabel="Month after planting", ylabel="Biomass oil content (%)"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/sensitivity/CIGE/cum_biomass_oil_mes.png", fig_biomass_oil)

"Morphology"
filter_leaf = filter(row -> row.IdGenotype in genotype, df_leaf_growth)
group_leaf_treeId = groupby(filter_leaf, [:TreeId, :MAP, :Site])

#leaf area index over time 
comb_LAI = combine(group_leaf_treeId, :LAI => (x -> sum(skipmissing(x))) => :LAI_MAP, :IdGenotype => first => :IdGenotype, :ObservationDate => unique => :Date)
clean_LAI = dropmissing(comb_LAI, :LAI_MAP)
clean_LAI_sorted = sort(clean_LAI, [:TreeId, :MAP])
cum_LAI = transform(groupby(clean_LAI_sorted, [:TreeId]), :LAI_MAP => (x -> cumsum(skipmissing(x))) => :Cumulated_LAI)
# remove the late tree (delete the tree that just n bunch grow >50 MAP)
first_LAI_map = combine(groupby(cum_LAI, :TreeId)) do subdf
        valid_rows = filter(:Cumulated_LAI => x -> x > 0, subdf)
        if nrow(valid_rows) == 0
                return (TreeId=subdf.TreeId[1], start_month=Inf)
        else
                return (TreeId=subdf.TreeId[1], start_month=minimum(valid_rows.MAP))
        end
end
valid_trees_LAI = filter(:start_month => x -> x ≤ 70, first_LAI_map).TreeId
cum_LAI_cleaned = filter(:TreeId => x -> x in valid_trees_LAI, cum_LAI)
CSV.write("2-results/calibration/cumulated_LAI_mes.csv", cum_LAI_cleaned)
lai_tree = data(cum_LAI_cleaned) *
           mapping(:MAP, :Cumulated_LAI, color=:TreeId, col=:IdGenotype, row=:Site) *
           visual(Lines)
fig_LAI_tree = draw(lai_tree; axis=(; xlabel="Month after planting", ylabel="Leaf area index (m2)"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/sensitivity/CIGE/LAI_tree.png", fig_LAI_tree)

#rachis length 
comb_rachis = combine(group_leaf_treeId, :RachisLength => (x -> sum(skipmissing(x))) => :RachisLengthMAP, :IdGenotype => first => :IdGenotype, :ObservationDate => unique => :Date)
clean_rachis = dropmissing(comb_rachis, :RachisLengthMAP)

#remove the strange tree
tree_trend_stats = combine(groupby(clean_rachis, :TreeId)) do subdf
        sorted = sort(subdf, :MAP)
        rachis = collect(sorted.RachisLengthMAP)

        if length(rachis) < 2
                return (TreeId=subdf.TreeId[1], keep=true)  # Not enough data to judge steps
        end

        steps = diff(rachis)
        worst_step = minimum(steps)
        best_step = maximum(steps)

        keep = !(worst_step ≤ -50 || best_step ≥ 150) # Drop if either a sudden drop OR a sudden spike is present

        return (TreeId=subdf.TreeId[1], keep=keep)
end

valid_rachis_trees = filter(:keep => x -> x, tree_trend_stats).TreeId
filter_rachis = filter(:TreeId => x -> x in valid_rachis_trees, clean_rachis)
CSV.write("2-results/calibration/cumulated_rachis_length_mes.csv", filter_rachis)
rachis_tree = data(filter_rachis) *
              mapping(:MAP, :RachisLengthMAP, color=:TreeId, col=:IdGenotype, row=:Site) *
              visual(Lines)
fig_rachis_tree = draw(rachis_tree; axis=(; xlabel="Month after planting", ylabel="Rachis length (cm)"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/sensitivity/CIGE/rachis_tree.png", fig_rachis_tree)

#Leaflet length #!check in the note from Rémi does it we put from the base, midd, or top
comb_leaflet = transform(group_leaf_treeId)
comb_leaflet.avg_leaflet_length = mean.(eachrow(select(comb_leaflet, [:AverageLeafletSampleLengthBase, :AverageLeafletSampleLengthMidd, :AverageLeafletSampleLengthTop])))
clean_avg_length = dropmissing(comb_leaflet, :avg_leaflet_length)
#remove the strange tree
leaflet_trend_stats = combine(groupby(clean_avg_length, :TreeId)) do subdf
        sorted = sort(subdf, :MAP)
        rachis = collect(sorted.avg_leaflet_length)

        if length(rachis) < 2
                return (TreeId=subdf.TreeId[1], keep=true)  # Not enough data to judge steps
        end

        steps = diff(rachis)
        worst_step = minimum(steps)
        best_step = maximum(steps)

        keep = !(worst_step ≤ -20 || best_step ≥ 100) # Drop if either a sudden drop OR a sudden spike is present

        return (TreeId=subdf.TreeId[1], keep=keep)
end
valid_leaflet_trees = filter(:keep => x -> x, leaflet_trend_stats).TreeId
filter_leaflet = filter(:TreeId => x -> x in valid_leaflet_trees, clean_avg_length)
filter_leaflet = select(filter_leaflet, [:Site, :IdGenotype, :TreeId, :ObservationDate, :MAP, :avg_leaflet_length])
rename!(filter_leaflet, :ObservationDate => :Date)
CSV.write("2-results/calibration/avg_leaflet_length_mes.csv", filter_leaflet)
avg_leaflet_length = data(filter_leaflet) *
                     mapping(:MAP, :avg_leaflet_length, color=:TreeId, col=:IdGenotype, row=:Site) *
                     visual(Lines)
fig_avg_leaflet_length_tree = draw(avg_leaflet_length; axis=(; xlabel="Month after planting", ylabel="Leaflet length (cm)"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/sensitivity/CIGE/avg_leaflet_length_tree.png", fig_avg_leaflet_length_tree)

#leaflet width #! filter the tree that has the leaflet that just started >80 MAP (SMSE) continue 180725
comb_leaflet.avg_leaflet_width = mean.(eachrow(select(comb_leaflet, [:AverageLeafletSampleWidthBase, :AverageLeafletSampleWidthMidd, :AverageLeafletSampleWidthTop])))
clean_avg_width = dropmissing(comb_leaflet, :avg_leaflet_width)
avg_leaflet_width = data(clean_avg_width) *
                    mapping(:MAP, :avg_leaflet_width, color=:TreeId, col=:IdGenotype, row=:Site) *
                    visual(Lines)
fig_avg_leaflet_width = draw(avg_leaflet_width; axis=(; xlabel="Month after planting", ylabel="Leaflet width (cm)"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=5, nbanks=3))
save("2-results/sensitivity/CIGE/avg_leaflet_width_tree.png", fig_avg_leaflet_width)


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

#stem girth #! try cumsum and then if still remove the tree when they has a 0 value
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

"phenology"
filter_phenology = filter(row -> row.IdGenotype in genotype, df_phenology)
group_pheno_phytomer = groupby(filter_phenology, [:TreeId, :PhytomerNumber, :RankOneLeafDate, :Site]) #!add tree id too
group_pheno_treeId = groupby(filter_phenology, [:TreeId, :RankOneLeafMAP, :Site])
group_pheno_IdGenotype = groupby(filter_phenology, [:TreeId, :IdGenotype, :RankOneLeafMAP, :Site])

#cumulative number of newleaf emitted per tree
n_count_tree = combine(group_pheno_treeId, :RankOneLeafMAP => (x -> count(!ismissing, x)) => :n_leaf_emitted, :IdGenotype => first => :IdGenotype, :RankOneLeafDate => unique => :Date)
clean_n_leaf = dropmissing(n_count_tree, :RankOneLeafMAP)
cum_n_leaf = transform(groupby(clean_n_leaf, [:TreeId]), :n_leaf_emitted => (x -> cumsum(skipmissing(x))) => :Cumulated_n_leaf_emitted)
# remove the late tree 
first_n_leaf_map = combine(groupby(cum_n_leaf, :TreeId)) do subdf
        valid_rows = filter(:Cumulated_n_leaf_emitted => x -> x > 0, subdf)
        if nrow(valid_rows) == 0
                return (TreeId=subdf.TreeId[1], start_month=Inf)
        else
                return (TreeId=subdf.TreeId[1], start_month=minimum(valid_rows.RankOneLeafMAP))
        end
end
valid_trees_n_leaf = filter(:start_month => x -> x ≤ 50, first_n_leaf_map).TreeId
cum_n_leaf_cleaned = filter(:TreeId => x -> x in valid_trees_n_leaf, cum_n_leaf)
rename!(cum_n_leaf_cleaned, :RankOneLeafMAP => :MAP)
CSV.write("2-results/calibration/cum_n_new_leaf_emitted.csv", cum_n_leaf_cleaned)
cum_n_leaf_tree = data(cum_n_leaf_cleaned) *
                  mapping(:MAP, :Cumulated_n_leaf_emitted, color=:TreeId, col=:IdGenotype, row=:Site) *
                  visual(Lines)
fig_cum_n_leaf_tree = draw(cum_n_leaf_tree; axis=(; xlabel="Month after planting", ylabel="Total leaf emitted"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3)) #GE03 and GE16 in presco and TOwE is not take into account of number of fruit 
save("2-results/sensitivity/CIGE/cum_n_leaf_emitted_tree.png", fig_cum_n_leaf_tree)

#average number of new leaf emitted per progeny #! filter the tree thay has the value is returned  as 0, dont know how to do
n_count_genotype = combine(group_pheno_IdGenotype, :RankOneLeafMAP => (x -> count(!ismissing, x)) => :n_leaf_emitted_genotype, :RankOneLeafDate => unique => :Date)
clean_n_leaf_genotype = dropmissing(n_count_genotype, :RankOneLeafMAP)
avg_n_leaf_emitted = combine(groupby(clean_n_leaf_genotype, [:TreeId, :IdGenotype, :RankOneLeafMAP, :Site]), :n_leaf_emitted_genotype => mean => :avg_n_leaf_emitted_genotype, :Date => unique => :Date,
        :RankOneLeafMAP => first => :MAP)
CSV.write("2-results/calibration/avg_n_leaf_emitted_progeny.csv", avg_n_leaf_emitted)
avg_n_leaf = data(avg_n_leaf_emitted) *
             mapping(:RankOneLeafMAP, :avg_n_leaf_emitted_genotype, color=:IdGenotype, row=:Site, group=:TreeId) *
             visual(Lines)
fig_avg_n_leaf = draw(avg_n_leaf; axis=(; xlabel="Month after planting", ylabel="Average number of leaf emitted (tree-1.month-1)"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/sensitivity/CIGE/avg_n_leaf_emitted_progeny.png", fig_avg_n_leaf)

#time between leaf emission and flowering per phytomer, per year, per site 
comb_phytomer_flowering = combine(group_pheno_phytomer, [:FloweringDate, :RankOneLeafDate] => ((f, r) -> ifelse.(ismissing.(f) .| ismissing.(r), missing, f .- r)) => :day_flowering_phytomer,
        :FloweringMAP => unique => :MAP,
        :IdGenotype => unique => :IdGenotype,
        :PhytomerNumber => unique => :PhytomerNumber,
        :FloweringDate => unique => :Date)
clean_phytomer_flowering = dropmissing(comb_phytomer_flowering, :day_flowering_phytomer)
sort(clean_phytomer_flowering, [:Site, :TreeId, :MAP])
CSV.write("2-results/calibration/time_leaf_flowering_phytomer.csv", clean_phytomer_flowering)
phytomer_flowering = data(clean_phytomer_flowering) *
                     mapping(:Date, :day_flowering_phytomer, color=:PhytomerNumber, row=:Site, group=:TreeId) * #upper boundary
                     visual(Lines)
fig_phytomer_flowering = draw(phytomer_flowering; axis=(; xlabel="Flowering Date", ylabel="Time between leaf emission and flowering (day)"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/sensitivity/CIGE/flowering_phytomer.png", fig_phytomer_flowering)

#time between leaf emission and flowering per progeny, per year, per site
comb_IdGenotype_flowering = transform(group_pheno_IdGenotype, [:FloweringDate, :RankOneLeafDate] => ((f, r) -> ifelse.(ismissing.(f) .| ismissing.(r), missing, f .- r)) => :days_flowering_IdGenotype,)
clean_IdGenotype_flowering = select(clean_IdGenotype_flowering, [:TreeId, :days_flowering_IdGenotype, :FloweringDate, :IdGenotype, :Site, :FloweringMAP])
clean_IdGenotype_flowering = dropmissing(comb_IdGenotype_flowering, :days_flowering_IdGenotype)
rename!(clean_IdGenotype_flowering, [:FloweringDate => :Date, :FloweringMAP => :MAP])
CSV.write("2-results/calibration/time_leaf_flowering_IdGenotype.csv", clean_IdGenotype_flowering)
IdGenotype_flowering = data(clean_IdGenotype_flowering) *
                       mapping(:Date, :days_flowering_IdGenotype, color=:IdGenotype, row=:Site, group=:TreeId) * #upper boundary
                       visual(Lines)
fig_IdGenotype_flowering = draw(IdGenotype_flowering; axis=(; xlabel="Flowering Date", ylabel="Time between leaf emission and flowering (day)"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/sensitivity/CIGE/flowering_genotype.png", fig_IdGenotype_flowering)

#time between flowering and Harvest per phytomer, per year, per site
comb_phytomer_harvest = combine(group_pheno_phytomer, [:HarvestDate, :FloweringDate] => ((h, f) -> ifelse.(ismissing.(h) .| ismissing.(f), missing, h .- f)) => :days_harvest_phytomer,
        :FloweringMAP => unique => :MAP,
        :IdGenotype => unique => :IdGenotype,
        :PhytomerNumber => unique => :PhytomerNumber,
        :FloweringDate => unique => :Date)
clean_phytomer_harvest = dropmissing(comb_phytomer_harvest, :days_harvest_phytomer)
CSV.write("2-results/calibration/time_flowering_harvest_phytomer.csv", clean_phytomer_harvest)
phytomer_harvest = data(clean_phytomer_harvest) *
                   mapping(:Date, :days_harvest_phytomer, color=:PhytomerNumber, row=:Site, group=:TreeId) * #upper boundary
                   visual(Lines)
fig_phytomer_harvest = draw(phytomer_harvest; axis=(; xlabel="Month after planting", ylabel="Harvest time per phytomer (month)"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/sensitivity/CIGE/harvest_phytomer.png", fig_phytomer_harvest)

#time between flowering and Harvest per IdGenotype, per year, per site
comb_IdGenotype_harvest = transform(group_pheno_IdGenotype, [:HarvestMAP, :FloweringMAP] => ((h, f) -> ifelse.(ismissing.(h) .| ismissing.(f), missing, h .- f)) => :month_harvest)
clean_IdGenotype_harvest = dropmissing(comb_IdGenotype_harvest, :month_harvest)
IdGenotype_harvest = data(clean_IdGenotype_harvest) *
                     mapping(:month_harvest, :HarvestMAP, color=:IdGenotype, row=:IdGenotype, col=:Site) * #upper boundary
                     visual(Lines)
fig_IdGenotype_harvest = draw(IdGenotype_harvest; axis=(; xlabel="Month after planting", ylabel="Harvest time per genotype (month)"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
save("2-results/sensitivity/CIGE/harvest_genotype.png", fig_IdGenotype_harvest)