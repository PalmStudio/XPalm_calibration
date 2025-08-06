"""
    rename_variables_names!(df, col_name)

Renames the simulation and observation columns in the DataFrame `df` based on the provided `col_name`.
The simulation columns are renamed by removing the prefix `col_name + "_sim_"` and the observation column is renamed to "observed".
"""
function rename_variables_names!(df, col_name)
    simulation_names = names(df, Cols(Regex(string("^", col_name, "_sim"))))
    observation_name = names(df, Cols(Regex(string("^", col_name, "_obs"))))
    new_simulation_names = last.(split.(simulation_names, Regex(string("^", col_name, "_sim_"))))
    select!(df, :MAP, :Site, [(simulation_names .=> new_simulation_names)..., (observation_name .=> "observed")...])

    return df
end