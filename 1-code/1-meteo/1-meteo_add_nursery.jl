# This is the code to make the meteo datasets from 3 sites (smse, presco, towe) within the same period (nursery + planting date)
# Note: Make sure to run all the 0_meteo code before this code

using XPalm, DataFrames, YAML, CSV
using CairoMakie, AlgebraOfGraphics, Statistics
using Dates

meteo_smse = CSV.read("2-results/meteorology/meteo_smse_cleaned.csv", missingstring=["NA", "NaN"], DataFrame) # Indonesia
meteo_presco = CSV.read("2-results/meteorology/meteo_presco_cleaned.csv", missingstring=["NA", "NaN"], DataFrame) # Benin
meteo_towe = CSV.read("2-results/meteorology/meteo_towe_cleaned.csv", missingstring=["NA", "NaN"], DataFrame) # Nigeria

#1. Identify the nursery period
#dataframe meteo nursery is coming from the average value of smse meteo (consider as the most favorable climate) along 1.5 years before the planting date
meteo_nursery = DataFrame(
    Tmin=mean(meteo_smse.Tmin,),
    Tmax=mean(meteo_smse.Tmax,),
    Wind=mean(meteo_smse.Wind,),
    Rh_max=mean(meteo_smse.Rh_max,),
    Rh_min=mean(meteo_smse.Rh_min,),
    Precipitations=mean(meteo_smse.Precipitations,),
    Ri_PAR_f=mean(meteo_smse.Ri_PAR_f,),
    Rg=mean(meteo_smse.Rg,),
    T=mean(meteo_smse.T,),
    Rh=mean(meteo_smse.Rh,),
)

nursery_days = Int(round(1.5 * 365))  # 548
meteo_nursery = repeat(meteo_nursery, nursery_days)
meteo_nursery.period = fill("Nursery", nrow(meteo_nursery))
CSV.write("2-results/template_meteo_nursery.csv", meteo_nursery)

# 2. Set the planting date
planting_smse = Date("2011-01-01")
planting_presco = Date("2010-05-01")
planting_towe = Date("2012-06-01")

df_planting_smse = filter(r -> r.date >= planting_smse, meteo_smse)
df_planting_presco = filter(r -> r.date >= planting_presco, meteo_presco)
df_planting_towe = filter(r -> r.date >= planting_towe, meteo_towe)

df_planting_smse.period = fill("Planting", nrow(df_planting_smse))
df_planting_presco.period = fill("Planting", nrow(df_planting_presco))
df_planting_towe.period = fill("Planting", nrow(df_planting_towe))

#3. meteo nursery + planting 
meteo_nursery_smse = copy(meteo_nursery)
meteo_nursery_smse.date = planting_smse .- Day.(nursery_days-1:-1:0) #in smse the planting date is 2011-01-01
meteo_smse_combined = vcat(meteo_nursery_smse, df_planting_smse; cols=:union)

meteo_nursery_presco = copy(meteo_nursery)
meteo_nursery_presco.date = planting_presco .- Day.(nursery_days:-1:1) #in presco the filling date will end before 2010-05-01
meteo_presco_combined = vcat(meteo_nursery_presco, df_planting_presco; cols=:union)

meteo_nursery_towe = copy(meteo_nursery)
meteo_nursery_towe.date = planting_towe .- Day.(nursery_days:-1:1) #in towe the filling date will end before 2012-06-01
meteo_towe_combined = vcat(meteo_nursery_towe, df_planting_towe; cols=:union)


csv_sets = (
    smse=meteo_smse_combined,
    presco=meteo_presco_combined,
    towe=meteo_towe_combined,
)

output_dir = "2-results/meteorology/"

for (name, df) in pairs(csv_sets)
    CSV.write(joinpath(output_dir, "meteo_$(name)_with_nursery.csv"), df, delim=";")
end

