using Revise
using XPalm, DataFrames, YAML, CSV
using CairoMakie, AlgebraOfGraphics

CSV.write("xpalm_introduction/2-results/meteo_presco.csv", meteo_presco)

meteo_smse = DataFrame(CSV.File("xpalm_introduction/2-results/meteo_smse_cleaned.csv"; select = ["date", "Tmin", "Tmax", "Wind", "Rh_max", "Rh_min", "Precipitations", "Ri_PAR_f", "Rg"]))  #Indonesia
meteo_towe = DataFrame(CSV.File("xpalm_introduction/2-results/meteo_towe_cleaned.csv"; select = ["date", "Tmin", "Tmax", "Wind", "Rh_max", "Rh_min", "Precipitations", "Ri_PAR_f", "Rg"],
missingstrings=["NA", "NaN"])) #Benin
meteo_presco = DataFrame(CSV.File("xpalm_introduction/2-results/meteo_presco_cleaned.csv"; select = ["date", "Tmin", "Tmax", "Wind", "Rh_max", "Rh_min", "Precipitations", "Ri_PAR_f", "Rg"])) #Nigeria

CSV.write("xpalm_introduction/2-results/meteo_towe.csv", meteo_towe)
describe(meteo_towe)
meteo_smse = dropmissing(meteo_smse) #none of the values are dropped
meteo_towe = dropmissing(meteo_towe) #none values are dropped
meteo_presco = dropmissing(meteo_presco) #none values are dropped

parameters = YAML.load_file("xpalm_introduction/0-data/xpalm_parameters.yml"; dicttype=Dict{Symbol,Any}) 

p = XPalm.Palm(parameters=parameters)

#simulation for SMSE

sim1_smse = xpalm(
    meteo_smse,
    DataFrame,
    vars = Dict(
        "Scene" => (:lai,),
        "Plant" => (:leaf_area, :biomass_bunch_harvested,),
        "Soil" => (:ftsw,),
        "Leaf" => (:biomass,),
    ),
    palm = p,
) 


#add the date depending on the timestep
sim1_smse.date = meteo_smse.date[sim1_smse.timestep]

#plot lai - scene
plt1_smse_lai = data(filter(:organ => ==("Scene"), sim1_smse)) *
    mapping(:date, :lai, color = :organ => string) *
    visual(Lines)
draw(plt1_smse_lai)

#plot leaf Area - plant
plt_smse_leaf_area = data(filter(:organ => ==("Plant"), sim1_smse)) *
    mapping(:date, :leaf_area, color = :organ => string) *
    visual(Lines)
draw(plt_smse_leaf_area)

#plot biomass_bunch_harvested - plant
plt_smse_biomass_bunch_harvested = data(filter(:organ => ==("Plant"), sim1_smse)) *
    mapping(:date, :biomass_bunch_harvested, color = :organ => string) *
    visual(Lines)
draw(plt_smse_biomass_bunch_harvested)

#plot ftsw - Soil
plt_smse_ftsw_soil = data(filter(:organ => ==("Soil"), sim1_smse)) *
    mapping(:date, :ftsw, color = :organ => string) *
    visual(Lines)
draw(plt_smse_ftsw_soil)

#plot biomass - leaf
plt_smse_biomass_leaf = data(filter(:organ => ==("Leaf"), sim1_smse)) *
    mapping(:date, :biomass, color = :organ => string) *
    visual(Lines)
draw(plt_smse_biomass_leaf)


###
#simulation for PRESCO

p = XPalm.Palm(parameters=parameters)

sim1_presco = xpalm(
    meteo_presco,
    DataFrame,
    vars = Dict(
        "Scene" => (:lai,),
        "Plant" => (:leaf_area, :biomass_bunch_harvested,),
        "Soil" => (:ftsw,),
        "Leaf" => (:biomass,),
    ),
    palm = p,
)


#add the date depending on the timestep
sim1_presco.date = meteo_presco.date[sim1_presco.timestep]

#plot lai - scene
plt1_presco_lai = data(filter(:organ => ==("Scene"), sim1_presco)) *
    mapping(:date, :lai, color = :organ => string) *
    visual(Lines)
fig1 = draw(plt1_presco_lai)


#plot leaf Area - plant
plt_presco_leaf_area = data(filter(:organ => ==("Plant"), sim1_presco)) *
    mapping(:date, :leaf_area, color = :organ => string) *
    visual(Lines)
draw(plt_presco_leaf_area)

#plot biomass_bunch_harvested - plant
plt_presco_biomass_bunch_harvested = data(filter(:organ => ==("Plant"), sim1_presco)) *
    mapping(:date, :biomass_bunch_harvested, color = :organ => string) *
    visual(Lines)
draw(plt_presco_biomass_bunch_harvested)

#plot ftsw - Soil
plt_presco_ftsw_soil = data(filter(:organ => ==("Soil"), sim1_presco)) *
    mapping(:date, :ftsw, color = :organ => string) *
    visual(Lines)
draw(plt_presco_ftsw_soil)

#plot biomass - leaf
plt_presco_biomass_leaf = data(filter(:organ => ==("Leaf"), sim1_presco)) *
    mapping(:date, :biomass, color = :organ => string) *
    visual(Lines)
draw(plt_presco_biomass_leaf)


### 

#simulation for TOWE

# Show column name and type
column_types = DataFrame(
    variable = names(select_pred_presco),
    type = map(eltype, eachcol(select_pred_presco))
)


describe(meteo_towe)
describe(meteo_presco)

p = XPalm.Palm(parameters=parameters)

sim1_towe = xpalm(
    meteo_towe,
    DataFrame,
    vars = Dict(
        "Scene" => (:lai,),
        "Plant" => (:leaf_area, :biomass_bunch_harvested,),
        "Soil" => (:ftsw,),
        "Leaf" => (:biomass,),
    ),
    palm = p,
)

Inf/Inf

#add the date depending on the timestep
sim1_towe.date = meteo_towe.date[sim1_towe.timestep]

#plot lai - scene
plt1_towe_lai = data(filter(:organ => ==("Scene"), sim1_towe)) *
    mapping(:date, :lai, color = :organ => string) *
    visual(Lines)
draw(plt1_towe_lai)

#plot leaf Area - plant
plt_towe_leaf_area = data(filter(:organ => ==("Plant"), sim1_towe)) *
    mapping(:date, :leaf_area, color = :organ => string) *
    visual(Lines)
draw(plt_towe_leaf_area)

#plot biomass_bunch_harvested - plant
plt_towe_biomass_bunch_harvested = data(filter(:organ => ==("Plant"), sim1_towe)) *
    mapping(:date, :biomass_bunch_harvested, color = :organ => string) *
    visual(Lines)
draw(plt_towe_biomass_bunch_harvested)

#plot ftsw - Soil
plt_towe_ftsw_soil = data(filter(:organ => ==("Soil"), sim1_towe)) *
    mapping(:date, :ftsw, color = :organ => string) *
    visual(Lines)
draw(plt_towe_ftsw_soil)

#plot biomass - leaf
plt_towe_biomass_leaf = data(filter(:organ => ==("Leaf"), sim1_towe)) *
    mapping(:date, :biomass, color = :organ => string) *
    visual(Lines)
draw(plt_towe_biomass_leaf)

