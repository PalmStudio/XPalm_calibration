"""
    run_simulation_all_cige_by_map(df_CIGE_species, parameters, meteos, out_vars; suffix="simulation")
    run_simulation_all_cige_by_map(df_CIGE_species, parameters<:AbstractVector, meteos, out_vars; suffix=nothing)
    run_simulation_all_cige_by_map(reference_simulation, df_CIGE_species, parameters::<:AbstractVector, meteos, out_vars; suffix=nothing)

Run XPalm simulations for all CIGE sites, integrate the results by MAP, and join with the observations.

If `parameters` is a vector, it will run simulations for each set of parameters and name the outputs using the corresponding suffix.
"""
function run_simulation_all_cige_by_map(df_CIGE_species, parameters, meteos, out_vars; suffix="simulation")
    simulations = run_simulations_all_cige_sites(parameters, out_vars, meteos)
    simulation_map = integrate_simulation_by_map(simulations)

    simulation_map["plant"] = innerjoin(simulation_map["plant"], df_CIGE_species, on=[:Site, :MAP], makeunique=true, renamecols="_sim_" * suffix => "_obs")
    simulation_map["female"] = innerjoin(simulation_map["female"], df_CIGE_species, on=[:Site, :MAP], makeunique=true, renamecols="_sim_" * suffix => "_obs")
    simulation_map["leaf"] = innerjoin(simulation_map["leaf"], df_CIGE_species, on=[:Site, :MAP], makeunique=true, renamecols="_sim_" * suffix => "_obs")

    return simulation_map
end

function run_simulation_all_cige_by_map(df_CIGE_species, parameters::T, meteos, out_vars; suffix=nothing) where T<:AbstractVector

    if isnothing(suffix)
        suffix = [string("_sim_", i) for i in 1:length(parameters)]
    end

    simulations = []
    for (i, s) in zip(parameters, suffix)
        @info "Running simulations for parameters: $s"
        simulation = run_simulations_all_cige_sites(i, out_vars, meteos)
        simulation_map = integrate_simulation_by_map(simulation)
        # Rename all variables in the simulation to add a suffix with the name:
        for i in keys(simulation_map)
            DataFrames.rename!(x -> string(x, s), simulation_map[i], cols=Not([:Site, :MAP]))
        end
        push!(simulations, simulation_map)
    end

    simulations = Dict(k => hcat([s[k] for s in simulations]..., makeunique=true) for k in keys(simulations[1]))

    simulations["plant"] = innerjoin(simulations["plant"], df_CIGE_species, on=[:Site, :MAP], makeunique=true, renamecols="" => "_obs")
    simulations["female"] = innerjoin(simulations["female"], df_CIGE_species, on=[:Site, :MAP], makeunique=true, renamecols="" => "_obs")
    simulations["leaf"] = innerjoin(simulations["leaf"], df_CIGE_species, on=[:Site, :MAP], makeunique=true, renamecols="" => "_obs")

    return simulations
end



function run_simulation_all_cige_by_map(reference_simulation, df_CIGE_species, parameters::T, meteos, out_vars; suffix=nothing) where T<:AbstractVector

    if isnothing(suffix)
        suffix = [string("_sim_", i) for i in 1:length(parameters)]
    else
        suffix = [string("_sim_", s) for s in suffix]
    end

    ref_sim = Dict(k => DataFrames.rename(x -> string(x, "_sim_reference_simulation"), v, cols=Not([:Site, :MAP])) for (k, v) in reference_simulation)

    simulations = []
    for (i, s) in zip(parameters, suffix)
        @info "Running simulations for parameters: $s"
        simulation = run_simulations_all_cige_sites(i, out_vars, meteos)
        simulation_map = integrate_simulation_by_map(simulation)
        # Rename all variables in the simulation to add a suffix with the name:
        for i in keys(simulation_map)
            DataFrames.rename!(x -> string(x, s), simulation_map[i], cols=Not([:Site, :MAP]))
        end
        push!(simulations, simulation_map)
    end

    simulations = Dict(k => hcat([s[k] for s in simulations]..., makeunique=true) for k in keys(ref_sim))
    simulations = Dict(k => hcat(v, simulations[k], makeunique=true) for (k, v) in ref_sim)

    simulations["plant"] = innerjoin(simulations["plant"], df_CIGE_species, on=[:Site, :MAP], makeunique=true, renamecols="" => "_obs")
    simulations["female"] = innerjoin(simulations["female"], df_CIGE_species, on=[:Site, :MAP], makeunique=true, renamecols="" => "_obs")
    simulations["leaf"] = innerjoin(simulations["leaf"], df_CIGE_species, on=[:Site, :MAP], makeunique=true, renamecols="" => "_obs")

    return simulations
end