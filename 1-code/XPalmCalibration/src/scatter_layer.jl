function scatter_layer(df, variable_name, variable_labels)
    df = XPalmCalibration.rename_variables_names(df, variable_name)
    filter!(row -> !ismissing(row.observed), df)
    df = stack(df, Not(:MAP, :Site, :observed), variable_name=:model, value_name=:simulation)

    ylabel = get(variable_labels, variable_name, variable_name)
    df.variable_name = fill(ylabel, nrow(df))  # Add for faceting
    obs_min = minimum(skipmissing(df.observed))
    obs_max = maximum(skipmissing(df.observed))

    sim_min = minimum(skipmissing(df.simulation))
    sim_max = maximum(skipmissing(df.simulation))

    min_axis = min(obs_min, sim_min)
    max_axis = max(obs_max, sim_max)

    layer = mapping([0], [1]) * visual(ABLines, color=:slategray, linestyle=:dash) +
            data(df) * mapping(:observed, :simulation, col=:Site, color=:model, row=:variable_name) * visual(Scatter)

    return layer, min_axis, max_axis
end

function scatter_SITE(df, variable_name, variable_labels)
    df = XPalmCalibration.rename_variables_names(df, variable_name)
    filter!(row -> !ismissing(row.observed), df)
    df = stack(df, Not(:MAP, :Site, :observed), variable_name=:model, value_name=:simulation)

    ylabel = get(variable_labels, variable_name, variable_name)
    df.variable_name = fill(ylabel, nrow(df))

    obs_min = minimum(skipmissing(df.observed))
    obs_max = maximum(skipmissing(df.observed))
    sim_min = minimum(skipmissing(df.simulation))
    sim_max = maximum(skipmissing(df.simulation))

    min_axis = min(obs_min, sim_min)
    max_axis = max(obs_max, sim_max)

    layer = mapping([0], [1]) * visual(ABLines, color=:slategray, linestyle=:dash) +
            data(df) * mapping(:observed, :simulation, col=:model, color=:Site, row=:variable_name) * visual(Scatter)

    return layer, min_axis, max_axis
end