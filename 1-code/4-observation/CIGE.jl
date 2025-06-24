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
group_bunch = groupby(filter_bunch, [:TreeId, :Year, :Site, :IdGenotype]) #total production per tree 

#Production yearly
comb_prod = combine(group_bunch, :BunchMass => (x -> sum(skipmissing(x))) => :YearlyProduction)

prod_1 = data(comb_prod) *
         mapping(:Year, :YearlyProduction, color=:TreeId, col=:IdGenotype, row=:Site) *
         visual(Lines)
draw(prod_1; figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3, width=50, framestyle=:none))

#number of fruit yearly = number of fertile fruit + number of non-fertile fruit
n_of_fruit = combine(group_bunch, [:NumberOfFertilFruits, :NumberOfUnfertilFruits] => ((f, n) -> ifelse.(ismissing.(f) .| ismissing.(n), missing, f .+ n)) => :n_of_fruit)
sum_of_fruit = transform(groupby(n_of_fruit, [:Year, :TreeId]), :n_of_fruit => (x -> sum(skipmissing(x))) => :sum_of_fruit)
fruit_1 = data(sum_of_fruit) *
          mapping(:Year, :sum_of_fruit, color=:TreeId, col=:IdGenotype, row=:Site) *
          visual(Lines)
draw(fruit_1; figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3, width=50, framestyle=:none))

#stalk biomass yearly
stalk_biomass = combine(group_bunch, [:peduncleDryWeight, :SpikeletsDryWeight] => ((p, s) -> ifelse.(ismissing.(p) .| ismissing.(s), missing, p .+ s)) => :stalk_biomass)
sum_stalk_biomass = transform(groupby(stalk_biomass, [:Year, :TreeId]), :stalk_biomass => (x -> sum(skipmissing(x))) => :Stalk_biomass_yearly)
sbiomass_1 = data(sum_stalk_biomass) *
             mapping(:Year, :Stalk_biomass_yearly, color=:TreeId, col=:IdGenotype, row=:Site) *
             visual(Lines)
draw(sbiomass_1; figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3, width=50, framestyle=:none))

#biomass oil
comb_biomass_oil = combine(group_bunch, :DryMesocarpOilContent => (x -> sum(skipmissing(x))) => :Yearly_biomass_oil)
obiomass_1 = data(comb_biomass_oil) *
             mapping(:Year, :Yearly_biomass_oil, color=:TreeId, col=:IdGenotype, row=:Site) *
             visual(Lines)
draw(obiomass_1, ; figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3, width=50, framestyle=:none))

"Morphology"
filter_leaf = filter(row -> row.IdGenotype in genotype, df_leaf_growth)
group_leaf = groupby(filter_leaf, [:TreeId, :Year, :Site, :IdGenotype])

#leaf area index over time
comb_LAI = combine(group_leaf, :LAI => (x -> sum(skipmissing(x))) => :LAI_yearly)
lai_1 = data(comb_LAI) *
        mapping(:Year, :LAI_yearly, color=:TreeId, col=:IdGenotype, row=:Site) *
        visual(Lines)
draw(lai_1; figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3, width=50, framestyle=:none))

#rachis length
comb_rachis = combine(group_leaf, :RachisLength => (x -> sum(skipmissing(x) => :RachisLengthYearly)))
rachis_1 = data(comb_rachis) *
           mapping(:Year, :RachisLengthYearly, color=:Site, layout=:IdGenotype) *
           visual(Lines)
draw(rachis_1; figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3, width=50, framestyle=:none))

#Leaflet length ??

"stem growth"
filter_stem = filter(row -> row.IdGenotype in genotype, df_stem_growth)
group_stem = groupby(filter_stem, [:TreeId, :Year, :Site, :IdGenotype])

#stem height
comb_sheight = combine(group_stem, :Height => (x -> sum(skipmissing(x))) => :stem_height_yearly)
sheight_1 = data(comb_sheight) *
            mapping(:Year, :stem_height_yearly, color=:TreeId, col=:IdGenotype, row=:Site) *
            visual(Lines)
draw(sheight_1; figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3, width=50, framestyle=:none))

#stem girth
stem_girth = combine(group_stem, :BottomPeriphery => (x -> sum(skipmissing(x))) => :Bottom_Girth,
        :OneAndHalfMeterPeriphery => (x -> sum(skipmissing(x))) => :OneAndHalfMeter_Girth,
        :TwoMeterPeriphery => (x -> sum(skipmissing(x))) => :TwoMeter_Girth)

stack_girth = stack(stem_girth, [:Bottom_Girth, :OneAndHalfMeter_Girth, :TwoMeter_Girth],
        variable_name=:Position,
        value_name=:Girth)
stack_girth.Position = replace.(string.(stack_girth.Position), "_Girth" => "")

plt_time = data(stack_girth) *
           mapping(:Year, :Girth, color=:TreeId, row=:Position, col=:IdGenotype) *
           visual(Lines)

draw(plt_time; figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3, width=50, framestyle=:none))


"phenology"

filter_phenology = filter(row -> row.IdGenotype in genotype, df_phenology)
group_phenology = groupby(filter_phenology, [:TreeId, :Year, :Site, :IdGenotype, :PhytomerNumber])
n_count = combine(group_phenology, nrow => :n_leaf_emitted)

#cumulative number of newleaf emitted per tree
group_count = groupby(n_count, [:TreeId, :Year, :Site])
sum_n_leaf = combine(n_count, :n_leaf_emitted => sum => :sum_n_leaf_emitted)
pheno_1 = data(sum_n_leaf) *
          mapping(:Year, :sum_n_leaf_emitted, color=:TreeId, layout=:Site) *
          visual(Lines)
draw(pheno_1; figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3, width=50, framestyle=:none))

#average number of new leaf emitted per progeny
group_phenology_2 = groupby(filter_phenology, [:IdGenotype, :Year, :Site])
n_count2 = combine(group_phenology_2, nrow => :n_leaf_emitted)
group_count2 = groupby(n_count2, [:IdGenotype, :Year, :Site])

avg_n_leaf_emitted = combine(group_count2, :n_leaf_emitted => mean => :avg_n_leaf_emitted)

pheno_2 = data(avg_n_leaf_emitted) *
          mapping(:Year, :avg_n_leaf_emitted, color=:Site, layout=:IdGenotype) *
          visual(Lines)
draw(pheno_2; figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3, width=50, framestyle=:none))

#time between leaf emission and flowering 
month_flowering = combine(group_phenology, [:FloweringMAP, :RankOneLeafMAP] => ((f, r) -> ifelse.(ismissing.(f) .| ismissing.(r), missing, f .- r)) => :month_flowering)
group_phenology_3 = groupby(month_flowering, [:IdGenotype])

pheno_3 =
        data(month_flowering) *
        #mapping(:FloweringMAP, :month_flowering, col=:IdGenotype, row=:Site) *#
        visual(Lines)
draw(pheno_3; figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3, width=50, framestyle=:none))

#time between flowering and Harvest
month_harvest = combine(group_phenology, [:HarvestMAP, :FloweringMAP] => ((h, f) -> ifelse.(ismissing.(h) .| ismissing.(f), missing, h .- f)) => :month_harvest)
group_phenology_4 = groupby(month_harvest, [:IdGenotype])

pheno_3 = data(month_harvest) *
          mapping(:month_harvest, col=:IdGenotype, row=:Site) *
          visual(Lines)
draw(pheno_3; figure=(; size=(1000, 600)), legend=(; position=:bottom, labelsize=4, nbanks=3, width=50, framestyle=:none))
