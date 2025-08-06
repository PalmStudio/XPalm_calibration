"""
    run_simulations_all_sites(params_default)

Run XPalm simulations for all sites with the given parameters.


params_default = YAML.load_file("1-code/5-calibration/xpalm_parameters_manual_calibration_1.yml")

out_vars = Dict{String,Any}(
    "Scene" => (:lai, :ET0, :leaf_area),
    "Plant" => (:leaf_area, :biomass_bunch_harvested, :phytomer_count, :production_speed, :n_bunches_harvested_cum, :n_bunches_harvested, :biomass_bunch_harvested_cum, :biomass_fruit_harvested),
    # "Soil" => (:ftsw, :qty_H2O_C_Roots, :transpiration),
    "Leaf" => (:leaf_area, :biomass, :rank),
    #"Phytomer" => (:TT_flowering,),
    "Female" => (:biomass_bunch_harvested, :biomass_fruit_harvested, :fruits_number_harvested, :biomass_stalk_harvested,),
    # "Male" => (:biomass,),
    # "Internode" => (:biomass,),
)
"""
function run_simulations_all_cige_sites(parameters, out_vars, meteos)
    params_SMSE = copy(parameters)
    params_SMSE["plot"]["latitude"] = 2.93416
    params_SMSE["plot"]["altitude"] = 15.5

    params_PR = copy(parameters)
    params_PR["plot"]["latitude"] = 6.137
    params_PR["plot"]["altitude"] = 15.5

    params_TOWE = copy(parameters)
    params_TOWE["plot"]["latitude"] = 7.00
    params_TOWE["plot"]["altitude"] = 15.5

    params = Dict("SMSE" => params_SMSE, "PR" => params_PR, "TOWE" => params_TOWE,)

    simulations = Dict{String,DataFrame}[]
    for (site, m) in meteos
        palm = XPalm.Palm(parameters=params[site])
        df = xpalm(m, DataFrame, vars=out_vars, palm=palm)
        for (k, v) in df
            v[!, "Site"] .= site
            # Add :date column by matching timestep
            v[!, :date] = m.date[v.timestep]

            planting_date = site == "SMSE" ? Date("2011-01-01") :
                            site == "PR" ? Date("2010-05-01") :
                            site == "TOWE" ? Date("2012-06-01") : missing
            v[!, :planting_date] .= planting_date
            v[!, :MAP] = m.MAP[v.timestep]
        end
        push!(simulations, df)
    end

    return simulations
end
