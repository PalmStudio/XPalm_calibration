using DataFrames, Dates, CSV, Statistics, Plots

# Ensure date columns are Date type
select_pred_towe.date = Date.(select_pred_towe.date)
select_pred_smse.date = Date.(select_pred_smse.date)

# Define the date range
start_date = Date("2012-01-02")
end_date = Date("2023-06-20")

# Filter smse data within date range
filtered_smse = filter(row -> row.date ≥ start_date && row.date ≤ end_date, select_pred_smse)

# Variables to transfer
vars_to_transfer = [:T, :Tmin, :Tmax, :Wind, :Rh, :Rh_max, :Rh_min, :Precipitations, :Ri_PAR_f, :Rg]

# Loop over each variable
for var in vars_to_transfer
    println("Processing variable: ", var)
    
    # Create a copy of towe to avoid overwriting for each variable
    temp_df = deepcopy(select_pred_towe)

    # Create a dictionary from filtered smse
    val_dict = Dict(row.date => row[var] for row in eachrow(filtered_smse))

    # Assign value or missing based on date match
    temp_df[!, var] = [get(val_dict, d, missing) for d in temp_df.date]

    # Fill missing with mean
    avg_val = mean(skipmissing(temp_df[!, var]))
    temp_df[!, var] = coalesce.(temp_df[!, var], avg_val)


    # Save CSV file
    filename = "xpalm_introduction/2-results/meteo_towe_cleaned_$(String(var)).csv"
    CSV.write(filename, temp_df, delim=";")
end

#comparison why is towe precip is strange

precip_towe = CSV.read("xpalm_introduction/2-results/meteo_towe_cleaned.csv", DataFrame, missingstring=["NA", "NaN"])
precip_towe_smse = CSV.read("xpalm_introduction/2-results/meteo_towe_cleaned_Precipitations.csv", DataFrame, missingstring=["NA", "NaN"])
precip_smse_real = CSV.read("xpalm_introduction/2-results/meteo_smse_cleaned.csv", DataFrame, missingstring=["NA", "NaN"])

#plot precipitations
precip_towe[!, :Site] = fill("TOWE", nrow(precip_towe))
precip_towe_smse[!, :Site] = fill("SMSE", nrow(precip_towe_smse))
precip_smse_real[!, :Site] = fill("SMSE_real", nrow(precip_smse_real))

precip_comb = vcat(precip_towe, precip_towe_smse, precip_smse_real; cols=:union)

using XPalm, Plots, DataFrames, YAML, CSV
using CairoMakie, AlgebraOfGraphics, Statistics
using Dates

plt_precip = data(precip_comb) *
mapping(:date, :Precipitations, color = :Site => string) *
visual(Lines)


draw(plt_precip; figure=(; title="Precipitations"))
