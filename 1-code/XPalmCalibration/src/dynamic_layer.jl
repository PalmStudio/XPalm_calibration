
function dynamic_layer(df, variable_name, variable_labels; xlabel="Month after planting")
    ylabel = get(variable_labels, variable_name, variable_name)
    df = XPalmCalibration.rename_variables_names(df, variable_name)
    df_long = stack(df, Not(:MAP, :Site), variable_name=:type, value_name=:value)
    filter!(row -> row.type != "observed" || !ismissing(row.value), df_long)
    p = data(df_long) * mapping(:MAP, :value, row=:Site, color=:type) * visual(Lines)
    return p, xlabel, ylabel
end