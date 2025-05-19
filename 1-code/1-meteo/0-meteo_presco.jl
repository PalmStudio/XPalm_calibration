using YAML, CSV, DataFrames, Dates, CairoMakie, AlgebraOfGraphics
using GLM, StatsBase, Statistics

csv_pred_presco = CSV.read("xpalm_introduction/0-data/all_meteo_predictions_presco.csv",
    DataFrame,
    missingstring=["NA", "NaN"]
)

rename!(csv_pred_presco, :TMax => :Tmax,
    :TMin => :Tmin,
    :HRMin => :Rh_min,
    :HRMax => :Rh_max,
    :WindSpeed => :Wind,
    :Rainfall => :Precipitations,
    :ObservationDate => :date,
    :PAR => :Ri_PAR_f,
)

#data that will be processed
select_pred_presco = select(csv_pred_presco, :date, :Tmax, :Tmin, :Rh_min, :Rh_max, :Wind, :Precipitations, :Ri_PAR_f, :TAverage_pred, :HRAverage_pred, :Rainfall_pred, :Rg_pred, :Rg, :TAverage, :HRAverage)  #its exist
select_pred_presco.Ri_PAR_f[findall(x -> !ismissing(x) && x == 0.0, select_pred_presco.Ri_PAR_f)] .= missing

select_pred_presco.Ri_PAR_pred = select_pred_presco.Rg_pred .* 0.48
select_pred_presco.Rh_max = select_pred_presco.Rh_max ./ 100
select_pred_presco.Rh_min = select_pred_presco.Rh_min ./ 100
select_pred_presco.HRAverage = select_pred_presco.HRAverage ./ 100

# Fit model (example for presco)
mod_presco_Tmax = lm(@formula(Tmax ~ TAverage_pred), select_pred_presco)
mod_presco_Tmin = lm(@formula(Tmin ~ TAverage_pred), select_pred_presco)
mod_presco_TAverage = lm(@formula(TAverage ~ TAverage_pred), select_pred_presco)
mod_presco_Rhmin = lm(@formula(Rh_min ~ HRAverage_pred), select_pred_presco)
mod_presco_Rhmax = lm(@formula(Rh_max ~ HRAverage_pred), select_pred_presco)
mod_presco_RhAverage = lm(@formula(HRAverage ~ HRAverage_pred), select_pred_presco)
mod_presco_Precipitation = lm(@formula(Precipitations ~ Rainfall_pred), select_pred_presco)
mod_presco_Rg = lm(@formula(Rg ~ Rg_pred), select_pred_presco)
mod_presco_Ri_PAR_f = lm(@formula(Ri_PAR_f ~ Ri_PAR_pred), select_pred_presco)



# Predict each rows 
select_pred_presco.Tmax_pred = coef(mod_presco_Tmax)[1] .+ coef(mod_presco_Tmax)[2] .* select_pred_presco.TAverage_pred
select_pred_presco.Tmin_pred = coef(mod_presco_Tmin)[1] .+ coef(mod_presco_Tmin)[2] .* select_pred_presco.TAverage_pred
select_pred_presco.TAverage_pred = coef(mod_presco_TAverage)[1] .+ coef(mod_presco_TAverage)[2] .* select_pred_presco.TAverage_pred
select_pred_presco.Rh_min_pred = coef(mod_presco_Rhmin)[1] .+ coef(mod_presco_Rhmin)[2] .* select_pred_presco.HRAverage_pred
select_pred_presco.Rh_max_pred = coef(mod_presco_Rhmax)[1] .+ coef(mod_presco_Rhmax)[2] .* select_pred_presco.HRAverage_pred
select_pred_presco.RhAverage_pred = coef(mod_presco_RhAverage)[1] .+ coef(mod_presco_RhAverage)[2] .* select_pred_presco.HRAverage_pred
select_pred_presco.Precipitations_pred = coef(mod_presco_Precipitation)[1] .+ coef(mod_presco_Precipitation)[2] .* select_pred_presco.Rainfall_pred
select_pred_presco.Precipitations_pred[findall(x -> !ismissing(x) && x < 0.0, select_pred_presco.Precipitations_pred)] .= 0.0 # set negative values to 0
select_pred_presco.Rg_pred = coef(mod_presco_Rg)[1] .+ coef(mod_presco_Rg)[2] .* select_pred_presco.Rg_pred
select_pred_presco.Ri_PAR_pred = coef(mod_presco_Ri_PAR_f)[1] .+ coef(mod_presco_Ri_PAR_f)[2] .* select_pred_presco.Ri_PAR_pred

# Now, replace missing 
select_pred_presco.Tmax = coalesce.(select_pred_presco.Tmax, select_pred_presco.Tmax_pred, mean(skipmissing(select_pred_presco.Tmax)))
select_pred_presco.Tmin = coalesce.(select_pred_presco.Tmin, select_pred_presco.Tmin_pred, mean(skipmissing(select_pred_presco.Tmin)))
select_pred_presco.TAverage = coalesce.(select_pred_presco.TAverage, select_pred_presco.TAverage_pred, mean(skipmissing(select_pred_presco.TAverage)))
select_pred_presco.Rh_min = coalesce.(select_pred_presco.Rh_min, select_pred_presco.Rh_min_pred, mean(skipmissing(select_pred_presco.Rh_min)))
select_pred_presco.Rh_max = coalesce.(select_pred_presco.Rh_max, select_pred_presco.Rh_max_pred, mean(skipmissing(select_pred_presco.Rh_max)))
select_pred_presco.HRAverage = coalesce.(select_pred_presco.HRAverage, select_pred_presco.RhAverage_pred, mean(skipmissing(select_pred_presco.HRAverage)))
select_pred_presco.Precipitations = coalesce.(select_pred_presco.Precipitations, select_pred_presco.Rainfall_pred, mean(skipmissing(select_pred_presco.Precipitations)))
select_pred_presco.Rg = coalesce.(select_pred_presco.Rg, select_pred_presco.Rg_pred, mean(skipmissing(select_pred_presco.Rg)))
select_pred_presco.Ri_PAR_f = coalesce.(select_pred_presco.Ri_PAR_f, select_pred_presco.Ri_PAR_pred, mean(skipmissing(select_pred_presco.Ri_PAR_f)))

# Plotting the temperature:
# Make a function to plot the data:
function plot_meteo(df, variables, title)
    select_pred_presco_long_meas = stack(select(df, :date, variables...), variables, variable_name=:variable, value_name=:value)
    select_pred_presco_long_sim = stack(select(df, :date, [string(i) * "_pred" => i for i in variables]...), variables, variable_name=:variable, value_name=:value)
    select_pred_presco_long = vcat(select_pred_presco_long_meas, select_pred_presco_long_sim, source=:source => [:measured, :predicted])
    data(select_pred_presco_long) * mapping(:date, :value, color=:source, row=:variable) * visual(Lines) |> draw(legend=(; orientation=:horizontal, position=:bottom), figure=(; title=title))
end

plot_meteo(select_pred_presco, [:Tmax, :Tmin, :TAverage], "Temperature presco") #plot the data
plot_meteo(select_pred_presco, [:Rh_min, :Rh_max], "Humidity presco") #plot the data
plot_meteo(select_pred_presco, [:Precipitations], "Rainfall presco") #plot the data

#exception for wind and Ri_PAR_f since they are not predicted
avg_wind = mean(skipmissing(select_pred_presco.Wind))

# Replace missing values of Wind with their respective averages and 0.0 with 1e-6
select_pred_presco.Wind = coalesce.(select_pred_presco.Wind, avg_wind)
select_pred_presco.Wind[select_pred_presco.Wind .== 0.0] .= 1e-6
any(select_pred_presco.Wind .== 0.0)

# Check summary after imputation
describe(select_pred_presco) #wow its works well

#rename TAverage and HRAverage to T and Rh
select_pred_presco = rename(select_pred_presco, :TAverage => :T, :HRAverage => :Rh)

#create the csv file
CSV.write("xpalm_introduction/2-results/meteo_presco_cleaned.csv", select_pred_presco, delim=";")

