#This code is to compute and data the field data from CIGE to compare with the model results afterwards

using CSV, DataFrames, Dates
using GLM, StatsBase, Statistics

# Data from CIGE
df_bunch_component = CSV.read("0-data/BunchComponents_CIGE.csv", DataFrame, missingstring=["NA", "NaN"])
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

rename!(df_bunch_component, :HarvestMAP => :MAP)
#add year after planting
# function year_planting!(df::DataFrame, map_col::Symbol)
#         df.Year = (df[!, map_col] .÷ 12) .+ 1
#         return df
# end

# year_planting!(df_bunch_component, :HarvestMAP)
# rename!(df_bunch_component, :HarvestMAP => :MAP)
# year_planting!(df_leaf_growth, :MAP)
# year_planting!(df_stem_growth, :MAP)

#special case for dataframe df_phenology because there is no any MAP column
# function mondf(d2::Date, d1::Date)
#         return (year(d2) - year(d1)) * 12 + (month(d2) - month(d1))
# end

# function year_planting_2!(df::DataFrame)
#         n = nrow(df)
#         year_col = Vector{Union{Int,Missing}}(undef, n)

#         last_valid_hmonth = missing
#         last_year = missing

#         for i in 1:n
#                 pdate = df.PlantingDate[i]
#                 hmonth = df.HarvestMonth[i]
#                 abmonth = df.AbortedMonth[i]
#                 asmonth = df.AppearedSpatheMonth[i]

#                 if hmonth !== missing
#                         event_month = hmonth
#                         last_valid_hmonth = hmonth
#                 elseif abmonth !== missing || asmonth !== missing
#                         event_month = last_valid_hmonth
#                 else
#                         event_month = missing
#                 end

#                 # if asmonth missing, take the value from previous row
#                 if event_month !== missing && pdate !== missing
#                         map_month = mondf(event_month, pdate)
#                         this_year = floor(Int, map_month / 12) + 1
#                         year_col[i] = this_year
#                         last_year = this_year
#                 else
#                         year_col[i] = last_year
#                 end
#         end

#         df.Year = year_col
#         return df
# end

# year_planting_2!(df_phenology)

"Bunch Component"
filter_bunch = filter(row -> row.IdGenotype in genotype, df_bunch_component)

# We remove rows where all the bunch component variables are missing. This happens on the few first MAPs for some trees, where we don't have any measurements:
df_production = filter(
        row -> !(ismissing(row.BunchMass) && ismissing(row.DryMesocarpOilContent) && ismissing(row.MesocarpsSampleWC) && ismissing(row.NumberOfFertilFruits) && ismissing(row.NumberOfUnfertilFruits) &&
                 ismissing(row.FertilFruitsFreshWeight) && ismissing(row.UnfertilFruitsFreshWeight) && ismissing(row.peduncleDryWeight) && ismissing(row.SpikeletsDryWeight) &&
                 ismissing(row.UnfertilFruitsDryWeight) && ismissing(row.peduncleFreshWeight) && ismissing(row.SpikeletsFreshWeight)),
        filter_bunch
)

# Computing new variables and keeping only the ones we need:
select!(
        df_production,
        :Site, :IdGenotype => :IdGenotype, :TreeId, :HarvestDate => :Date, :MAP, :PhytomerNumber, :BunchMass, :DryMesocarpOilContent, :MesocarpsSampleWC,
        [:NumberOfFertilFruits, :NumberOfUnfertilFruits] => ((f, n) -> ifelse.(ismissing.(f) .| ismissing.(n), missing, f .+ n)) => :n_of_fruit,
        # We use FertilFruitsFreshWeight to compute the number of bunches, as other variables were not always measured (e.g. BunchMass is curiously not always available)
        [:UnfertilFruitsFreshWeight, :FertilFruitsFreshWeight] => ByRow((uf, f) -> any(ismissing.([uf, f])) ? missing : uf + f) => :biomass_fresh_fruit,
        [:UnfertilFruitsDryWeight, :FertilFruitsFreshWeight, :ThirtyNutsWC] => ByRow((uf_dry, f_wet, wc) -> any(ismissing.([uf_dry, f_wet, wc])) ? missing : uf_dry + (f_wet * (1.0 - wc))) => :biomass_dry_fruit,
        [:peduncleDryWeight, :SpikeletsDryWeight] => ((p, s) -> ifelse.(ismissing.(p) .| ismissing.(s), missing, p .+ s)) => :stalk_dry_biomass,
        [:peduncleFreshWeight, :SpikeletsFreshWeight] => ((p, s) -> ifelse.(ismissing.(p) .| ismissing.(s), missing, p .+ s)) => :stalk_fresh_biomass
)
# We have missing measurements at MAP 47 in SMSE for some variables (BunchMass, UnfertilFruitsDryWeight...).

function fn_no_missings(values, fn)
        if all(ismissing.(values))
                return missing
        else
                return fn(skipmissing(values))
        end
end

# Integrating at MAP level for each tree each site (because we can't compare the prodution at phytomer level with the model as each phytomer has its own phenology)
df_production_MAP = combine(
        groupby(df_production, [:Site, :TreeId, :MAP]),
        :IdGenotype => unique => :IdGenotype,
        :Date => last => :Date,
        :BunchMass => sum => :bunch_fresh_mass_total, #!FFB per MAP per tree, we don't use `fn_no_missings` because its a cumulation of all bunches harvested, if there is a missing, we don't know the total bunch mass harvested
        :BunchMass => (x -> fn_no_missings(x, mean)) => :bunch_fresh_mass_average, #! AFB in one bunch. Here we use `fn_no_missings` because we want the value for one bunch (preferably in average)
        nrow => :n_of_bunch,
        :DryMesocarpOilContent => (x -> fn_no_missings(x, mean)) => :DryMesocarpOilContent,
        :MesocarpsSampleWC => (x -> fn_no_missings(x, mean)) => :MesocarpsSampleWC,
        :n_of_fruit => sum => :n_of_fruit_total,
        :n_of_fruit => (x -> fn_no_missings(x, mean)) => :n_of_fruit_average,
        # Note on the following variables: we cannot use the sum because only one bunch out of many (from different trees of the same genotype) was dissected per observation date:
        :biomass_fresh_fruit => (x -> fn_no_missings(x, mean)) => :biomass_fresh_fruit_per_bunch, #! Fresh mesocarp biomass per bunch.
        :biomass_dry_fruit => (x -> fn_no_missings(x, mean)) => :biomass_dry_fruit_per_bunch,
        :stalk_dry_biomass => (x -> fn_no_missings(x, mean)) => :stalk_dry_biomass_per_bunch,
        :stalk_fresh_biomass => (x -> fn_no_missings(x, mean)) => :stalk_fresh_biomass_per_bunch,
        # :bunch_fresh_mass => (x -> fn_no_missings(x, mean)) => :bunch_fresh_mass_per_bunch,
        [:stalk_dry_biomass, :biomass_dry_fruit, :BunchMass] => ((stalk_dry, fruits_dry, bunch_wet) -> fn_no_missings(1 .- ((stalk_dry .+ fruits_dry) ./ bunch_wet), mean)) => :bunch_water_content
        # [:stalk_dry_biomass, :biomass_dry_fruit, :BunchMass] => ((stalk_dry, fruits_dry, bunch_wet) -> (1 .- ((stalk_dry .+ fruits_dry) ./ bunch_wet), mean)) => :bunch_water_content
)

transform!(df_production_MAP, :bunch_water_content => ByRow(x -> ismissing(x) ? missing : (x < 0.0 ? 0.0 : x)) => :bunch_water_content) #! to avoid negative values (see graph below)

# Average water content of the bunches per site:
combine(groupby(df_production_MAP, :Site), :bunch_water_content => (x -> mean(skipmissing(x))) => :avg_bunch_water_content)
# 3×2 DataFrame
#  Row │ Site     avg_bunch_water_content 
#      │ String7  Float64                 
# ─────┼──────────────────────────────────
#    1 │ PR                      0.355204
#    2 │ SMSE                    0.41636
#    3 │ TOWE                    0.380513
# Total average is 38.5% water content in average -> mean(skipmissing(df_production_MAP.bunch_water_content))

# Plotting the total fresh fruit biomass + stalk fresh biomass against the bunch mass (should be the same approximately):
# df_test = DataFrame(ffb=df_production.biomass_fresh_fruit .+ df_production.stalk_fresh_biomass, BunchMass=df_production.BunchMass)
# f, ax, p = scatter(df_test.BunchMass, df_test.ffb, axis=(ylabel="Bunch total fresh mass (kg)", xlabel="Sum of fruits and stalk fresh mass (kg)"))
# ablines!(ax, [0], [1], color=:grey, linestyle=:dash)
# f

transform!(
        df_production_MAP,
        [:bunch_fresh_mass_total, :bunch_water_content] => ((biomass_fresh, water_content) -> biomass_fresh .* (1.0 .- water_content)) => :bunch_dry_mass_total, #! total dry mass of the bunch, approximated using the water content of one bunch per progeny in a measurement sessions (kg)
        [:bunch_fresh_mass_average, :bunch_water_content] => ((biomass_fresh, water_content) -> biomass_fresh .* (1.0 .- water_content)) => :bunch_dry_mass_per_bunch,
)

df_start_measurement_each_site = combine(groupby(dropmissing(df_production_MAP, :bunch_fresh_mass_total), :Site), :MAP => minimum => :StartMAP)
dict_start_site = Dict(zip(df_start_measurement_each_site.Site, df_start_measurement_each_site.StartMAP))
start_MAP_Tree = combine(groupby(dropmissing(df_production_MAP, :bunch_fresh_mass_total), [:Site, :TreeId]), :MAP => minimum => :StartMAP)
trees_selected = filter(row -> row.StartMAP <= dict_start_site[row.Site] + 5, start_MAP_Tree) #! we keep trees that have their first measurement within 5 months after the start month for each site

# Filter-out the rows where the first measurements where at the MAP is less than the start month for each site
df_production_MAP_filtered = filter(row -> row.TreeId in trees_selected.TreeId && minimum(row.MAP) .>= dict_start_site[row.Site], df_production_MAP)

# Removing some weird MesocarpsSampleWC measurements (3 values in PR):
df_to_remove = filter(row -> !ismissing(row.MesocarpsSampleWC) && row.Site == "PR" && (row.MesocarpsSampleWC > 0.8 || row.MesocarpsSampleWC < 0.1), df_production_MAP_filtered, view=true)
df_to_remove.MesocarpsSampleWC .= missing

# Same for stalk_dry_biomass
# df_to_remove = filter(row -> row.TreeId == "TOWE_POGP37_2_GE12_4_28" && row.MAP == 89, df_production_MAP_filtered, view=true) #? most probably a mistake in the point -> 15.5416 is probably 1.55416
df_to_remove = filter(row -> !ismissing(row.stalk_dry_biomass_per_bunch) && row.stalk_dry_biomass_per_bunch > 5.0, df_production_MAP_filtered, view=true)
df_to_remove.stalk_dry_biomass_per_bunch .= missing

# Same for :stalk_fresh_biomass
df_to_remove = filter(row -> !ismissing(row.stalk_fresh_biomass_per_bunch) && row.stalk_fresh_biomass_per_bunch > 15.0, df_production_MAP_filtered, view=true)
df_to_remove.stalk_fresh_biomass_per_bunch .= missing

# using AlgebraOfGraphics
# p = data(transform(groupby(df_production_MAP_filtered, :TreeId), :bunch_fresh_mass_total => (x -> cumsum(skipmissing(x))) => :bunch_fresh_mass_total_cum)) *
#     mapping(:MAP, :bunch_fresh_mass_total_cum, color=:TreeId, col=:IdGenotype, row=:Site) *
#     visual(Lines)
# draw(p, legend=(show=false,), figure=(size=(1000, 600),), axis=(xlabel="Month after planting", ylabel="Bunch mass (kg)"))
sort!(df_production_MAP_filtered, [:Site, :MAP])
CSV.write("2-results/calibration/CIGE/temporary_data/production_cige.csv", df_production_MAP_filtered)

"Morphology"
df_filter_leaf = filter(row -> row.IdGenotype in genotype && row.TreeId in trees_selected.TreeId, df_leaf_growth)
#! We have any other variables in this dataframe, such as rachis length and biomass, leaflet length, leaflet width, etc.
rename!(df_filter_leaf, :ObservationDate => :Date)
select!(df_filter_leaf, Not(:Plot, :BlockNumber, :LineNumber, :TreeNumber, :LAI))

# Removing weird values: 
df_to_remove = filter(row -> !ismissing(row.RachisWC) && (row.RachisWC > 0.9 || row.RachisWC < 0.4), df_filter_leaf, view=true)
df_to_remove.RachisWC .= missing

#removing the rachis length 
df_to_remove = filter(row -> !ismissing(row.RachisLength) && row.Site == "PR" && row.RachisLength < 200.0, df_filter_leaf, view=true)
df_to_remove.RachisLength .= missing

#removing the rachis dry weight 
df_to_remove = filter(row -> !ismissing(row.RachisDryWeight) && (row.RachisDryWeight > 2.6 || row.RachisDryWeight < 0.1), df_filter_leaf, view=true)
df_to_remove.RachisDryWeight .= missing

#remove rachis wc
df_to_remove = filter(row -> !ismissing(row.RachisWC) && (row.RachisWC < 0.5 || row.RachisWC > 0.81), df_filter_leaf, view=true)
df_to_remove.RachisWC .= missing

#remove number of leaflet
df_to_remove = filter(row -> !ismissing(row.NumberOfLeaflets) && row.NumberOfLeaflets < 200, df_filter_leaf, view=true)
df_to_remove.NumberOfLeaflets .= missing

CSV.write("2-results/calibration/CIGE/temporary_data/data_leaf_rank_17.csv", df_filter_leaf)
# using AlgebraOfGraphics
# p = data(df_filter_leaf) *
#     mapping(:MAP, :LeafArea, color=:TreeId, col=:IdGenotype, row=:Site) *
#     visual(Lines)
# draw(p, legend=(show=false,), figure=(size=(1000, 600),), axis=(xlabel="Month after planting", ylabel="Leaf Area at Rank 17 (m²)"))

"stem growth"
filter_stem = filter(row -> row.IdGenotype in genotype, df_stem_growth)
rename!(filter_stem, :ObservationDate => :Date)
select!(filter_stem, Not(:Plot, :LineNumber, :TreeNumber, :PlantingDate))
dropmissing!(filter_stem, :Height) #dropmissing based on the height
CSV.write("2-results/calibration/CIGE/temporary_data/data_stem.csv", filter_stem)

"phenology"
df_filter_phenology = filter(row -> row.IdGenotype in genotype && row.TreeId in trees_selected.TreeId, df_phenology)

#cumulative number of newleaf emitted per tree per MAP
n_count_tree = combine(groupby(df_filter_phenology, [:TreeId, :RankOneLeafMAP, :Site]),
        :RankOneLeafMAP => (x -> count(!ismissing, x)) => :n_leaf_emitted,
        :IdGenotype => first => :IdGenotype,
        :RankOneLeafDate => last => :Date) #to avoid recalculate when theres 2 dates different while the counting is already by group provided
clean_n_leaf = dropmissing(n_count_tree, :RankOneLeafMAP)
cum_n_leaf = transform(groupby(clean_n_leaf, [:TreeId]), :n_leaf_emitted => (x -> cumsum(skipmissing(x))) => :Cumulated_n_leaf_emitted)
rename!(cum_n_leaf, :RankOneLeafMAP => :MAP)
CSV.write("2-results/calibration/CIGE/temporary_data/cum_n_new_leaf_emitted.csv", cum_n_leaf)

#average time to leaf emitted per tree per phytomer number and per MAP
#! there is an issue for phytomer number 2 for TreeId SMSE_B22_2_GE12_57_3, we have two measurements, we keep the second one (most probably the correct one)
df_test_one_value_per_phytomer = combine(groupby(df_filter_phenology, [:TreeId, :PhytomerNumber, :Site]), :RankOneLeafDate => length => :length)
all(df_test_one_value_per_phytomer.length .== 1) #check that we have only one date per tree per phytomer number
wrong_measurement = filter(row -> row.length > 1, df_test_one_value_per_phytomer)

# Removing this row from the dataframe
filter!(row -> !(row.TreeId == "SMSE_B22_2_GE12_57_3" && row.PhytomerNumber == 2 && !ismissing(row.AppearedSpearDate) && row.AppearedSpearDate == Date(2018, 1, 11)), df_filter_phenology)

comb_phytomer_leaf = select(df_filter_phenology, :Site, :TreeId, :PhytomerNumber, :RankOneLeafDate => :Date, :IdGenotype => :IdGenotype, :RankOneLeafMAP => :MAP)
dropmissing!(comb_phytomer_leaf, :Date)
sort!(comb_phytomer_leaf, [:TreeId, :Date])
days_between_leaf = combine(groupby(comb_phytomer_leaf, [:TreeId, :Date]), last)
transform!(
        groupby(days_between_leaf, :TreeId),
        :Date => (x -> [missing; Dates.value.(diff(x))]) => :days_leaf_phytomer,
        :PhytomerNumber => (x -> [missing; diff(x)]) => :number_phytomer_emmited
)
days_between_leaf.number_days_last_phytomer = days_between_leaf.days_leaf_phytomer ./ days_between_leaf.number_phytomer_emmited
select!(days_between_leaf, :Site, :IdGenotype, :TreeId, :Date, :MAP, :PhytomerNumber, :number_days_last_phytomer, :number_phytomer_emmited)
# p = data(dropmissing(days_between_leaf, :number_days_last_phytomer)) *
#     mapping(:MAP, :days_leaf_phytomer, color=:TreeId, col=:IdGenotype, row=:Site) *
#     visual(Lines)
# draw(p, legend=(show=false,), figure=(size=(1000, 600),), axis=(xlabel="Month after planting", ylabel="Days between leaf emission and next leaf (days)"))
# CSV.write("2-results/calibration/CIGE/temporary_data/time_leaf_phytomer.csv", days_between_leaf)

# Average by MAP
mean_leaf_MAP = combine(
        groupby(days_between_leaf, [:Site, :TreeId, :MAP]),
        :IdGenotype => first => :IdGenotype,
        :Date => last => :Date,
        :number_days_last_phytomer => mean => :phyllochron_days_per_MAP,
        :number_phytomer_emmited => sum => :sum_n_phytomer_MAP,
)

dropmissing!(mean_leaf_MAP, :sum_n_phytomer_MAP)

mean_leaf_MAP = transform(
        groupby(mean_leaf_MAP, [:Site, :TreeId,]),
        :sum_n_phytomer_MAP => (x -> [missing; diff(x)]) => :phytomer_emitted
)
CSV.write("2-results/calibration/CIGE/temporary_data/time_leaf_MAP.csv", mean_leaf_MAP)

#average time between leaf emission and flowering per tree per phytomer and per MAP
comb_phytomer_flowering = transform(df_filter_phenology, [:FloweringDate, :RankOneLeafDate] => ((f, r) -> ifelse(ismissing(f) | ismissing(r), missing, f - r)) => :day_flowering_phytomer)
dropmissing!(comb_phytomer_flowering, :day_flowering_phytomer)
comb_phytomer_flowering.day_flowering_phytomer = coalesce.(Dates.value.(comb_phytomer_flowering.day_flowering_phytomer), missing)
select!(comb_phytomer_flowering, :Site, :IdGenotype, :TreeId, :PhytomerNumber, :day_flowering_phytomer, :FloweringDate => :Date, :FloweringMAP => :MAP)
# CSV.write("2-results/calibration/CIGE/temporary_data/time_leaf_flowering_phytomer.csv", comb_phytomer_flowering)
mean_flowering_MAP = combine(
        groupby(comb_phytomer_flowering, [:TreeId, :MAP, :Site]),
        :IdGenotype => first => :IdGenotype,
        :Date => last => :Date,
        :day_flowering_phytomer => (x -> round(Int, mean(x))) => :day_flowering_MAP,
)
CSV.write("2-results/calibration/CIGE/temporary_data/time_leaf_flowering_MAP.csv", mean_flowering_MAP)

#time between flowering and Harvest per tree per phytomer and per MAP
comb_phytomer_harvest = transform(df_filter_phenology, [:HarvestDate, :FloweringDate] => ((h, f) -> ifelse.(ismissing.(h) .| ismissing.(f), missing, h .- f)) => :days_harvest_phytomer)
dropmissing!(comb_phytomer_harvest, :days_harvest_phytomer)
comb_phytomer_harvest.days_harvest_phytomer = coalesce.(Dates.value.(comb_phytomer_harvest.days_harvest_phytomer), missing)
select!(comb_phytomer_harvest, :Site, :IdGenotype, :TreeId, :PhytomerNumber, :days_harvest_phytomer, :HarvestDate => :Date, :HarvestMAP => :MAP)
# CSV.write("2-results/calibration/CIGE/temporary_data/time_flowering__harvest_phytomer.csv", comb_phytomer_harvest)
mean_harvest_MAP = combine(
        groupby(comb_phytomer_harvest, [:TreeId, :MAP, :Site]),
        :IdGenotype => first => :IdGenotype,
        :Date => last => :Date,
        :days_harvest_phytomer => (x -> round(Int, mean(x))) => :days_harvest_MAP
)

# Fix some weird values:
df_to_remove = filter(row -> !ismissing(row.days_harvest_MAP) && (row.days_harvest_MAP < 100 || row.days_harvest_MAP > 250) && row.IdGenotype in ["GE16", "GE06", "GE03"], mean_harvest_MAP, view=true)
df_to_remove.days_harvest_MAP .= missing

CSV.write("2-results/calibration/CIGE/temporary_data/time_flowering_harvest_MAP.csv", mean_harvest_MAP)



# Making the CIGE calibration dataframe:
# Tree scale
mes_cum_prod = CSV.read("2-results/calibration/CIGE/temporary_data/production_cige.csv", DataFrame)
mes_cum_n_new_leaf_emitted = CSV.read("2-results/calibration/CIGE/temporary_data/cum_n_new_leaf_emitted.csv", DataFrame)
mes_leaf_MAP = CSV.read("2-results/calibration/CIGE/temporary_data/time_leaf_MAP.csv", DataFrame)
mes_flowering_MAP = CSV.read("2-results/calibration/CIGE/temporary_data/time_leaf_flowering_MAP.csv", DataFrame)
mes_harvest_MAP = CSV.read("2-results/calibration/CIGE/temporary_data/time_flowering_harvest_MAP.csv", DataFrame)
mes_leaf = CSV.read("2-results/calibration/CIGE/temporary_data/data_leaf_rank_17.csv", DataFrame)
mes_stem = CSV.read("2-results/calibration/CIGE/temporary_data/data_stem.csv", DataFrame)

transform_date_as_yearmonth!(df::DataFrame) = transform!(df, :Date => ByRow(x -> Dates.Date(Dates.yearmonth(x)..., 1)) => :Date)

merged_CIGE = outerjoin(
        transform_date_as_yearmonth!(mes_cum_prod),
        transform_date_as_yearmonth!(mes_cum_n_new_leaf_emitted),
        transform_date_as_yearmonth!(mes_leaf_MAP),
        transform_date_as_yearmonth!(mes_flowering_MAP),
        transform_date_as_yearmonth!(mes_harvest_MAP),
        transform_date_as_yearmonth!(mes_leaf),
        transform_date_as_yearmonth!(mes_stem),
        on=[:TreeId, :Date, :MAP, :Site, :IdGenotype],
        makeunique=true
)
sort!(merged_CIGE, [:TreeId, :Date, :MAP, :Site])
CSV.write("2-results/calibration/CIGE/CIGE.csv", merged_CIGE)