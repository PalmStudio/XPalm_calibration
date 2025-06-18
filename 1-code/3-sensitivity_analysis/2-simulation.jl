using XPalm
using PlantSimEngine
using YAML, CSV, DataFrames
using Base.Threads
using Statistics
using Dates

# Names of the sites:
sites = ["smse", "presco", "towe"]

# Import the meteo data:
meteos = Dict(i => CSV.read("2-results/meteorology/meteo_$(i)_with_nursery.csv", DataFrame) for i in sites)

# Import the template YAML file:
template_yaml = "0-data/xpalm_parameters.yml"
# Load the template YAML file:
template_parameters = YAML.load_file(template_yaml; dicttype=Dict{Symbol,Any})

# Importing the design of experiment (DOE) for the sensitivity analysis:
doe = CSV.read("2-results/sensitivity/doe.csv", DataFrame)

# Set the initial water content to the field capacity, because those values are correlated:
col_H_0 = findfirst(x -> endswith(x, "initial_water_content"), names(doe))
col_H_FC = findfirst(x -> endswith(x, "field_capacity"), names(doe))
doe[:, col_H_0] .= doe[:, col_H_FC]
#! remember to remove the `initial_water_content` from the sensitivity analysis.
#! We could also fix the `field_capacity` to a constant value, and analyse the effect of the `initial_water_content` instead.

function set_nested!(dict::D, path::Vector{<:AbstractString}, value) where D<:AbstractDict
    d = dict
    for k in path[1:end-1]
        d = d[k]
    end
    d[path[end]] = value
end

function set_nested!(dict::D, path::Vector{<:AbstractString}, value) where D<:Dict{Symbol,Any}
    d = dict
    for k in path[1:end-1]
        d = d[Symbol(k)]
    end
    d[Symbol(path[end])] = value
end


# Set the parameters for each site:
latitude = Dict("smse" => 2.93416, "presco" => 6.137, "towe" => 7.00) # Towe should be 7.65 but there's a bug in the model
altitude = Dict("smse" => 15.5, "presco" => 15.5, "towe" => 15.5)

# Define the output variables:

out_vars = Dict(
    "Scene" => (:lai, :ET0,),
    "Plant" => (:leaf_area, :biomass_bunch_harvested, :plant_age, :biomass_bunch_harvested_cum, :aPPFD, :carbon_assimilation, :n_bunches_harvested_cum, :n_bunches_harvested, :Rm, :reserve, :yield_gap_oil, :biomass_oil_harvested),
    "Soil" => (:ftsw, :qty_H2O_C_Roots, :transpiration),
    "Leaf" => (:biomass,),
    "Phytomer" => (:phytomer_count,),
    "Female" => (:biomass_bunch_harvested, :plant_age, :biomass, :fruits_number, :nb_fruits_flag),
    "Male" => (:biomass,),
    "Internode" => (:biomass,),
)

# Run simulations for each DOE row in parallel and collect results safely:
const N = nrow(doe)


simulations = Dict(site => Vector{Dict{String,Any}}(undef, N) for site in sites)

@time Threads.@threads for i in 1:N # 40s for 10 simulations on my machine, 10 threads
    # i = 1 
    row = doe[i, :]
    parameters = deepcopy(template_parameters)

    # Set the parameters to the values in the current simulation of the DOE:
    for (k, v) in pairs(row)
        parameter_path = split(string(k), "|")
        set_nested!(parameters, parameter_path, v)
    end
    # YAML.write_file("xpalm_parameters_$i.yml", parameters) # Un-comment to write the parameters to a YAML file

    for site in sites # site = sites[1]
        parameters[:plot][:latitude] = latitude[site]
        parameters[:plot][:altitude] = altitude[site]

        # sim = xpalm(meteos[site], DataFrame; vars=out_vars, palm=XPalm.Palm(initiation_age=0, parameters=parameters))
        palm = XPalm.Palm(initiation_age=0, parameters=parameters)
        out = PlantSimEngine.run!(palm.mtg, XPalm.model_mapping(palm), meteos[site], tracked_outputs=out_vars, executor=PlantSimEngine.SequentialEx(), check=false)

        # Filter out empty outputs (in case e.g. Females are never created during the simulation):
        filter!(kv -> !isempty(kv[2]), out)

        sim = PlantSimEngine.convert_outputs(out, DataFrame, no_value=missing) #only until here to test

        plant_age = sim["Plant"].plant_age
        nursery_duration = Int(1.5 * 366) # 366 because it rounds up to 549
        age_3 = nursery_duration + 3 * 365
        age_6 = nursery_duration + 6 * 365
        age_9 = nursery_duration + 9 * 365
        age_12 = nursery_duration + 12 * 365
        index_age_3_to_6 = findall(x -> age_3 < x <= age_6, plant_age)
        index_age_6_to_9 = findall(x -> age_6 < x <= age_9, plant_age)
        index_age_9_to_12 = findall(x -> age_9 < x <= age_12, plant_age)

        # Computing years based on 365 consecutive days. Year 1 starts after nursery
        days_after_nursery_indices = 1:(nrow(sim["Plant"])-nursery_duration)
        # Calculate year numbers for the period after nursery
        # Year 1 starts on day 1 after nursery, Year 2 on day 366 after nursery, etc.
        years_post_nursery = floor.(Int, (days_after_nursery_indices .- 1) ./ 365) .+ 1
        sim["Plant"].year = vcat(fill(0, nursery_duration), years_post_nursery)

        if haskey(sim, "Female")
            df_female = sim["Female"]
            df_female_3_to_6 = filter(x -> age_3 < x.plant_age <= age_6, df_female, view=true)
            df_female_6_to_9 = filter(x -> age_6 < x.plant_age <= age_9, df_female, view=true)
            df_female_9_to_12 = filter(x -> age_9 < x.plant_age <= age_12, df_female, view=true)

            df_female_bunch_harvested_3_to_6 = filter(x -> x.biomass_bunch_harvested > 0.0, df_female_3_to_6, view=true)
            average_female_bunch_harvested_3_to_6 = mean(df_female_bunch_harvested_3_to_6.biomass_bunch_harvested)
            std_rel_female_bunch_harvested_3_to_6 = std(df_female_bunch_harvested_3_to_6.biomass_bunch_harvested) / average_female_bunch_harvested_3_to_6
            df_female_bunch_harvested_6_to_9 = filter(x -> x.biomass_bunch_harvested > 0.0, df_female_6_to_9, view=true)
            average_female_bunch_harvested_6_to_9 = mean(df_female_bunch_harvested_6_to_9.biomass_bunch_harvested)
            std_rel_female_bunch_harvested_6_to_9 = std(df_female_bunch_harvested_6_to_9.biomass_bunch_harvested) / average_female_bunch_harvested_6_to_9
            df_female_bunch_harvested_9_to_12 = filter(x -> x.biomass_bunch_harvested > 0.0, df_female_9_to_12, view=true)
            average_female_bunch_harvested_9_to_12 = mean(df_female_bunch_harvested_9_to_12.biomass_bunch_harvested)
            std_rel_female_bunch_harvested_9_to_12 = std(df_female_bunch_harvested_9_to_12.biomass_bunch_harvested)

            df_female_subset = subset(df_female, :nb_fruits_flag, view=true) # We only pass :nb_fruits_flag because we want to filter for when it is true
            if nrow(df_female_subset) > 0
                df_female_subset = combine(
                    groupby(df_female_subset, :node),
                    :fruits_number => maximum => :fruits_number,
                    :biomass => maximum => :biomass_maximum
                )
                potential_number_fruits = maximum(df_female_subset.fruits_number)
                potential_fruits_biomass = maximum(df_female_subset.biomass_maximum)
            else
                potential_number_fruits = missing
                potential_fruits_biomass = missing
            end

            df_female_3_to_6_subset = subset(df_female_3_to_6, :nb_fruits_flag, view=true)
            if nrow(df_female_3_to_6_subset) > 0
                average_number_fruits_3_to_6 = mean(
                    combine(
                        groupby(df_female_3_to_6_subset, :node),
                        :fruits_number => maximum => :fruits_number).fruits_number
                )
            else
                average_number_fruits_3_to_6 = missing
            end

            df_female_6_to_9_subset = subset(df_female_6_to_9, :nb_fruits_flag, view=true)
            if nrow(df_female_6_to_9_subset) > 0
                average_number_fruits_6_to_9 = mean(
                    combine(
                        groupby(df_female_6_to_9_subset, :node),
                        :fruits_number => maximum => :fruits_number).fruits_number
                )
            else
                average_number_fruits_6_to_9 = missing
            end

            df_female_9_to_12_subset = subset(df_female_9_to_12, :nb_fruits_flag, view=true)
            if nrow(df_female_9_to_12_subset) > 0
                average_number_fruits_9_to_12 = mean(
                    combine(
                        groupby(df_female_9_to_12_subset, :node),
                        :fruits_number => maximum => :fruits_number).fruits_number
                )
            else
                average_number_fruits_9_to_12 = missing
            end

            # Computing the annual yield of each year in the age range 3 to 6 in t ha-1 year-1:
            df_yield_age_3_to_6 = combine(
                groupby(subset(sim["Plant"], :year => ByRow(y -> 3 <= y < 6), view=true), :year),
                :biomass_bunch_harvested => (x -> sum(x) * 1e-6 / (parameters[:plot][:scene_area] / 10000.0)) => :biomass_bunch_harvested
            )
            yield_3_to_6_average = mean(df_yield_age_3_to_6[!, :biomass_bunch_harvested])
            yield_3_to_6_std_relative = std(df_yield_age_3_to_6[!, :biomass_bunch_harvested]) / yield_3_to_6_average

            df_yield_age_6_to_9 = combine(
                groupby(subset(sim["Plant"], :year => ByRow(y -> 6 <= y < 9), view=true), :year),
                :biomass_bunch_harvested => (x -> sum(x) * 1e-6 / (parameters[:plot][:scene_area] / 10000.0)) => :biomass_bunch_harvested
            )
            yield_6_to_9_average = mean(df_yield_age_6_to_9[!, :biomass_bunch_harvested])
            yield_6_to_9_std_relative = std(df_yield_age_6_to_9[!, :biomass_bunch_harvested]) / yield_6_to_9_average
            df_yield_age_9_to_12 = combine(
                groupby(subset(sim["Plant"], :year => ByRow(y -> 9 <= y < 12), view=true), :year),
                :biomass_bunch_harvested => (x -> sum(x) * 1e-6 / (parameters[:plot][:scene_area] / 10000.0)) => :biomass_bunch_harvested
            )
            yield_9_to_12_average = mean(df_yield_age_9_to_12[!, :biomass_bunch_harvested])
            yield_9_to_12_std_relative = std(df_yield_age_9_to_12[!, :biomass_bunch_harvested]) / yield_9_to_12_average
        else
            average_female_bunch_harvested_3_to_6 = missing
            average_female_bunch_harvested_6_to_9 = missing
            average_female_bunch_harvested_9_to_12 = missing
            yield_3_to_6_average = missing
            yield_3_to_6_std_relative = missing
            yield_6_to_9_average = missing
            yield_6_to_9_std_relative = missing
            yield_9_to_12_average = missing
            yield_9_to_12_std_relative = missing
            average_number_fruits_3_to_6 = missing
            average_number_fruits_6_to_9 = missing
            average_number_fruits_9_to_12 = missing
            potential_number_fruits = missing
            potential_fruits_biomass = missing
        end

        if haskey(sim, "Male")
            df_males = combine(groupby(sim["Male"], :node), :biomass => maximum => :max_biomass)
            total_biomass_males = sum(df_males.max_biomass)
            n_males = nrow(df_males)
        else
            total_biomass_males = missing
            n_males = missing
        end

        simulations[site][i] = Dict(
            "doe" => i, "site" => site,
            "cumulated_yield" => sim["Plant"].biomass_bunch_harvested_cum[end] * 1e-6 / (parameters[:plot][:scene_area] / 10000.0), # Cumulated yield in t ha-1 over the whole simulation
            "average_yield" => sim["Plant"].biomass_bunch_harvested_cum[end] * 1e-6 / (parameters[:plot][:scene_area] / 10000.0) / (nrow(sim["Plant"]) / 365), # Cumulated yield in t ha-1 year-1
            "average_yield_3_to_6" => yield_3_to_6_average, # Average yield in t ha-1 year-1 in the age range
            "average_yield_6_to_9" => yield_6_to_9_average,
            "average_yield_9_to_12" => yield_9_to_12_average,
            "yield_variability_3_to_6" => yield_3_to_6_std_relative, # Relative standard deviation of the yield in the age range
            "yield_variability_6_to_9" => yield_6_to_9_std_relative,
            "yield_variability_9_to_12" => yield_9_to_12_std_relative,
            "max_ftsw" => maximum(sim["Soil"].ftsw), # Maximum ftsw (fraction of transpirable soil water) during the simulation
            "min_ftsw" => minimum(sim["Soil"].ftsw),
            "max_qty_H2O_C_Roots" => maximum(sim["Soil"].qty_H2O_C_Roots), # Maximum water content available for the roots
            "min_qty_H2O_C_Roots" => minimum(sim["Soil"].qty_H2O_C_Roots), # Minimum....
            "transpiration_3_to_6" => sum(sim["Soil"].transpiration[(index_age_3_to_6)]), # cumulated transpiration in the age range
            "transpiration_6_to_9" => sum(sim["Soil"].transpiration[(index_age_6_to_9)]),
            "transpiration_9_to_12" => sum(sim["Soil"].transpiration[(index_age_9_to_12)]),
            "n_bunches_harvested_cum_3_to_6" => sim["Plant"].n_bunches_harvested_cum[last(index_age_3_to_6)] - sim["Plant"].n_bunches_harvested_cum[first(index_age_3_to_6)], # Cumulated harvested bunches in the age range
            "n_bunches_harvested_cum_6_to_9" => sim["Plant"].n_bunches_harvested_cum[last(index_age_6_to_9)] - sim["Plant"].n_bunches_harvested_cum[first(index_age_6_to_9)],
            "n_bunches_harvested_cum_9_to_12" => sim["Plant"].n_bunches_harvested_cum[last(index_age_9_to_12)] - sim["Plant"].n_bunches_harvested_cum[first(index_age_9_to_12)],
            "n_males" => n_males,
            "average_n_bunches_harvested_3_to_6" => mean(sim["Plant"].n_bunches_harvested[index_age_3_to_6]), # Number of bunches harvested per plant and per day in average
            "average_n_bunches_harvested_6_to_9" => mean(sim["Plant"].n_bunches_harvested[index_age_6_to_9]),
            "average_n_bunches_harvested_9_to_12" => mean(sim["Plant"].n_bunches_harvested[index_age_9_to_12]),
            "average_bunch_weight_3_to_6" => average_female_bunch_harvested_3_to_6, # Average weight of the harvested bunches in the age range
            "average_bunch_weight_6_to_9" => average_female_bunch_harvested_6_to_9,
            "average_bunch_weight_9_to_12" => average_female_bunch_harvested_9_to_12,
            "aPPFD_3_to_6" => sum(sim["Plant"].aPPFD[(index_age_3_to_6)]),
            "aPPFD_6_to_9" => sum(sim["Plant"].aPPFD[(index_age_6_to_9)]),
            "aPPFD_9_to_12" => sum(sim["Plant"].aPPFD[(index_age_9_to_12)]),
            "Rm_3_to_6" => sum(sim["Plant"].Rm[(index_age_3_to_6)]),
            "Rm_6_to_9" => sum(sim["Plant"].Rm[(index_age_6_to_9)]),
            "Rm_9_to_12" => sum(sim["Plant"].Rm[(index_age_9_to_12)]),
            "carbon_assimilation_3_to_6" => sum(sim["Plant"].carbon_assimilation[(index_age_3_to_6)]),
            "carbon_assimilation_6_to_9" => sum(sim["Plant"].carbon_assimilation[(index_age_6_to_9)]),
            "carbon_assimilation_9_to_12" => sum(sim["Plant"].carbon_assimilation[(index_age_9_to_12)]),
            "max_leaf_area_3_to_6" => maximum(sim["Plant"].leaf_area[index_age_3_to_6]),
            "max_leaf_area_6_to_9" => maximum(sim["Plant"].leaf_area[index_age_6_to_9]),
            "max_leaf_area_9_to_12" => maximum(sim["Plant"].leaf_area[index_age_9_to_12]),
            "min_leaf_area_3_to_6" => minimum(sim["Plant"].leaf_area[index_age_3_to_6]),
            "min_leaf_area_6_to_9" => minimum(sim["Plant"].leaf_area[index_age_6_to_9]),
            "min_leaf_area_9_to_12" => minimum(sim["Plant"].leaf_area[index_age_9_to_12]),
            "average_leaf_area_3_to_6" => mean(sim["Plant"].leaf_area[index_age_3_to_6]),
            "average_leaf_area_6_to_9" => mean(sim["Plant"].leaf_area[index_age_6_to_9]),
            "average_leaf_area_9_to_12" => mean(sim["Plant"].leaf_area[index_age_9_to_12]),
            "n_phytomer_3_to_6" => sim["Phytomer"].phytomer_count[last(index_age_3_to_6)] - sim["Phytomer"].phytomer_count[first(index_age_3_to_6)],
            "n_phytomer_6_to_9" => sim["Phytomer"].phytomer_count[last(index_age_6_to_9)] - sim["Phytomer"].phytomer_count[first(index_age_6_to_9)],
            "n_phytomer_9_to_12" => sim["Phytomer"].phytomer_count[last(index_age_9_to_12)] - sim["Phytomer"].phytomer_count[first(index_age_9_to_12)],
            "biomass_leaf" => sum(combine(groupby(sim["Leaf"], :node), :biomass => maximum).biomass_maximum),
            "biomass_male" => total_biomass_males,
            "biomass_internode" => sum(combine(groupby(sim["Internode"], :node), :biomass => maximum).biomass_maximum),
            "reserve" => mean(sim["Plant"].reserve),
            "average_n_fruits_3_to_6" => average_number_fruits_3_to_6,
            "average_n_fruits_6_to_9" => average_number_fruits_6_to_9,
            "average_n_fruits_9_to_12" => average_number_fruits_9_to_12,
            "potential_n_fruits" => potential_number_fruits,
            "potential_fruits_biomass" => potential_fruits_biomass,
            "harvested_oil_cum_3_to_6" => sum(sim["Plant"].biomass_oil_harvested[(index_age_3_to_6)]) * 1e-6 / (parameters[:plot][:scene_area] / 10000.0), # Cumulated harvested oil in the age range in t ha-1
            "harvested_oil_cum_6_to_9" => sum(sim["Plant"].biomass_oil_harvested[(index_age_6_to_9)]) * 1e-6 / (parameters[:plot][:scene_area] / 10000.0),
            "harvested_oil_cum_9_to_12" => sum(sim["Plant"].biomass_oil_harvested[(index_age_9_to_12)]) * 1e-6 / (parameters[:plot][:scene_area] / 10000.0),
            "yield_gap_oil_3_to_6" => mean(sim["Plant"].yield_gap_oil[index_age_3_to_6]),
            "yield_gap_oil_6_to_9" => mean(sim["Plant"].yield_gap_oil[index_age_6_to_9]),
            "yield_gap_oil_9_to_12" => mean(sim["Plant"].yield_gap_oil[index_age_9_to_12]),
            # Compute the variables we need to investigate for the sensitivity analysis
        )
    end
end

df_simulations = vcat([DataFrame(i) for i in values(simulations)]...)
#df_simulations = vcat([DataFrame(i) for i in values(simulations)]...)
# df_simulations = vcat([DataFrame([i[j] for j in 1:length(i) if isassigned(i, j)]) for i in values(simulations)]...)

CSV.write("2-results/sensitivity/simulations_on_doe.csv", df_simulations)

# ~10s per row of doe, with 3 sites per row coming to 15000 days simulated in total, gives 
# 705.73 μs per day, or 0.257 s per year.

# meteo_all = vcat(meteos["smse"], meteos["presco"], meteos["towe"])
# dfs_all = leftjoin(simulations, meteo_all, on=[:Site, :date,])
# sort!(dfs_all, [:Site, :timestep])
