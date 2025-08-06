"""
    rename_variables_names(df, col_name)

Renames the simulation and observation columns in the DataFrame `df` based on the provided `col_name`.
The simulation columns are renamed by removing the prefix `col_name + "_sim_"` and the observation column is renamed to "observed".
"""
function rename_variables_names(df, col_name)
    simulation_names = grep_variable(df, col_name, type="sim")
    observation_name = grep_variable(df, col_name, type="obs")
    new_simulation_names = new_simulation_name(simulation_names, col_name)

    df = select(df, :MAP, :Site, [(simulation_names .=> new_simulation_names)..., (observation_name .=> "observed")...])

    return df
end

"""
    grep_variable(df, col_name; type="sim")

Returns the names of the simulation or observation variables in the DataFrame `df` that match the given `col_name`.
If `type` is "sim", it returns simulation variable names; if "obs", it returns observation variable names.
The `col_name` should be a string that match the variable names in the DataFrame.
"""
function grep_variable(df, col_name; type="sim")
    type = type == "sim" ? "_sim" : "_obs"
    names(df, Cols(Regex(string("^", col_name, type))))
end


"""
    new_simulation_name(simulation_names, col_name)

Returns a vector of new simulation names by removing the prefix `col_name + "_sim_"` from each name in `simulation_names`.
This is useful for renaming simulation variables in a DataFrame.
"""
function new_simulation_name(simulation_names, col_name)
    return last.(split.(simulation_names, Regex(string("^", col_name, "_sim_"))))
end