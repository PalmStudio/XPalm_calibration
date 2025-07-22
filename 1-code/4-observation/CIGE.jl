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

#production per tree and cumulated production each tree
comb_prod = combine(groupby(filter_bunch, [:TreeId, :MAP, :Site, :PhytomerNumber]), :BunchMass => (x -> sum(skipmissing(x))) => :Production_mes, :IdGenotype => first => :IdGenotype, :HarvestDate => unique => :Date)
clean_prod = dropmissing(comb_prod, :Production_mes)
cum_prod = transform(groupby(clean_prod, [:TreeId]), :Production_mes => (x -> cumsum(skipmissing(x))) => :CumulatedProduction_mes)
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
sort!(cum_prod_cleaned, [:TreeId, :MAP])

cum_prod_cleaned_MAP = combine(
        groupby(cum_prod_cleaned, [:TreeId, :MAP, :Site]),
        :IdGenotype => first => :IdGenotype,
        :Date => last => :Date,
        :Production_mes => mean => :Production_mes,
        :CumulatedProduction_mes => last => :CumulatedProduction_mes
)
sort!(cum_prod_cleaned_MAP, [:Site, :MAP])
CSV.write("2-results/calibration/cumulated_production_mes.csv", cum_prod_cleaned_MAP)

#number of bunch per tree
n_of_bunch = combine(groupby(filter_bunch, [:TreeId, :MAP, :Site, :PhytomerNumber]), :BunchMass => (x -> count(!ismissing, x)) => :n_of_bunch, :IdGenotype => first => :IdGenotype, :HarvestDate => unique => :Date)
clean_n_bunch = dropmissing(n_of_bunch, :n_of_bunch)
cum_n_bunch = transform(groupby(clean_n_bunch, [:TreeId]), :n_of_bunch => (x -> cumsum(skipmissing(x))) => :cum_n_bunch_mes)
# remove the late tree (delete the tree that just n bunch grow >50 MAP)
first_n_bunch_map = combine(groupby(cum_n_bunch, :TreeId)) do subdf
        valid_rows = filter(:cum_n_bunch_mes => x -> x > 0, subdf)
        if nrow(valid_rows) == 0
                return (TreeId=subdf.TreeId[1], start_month=Inf)
        else
                return (TreeId=subdf.TreeId[1], start_month=minimum(valid_rows.MAP))
        end
end
valid_trees_bunch = filter(:start_month => x -> x ≤ 70, first_n_bunch_map).TreeId
cum_n_bunch_cleaned = filter(:TreeId => x -> x in valid_trees_bunch, cum_n_bunch)
sort(cum_n_bunch_cleaned, [:TreeId, :MAP])
cum_n_bunch_MAP = combine(groupby(cum_n_bunch_cleaned, [:TreeId, :MAP, :Site]),
        :IdGenotype => first => :IdGenotype,
        :n_of_bunch => sum => :sum_n_bunch_mes,
        :cum_n_bunch_mes => last => :cum_n_bunch_mes,
        :Date => last => :Date)
CSV.write("2-results/calibration/cumulated_n_bunch_mes.csv", cum_n_bunch_MAP)

#number of fruit  = number of fertile fruit + number of non-fertile fruit# 
n_of_fruit = transform(filter_bunch, [:NumberOfFertilFruits, :NumberOfUnfertilFruits] => ((f, n) -> ifelse.(ismissing.(f) .| ismissing.(n), missing, f .+ n)) => :n_of_fruit)
dropmissing!(n_of_fruit, :n_of_fruit)
sum_of_fruit = combine(groupby(n_of_fruit, [:TreeId, :MAP, :Site, :PhytomerNumber]), :n_of_fruit => (x -> sum(skipmissing(x))) => :sum_of_fruit, :IdGenotype => first => :IdGenotype, :HarvestDate => unique => :Date)
clean_sum_fruit = dropmissing(sum_of_fruit, :sum_of_fruit)
sort!(clean_sum_fruit, [:TreeId, :MAP, :PhytomerNumber])
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

cum_n_fruit_cleaned_MAP = combine(
        groupby(cum_n_fruit_cleaned, [:TreeId, :MAP, :Site]),
        :IdGenotype => first => :IdGenotype,
        :sum_of_fruit => mean => :sum_of_fruit,
        :Cumulated_n_fruit_mes => last => :Cumulated_n_fruit_mes,
        :Date => last => :Date
)
CSV.write("2-results/calibration/cumulated_n_fruit_mes.csv", cum_n_fruit_cleaned_MAP)

#stalk biomass per tree 
stalk_biomass = transform(filter_bunch, [:peduncleDryWeight, :SpikeletsDryWeight] => ((p, s) -> ifelse.(ismissing.(p) .| ismissing.(s), missing, p .+ s)) => :stalk_biomass)
dropmissing!(stalk_biomass, :stalk_biomass)
sum_stalk_biomass = combine(groupby(stalk_biomass, [:TreeId, :MAP, :Site, :PhytomerNumber]), :stalk_biomass => (x -> sum(skipmissing(x))) => :sum_stalk_biomass, :IdGenotype => first => :IdGenotype, :HarvestDate => unique => :Date)
clean_sum_stalk_biomass = dropmissing(sum_stalk_biomass, :sum_stalk_biomass)
sort!(clean_sum_stalk_biomass, [:TreeId, :MAP, :PhytomerNumber])
cum_stalk_biomass = transform(groupby(clean_sum_stalk_biomass, [:TreeId]), :sum_stalk_biomass => (x -> cumsum(skipmissing(x))) => :Cumulated_stalk_biomass_mes)
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
cum_stalk_biomass_MAP = combine(
        groupby(cum_stalk_biomass_cleaned, [:TreeId, :MAP, :Site]),
        :IdGenotype => first => :IdGenotype,
        :sum_stalk_biomass => mean => :sum_stalk_biomass_mes,
        :Cumulated_stalk_biomass_mes => last => :Cumulated_stalk_biomass_mes,
        :Date => last => :Date)
CSV.write("2-results/calibration/cumulated_stalk_biomass_mes.csv", cum_stalk_biomass_MAP)

#biomass oil
comb_biomass_oil = combine(groupby(filter_bunch, [:TreeId, :MAP, :Site, :PhytomerNumber]), :DryMesocarpOilContent => (x -> sum(skipmissing(x))) => :Biomass_oil, :IdGenotype => first => :IdGenotype, :HarvestDate => unique => :Date)
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
sort!(cum_biomass_oil_cleaned, [:TreeId, :MAP])
cum_biomass_oil_MAP = combine(
        groupby(cum_biomass_oil_cleaned, [:TreeId, :MAP, :Site]),
        :IdGenotype => first => :IdGenotype,
        :Date => last => :Date,
        :Biomass_oil => mean => :Biomass_oil_mes,
        :Cumulated_biomass_oil_mes => last => :Cumulated_biomass_oil_mes,
)
CSV.write("2-results/calibration/cumulated_biomass_oil_mes.csv", cum_biomass_oil_MAP)


"Morphology"
filter_leaf = filter(row -> row.IdGenotype in genotype, df_leaf_growth)

#leaf area index over time per tree per MAP
comb_LAI = combine(groupby(filter_leaf, [:TreeId, :MAP, :Site]), :LAI => (x -> sum(skipmissing(x))) => :LAI_mes, :IdGenotype => first => :IdGenotype, :ObservationDate => unique => :Date)
clean_LAI = dropmissing(comb_LAI, :LAI_mes)
clean_LAI_sorted = sort(clean_LAI, [:TreeId, :MAP])
# remove the fluctuated tree
first_LAI_map = combine(groupby(clean_LAI_sorted, :TreeId)) do subdf
        valid_rows = filter(:LAI_mes => x -> x > 0, subdf)
        if nrow(valid_rows) == 0
                return (TreeId=subdf.TreeId[1], start_month=Inf)
        else
                return (TreeId=subdf.TreeId[1], start_month=minimum(valid_rows.MAP))
        end
end

valid_trees_LAI = filter(:start_month => x -> x ≤ 80, first_LAI_map).TreeId

df_lai_diff = combine(groupby(clean_LAI_sorted, :TreeId)) do subdf
        lai_diff = diff(subdf.LAI_mes)
        max_drop = minimum([0.0; lai_diff])  # add 0 to avoid empty diff
        return (TreeId=subdf.TreeId[1], max_drop=max_drop)
end

drop_threshold = -1.1
stable_trees = filter(:max_drop => x -> x ≥ drop_threshold, df_lai_diff).TreeId
valid_trees_final = intersect(valid_trees_LAI, stable_trees)
cum_LAI_cleaned = filter(:TreeId => x -> x in valid_trees_final, clean_LAI_sorted)
CSV.write("2-results/calibration/LAI_mes.csv", cum_LAI_cleaned)

# #rachis length 
# comb_rachis = combine(group_leaf_treeId, :RachisLength => (x -> sum(skipmissing(x))) => :RachisLengthMAP, :IdGenotype => first => :IdGenotype, :ObservationDate => unique => :Date)
# clean_rachis = dropmissing(comb_rachis, :RachisLengthMAP)

# #remove the strange tree
# tree_trend_stats = combine(groupby(clean_rachis, :TreeId)) do subdf
#         sorted = sort(subdf, :MAP)
#         rachis = collect(sorted.RachisLengthMAP)

#         if length(rachis) < 2
#                 return (TreeId=subdf.TreeId[1], keep=true)  # Not enough data to judge steps
#         end

#         steps = diff(rachis)
#         worst_step = minimum(steps)
#         best_step = maximum(steps)

#         keep = !(worst_step ≤ -50 || best_step ≥ 150) # Drop if either a sudden drop OR a sudden spike is present

#         return (TreeId=subdf.TreeId[1], keep=keep)
# end

# valid_rachis_trees = filter(:keep => x -> x, tree_trend_stats).TreeId
# filter_rachis = filter(:TreeId => x -> x in valid_rachis_trees, clean_rachis)
# CSV.write("2-results/calibration/cumulated_rachis_length_mes.csv", filter_rachis)
# rachis_tree = data(filter_rachis) *
#               mapping(:MAP, :RachisLengthMAP, color=:TreeId, col=:IdGenotype, row=:Site) *
#               visual(Lines)
# fig_rachis_tree = draw(rachis_tree; axis=(; xlabel="Month after planting", ylabel="Rachis length (cm)"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
# save("2-results/sensitivity/CIGE/rachis_tree.png", fig_rachis_tree)

# #Leaflet length #!check in the note from Rémi does it we put from the base, midd, or top
# comb_leaflet = transform(group_leaf_treeId)
# comb_leaflet.avg_leaflet_length = mean.(eachrow(select(comb_leaflet, [:AverageLeafletSampleLengthBase, :AverageLeafletSampleLengthMidd, :AverageLeafletSampleLengthTop])))
# clean_avg_length = dropmissing(comb_leaflet, :avg_leaflet_length)
# #remove the strange tree
# leaflet_trend_stats = combine(groupby(clean_avg_length, :TreeId)) do subdf
#         sorted = sort(subdf, :MAP)
#         rachis = collect(sorted.avg_leaflet_length)

#         if length(rachis) < 2
#                 return (TreeId=subdf.TreeId[1], keep=true)  # Not enough data to judge steps
#         end

#         steps = diff(rachis)
#         worst_step = minimum(steps)
#         best_step = maximum(steps)

#         keep = !(worst_step ≤ -20 || best_step ≥ 100) # Drop if either a sudden drop OR a sudden spike is present

#         return (TreeId=subdf.TreeId[1], keep=keep)
# end
# valid_leaflet_trees = filter(:keep => x -> x, leaflet_trend_stats).TreeId
# filter_leaflet = filter(:TreeId => x -> x in valid_leaflet_trees, clean_avg_length)
# filter_leaflet = select(filter_leaflet, [:Site, :IdGenotype, :TreeId, :ObservationDate, :MAP, :avg_leaflet_length])
# rename!(filter_leaflet, :ObservationDate => :Date)
# CSV.write("2-results/calibration/avg_leaflet_length_mes.csv", filter_leaflet)
# avg_leaflet_length = data(filter_leaflet) *
#                      mapping(:MAP, :avg_leaflet_length, color=:TreeId, col=:IdGenotype, row=:Site) *
#                      visual(Lines)
# fig_avg_leaflet_length_tree = draw(avg_leaflet_length; axis=(; xlabel="Month after planting", ylabel="Leaflet length (cm)"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
# save("2-results/sensitivity/CIGE/avg_leaflet_length_tree.png", fig_avg_leaflet_length_tree)

# #leaflet width #! filter the tree that has the leaflet that just started >80 MAP (SMSE) continue 180725
# comb_leaflet.avg_leaflet_width = mean.(eachrow(select(comb_leaflet, [:AverageLeafletSampleWidthBase, :AverageLeafletSampleWidthMidd, :AverageLeafletSampleWidthTop])))
# clean_avg_width = dropmissing(comb_leaflet, :avg_leaflet_width)
# avg_leaflet_width = data(clean_avg_width) *
#                     mapping(:MAP, :avg_leaflet_width, color=:TreeId, col=:IdGenotype, row=:Site) *
#                     visual(Lines)
# fig_avg_leaflet_width = draw(avg_leaflet_width; axis=(; xlabel="Month after planting", ylabel="Leaflet width (cm)"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=5, nbanks=3))
# save("2-results/sensitivity/CIGE/avg_leaflet_width_tree.png", fig_avg_leaflet_width)


# "stem growth"
# filter_stem = filter(row -> row.IdGenotype in genotype, df_stem_growth)
# group_stem_treeId = groupby(filter_stem, [:TreeId, :MAP, :Site])

# #stem height
# comb_sheight = combine(group_stem_treeId, :Height => (x -> sum(skipmissing(x))) => :stem_height_MAP, :IdGenotype => unique => :IdGenotype)
# clean_sheight = dropmissing(comb_sheight, :stem_height_MAP)
# sheight_tree = data(clean_sheight) *
#                mapping(:MAP, :stem_height_MAP, color=:TreeId, col=:IdGenotype, row=:Site) *
#                visual(Lines)
# fig_sheight_tree = draw(sheight_tree; axis=(; xlabel="Month after planting", ylabel="Stem height (m)"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
# save("2-results/sensitivity/CIGE/stem_height_tree.png", fig_sheight_tree)

# #stem girth 
# stem_girth = combine(group_stem_treeId, :BottomPeriphery => (x -> sum(skipmissing(x))) => :Bottom_Girth,
#         :OneAndHalfMeterPeriphery => (x -> sum(skipmissing(x))) => :OneAndHalfMeter_Girth,
#         :TwoMeterPeriphery => (x -> sum(skipmissing(x))) => :TwoMeter_Girth, :IdGenotype => unique => :IdGenotype)

# stack_girth = stack(stem_girth, [:Bottom_Girth, :OneAndHalfMeter_Girth, :TwoMeter_Girth],
#         variable_name=:Position,
#         value_name=:Girth)
# stack_girth.Position = replace.(string.(stack_girth.Position), "_Girth" => "")

# clean_stack_girth = dropmissing(stack_girth, :Girth)

# #girth smse 
# position_girth_smse = data(filter(row -> row.Site == "SMSE", clean_stack_girth)) *
#                       mapping(:MAP, :Girth, color=:TreeId, row=:Position, col=:IdGenotype) *
#                       visual(Lines)
# fig_girth_smse = draw(position_girth_smse; axis=(; xlabel="Month after planting", ylabel="Stem girth (m) SMSE"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
# save("2-results/sensitivity/CIGE/girth_smse_tree.png", fig_girth_smse)

# #girth presco 
# position_girth_presco = data(filter(row -> row.Site == "PR", clean_stack_girth)) *
#                         mapping(:MAP, :Girth, color=:TreeId, row=:Position, col=:IdGenotype) *
#                         visual(Lines)
# fig_girth_presco = draw(position_girth_presco; axis=(; xlabel="Month after planting", ylabel="Stem girth (m) PRESCO"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
# save("2-results/sensitivity/CIGE/girth_presco_tree.png", fig_girth_presco)

# #girth towe 
# position_girth_towe = data(filter(row -> row.Site == "TOWE", clean_stack_girth)) *
#                       mapping(:MAP, :Girth, color=:TreeId, row=:Position, col=:IdGenotype) *
#                       visual(Lines)
# fig_girth_towe = draw(position_girth_towe; axis=(; xlabel="Month after planting", ylabel="Stem girth (m) TOWE"), figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3))
# save("2-results/sensitivity/CIGE/girth_towe_tree.png", fig_girth_towe)

"phenology"
filter_phenology = filter(row -> row.IdGenotype in genotype, df_phenology)

#cumulative number of newleaf emitted per tree per MAP
n_count_tree = combine(groupby(filter_phenology, [:TreeId, :RankOneLeafMAP, :Site]),
        :RankOneLeafMAP => (x -> count(!ismissing, x)) => :n_leaf_emitted,
        :IdGenotype => first => :IdGenotype,
        :RankOneLeafDate => last => :Date) #to avoid recalculate when theres 2 dates different while the counting is already by group provided
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

#average time to leaf emitted per tree per phytomer number and per MAP
comb_phytomer_leaf = combine(groupby(filter_phenology, [:TreeId, :PhytomerNumber, :Site]), :RankOneLeafDate => unique => :Date,
        :IdGenotype => first => :IdGenotype,
        :RankOneLeafMAP => unique => :MAP)
dropmissing!(comb_phytomer_leaf, :Date)
sort!(comb_phytomer_leaf, [:TreeId, :Date])
days_between_leaf = combine(groupby(comb_phytomer_leaf, [:TreeId, :Date]), last)
days_between_leaf.days_leaf_phytomer = [missing; diff(days_between_leaf.Date)]
days_between_leaf.days_leaf_phytomer = [ismissing(d) ? missing : Dates.value(d) for d in days_between_leaf.days_leaf_phytomer]
CSV.write("2-results/calibration/time_leaf_phytomer.csv", days_between_leaf)
mean_leaf_MAP = combine(groupby(days_between_leaf, [:TreeId, :MAP, :Site]),
        :days_leaf_phytomer => mean => :days_leaf_MAP,
        :Date => last => :Date,
        :IdGenotype => first => :IdGenotype)
CSV.write("2-results/calibration/time_leaf_MAP.csv", mean_leaf_MAP)

#average time between leaf emission and flowering per tree per phytomer and per MAP
comb_phytomer_flowering = transform(filter_phenology, [:FloweringDate, :RankOneLeafDate] => ((f, r) -> ifelse(ismissing(f) | ismissing(r), missing, f - r)) => :day_flowering_phytomer)
dropmissing!(comb_phytomer_flowering, :day_flowering_phytomer)
comb_phytomer_flowering.day_flowering_phytomer = coalesce.(Dates.value.(comb_phytomer_flowering.day_flowering_phytomer), missing)
mean_phytomer_flowering = combine(groupby(comb_phytomer_flowering, [:TreeId, :PhytomerNumber, :Site]), :day_flowering_phytomer => mean => :day_flowering_phytomer,
        :IdGenotype => first => :IdGenotype,
        :FloweringDate => unique => :Date,
        :FloweringMAP => unique => :MAP)
CSV.write("2-results/calibration/time_leaf_flowering_phytomer.csv", mean_phytomer_flowering)
mean_flowering_MAP = combine(groupby(mean_phytomer_flowering, [:TreeId, :MAP, :Site]),
        :IdGenotype => first => :IdGenotype,
        :day_flowering_phytomer => mean => :day_flowering_MAP,
        :Date => last => :Date)
CSV.write("2-results/calibration/time_leaf_flowering_MAP.csv", mean_flowering_MAP)

#time between flowering and Harvest per tree per phytomer and per MAP
comb_phytomer_harvest = transform(filter_phenology, [:HarvestDate, :FloweringDate] => ((h, f) -> ifelse.(ismissing.(h) .| ismissing.(f), missing, h .- f)) => :days_harvest_phytomer)
dropmissing!(comb_phytomer_harvest, :days_harvest_phytomer)
comb_phytomer_harvest.days_harvest_phytomer = coalesce.(Dates.value.(comb_phytomer_harvest.days_harvest_phytomer), missing)
mean_phytomer_harvest = combine(groupby(comb_phytomer_harvest, [:TreeId, :PhytomerNumber, :Site]), :days_harvest_phytomer => mean => :days_harvest_phytomer,
        :IdGenotype => first => :IdGenotype,
        :HarvestDate => unique => :Date,
        :HarvestMAP => unique => :MAP)
CSV.write("2-results/calibration/time_flowering__harvest_phytomer.csv", mean_phytomer_harvest)
mean_harvest_MAP = combine(groupby(mean_phytomer_harvest, [:TreeId, :MAP, :Site]),
        :IdGenotype => first => :IdGenotype,
        :Date => last => :Date, #avoid the repetition
        :days_harvest_phytomer => mean => :days_harvest_MAP)
CSV.write("2-results/calibration/time_flowering_harvest_MAP.csv", mean_harvest_MAP)
