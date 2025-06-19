'This code is to compute and data the field data from CIGE to compare with the model results afterwards'

using CSV, DataFrames, Dates, CairoMakie, AlgebraOfGraphics
using GLM, StatsBase, Statistics
#Biomass
# Load and prepare data
df_total_prod = CSV.read("0-data/TotalProduction_CIGE.csv", DataFrame, missingstring=["NA", "NaN"])

#take the year from HarvestDate
df_total_prod.Year = (df_total_prod.HarvestMAP .÷ 12) .+ 1 #modulo

#group first by TreeId so that we can have the total production per tree 
group_treeId = groupby(df_total_prod, [:TreeId, :Year, :Site])

#compute the sum of BunchMass per TreeId
group_treeId = combine(group_treeId, :BunchMass => (x -> sum(skipmissing(x))) => :YearlyProduction)

#plot the data per year between 3 sites and per TreeId
vars = [:YearlyProduction]
hum_stacked = stack(group_treeId, vars; variable_name=:variable, value_name=:value)
plt_1 = data(hum_stacked) *
        mapping(:Year, :value, color=:TreeId, layout=:Site) *
        visual(Lines)
draw(plt_1)


