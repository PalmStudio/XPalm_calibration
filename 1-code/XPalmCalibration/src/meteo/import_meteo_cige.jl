"""
    import_meteo_cige(meteo_smse, meteo_pr, meteo_towe)

Import meteorological data for CIGE sites and return them as a dictionary of Weather objects.

# Arguments

- `meteo_smse`: Path to the SMSE meteorological data CSV file.
- `meteo_pr`: Path to the PR meteorological data CSV file.
- `meteo_towe`: Path to the TOWE meteorological data CSV file.

# Note

The files are computed using the scripts in `1-code/1-meteo`. Please run all those scripts before running this function.
"""
function import_meteo_cige(meteo_smse, meteo_pr, meteo_towe)
    meteos = Dict(
        "SMSE" => CSV.read(meteo_smse, DataFrame),
        "PR" => CSV.read(meteo_pr, DataFrame),
        "TOWE" => CSV.read(meteo_towe, DataFrame)
    )

    # Removing the year-month, and arranging the columns:
    for (site, meteo) in meteos
        select!(meteo, :date, :MAP, :T, :Tmin, :Tmax, :Wind, :Rh, :Rh_max, :Rh_min, :Precipitations, :Ri_PAR_f, :Rg)
    end

    # Transform the meteo dataframe in Weather object for speed:
    meteos = Dict(site => Weather(meteo) for (site, meteo) in meteos)

    return meteos
end