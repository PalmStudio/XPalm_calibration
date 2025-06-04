using YAML, CSV, DataFrames, Dates, CairoMakie, AlgebraOfGraphics
using GLM, StatsBase, Statistics

csv_pred_towe = CSV.read("0-data/all_meteo_predictions_towe.csv",
    DataFrame,
    missingstring=["NA", "NaN"]
)

rename!(csv_pred_towe, :TMax => :Tmax,
    :TMin => :Tmin,
    :HRMin => :Rh_min,
    :HRMax => :Rh_max,
    :WindSpeed => :Wind,
    :Rainfall => :Precipitations,
    :ObservationDate => :date,
    :PAR => :Ri_PAR_f,
)

#data that will be processed
select_pred_towe = select(csv_pred_towe, :date, :Tmax, :Tmin, :Rh_min, :Rh_max, :Wind, :Precipitations, :Ri_PAR_f, :TAverage_pred, :HRAverage_pred, :Rainfall_pred, :Rg_pred, :Rg, :TAverage, :HRAverage)  #its exist
select_pred_towe.Ri_PAR_f[findall(x -> !ismissing(x) && x == 0.0, select_pred_towe.Ri_PAR_f)] .= missing

select_pred_towe.Ri_PAR_pred = select_pred_towe.Rg_pred .* 0.48
select_pred_towe.Rh_max = select_pred_towe.Rh_max ./ 100
select_pred_towe.Rh_min = select_pred_towe.Rh_min ./ 100
select_pred_towe.HRAverage = select_pred_towe.HRAverage ./ 100

# Fit model (example for towe)
mod_towe_Tmax = lm(@formula(Tmax ~ TAverage_pred), select_pred_towe)
mod_towe_Tmin = lm(@formula(Tmin ~ TAverage_pred), select_pred_towe)
mod_towe_TAverage = lm(@formula(TAverage ~ TAverage_pred), select_pred_towe)
mod_towe_Rhmin = lm(@formula(Rh_min ~ HRAverage_pred), select_pred_towe)
mod_towe_Rhmax = lm(@formula(Rh_max ~ HRAverage_pred), select_pred_towe)
mod_towe_RhAverage = lm(@formula(HRAverage ~ HRAverage_pred), select_pred_towe)
mod_towe_Precipitation = lm(@formula(Precipitations ~ Rainfall_pred), select_pred_towe)
mod_towe_Rg = lm(@formula(Rg ~ Rg_pred), select_pred_towe)
mod_towe_Ri_PAR_f = lm(@formula(Ri_PAR_f ~ Ri_PAR_pred), select_pred_towe)

# Predict each rows 
select_pred_towe.Tmax_pred = coef(mod_towe_Tmax)[1] .+ coef(mod_towe_Tmax)[2] .* select_pred_towe.TAverage_pred
select_pred_towe.Tmin_pred = coef(mod_towe_Tmin)[1] .+ coef(mod_towe_Tmin)[2] .* select_pred_towe.TAverage_pred
select_pred_towe.TAverage_pred = coef(mod_towe_TAverage)[1] .+ coef(mod_towe_TAverage)[2] .* select_pred_towe.TAverage_pred
select_pred_towe.Rh_min_pred = coef(mod_towe_Rhmin)[1] .+ coef(mod_towe_Rhmin)[2] .* select_pred_towe.HRAverage_pred
select_pred_towe.Rh_max_pred = coef(mod_towe_Rhmax)[1] .+ coef(mod_towe_Rhmax)[2] .* select_pred_towe.HRAverage_pred
select_pred_towe.RhAverage_pred = coef(mod_towe_RhAverage)[1] .+ coef(mod_towe_RhAverage)[2] .* select_pred_towe.HRAverage_pred
select_pred_towe.Precipitations_pred = coef(mod_towe_Precipitation)[1] .+ coef(mod_towe_Precipitation)[2] .* select_pred_towe.Rainfall_pred
select_pred_towe.Precipitations_pred[findall(x -> !ismissing(x) && x < 0.0, select_pred_towe.Precipitations_pred)] .= 0.0 # set negative values to 0
select_pred_towe.Rg_pred = coef(mod_towe_Rg)[1] .+ coef(mod_towe_Rg)[2] .* select_pred_towe.Rg_pred
select_pred_towe.Ri_PAR_pred = coef(mod_towe_Ri_PAR_f)[1] .+ coef(mod_towe_Ri_PAR_f)[2] .* select_pred_towe.Ri_PAR_pred

# Now, replace missing 
select_pred_towe.Tmax = coalesce.(select_pred_towe.Tmax, select_pred_towe.Tmax_pred, mean(skipmissing(select_pred_towe.Tmax)))
select_pred_towe.Tmin = coalesce.(select_pred_towe.Tmin, select_pred_towe.Tmin_pred, mean(skipmissing(select_pred_towe.Tmin)))
select_pred_towe.TAverage = coalesce.(select_pred_towe.TAverage, select_pred_towe.TAverage_pred, mean(skipmissing(select_pred_towe.TAverage)))
select_pred_towe.Rh_min = coalesce.(select_pred_towe.Rh_min, select_pred_towe.Rh_min_pred, mean(skipmissing(select_pred_towe.Rh_min)))
select_pred_towe.Rh_max = coalesce.(select_pred_towe.Rh_max, select_pred_towe.Rh_max_pred, mean(skipmissing(select_pred_towe.Rh_max)))
select_pred_towe.HRAverage = coalesce.(select_pred_towe.HRAverage, select_pred_towe.RhAverage_pred, mean(skipmissing(select_pred_towe.HRAverage)))
select_pred_towe.Precipitations = coalesce.(select_pred_towe.Precipitations, select_pred_towe.Rainfall_pred, mean(skipmissing(select_pred_towe.Precipitations)))
select_pred_towe.Rg = coalesce.(select_pred_towe.Rg, select_pred_towe.Rg_pred, mean(skipmissing(select_pred_towe.Rg)))
select_pred_towe.Ri_PAR_f = coalesce.(select_pred_towe.Ri_PAR_f, select_pred_towe.Ri_PAR_pred, mean(skipmissing(select_pred_towe.Ri_PAR_f)))

#exception for wind and Ri_PAR_f since they are not predicted
avg_wind = mean(skipmissing(select_pred_towe.Wind))

# Replace missing values of Wind with their respective averages and 0.0 with 1e-6
select_pred_towe.Wind = coalesce.(select_pred_towe.Wind, avg_wind)
select_pred_towe.Wind[select_pred_towe.Wind.==0.0] .= 1e-6
any(select_pred_towe.Wind .== 0.0)

#replace the too fluctuated value with the average value 
select_pred_towe.Wind[select_pred_towe.Wind.>5] .= avg_wind
select_pred_towe.Rg[select_pred_towe.Rg.>30] .= mean(skipmissing(select_pred_towe.Rg))

# Plotting the temperature:
# Make a function to plot the data:
function plot_meteo(df, variables, title)
    select_pred_towe_long_meas = stack(select(df, :date, variables...), variables, variable_name=:variable, value_name=:value)
    select_pred_towe_long_sim = stack(select(df, :date, [string(i) * "_pred" => i for i in variables]...), variables, variable_name=:variable, value_name=:value)
    select_pred_towe_long = vcat(select_pred_towe_long_meas, select_pred_towe_long_sim, source=:source => [:measured, :predicted])
    data(select_pred_towe_long) * mapping(:date, :value, color=:source, row=:variable) * visual(Lines) |> draw(legend=(; orientation=:horizontal, position=:bottom), figure=(; title=title))
end

plot_meteo(select_pred_towe, [:Tmax, :Tmin, :TAverage], "Temperature towe") #plot the data
plot_meteo(select_pred_towe, [:Rh_min, :Rh_max], "Humidity towe") #plot the data
plot_meteo(select_pred_towe, [:Precipitations], "Rainfall towe") #plot the data

# Check summary after imputation
describe(select_pred_towe)

#rename TAverage and HRAverage to T and Rh
select_pred_towe = rename(select_pred_towe, :TAverage => :T, :HRAverage => :Rh)

#create the csv file
CSV.write("2-results/meteorology/meteo_towe_cleaned.csv", select_pred_towe, delim=";")

