function evaluate_generic(df, variable_name; ylabel=variable_name, xlabel="Month after planting")
    df = copy(df)
    rename_variables_names!(df, variable_name)
    df_long = stack(df, Not(:MAP, :Site), variable_name=:type, value_name=:value)
    p = data(df_long) * mapping(:MAP, :value, row=:Site, color=:type) * visual(Lines)
    fig = draw(p; axis=(; xlabel=xlabel, ylabel=ylabel), figure=(; size=(1000, 600)), legend=(; position=:bottom))

    return fig
end