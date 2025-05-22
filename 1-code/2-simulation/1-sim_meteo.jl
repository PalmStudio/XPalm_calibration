'This is XPalm simulation for each sites to plot the considered parameters'

using Revise
using XPalm, DataFrames, YAML, CSV
using CairoMakie, AlgebraOfGraphics

#simulation for SMSE

meteo_smse = CSV.read("2-results/meteo_smse_cleaned.csv", missingstring=["NA", "NaN"], DataFrame) #Benin
parameters = YAML.load_file("0-data/xpalm_parameters.yml"; dicttype=Dict{Symbol,Any})

p = XPalm.Palm(parameters=parameters)

sim = xpalm(
    meteo_smse,
    DataFrame,
    vars=Dict(
        "Scene" => (:lai, :ET0),
        "Plant" => (:leaf_area, :biomass_bunch_harvested, :plant_age, :biomass_bunch_harvested_cum, :aPPFD, :carbon_assimilation),
        "Soil" => (:ftsw, :qty_H2O_C2_Roots, :transpiration),
        "Leaf" => (:biomass,),
    ),
    palm=p
)

sim[!, :date] = meteo_smse.date[sim.timestep]

data(filter(:organ => ==("Scene"), sim)) *
mapping(:date, :ET0) *
visual(Lines) |> draw

data(filter(:organ => ==("Soil"), sim)) *
mapping(:date, :qty_H2O_C2_Roots) *
visual(Lines) |> draw

data(filter(:organ => ==("Soil"), sim)) *
mapping(:date, :ftsw) *
visual(Lines) |> draw

data(filter(:organ => ==("Soil"), sim)) *
mapping(:date, :transpiration) *
visual(Lines) |> draw


data(filter(:organ => ==("Plant"), sim)) *
mapping(:date, :biomass_bunch_harvested_cum) *
visual(Lines) |> draw

data(filter(:organ => ==("Plant"), sim)) *
mapping(:date, :aPPFD) *
visual(Lines) |> draw

data(filter(:organ => ==("Plant"), sim)) *
mapping(:date, :carbon_assimilation) *
visual(Lines) |> draw


###
#simulation for PRESCO

meteo_presco = CSV.read("2-results/meteo_presco_cleaned.csv", missingstring=["NA", "NaN"], DataFrame) #Benin
parameters = YAML.load_file("0-data/xpalm_parameters.yml"; dicttype=Dict{Symbol,Any})

p = XPalm.Palm(parameters=parameters)

sim = xpalm(
    meteo_presco,
    DataFrame,
    vars=Dict(
        "Scene" => (:lai, :ET0),
        "Plant" => (:leaf_area, :biomass_bunch_harvested, :plant_age, :biomass_bunch_harvested_cum, :aPPFD, :carbon_assimilation),
        "Soil" => (:ftsw, :qty_H2O_C2_Roots, :transpiration),
        "Leaf" => (:biomass,),
    ),
    palm=p
)

sim[!, :date] = meteo_presco.date[sim.timestep]

data(filter(:organ => ==("Scene"), sim)) *
mapping(:date, :ET0) *
visual(Lines) |> draw

data(filter(:organ => ==("Soil"), sim)) *
mapping(:date, :qty_H2O_C2_Roots) *
visual(Lines) |> draw

data(filter(:organ => ==("Soil"), sim)) *
mapping(:date, :ftsw) *
visual(Lines) |> draw

data(filter(:organ => ==("Soil"), sim)) *
mapping(:date, :transpiration) *
visual(Lines) |> draw


data(filter(:organ => ==("Plant"), sim)) *
mapping(:date, :biomass_bunch_harvested_cum) *
visual(Lines) |> draw

data(filter(:organ => ==("Plant"), sim)) *
mapping(:date, :aPPFD) *
visual(Lines) |> draw

data(filter(:organ => ==("Plant"), sim)) *
mapping(:date, :carbon_assimilation) *
visual(Lines) |> draw


### 

#simulation for TOWE
meteo_towe = CSV.read("2-results/meteo_towe_cleaned.csv", missingstring=["NA", "NaN"], DataFrame) #Benin
parameters = YAML.load_file("0-data/xpalm_parameters.yml"; dicttype=Dict{Symbol,Any})

p = XPalm.Palm(parameters=parameters)

sim = xpalm(
    meteo_towe,
    DataFrame,
    vars=Dict(
        "Scene" => (:lai, :ET0),
        "Plant" => (:leaf_area, :biomass_bunch_harvested, :plant_age, :biomass_bunch_harvested_cum, :aPPFD, :carbon_assimilation),
        "Soil" => (:ftsw, :qty_H2O_C2_Roots, :transpiration),
        "Leaf" => (:biomass,),
    ),
    palm=p
)

sim[!, :date] = meteo_towe.date[sim.timestep]

data(filter(:organ => ==("Scene"), sim)) *
mapping(:date, :ET0) *
visual(Lines) |> draw

data(filter(:organ => ==("Soil"), sim)) *
mapping(:date, :qty_H2O_C2_Roots) *
visual(Lines) |> draw

data(filter(:organ => ==("Soil"), sim)) *
mapping(:date, :ftsw) *
visual(Lines) |> draw

data(filter(:organ => ==("Soil"), sim)) *
mapping(:date, :transpiration) *
visual(Lines) |> draw


data(filter(:organ => ==("Plant"), sim)) *
mapping(:date, :biomass_bunch_harvested_cum) *
visual(Lines) |> draw

data(filter(:organ => ==("Plant"), sim)) *
mapping(:date, :aPPFD) *
visual(Lines) |> draw

data(filter(:organ => ==("Plant"), sim)) *
mapping(:date, :carbon_assimilation) *
visual(Lines) |> draw

