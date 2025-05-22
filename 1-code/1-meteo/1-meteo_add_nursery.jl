"""
This is the code to make the meteo datasets from 3 sites (smse, presco, towe) within the same period (nursery + planting date)
Note: Make sure to run all the 0_meteo code before this code
"""

using XPalm, DataFrames, YAML, CSV
using CairoMakie, AlgebraOfGraphics, Statistics
using Dates

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
)

nursery_days = Int(round(1.5 * 365))  # 548
meteo_nursery = repeat(meteo_nursery, nursery_days)
CSV.write("2-results/meteo_nursery.csv", meteo_nursery)

#2. Identify the planting date
planting_smse = Date("2011-01-01")
planting_presco = Date("2010-05-01")
planting_towe = Date("2012-06-01")

df_planting_smse = filter(r -> r.date >= planting_smse, meteo_smse)
df_planting_presco = filter(r -> r.date >= planting_presco, meteo_presco)
df_planting_towe = filter(r -> r.date >= planting_towe, meteo_towe)

#3. meteo nursery + planting 

meteo_smse_combined = vcat(meteo_nursery, df_planting_smse; cols=:union)
meteo_presco_combined = vcat(meteo_nursery, df_planting_presco; cols=:union)
meteo_towe_combined = vcat(meteo_nursery, df_planting_towe; cols=:union)

add_smse = planting_smse .- Day.(nursery_days-1:-1:0) #in smse the planting date is 2011-01-01 isnt included so the filling dats is end 2011-01-01
add_presco = planting_presco .- Day.(nursery_days:-1:1) #in presco the filling date will end before 2010-05-01
add_towe = planting_towe .- Day.(nursery_days:-1:1) #in towe the filling date will end before 2012-06-01

#fill in the missing date values
datasets = (
    smse=(df=Ref(meteo_smse_combined), dates=add_smse),
    presco=(df=Ref(meteo_presco_combined), dates=add_presco),
    towe=(df=Ref(meteo_towe_combined), dates=add_towe),
)

# Loop through each dataset and assign dates where missing
for (name, (df_ref, dates)) in pairs(datasets)
    df = df_ref[]
    missing_inds = findall(ismissing, df.date)

    if length(missing_inds) == length(dates)
        df.date[missing_inds] = dates
        @info "Filled missing dates for $name"
    else
        error("Mismatch in $name: $(length(missing_inds)) missing vs $(length(dates)) dates.")
    end
end

csv_sets = (
    smse=meteo_smse_combined,
    presco=meteo_presco_combined,
    towe=meteo_towe_combined,
)

output_dir = "2-results"

for (name, df) in pairs(csv_sets)
    CSV.write(joinpath(output_dir, "meteo_$(name)_combined.csv"), df, delim=";")
end

