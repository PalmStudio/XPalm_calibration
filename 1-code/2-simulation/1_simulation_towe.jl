using XPalm, DataFrames, YAML, CSV
using CairoMakie, AlgebraOfGraphics, Statistics
using Dates


meteo = CSV.read("2-results/meteo_towe_cleaned.csv", missingstring=["NA", "NaN"], DataFrame) #Benin
parameters = YAML.load_file("0-data/xpalm_parameters.yml"; dicttype=Dict{Symbol,Any})

p = XPalm.Palm(parameters=parameters)

sim = xpalm(
    meteo,
    DataFrame,
    vars=Dict(
        "Scene" => (:lai, :ET0),
        "Plant" => (:leaf_area, :biomass_bunch_harvested, :plant_age, :biomass_bunch_harvested_cum, :aPPFD, :carbon_assimilation),
        "Soil" => (:ftsw, :qty_H2O_C2_Roots, :transpiration),
        "Leaf" => (:biomass,),
    ),
    palm=p
)

sim[!, :date] = meteo.date[sim.timestep]

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
