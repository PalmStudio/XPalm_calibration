using YAML, CSV, DataFrames, Dates, CairoMakie, AlgebraOfGraphics
using GLM, StatsBase, Statistics

csv_pred_smse = CSV.read("0-data/all_meteo_predictions_smse.csv",
    DataFrame,
    missingstring=["NA", "NaN"]
)

rename!(csv_pred_smse, :TMax => :Tmax,
    :TMin => :Tmin,
    :HRMin => :Rh_min,
    :HRMax => :Rh_max,
    :WindSpeed => :Wind,
    :Rainfall => :Precipitations,
    :ObservationDate => :date,
    :PAR => :Ri_PAR_f,
)

#data that will be processed
select_pred_smse = select(csv_pred_smse, :date, :Tmax, :Tmin, :Rh_min, :Rh_max, :Wind, :Precipitations, :Ri_PAR_f, :TAverage_pred, :HRAverage_pred, :Rainfall_pred, :Rg_pred, :Rg, :TAverage, :HRAverage)  #its exist
select_pred_smse.Ri_PAR_f = allowmissing(select_pred_smse.Ri_PAR_f) #this is different from the other datasets to zvoid eror
select_pred_smse.Ri_PAR_f[findall(x -> !ismissing(x) && x == 0.0, select_pred_smse.Ri_PAR_f)] .= missing

select_pred_smse.Ri_PAR_pred = select_pred_smse.Rg_pred .* 0.48
select_pred_smse.Rh_max = select_pred_smse.Rh_max ./ 100
select_pred_smse.Rh_min = select_pred_smse.Rh_min ./ 100
select_pred_smse.HRAverage = select_pred_smse.HRAverage ./ 100

# Fit model (example for smse)
mod_smse_Tmax = lm(@formula(Tmax ~ TAverage_pred), select_pred_smse)
mod_smse_Tmin = lm(@formula(Tmin ~ TAverage_pred), select_pred_smse)
mod_smse_TAverage = lm(@formula(TAverage ~ TAverage_pred), select_pred_smse)
mod_smse_Rhmin = lm(@formula(Rh_min ~ HRAverage_pred), select_pred_smse)
mod_smse_Rhmax = lm(@formula(Rh_max ~ HRAverage_pred), select_pred_smse)
mod_smse_RhAverage = lm(@formula(HRAverage ~ HRAverage_pred), select_pred_smse)
mod_smse_Precipitation = lm(@formula(Precipitations ~ Rainfall_pred), select_pred_smse)
mod_smse_Rg = lm(@formula(Rg ~ Rg_pred), select_pred_smse)
mod_smse_Ri_PAR_f = lm(@formula(Ri_PAR_f ~ Ri_PAR_pred), select_pred_smse)

# Predict each rows 
select_pred_smse.Tmax_pred = coef(mod_smse_Tmax)[1] .+ coef(mod_smse_Tmax)[2] .* select_pred_smse.TAverage_pred
select_pred_smse.Tmin_pred = coef(mod_smse_Tmin)[1] .+ coef(mod_smse_Tmin)[2] .* select_pred_smse.TAverage_pred
select_pred_smse.TAverage_pred = coef(mod_smse_TAverage)[1] .+ coef(mod_smse_TAverage)[2] .* select_pred_smse.TAverage_pred
select_pred_smse.Rh_min_pred = coef(mod_smse_Rhmin)[1] .+ coef(mod_smse_Rhmin)[2] .* select_pred_smse.HRAverage_pred
select_pred_smse.Rh_max_pred = coef(mod_smse_Rhmax)[1] .+ coef(mod_smse_Rhmax)[2] .* select_pred_smse.HRAverage_pred
select_pred_smse.RhAverage_pred = coef(mod_smse_RhAverage)[1] .+ coef(mod_smse_RhAverage)[2] .* select_pred_smse.HRAverage_pred
select_pred_smse.Precipitations_pred = coef(mod_smse_Precipitation)[1] .+ coef(mod_smse_Precipitation)[2] .* select_pred_smse.Rainfall_pred
select_pred_smse.Precipitations_pred[findall(x -> !ismissing(x) && x < 0.0, select_pred_smse.Precipitations_pred)] .= 0.0 # set negative values to 0
select_pred_smse.Rg_pred = coef(mod_smse_Rg)[1] .+ coef(mod_smse_Rg)[2] .* select_pred_smse.Rg_pred
select_pred_smse.Ri_PAR_pred = coef(mod_smse_Ri_PAR_f)[1] .+ coef(mod_smse_Ri_PAR_f)[2] .* select_pred_smse.Ri_PAR_pred

# Now, replace missing 
select_pred_smse.Tmax = coalesce.(select_pred_smse.Tmax, select_pred_smse.Tmax_pred, mean(skipmissing(select_pred_smse.Tmax)))
select_pred_smse.Tmin = coalesce.(select_pred_smse.Tmin, select_pred_smse.Tmin_pred, mean(skipmissing(select_pred_smse.Tmin)))
select_pred_smse.TAverage = coalesce.(select_pred_smse.TAverage, select_pred_smse.TAverage_pred, mean(skipmissing(select_pred_smse.TAverage)))
select_pred_smse.Rh_min = coalesce.(select_pred_smse.Rh_min, select_pred_smse.Rh_min_pred, mean(skipmissing(select_pred_smse.Rh_min)))
select_pred_smse.Rh_max = coalesce.(select_pred_smse.Rh_max, select_pred_smse.Rh_max_pred, mean(skipmissing(select_pred_smse.Rh_max)))
select_pred_smse.HRAverage = coalesce.(select_pred_smse.HRAverage, select_pred_smse.RhAverage_pred, mean(skipmissing(select_pred_smse.HRAverage)))
select_pred_smse.Precipitations = coalesce.(select_pred_smse.Precipitations, select_pred_smse.Rainfall_pred, mean(skipmissing(select_pred_smse.Precipitations)))
select_pred_smse.Rg = coalesce.(select_pred_smse.Rg, select_pred_smse.Rg_pred, mean(skipmissing(select_pred_smse.Rg)))
select_pred_smse.Ri_PAR_f = coalesce.(select_pred_smse.Ri_PAR_f, select_pred_smse.Ri_PAR_pred, mean(skipmissing(select_pred_smse.Ri_PAR_f)))

#exception for wind and Ri_PAR_f since they are not predicted
avg_wind = mean(skipmissing(select_pred_smse.Wind))

# Replace missing values of Wind with their respective averages and 0.0 with 1e-6
select_pred_smse.Wind = coalesce.(select_pred_smse.Wind, avg_wind)
select_pred_smse.Wind[select_pred_smse.Wind.==0.0] .= 1e-6
any(select_pred_smse.Wind .== 0.0)

#replace the too fluctuated value with the average value 
select_pred_smse.Rg[select_pred_smse.Rg.>30] .= mean(skipmissing(select_pred_smse.Rg))
select_pred_smse.Tmin[select_pred_smse.Tmin.>30] .= mean(skipmissing(select_pred_smse.Tmin))

# Plotting the temperature:
# Make a function to plot the data:
function plot_meteo(df, variables, title)
    select_pred_smse_long_meas = stack(select(df, :date, variables...), variables, variable_name=:variable, value_name=:value)
    select_pred_smse_long_sim = stack(select(df, :date, [string(i) * "_pred" => i for i in variables]...), variables, variable_name=:variable, value_name=:value)
    select_pred_smse_long = vcat(select_pred_smse_long_meas, select_pred_smse_long_sim, source=:source => [:measured, :predicted])
    data(select_pred_smse_long) * mapping(:date, :value, color=:source, row=:variable) * visual(Lines) |> draw(legend=(; orientation=:horizontal, position=:bottom), figure=(; title=title))
end

plot_meteo(select_pred_smse, [:Tmax, :Tmin, :TAverage], "Temperature smse") #plot the data
plot_meteo(select_pred_smse, [:Rh_min, :Rh_max], "Humidity smse") #plot the data
plot_meteo(select_pred_smse, [:Precipitations], "Rainfall smse") #plot the data


# Check summary after imputation
describe(select_pred_smse)

#rename TAverage and HRAverage to T and Rh
select_pred_smse = rename(select_pred_smse, :TAverage => :T, :HRAverage => :Rh)

#Eror occured due to the relative humidity goes above 1 (1.0098) only for smse 
any(select_pred_smse.Rh .== 1.0098)
select_pred_smse.Rh[select_pred_smse.Rh.==1.0098] .= 1

#create the csv file
CSV.write("2-results/meteorology/meteo_smse_cleaned.csv", select_pred_smse, delim=";")

