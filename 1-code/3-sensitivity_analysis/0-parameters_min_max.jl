using YAML, CSV, DataFrames, Dates, CairoMakie, AlgebraOfGraphics
using GLM, StatsBase, Statistics

df_params = CSV.read("2-results/1-doe.csv", DataFrame)

colnames = names(df_params)

# Create a DataFrame with empty Min and Max columns
range_params = DataFrame(
    Variable = colnames,
    Min = Vector{Union{Missing, String}}(missing, length(colnames)),
    Max = Vector{Union{Missing, String}}(missing, length(colnames))
)

CSV.write("2-results/range_parameters.csv", range_params, delim=";")