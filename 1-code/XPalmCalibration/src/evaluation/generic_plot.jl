function evaluate_generic_dynamic(df, variable_name; ylabel=variable_name, xlabel="Month after planting")
    df = rename_variables_names(df, variable_name)
    df_long = stack(df, Not(:MAP, :Site), variable_name=:type, value_name=:value)
    filter!(row -> row.type != "observed" || !ismissing(row.value), df_long)
    p = data(df_long) * mapping(:MAP, :value, row=:Site, color=:type) * visual(Lines)
    fig = draw(p; axis=(; xlabel=xlabel, ylabel=ylabel), figure=(; size=(1000, 600)), legend=(; position=:bottom))

    return fig
end


function evaluate_generic_scatter(df, variable_name; ylabel="Simulation", xlabel="Observations", title=variable_name)
    df = rename_variables_names(df, variable_name)
    filter!(row -> !ismissing(row.observed), df)
    df = stack(df, Not(:MAP, :Site, :observed), variable_name=:model, value_name=:simulation)

    # Compute min and max for axis limits, skip the missing values
    obs_min = minimum(skipmissing(df.observed))
    obs_max = maximum(skipmissing(df.observed))
    sim_min = minimum(skipmissing(df.simulation))
    sim_max = maximum(skipmissing(df.simulation))

    min_axis = min(obs_min, sim_min)
    max_axis = max(obs_max, sim_max)

    n_models = length(unique(df.model))
    plot_legend = n_models > 1

    p = mapping([0], [1]) * visual(ABLines, color=:slategray, linestyle=:dash) +
        data(df) * mapping(:observed, :simulation, col=:Site, color=:model) * visual(Scatter)

    fig = draw(p;
        axis=(;
            xlabel=xlabel,
            ylabel=ylabel,
            aspect=1,
            limits=((min_axis, max_axis), (min_axis, max_axis))
        ),
        figure=(; size=(1000, 600), title=title),
        legend=(; position=:bottom, show=plot_legend)
    )

    return fig
end
