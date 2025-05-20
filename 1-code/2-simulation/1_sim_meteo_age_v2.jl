using XPalm, DataFrames, YAML, CSV
using CairoMakie, AlgebraOfGraphics, Statistics
using Dates

meteo_smse = CSV.read("2-results/meteo_smse_cleaned.csv", missingstring=["NA", "NaN"], DataFrame)  #Indonesia
meteo_towe = DataFrame(CSV.File("xpalm_introduction/2-results/meteo_towe_cleaned.csv", missingstring=["NA", "NaN"])) #Benin
meteo_presco = DataFrame(CSV.File("xpalm_introduction/2-results/meteo_presco_cleaned.csv", missingstring=["NA", "NaN"])) #Nigeria

sites = Dict(
    "SMSE" => meteo_smse,
    "PRESCO" => meteo_presco,
    "TOWE" => meteo_towe,
)

res_age = DataFrame[]
parameters = YAML.load_file("xpalm_introduction/0-data/xpalm_parameters.yml"; dicttype=Dict{Symbol,Any})


for (site, meteo) in sites
    p = XPalm.Palm(parameters=parameters)
    sim_age = xpalm(
        meteo,
        DataFrame,
        vars=Dict(
            "Scene" => (:lai,),
            "Plant" => (:leaf_area, :biomass_bunch_harvested, :plant_age, :biomass_bunch_harvested_cum),
            "Soil" => (:ftsw,),
            "Leaf" => (:biomass,),
        ),
        palm=p
    )
    sim_age[!, :date] = meteo.date[sim_age.timestep]
    sim_age[!, :Site] = fill(site, nrow(sim_age))
    push!(res_age, sim_age)
end

all_sim_age = vcat(res_age...)

#see why is the leaf area stop growing in meteo towe
leaf_towe = filter(row -> row.Site == "TOWE" && row.organ == "Plant", all_sim_age)[!, [:date, :plant_age, :leaf_area]]
leaf_presco = filter(row -> row.Site == "PRESCO" && row.organ == "Plant", all_sim_age)[!, [:date, :plant_age, :leaf_area]]

#simulation investigating towe 
p = XPalm.Palm(parameters=parameters)

age_leaf_towe = xpalm(
    meteo_towe,
    DataFrame,
    vars=Dict(
        "Scene" => (:lai,),
        "Plant" => (:leaf_area, :plant_age, :biomass_bunch_harvested, :biomass, :carbon_demand,),
        "Female" => (:biomass, :carbon_demand_plant, :carbon_offer_plant,),
        "Soil" => (:ftsw,),
        "Leaf" => (:biomass,),
    ),
    palm=p,
)

plt1_age_towe = data(filter(:organ => ==("Plant"), age_leaf_towe)) *
                mapping(:plant_age, :leaf_area, color=:organ => string) *
                visual(Lines)
draw(plt1_age_towe)

plt_2 = data(filter(:organ => ==("Female"), age_leaf_towe)) *
        mapping(:ftsw, :carbon_offer_plant, color=:organ => string) *
        visual(Lines)







#########
plt_age1 = data(filter(:organ => ==("Plant"), all_sim_age)) *
           mapping(:plant_age, :leaf_area, color=:Site) *
           visual(Lines)
draw(plt_age1)


# Filter rows where plant_age and leaf_area are both present
plant_age_clean = filter(row -> !ismissing(row.plant_age) && !ismissing(row.leaf_area), all_sim_age)
age_bunch = filter(row ->
        row.plant_age !== missing &&
            row.biomass_bunch_harvested !== missing &&
            row.plant_age != 0,
    all_sim_age)

# Create a line plot grouped by site
age_leaf_area = data(filter(:organ => ==("Plant"), all_sim_age)) *
                mapping(:plant_age, :leaf_area, color=:Site => string) *
                visual(Lines)
draw(age_leaf_area)
age_lai = data(filter(:organ => ==("Scene"), all_sim_age)) *
          mapping(:plant_age, :lai, color=:Site => string) *
          visual(Lines)
draw(age_lai)
age_biomass = data(filter(:organ => ==("Plant"), all_sim_age)) *
              mapping(:plant_age, :biomass_bunch_harvested, color=:Site => string) *
              visual(Lines)
draw(age_biomass)
age_ftsw = data(filter(:organ => ==("Soil"), all_sim_age)) *
           mapping(:plant_age, :ftsw, color=:Site => string) *
           visual(Lines)
draw(age_ftsw)
age_biomass = data(filter(:organ => ==("Plant"), all_sim_age)) *
              mapping(:plant_age, :biomass, color=:Site => string) *
              visual(Lines)
draw(age_biomass)

#####

#dataframe meteo nursery is coming from the average value of smse meteo
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
CSV.write("xpalm_introduction/2-results/meteo_nursery.csv", meteo_nursery)

#not possible to make the simulation because the date is missing
#will merge with the planting dataset after

#plot depending on the plant age

# Get the first date in the meteo file
seed_smse = Date("2011-01-02") #2011-01-02
seed_presco = Date("2010-01-02") #2010-01-02
seed_towe = Date("2012-01-02") #2012-01-02

planting_smse = Date("2011-01-01")
planting_presco = Date("2010-05-01")
planting_towe = Date("2012-06-01")


days_smse = Dates.value.(planting_smse - seed_smse)
days_presco = Dates.value.(seed_presco - planting_presco)
days_towe = Dates.value.(seed_towe - planting_towe)

df_planting_smse = filter(r -> r.date >= planting_smse, meteo_smse)
df_planting_presco = filter(r -> r.date >= planting_presco, meteo_presco)
df_planting_towe = filter(r -> r.date >= planting_towe, meteo_towe)

sites_age = Dict(
    "SMSE" => df_planting_smse,
    "PRESCO" => df_planting_presco,
    "TOWE" => df_planting_towe,
)

sims = DataFrame[]
parameters = YAML.load_file("xpalm_introduction/0-data/xpalm_parameters.yml"; dicttype=Dict{Symbol,Any})


for (site, meteo) in sites_age
    p = XPalm.Palm(parameters=parameters)
    sim2_age = xpalm(
        meteo,
        DataFrame,
        vars=Dict(
            "Scene" => (:lai,),
            "Plant" => (:leaf_area, :biomass_bunch_harvested, :plant_age, :biomass_bunch_harvested_cum),
            "Soil" => (:ftsw,),
            "Leaf" => (:biomass,),
        ),
        palm=p
    )
    sim2_age[!, :date] = meteo.date[sim2_age.timestep]
    sim2_age[!, :Site] = fill(site, nrow(sim2_age))
    push!(sims, sim2_age)
end

all_sim2_age = vcat(sims...)

age2_biomass_bunch_cum = data(filter(:organ => ==("Plant"), all_sim2_age)) *
                         mapping(:plant_age, :biomass_bunch_harvested_cum, color=:Site => string) *
                         visual(Lines)
draw(age2_biomass_bunch_cum)

age2_leaf_area = data(filter(:organ => ==("Plant"), all_sim2_age)) *
                 mapping(:plant_age, :leaf_area, color=:Site => string) *
                 visual(Lines)
draw(age2_leaf_area)


#meteo nursery + planting 

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

output_dir = "xpalm_introduction/2-results"

for (name, df) in pairs(csv_sets)
    CSV.write(joinpath(output_dir, "meteo_$(name)_combined.csv"), df, delim=";")
end

#try the simulation
#with only the nursery data that the date is depends on the meteo smse combined
nursery_smse = filter(r -> r.date < planting_smse, meteo_smse_combined)

sim1_smse_nursery = xpalm(
    nursery_smse,
    DataFrame,
    vars=Dict(
        "Scene" => (:lai,),
        "Plant" => (:leaf_area, :biomass_bunch_harvested, :plant_age, :biomass_bunch_harvested_cum,),
        "Soil" => (:ftsw,),
        "Leaf" => (:biomass,),
    ),
    palm=p,
)
plt1 = data(filter(:organ => ==("Plant"), sim1_smse_nursery)) *
       mapping(:plant_age, :biomass_bunch_harvested_cum) *
       visual(Lines)
draw(plt1)


#ximulation with combined data, including the nursery and planting

sim2_smse_combined = xpalm(
    meteo_smse_combined,
    DataFrame,
    vars=Dict(
        "Scene" => (:lai,),
        "Plant" => (:leaf_area, :biomass_bunch_harvested, :plant_age, :biomass_bunch_harvested_cum,),
        "Soil" => (:ftsw,),
        "Leaf" => (:biomass,),
    ),
    palm=p,
)

plt_2 = data(filter(:organ => ==("Plant"), sim2_smse_combined)) *
        mapping(:plant_age, :biomass_bunch_harvested_cum) *
        visual(Lines)
draw(plt_2)

csv_sets = (
    smse=meteo_smse_combined,
    presco=meteo_presco_combined,
    towe=meteo_towe_combined,
)

sims = DataFrame[]
parameters = YAML.load_file("xpalm_introduction/0-data/xpalm_parameters.yml"; dicttype=Dict{Symbol,Any})


for (site, meteo) in pairs(csv_sets)
    p = XPalm.Palm(parameters=parameters)
    sim3_age = xpalm(
        meteo,
        DataFrame,
        vars=Dict(
            "Scene" => (:lai,),
            "Plant" => (:leaf_area, :biomass_bunch_harvested, :plant_age, :biomass_bunch_harvested_cum),
            "Soil" => (:ftsw,),
            "Leaf" => (:biomass,),
        ),
        palm=p
    )
    sim3_age[!, :Site] = fill(site, nrow(sim3_age))
    push!(sims, sim3_age)
end

all_sim3_age = vcat(sims...)

age3_biomass_bunch_cum = data(filter(:organ => ==("Plant"), all_sim3_age)) *
                         mapping(:plant_age, :biomass_bunch_harvested_cum, color=:Site => string) *
                         visual(Lines)
draw(age3_biomass_bunch_cum)

age3_leaf_area = data(filter(:organ => ==("Plant"), all_sim3_age)) *
                 mapping(:plant_age, :leaf_area, color=:Site => string) *
                 visual(Lines)
draw(age3_leaf_area)

age3_ftsw = data(filter(:organ => ==("Soil"), all_sim3_age)) *
            mapping(:plant_age, :ftsw, color=:Site => string) *
            visual(Lines)
draw(age3_ftsw)