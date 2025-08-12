"""
    evaluate_statistics(df, variable_name)

Evaluates the statistics of a given variable in the DataFrame `df` and returns a DataFrame with RMSE, nRMSE, Bias, nBias, and EF for each Site and model.
"""
function evaluate_statistics(df, variable_name)
    df = rename_variables_names(df, variable_name)
    filter!(row -> !ismissing(row.observed) && all(!ismissing, row[Not(:MAP, :Site, :observed)]), df)
    df = stack(df, Not(:MAP, :Site, :observed), variable_name=:model, value_name=:simulation)
    stats = combine(
        groupby(df, [:Site, :model], sort=true),
        [:observed, :simulation] => ((x, y) -> RMSE(x, y)) => :RMSE,
        [:observed, :simulation] => ((x, y) -> nRMSE(x, y)) => :nRMSE,
        [:observed, :simulation] => ((x, y) -> Bias(x, y)) => :Bias,
        [:observed, :simulation] => ((x, y) -> nBias(x, y)) => :nBias,
        [:observed, :simulation] => ((x, y) -> EF(x, y)) => :EF,
    )

    stats_all = combine(
        groupby(df, [:model], sort=true),
        :model => (x -> "All") => :Site,
        [:observed, :simulation] => ((x, y) -> RMSE(x, y)) => :RMSE,
        [:observed, :simulation] => ((x, y) -> nRMSE(x, y)) => :nRMSE,
        [:observed, :simulation] => ((x, y) -> Bias(x, y)) => :Bias,
        [:observed, :simulation] => ((x, y) -> nBias(x, y)) => :nBias,
        [:observed, :simulation] => ((x, y) -> EF(x, y)) => :EF,
    )

    return vcat(stats, stats_all)
end


"""
    RMSE(obs,sim)

Returns the Root Mean Squared Error between observations `obs` and simulations `sim`.
The closer to 0 the better.
"""
function RMSE(obs, sim, digits=2)
    return round(sqrt(sum((obs .- sim) .^ 2) / length(obs)), digits=digits)
end

"""
    nRMSE(obs,sim)

Returns the normalized Root Mean Squared Error between observations `obs` and simulations `sim`.
The closer to 0 the better.
"""
function nRMSE(obs, sim; digits=2)
    return round(
        sqrt(sum((obs .- sim) .^ 2) / length(obs)) / (findmax(obs)[1] - findmin(obs)[1]),
        digits=digits,
    )
end

"""
    EF(obs,sim)

Returns the Efficiency Factor between observations `obs` and simulations `sim` using NSE (Nash-Sutcliffe efficiency) model.
More information can be found at https://en.wikipedia.org/wiki/Nash%E2%80%93Sutcliffe_model_efficiency_coefficient.
The closer to 1 the better.
"""
function EF(obs, sim, digits=2)
    SSres = sum((obs - sim) .^ 2)
    SStot = sum((obs .- mean(obs)) .^ 2)
    return round(1 - SSres / SStot, digits=digits)
end

"""
	    Bias(obs,sim)

	Returns the bias between observations `obs` and simulations `sim`.
	The closer to 0 the better.
	"""
function Bias(obs, sim, digits=4)
    return round(mean(sim .- obs), digits=digits)
end

"""
	nBias(obs,sim; digits = 2)

Returns the normalised bias (%) between observations `obs` and simulations `sim`.
The closer to 0 the better.
"""
function nBias(obs, sim; digits=2)
    return round(mean((sim .- obs)) / (findmax(obs)[1] - findmin(obs)[1]), digits=digits)
end