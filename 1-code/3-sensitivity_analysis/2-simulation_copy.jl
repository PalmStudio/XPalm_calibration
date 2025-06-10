using XPalm
using PlantSimEngine
using YAML, CSV, DataFrames
using Base.Threads
using Statistics


sites = ["smse", "presco"]
meteos = Dict(s => CSV.read("2-results/meteorology/meteo_$(s)_with_nursery.csv",
    DataFrame) for s in sites)

template_parameters = YAML.load_file(
    "0-data/xpalm_parameters.yml"; dicttype=Dict{Symbol,Any})

doe = CSV.read("2-results/sensitivity/doe.csv", DataFrame)

col_H0 = findfirst(endswith("initial_water_content"), names(doe))
col_FC = findfirst(endswith("field_capacity"), names(doe))
doe[:, col_H0] .= doe[:, col_FC]


function set_nested!(dict::AbstractDict, path::Vector{<:AbstractString}, value)
    d = dict
    for k in path[1:end-1]
        d = d[Symbol(k)]
    end
    d[Symbol(path[end])] = value
end

latitude = Dict("smse" => 2.93416, "presco" => 6.137, "towe" => 7.00)
altitude = Dict("smse" => 15.5, "presco" => 15.5, "towe" => 15.5)

out_vars = Dict(
    "Scene" => (:lai, :ET0),
    "Plant" => (:leaf_area, :biomass_bunch_harvested, :plant_age,
        :biomass_bunch_harvested_cum, :aPPFD, :carbon_assimilation,
        :n_bunches_harvested_cum),
    "Soil" => (:ftsw, :qty_H2O_C_Roots, :transpiration),
    "Leaf" => (:biomass,),
    "Female" => (:biomass_bunch_harvested, :plant_age),
)

const N = nrow(doe)

simulations = Dict(s => Vector{Dict{String,Any}}(undef, N) for s in sites)

@time Threads.@threads for i in 1:N  #145990.415614 seconds (254.49 G allocations: 12.005 TiB, 1.76% gc time, 1.03% compilation time)
    # copy template once per thread, then adjust with DOE row
    base_params = deepcopy(template_parameters)
    for (k, v) in pairs(doe[i, :])
        set_nested!(base_params, split(string(k), "|"), v)
    end

    thread_results = Dict{String,Dict{String,Any}}()    # local bucket

    # loop over sites (still inside the same thread)
    for site in sites
        params = deepcopy(base_params)                   # local copy per site
        params[:plot][:latitude] = latitude[site]
        params[:plot][:altitude] = altitude[site]

        palm = XPalm.Palm(initiation_age=0, parameters=params)

        out = PlantSimEngine.run!(palm.mtg,
            XPalm.model_mapping(palm),
            meteos[site];
            tracked_outputs=out_vars,
            executor=PlantSimEngine.SequentialEx(),
            check=false)

        #  key fix: drop empty vectors so downstream code never crashes
        filter!(kv -> !isempty(kv[2]), out)

        sim = PlantSimEngine.convert_outputs(out, DataFrame; no_value=missing)

        soil_ftsw = sim["Soil"].ftsw
        max_ftsw = maximum(soil_ftsw)
        min_ftsw = minimum(soil_ftsw)

        plant_age = sim["Plant"].plant_age
        nursery_duration = 1.5 * 365
        age_3 = nursery_duration + 3 * 365
        age_6 = nursery_duration + 6 * 365
        idx_3_to_6 = findall(x -> age_3 < x ≤ age_6, plant_age)

        avg_female_3_to_6 = haskey(sim, "Female") ?
        begin
            df_fem = filter(x -> x.biomass_bunch_harvested > 0.0 &&
                    age_3 < x.plant_age ≤ age_6,
                sim["Female"])
            isempty(df_fem) ? missing : mean(df_fem.biomass_bunch_harvested)
        end :
                            missing

        # store in local bucket
        thread_results[site] = Dict(
            "doe" => i,
            "site" => site,
            "max_ftsw" => max_ftsw,
            "min_ftsw" => min_ftsw,
            "max_qty_H2O_C_Roots" => maximum(sim["Soil"].qty_H2O_C_Roots),
            "min_qty_H2O_C_Roots" => minimum(sim["Soil"].qty_H2O_C_Roots),
            "n_bunches_harvested_cum_3_to_6" =>
                sim["Plant"].n_bunches_harvested_cum[last(idx_3_to_6)] -
                sim["Plant"].n_bunches_harvested_cum[first(idx_3_to_6)],
            "average_bunch_biomass_3_to_6" => avg_female_3_to_6,
        )
    end

    # after the thread is done, copy its results into the shared dict
    for (site, res) in thread_results
        simulations[site][i] = res            # each i is unique > safe
    end
end


df_simulations = vcat([DataFrame(v) for v in values(simulations)]...)
CSV.write("2-results/sensitivity/simulations_copy_test.csv", df_simulations)



#repeat for towe only#######

sites = ["towe"]
meteos = Dict(s => CSV.read("2-results/meteorology/meteo_$(s)_with_nursery.csv",
    DataFrame) for s in sites)

template_parameters = YAML.load_file(
    "0-data/xpalm_parameters.yml"; dicttype=Dict{Symbol,Any})

doe = CSV.read("2-results/sensitivity/doe.csv", DataFrame)

col_H0 = findfirst(endswith("initial_water_content"), names(doe))
col_FC = findfirst(endswith("field_capacity"), names(doe))
doe[:, col_H0] .= doe[:, col_FC]


function set_nested!(dict::AbstractDict, path::Vector{<:AbstractString}, value)
    d = dict
    for k in path[1:end-1]
        d = d[Symbol(k)]
    end
    d[Symbol(path[end])] = value
end

latitude = Dict("smse" => 2.93416, "presco" => 6.137, "towe" => 7.00)
altitude = Dict("smse" => 15.5, "presco" => 15.5, "towe" => 15.5)

out_vars = Dict(
    "Scene" => (:lai, :ET0),
    "Plant" => (:leaf_area, :biomass_bunch_harvested, :plant_age,
        :biomass_bunch_harvested_cum, :aPPFD, :carbon_assimilation,
        :n_bunches_harvested_cum),
    "Soil" => (:ftsw, :qty_H2O_C_Roots, :transpiration),
    "Leaf" => (:biomass,),
    "Female" => (:biomass_bunch_harvested, :plant_age),
)

const N = nrow(doe)

simulations = Dict(s => Vector{Dict{String,Any}}(undef, N) for s in sites)

@time Threads.@threads for i in 1:N  #timr -> 145990.415614 seconds (254.49 G allocations: 12.005 TiB, 1.76% gc time, 1.03% compilation time)
    # copy template once per thread, then adjust with DOE row
    base_params = deepcopy(template_parameters)
    for (k, v) in pairs(doe[i, :])
        set_nested!(base_params, split(string(k), "|"), v)
    end

    thread_results = Dict{String,Dict{String,Any}}()    # local bucket

    # loop over sites (still inside the same thread)
    for site in sites
        params = deepcopy(base_params)                   # local copy per site
        params[:plot][:latitude] = latitude[site]
        params[:plot][:altitude] = altitude[site]

        palm = XPalm.Palm(initiation_age=0, parameters=params)

        out = PlantSimEngine.run!(palm.mtg,
            XPalm.model_mapping(palm),
            meteos[site];
            tracked_outputs=out_vars,
            executor=PlantSimEngine.SequentialEx(),
            check=false)

        # *** key fix: drop empty vectors so downstream code never crashes *****
        filter!(kv -> !isempty(kv[2]), out)

        sim = PlantSimEngine.convert_outputs(out, DataFrame; no_value=missing)

        soil_ftsw = sim["Soil"].ftsw
        max_ftsw = maximum(soil_ftsw)
        min_ftsw = minimum(soil_ftsw)

        plant_age = sim["Plant"].plant_age
        nursery_duration = 1.5 * 365
        age_3 = nursery_duration + 3 * 365
        age_6 = nursery_duration + 6 * 365
        idx_3_to_6 = findall(x -> age_3 < x ≤ age_6, plant_age)

        avg_female_3_to_6 = haskey(sim, "Female") ?
        begin
            df_fem = filter(x -> x.biomass_bunch_harvested > 0.0 &&
                    age_3 < x.plant_age ≤ age_6,
                sim["Female"])
            isempty(df_fem) ? missing : mean(df_fem.biomass_bunch_harvested)
        end :
                            missing

        # store in local bucket
        thread_results[site] = Dict(
            "doe" => i,
            "site" => site,
            "max_ftsw" => max_ftsw,
            "min_ftsw" => min_ftsw,
            "max_qty_H2O_C_Roots" => maximum(sim["Soil"].qty_H2O_C_Roots),
            "min_qty_H2O_C_Roots" => minimum(sim["Soil"].qty_H2O_C_Roots),
            "n_bunches_harvested_cum_3_to_6" =>
                sim["Plant"].n_bunches_harvested_cum[last(idx_3_to_6)] -
                sim["Plant"].n_bunches_harvested_cum[first(idx_3_to_6)],
            "average_bunch_biomass_3_to_6" => avg_female_3_to_6,
        )
    end

    # after the thread is done, copy its results into the shared dict
    for (site, res) in thread_results
        simulations_towe[site][i] = res            # each i is unique > safe
    end
end


df_simulations_towe = vcat([DataFrame(v) for v in values(simulations_towe)]...)
CSV.write("2-results/sensitivity/simulations_copy_test_towe.csv", df_simulations_towe)

#vcat all
res_sets = (
    res_smse_presco=CSV.read("2-results/sensitivity/simulations_copy_test.csv", DataFrame),
    res_towe=CSV.read("2-results/sensitivity/simulations_copy_test_towe.csv", DataFrame),
)

CSV.write("2-results/sensitivity/simulations_copy_test_all.csv", vcat(res_sets...))
