using YAML, CSV, DataFrames

# Load the nested YAML file
parameters = YAML.load_file("0-data/xpalm_parameters.yml"; dicttype=Dict{String,Any})

function get_xpalm_parameters(key, value, parameter_list=Dict{String,Any}())
    if key != ""
        key = string(key, "|")
    end

    for (k, v) in value
        if v isa Dict
            # If the value is a dictionary, call the function recursively
            get_xpalm_parameters(string(key, k), v, parameter_list)
        else
            push!(parameter_list, string(key, k) => v)
        end
    end

    return parameter_list
end

get_xpalm_parameters(parameters) = get_xpalm_parameters("", parameters, Dict{String,Any}())

flattened_parameters = get_xpalm_parameters(parameters)

df = DataFrame(variable=collect(keys(flattened_parameters)), value=collect(values(flattened_parameters)))
df.unit .= missing
df.definition .= missing
df.sensitivity .= missing
df.low_boundary .= df.value .* 0.5
df.high_boundary .= df.value .* 1.5
df.source .= missing
df.comment .= missing
output_file = "2-results/xpalm_parameters_raw.csv"
# !isfile(output_file) && CSV.write(output_file, df, delim=";")

# Note: `xpalm_parameters_raw.csv` is a first draft of the parameters without knowledge about the units,
# definitions, usage for sensitivity, sources, and with a first guess for the boundaries set to +/- 50% of the value.
# It serves as a starting point for further manual refinement and validation in the `xpalm_parameters.csv` file