
"""
    integrate_simulation_by_map(parameters, out_vars, meteos)


"""
function integrate_simulation_by_map(simulations)
    # Plant scale
    dfs_plant = vcat([s["Plant"] for s in simulations]...)
    sort!(dfs_plant, [:Site, :timestep])

    dfs_plant_MAP = combine(
        groupby(dfs_plant, [:Site, :MAP]),
        :leaf_area => last => :Leaf_area, #total leaf area per month #!done
        :biomass_bunch_harvested => sum => :biomass_bunch_harvested_MAP, #total biomass bunch harvested
        :biomass_bunch_harvested_cum => last => :biomass_bunch_harvested_cum, #dynamic cumulated bunch biomass per MAP
        :biomass_fruit_harvested => sum => :biomass_fruit_harvested_MAP, #gr (?)
        :n_bunches_harvested => sum => :total_n_bunches_harvested, #total number bunch per MAP (fluctuated)
        :n_bunches_harvested_cum => last => :n_bunches_harvested_cum,#dynamic number bunch per MAP
        :phytomer_count => last => :phytomer_count, #total number of phytomer per MAP
        :phytomer_count => (x -> x[end] - x[1]) => :diff_phytomer_emmitted, #the difference phytomer emitted between MAP
    )

    dfs_leaf = vcat([s["Leaf"] for s in simulations]...)
    sort!(dfs_leaf, [:Site, :timestep])
    filter!(x -> x.rank == 17, dfs_leaf)
    dfs_leaf_MAP = combine(groupby(dfs_leaf, [:Site, :MAP]), :leaf_area => last => :Leaf_area_17)


    dfs_female = vcat([s["Female"] for s in simulations]...)
    df_female_MAP = combine(
        groupby(dfs_female, [:Site, :MAP]),
        :biomass_bunch_harvested => (x -> mean(filter(x -> x > 0.0, x)) * 1e-3) => :bunch_dry_mass_per_bunch, #average individual bunch biomass in one MAP in kg
        :biomass_bunch_harvested => (x -> sum(filter(x -> x > 0.0, x)) * 1e-3) => :bunch_dry_biomass, #change to kg and total it (?)
        :biomass_fruit_harvested => (x -> mean(filter(x -> x > 0.0, x)) * 1e-3) => :biomass_dry_fruit_per_bunch, #change to kg and total it (?)
    )

    return (plant=dfs_plant_MAP, leaf=dfs_leaf_MAP, female=df_female_MAP)
end