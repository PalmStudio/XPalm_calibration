using YAML, CSV, DataFrames

# Load the nested YAML file
parameters = YAML.load_file("xpalm_introduction/0-data/xpalm_parameters.yml"; dicttype=Dict{String, Any})

# Recursive function to flatten nested dictionaries
function flatten_dict(d::Dict, prefix::String = ""; sep::String = ".")
    result = Dict{String, Any}()
    for (k, v) in d
        key = isempty(prefix) ? k : "$prefix$sep$k"
        if v isa Dict
            result = merge(result, flatten_dict(v, key, sep=sep))
        else
            result[key] = v
        end
    end
    return result
end

# Flatten and convert to DataFrame
flat = flatten_dict(parameters)
df = DataFrame(key=collect(keys(flat)), value=collect(values(flat)))

# Save to CSV
CSV.write("xpalm_introduction/2-results/ parameters.csv", df, delim=";")


##version 2 by gpt
using YAML, DataFrames, CSV

# Load YAML
parameters = YAML.load_file("xpalm_introduction/0-data/xpalm_parameters.yml"; dicttype=Dict{String, Any})

# Recursive function to flatten with arrays expanded
function flatten_dict_expanded(d::Any; prefix::String = "", sep::String = ".")
    if d isa Dict
        # flatten each dict key recursively and merge all
        result = Dict{String, Vector{Any}}()
        for (k, v) in d
            key = isempty(prefix) ? k : "$prefix$sep$k"
            sub = flatten_dict_expanded(v, prefix=key, sep=sep)
            # merge while expanding arrays vertically
            for (subk, subv) in sub
                if haskey(result, subk)
                    # concatenate vectors vertically
                    result[subk] = vcat(result[subk], subv)
                else
                    result[subk] = subv
                end
            end
        end
        return result
    elseif d isa AbstractVector
        # for arrays, return each element as a vector so later concatenation works
        # assume each element is scalar or dict or array
        combined = Dict{String, Vector{Any}}()
        for (i, item) in enumerate(d)
            sub = flatten_dict_expanded(item, prefix=prefix, sep=sep)
            for (k, v) in sub
                if haskey(combined, k)
                    combined[k] = vcat(combined[k], v)
                else
                    combined[k] = v
                end
            end
        end
        return combined
    else
        # scalar leaf node, wrap in vector
        return Dict(prefix => [d])
    end
end

# Flatten expanded
flat_expanded = flatten_dict_expanded(parameters)

# Now find max length of any value vector (arrays expanded)
maxlen = maximum(length.(values(flat_expanded)))

# For shorter vectors, repeat last element to match maxlen
for (k,v) in flat_expanded
    if length(v) < maxlen
        lastval = v[end]
        flat_expanded[k] = vcat(v, fill(lastval, maxlen - length(v)))
    end
end

# Convert Dict of vectors to DataFrame
df = DataFrame(flat_expanded)

# Save to CSV
CSV.write("xpalm_introduction/2-results/parameters_expanded.csv", df, delim=";")

##trial 3

function flatten_dict_safe(d::Dict, prefix::String = ""; sep::String = ".")
    result = Dict{String, Any}()
    for (k, v) in d
        key = isempty(prefix) ? k : "$prefix$sep$k"
        if v isa Dict
            # Recursively flatten
            sub = flatten_dict_safe(v, key, sep=sep)
            # Update result carefully without overwriting existing keys silently
            for (subk, subv) in sub
                if haskey(result, subk)
                    # If key exists, warn and append with a suffix or handle as needed
                    @warn "Duplicate key detected: $subk - overwriting existing value."
                end
                result[subk] = subv
            end
        else
            # Assign scalar leaf value
            if haskey(result, key)
                @warn "Duplicate key detected: $key - overwriting existing value."
            end
            result[key] = v
        end
    end
    return result
end

flat = flatten_dict_safe(parameters)
df = DataFrame(key=collect(keys(flat)), value=collect(values(flat)))
CSV.write("xpalm_introduction/2-results/parameters.csv", df, delim=";")


#trial 4
using YAML
using DataFrames
using CSV

# Load YAML file (keys as Symbols)
parameters = YAML.load_file("xpalm_introduction/0-data/xpalm_parameters.yml"; dicttype=Dict{Symbol, Any})

# Flatten nested Dict{Symbol, Any} to Dict{String, Any} with dot-separated keys
function flatten_dict_symbol_keys(d::Dict{Symbol, Any}, prefix::String = ""; sep::String = ".")
    result = Dict{String, Any}()
    for (k, v) in d
        key_str = string(k)  # convert Symbol to String
        key = isempty(prefix) ? key_str : "$prefix$sep$key_str"
        if v isa Dict{Symbol, Any}
            sub = flatten_dict_symbol_keys(v, key, sep=sep)
            for (subk, subv) in sub
                if haskey(result, subk)
                    @warn "Duplicate key detected: $subk - overwriting existing value."
                end
                result[subk] = subv
            end
        else
            if haskey(result, key)
                @warn "Duplicate key detected: $key - overwriting existing value."
            end
            result[key] = v
        end
    end
    return result
end

# Flatten parameters dict
flat_params = flatten_dict_symbol_keys(parameters)

# Create DataFrame
df = DataFrame(key=collect(keys(flat_params)), value=collect(values(flat_params)))

println("Number of flattened parameters: ", nrow(df))

# Write to CSV with semicolon delimiter
CSV.write("xpalm_introduction/2-results/parameters.csv", df, delim=";")


#trial 5

using YAML
using DataFrames
using CSV

# Load YAML file (keys as Symbols)
parameters = YAML.load_file("xpalm_introduction/0-data/xpalm_parameters.yml"; dicttype=Dict{Symbol, Any})

# Function to update a nested value given a dot-separated key path
function update_nested_value!(dict::Dict{Symbol, Any}, key_path::String, new_value; sep::String = ".")
    keys = split(key_path, sep)
    current = dict
    for k in keys[1:end-1]
        sym_k = Symbol(k)
        if haskey(current, sym_k)
            current = current[sym_k]
            if !(current isa Dict{Symbol, Any})
                error("Intermediate key '$k' does not point to a Dict.")
            end
        else
            error("Key '$k' not found in dictionary.")
        end
    end
    last_key = Symbol(keys[end])
    if haskey(current, last_key)
        current[last_key] = new_value
    else
        error("Key '$last_key' not found in dictionary.")
    end
end

# Flatten nested Dict{Symbol, Any} to Dict{String, Any} with dot-separated keys
function flatten_dict_symbol_keys(d::Dict{Symbol, Any}, prefix::String = ""; sep::String = ".")
    result = Dict{String, Any}()
    for (k, v) in d
        key_str = string(k)  # convert Symbol to String
        key = isempty(prefix) ? key_str : "$prefix$sep$key_str"
        if v isa Dict{Symbol, Any}
            sub = flatten_dict_symbol_keys(v, key, sep=sep)
            for (subk, subv) in sub
                if haskey(result, subk)
                    @warn "Duplicate key detected: $subk - overwriting existing value."
                end
                result[subk] = subv
            end
        else
            if haskey(result, key)
                @warn "Duplicate key detected: $key - overwriting existing value."
            end
            result[key] = v
        end
    end
    return result
end

# Example: Update a nested parameter value before flattening

update_nested_value!(parameters, "carbon_demand.leaf.respiration_cost", 2.5)

# Flatten the updated dictionary
flat_params = flatten_dict_symbol_keys(parameters)

# Create DataFrame from flattened dict
df = DataFrame(key=collect(keys(flat_params)), value=collect(values(flat_params)))

println("Number of flattened parameters: ", nrow(df))

# Write to CSV file with semicolon delimiter
CSV.write("xpalm_introduction/2-results/parameters.csv", df, delim=";")

##trial 5555

using YAML
using DataFrames
using CSV

# Load YAML file with top-level Symbol keys
parameters = YAML.load_file("xpalm_introduction/0-data/xpalm_parameters.yml"; dicttype=Dict{Symbol, Any})

# Collect only the top-level entries
key_list = String[]
value_list = String[]

for (k, v) in parameters
    push!(key_list, String(k))
    if v isa Dict
        push!(value_list, "Dict")  # Indicate that this entry is a nested dictionary
    else
        push!(value_list, string(v))  # Keep scalar values
    end
end

# Create a DataFrame showing top-level structure
df_top = DataFrame(key = key_list, value_or_type = value_list)

# Save to CSV with semicolon delimiter
CSV.write("xpalm_introduction/2-results/parameters_top_level.csv", df_top, delim=";")

println("Top-level structure saved with ", nrow(df_top), " entries.")


#trial 66

using CSV
using DataFrames

# Load the flattened CSV
df = CSV.read("xpalm_introduction/2-results/parameters_top_level.csv", DataFrame; delim=';')

# Function to recursively build nested dictionary
function build_nested_dict(df::DataFrame)
    nested = Dict{Symbol, Any}()
    for row in eachrow(df)
        keys = split(row.key, ".")
        current = nested
        for (i, k) in enumerate(keys)
            sym = Symbol(k)
            if i == length(keys)
                # Convert value to Float64 if possible, otherwise keep as string
                val = tryparse(Float64, row.value_or_type)
                current[sym] = isnothing(val) ? row.value_or_type : val
            else
                if !haskey(current, sym)
                    current[sym] = Dict{Symbol, Any}()
                end
                current = current[sym]
            end
        end
    end
    return nested
end

# Build the nested parameters dictionary
parameters = build_nested_dict(df)

# Now test with XPalm
using XPalm
p1 = XPalm.Palm(initiation_age=0, parameters=parameters)

params1_towe = xpalm(
    meteo_towe,
    DataFrame,
    vars = Dict(
        "Scene" => (:lai,),
        "Plant" => (:leaf_area, :biomass_bunch_harvested,),
        "Soil" => (:ftsw,),
        "Leaf" => (:biomass,),
    ),
    palm = p1,
) 


###

using CSV
using DataFrames
using XPalm

# === 1. Load meteo_towe ===
meteo_towe = CSV.read("xpalm_introduction/0-data/meteo_towe.csv", DataFrame)

# === 2. Convert column names from String to Symbol ===
rename!(meteo_towe, Symbol.(names(meteo_towe)))

# === 3. Load and reconstruct parameters from CSV (if needed) ===
params_df = CSV.read("xpalm_introduction/2-results/parameters_top_level.csv", DataFrame)

# Reconstruct nested Dict{Symbol, Any}
function reconstruct_parameters(df::DataFrame)
    param_dict = Dict{Symbol, Any}()
    for row in eachrow(df)
        key = Symbol(row[:key])
        val = row[:value]
        if val isa AbstractString && occursin(r"^\d+\.?\d*$", val)
            val = parse(Float64, val)
        end
        param_dict[key] = val
    end
    return param_dict
end

parameters = reconstruct_parameters(params_df)

# === 4. Create XPalm palm object ===
p1 = XPalm.Palm(initiation_age=0, parameters=parameters)

# === 5. Run XPalm simulation ===
params1_towe = xpalm(
    meteo_towe,
    DataFrame,
    vars = Dict(
        "Scene" => (:lai,),
        "Plant" => (:leaf_area, :biomass_bunch_harvested,),
        "Soil" => (:ftsw,),
        "Leaf" => (:biomass,),
    ),
    palm = p1,
)