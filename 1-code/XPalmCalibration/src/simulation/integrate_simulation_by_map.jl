
"""
    integrate_simulation_by_map(
        simulations;
        CC_Fruit=0.4857,     # Fruit carbon content (gC g-1 dry mass)
        water_content_mesocarp=0.25,  # Water content of the mesocarp
        water_content_stalk=0.667, #water content of the stalk (peduncle + spikelets)
        bunch_dry_to_fresh_ratio=1 / (1 - water_content_mesocarp),  # Based on the mesocarp water content of 0.3
        stalk_dry_to_fresh_ratio=1 / (1 - water_content_stalk),
    )

Integrates simulation results by MAP (Months After Planting) for comparing with the data.
"""
function integrate_simulation_by_map(
    simulations;
    CC_Fruit=0.4857,     # Fruit carbon content (gC g-1 dry mass)
    water_content_mesocarp=0.25,  # Water content of the mesocarp
    water_content_stalk=0.667, #water content of the stalk (peduncle + spikelets)
    water_content_fruit=0.2358, #water content of the fruit (from the (dry fruit + fresh fruit) / fresh fruit)
    bunch_dry_to_fresh_ratio=1 / (1 - water_content_mesocarp),  # Based on the mesocarp water content of 0.3
    stalk_dry_to_fresh_ratio=1 / (1 - water_content_stalk),
    fruit_dry_to_fresh_ratio=1 / (1 - water_content_fruit)
)
    # Plant scale
    dfs_plant = vcat([s["Plant"] for s in simulations]...)
    sort!(dfs_plant, [:Site, :timestep])

    dfs_plant_MAP = combine(
        groupby(dfs_plant, [:Site, :MAP]),
        :leaf_area => last => :Leaf_area_17, #total leaf area per month #!done
        :biomass_bunch_harvested => sum => :biomass_bunch_harvested_MAP, #total biomass bunch harvested
        :biomass_bunch_harvested_cum => last => :biomass_bunch_harvested_cum, #dynamic cumulated bunch biomass per MAP
        :biomass_fruit_harvested => sum => :biomass_fruit_harvested_MAP, #gr (?)
        :n_bunches_harvested => sum => :total_n_bunches_harvested, #!2 total number bunch per MAP (fluctuated)
        :n_bunches_harvested_cum => last => :n_bunches_harvested_cum,#dynamic number bunch per MAP
        :phytomer_count => last => :phytomer_count, #total number of phytomer per MAP
        :phytomer_count => (x -> x[end] - x[1]) => :diff_phytomer_emmitted, #the difference phytomer emitted between MAP
    )
    #!compute FFB (bunch_fresh_biomass from biomass_bunch_harvested)
    dfs_plant_MAP[!, :bunch_fresh_biomass] = (dfs_plant_MAP.biomass_bunch_harvested_MAP .* 1e-3 ./ CC_Fruit) .* bunch_dry_to_fresh_ratio #!FFB

    #!compute the cumulated FFB (MAP 50 - 100) from bunch fresh biomass start from 0 in the MAP 50
    FFB_50_to_100 = filter(row -> (50 <= row.MAP <= 100) && !ismissing(row.bunch_fresh_biomass), dfs_plant_MAP)[:, [:MAP, :Site, :bunch_fresh_biomass]]
    transform!(groupby(FFB_50_to_100, :Site), :bunch_fresh_biomass => cumsum => :cumulated_FFB)
    select!(FFB_50_to_100, Not(:bunch_fresh_biomass))
    leftjoin!(dfs_plant_MAP, FFB_50_to_100, on=[:Site, :MAP])


    # Compute cumulated_n_leaf_emitted based on the first observation MAP of CIGE each site
    dfs_plant_MAP[!, :cumulated_n_leaf_emitted] = Vector{Union{Missing,Int64}}(missing, nrow(dfs_plant_MAP))
    thresholds = start_MAP()

    for subdf in groupby(dfs_plant_MAP, :Site)
        site = unique(subdf.Site)[1]
        threshold = thresholds[site]

        sort!(subdf, :MAP)
        start_count = findfirst(x -> x >= threshold, subdf.MAP)

        if isnothing(start_count)
            continue  # skip if no MAP ≥ threshold
        end

        base_value = subdf.phytomer_count[start_count]
        cumulated = vcat(
            fill(missing, start_count - 1),
            subdf.phytomer_count[start_count:end] .- base_value
        )

        dfs_plant_MAP[dfs_plant_MAP.Site.==site, :cumulated_n_leaf_emitted] .= cumulated
    end

    #leaf scale

    dfs_leaf = vcat([s["Leaf"] for s in simulations]...)
    sort!(dfs_leaf, [:Site, :timestep])
    filter!(x -> x.rank == 17, dfs_leaf)
    dfs_leaf_MAP = combine(groupby(dfs_leaf, [:Site, :MAP]), :leaf_area => last => :Leaf_area_17)
    filter!(row -> !ismissing(row.Leaf_area_17), dfs_leaf_MAP)


    dfs_female = vcat([s["Female"] for s in simulations]...)
    dfs_female_MAP = combine(
        groupby(dfs_female, [:Site, :MAP]),
        :biomass_bunch_harvested => (x -> isempty(filter(y -> y > 0.0, skipmissing(x))) ? missing : mean(filter(y -> y > 0.0, skipmissing(x))) * 1e-3) => :bunch_dry_mass_per_bunch,
        :biomass_bunch_harvested => (x -> isempty(filter(y -> y > 0.0, skipmissing(x))) ? missing : sum(filter(y -> y > 0.0, skipmissing(x))) * 1e-3) => :bunch_dry_biomass,
        :biomass_fruit_harvested => (x -> isempty(filter(y -> y > 0.0, skipmissing(x))) ? missing : mean(filter(y -> y > 0.0, skipmissing(x))) * 1e-3) => :fruit_dry_mass_per_bunch,
        :fruits_number_harvested => (x -> isempty(filter(y -> y > 0.0, skipmissing(x))) ? missing : mean(filter(y -> y > 0.0, skipmissing(x)))) => :avg_n_fruit_per_bunch,
        :biomass_stalk_harvested => (x -> isempty(filter(y -> y > 0.0, skipmissing(x))) ? missing : mean(filter(y -> y > 0.0, skipmissing(x))) * 1e-3) => :stalk_dry_biomass_per_bunch,
    )

    #!compute FFB (bunch_fresh_biomass from biomass_bunch_harvested)
    dfs_female_MAP[!, :bunch_fresh_mass_per_bunch] = (dfs_female_MAP.bunch_dry_mass_per_bunch ./ CC_Fruit) .* bunch_dry_to_fresh_ratio #!FFB
    dfs_female_MAP[!, :stalk_fresh_biomass_per_bunch] = (dfs_female_MAP.stalk_dry_biomass_per_bunch ./ CC_Fruit) .* stalk_dry_to_fresh_ratio #!this wrong, should check the water content on stalk
    dfs_female_MAP[!, :fruit_fresh_mass_per_bunch] = (dfs_female_MAP.fruit_dry_mass_per_bunch ./ CC_Fruit) .* fruit_dry_to_fresh_ratio #!make fruit_dry_to_fresh_ratio
    return Dict("plant" => dfs_plant_MAP, "leaf" => dfs_leaf_MAP, "female" => dfs_female_MAP)
end