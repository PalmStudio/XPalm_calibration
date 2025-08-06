
"""
    fn_no_missings(values, fn)

This function checks if all values in the input `values` are missing. If they are, it returns `missing`. Otherwise, it applies the function `fn` to the non-missing values and returns the result.
"""
function fn_no_missings(values, fn)
    if all(ismissing.(values))
        return missing
    else
        return fn(skipmissing(values))
    end
end