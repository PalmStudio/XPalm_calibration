# This is XPalm simulation for sites comparison to plot the considered parameters

using XPalm
using PlantMeteo
using PlantSimEngine
using DataFrames, CSV, YAML, StatsBase, Dates
using CairoMakie, AlgebraOfGraphics, Statistics

#load long data
sites_comb = Dict(
    "SMSE" => CSV.read("2-results/meteorology/meteo_smse_with_nursery.csv", missingstring=["NA", "NaN"], DataFrame),
    "PRESCO" => CSV.read("2-results/meteorology/meteo_presco_with_nursery.csv", missingstring=["NA", "NaN"], DataFrame),
    "TOWE" => CSV.read("2-results/meteorology/meteo_towe_with_nursery.csv", missingstring=["NA", "NaN"], DataFrame)
)
combined_df = vcat(
    [hcat(df, DataFrame(site=fill(site, nrow(df)))) for (site, df) in sites_comb]...
)

CSV.write("2-results/meteorology/combine_meteo.csv", combined_df)

#simulation all climate with nursery

meteo = CSV.read("2-results/meteorology/combine_meteo.csv", missingstring=["NA", "NaN"], DataFrame)
meteos = [Weather(i) for i in groupby(meteo, :site)]

begin
    params_default = (YAML.load_file("0-data/xpalm_parameters.yml"))

    params_SMSE = copy(params_default)
    params_SMSE["plot"]["latitude"] = 2.93416
    params_SMSE["plot"]["altitude"] = 15.5

    params_PRESCO = copy(params_default)
    params_PRESCO["plot"]["latitude"] = 6.137
    params_PRESCO["plot"]["altitude"] = 15.5

    params_TOWE = copy(params_default)
    params_TOWE["plot"]["latitude"] = 7.00
    params_TOWE["plot"]["altitude"] = 15.5

    params = Dict("SMSE" => params_SMSE, "PRESCO" => params_PRESCO, "TOWE" => params_TOWE,)
    out_vars = Dict{String,Any}("Scene" => (:lai, :ET0),
        "Plant" => (:leaf_area, :biomass_bunch_harvested, :plant_age, :biomass_bunch_harvested_cum, :aPPFD, :carbon_assimilation, :n_bunches_harvested_cum, :n_bunches_harvested, :Rm, :reserve, :yield_gap_oil, :biomass_oil_harvested),
        "Soil" => (:ftsw, :qty_H2O_C_Roots, :transpiration),
        "Leaf" => (:biomass,),
        "Phytomer" => (:phytomer_count,),
        "Female" => (:biomass_bunch_harvested, :plant_age, :biomass, :fruits_number, :nb_fruits_flag),
        "Male" => (:biomass,),
        "Internode" => (:biomass,),)

    simulations = DataFrame[]
    for m in meteos
        site = m[1].site
        palm = XPalm.Palm(parameters=params[site])
        df = xpalm(m, DataFrame, vars=out_vars, palm=palm)
        df = df["Soil"]

        # Add site name
        df[!, "Site"] .= site

        # Get matching meteorology data for the current site
        meteo_site = filter(:site => x -> x == site, meteo)

        # Add :date column by matching timestep
        df[!, :date] = meteo_site.date[df.timestep]

        #add planting date 
        planting_date = site == "SMSE" ? Date("2011-01-01") :
                        site == "PRESCO" ? Date("2010-05-01") :
                        site == "TOWE" ? Date("2012-06-01") : missing

        df[!, :planting_date] .= planting_date

        #add MAP
        df[!, :MAP] = [(year(d) - year(planting_date)) * 12 + (month(d) - month(planting_date)) for d in df.date]

        push!(simulations, df)
    end
end

dfs_all = vcat(simulations...)

mkpath("2-results/simulations")
CSV.write("2-results/simulations/sim_comparison_soil.csv", dfs_all)

#plot the comparison of number of ftsw < 0.3 within the sites in bar plot
df_ftsw = CSV.read("2-results/simulations/sim_comparison_soil.csv", missingstring=["NA", "NaN"], DataFrame)
data(df_ftsw) * mapping(:MAP, :ftsw, color=:Site) * visual(Lines) |> draw

threshold_ftsw = 0.3
df_count_ftsw_stress = combine(groupby(df_ftsw, [:Site, :MAP]), :ftsw => (x -> sum(0.0 .< x .< threshold_ftsw)) => :n_ftsw)

plt_ftsw = data(df_count_ftsw_stress) *
           mapping(:MAP, :n_ftsw, color=:Site) *
           visual(Lines)
fig_n_ftsw = draw(plt_ftsw)
save("2-results/simulations/n_ftsw.png", fig_n_ftsw)