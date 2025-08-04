function evaluate(df_plant, df_female, path_outputs)
    #plant scale
    fig_phyllochron = evaluate_phyllochron(df_plant)
    fig_n_bunch = evaluate_bunch_number(df_plant)
    #female scale
    fig_biomass_dry_fruit = evaluate_biomass_dry_fruit(df_female)

    mkpath(path_outputs)
    save(joinpath(path_outputs, "1.leaf_emitted.png"), fig_phyllochron)
    save(joinpath(path_outputs, "2.total_n_bunches_harvested (plant-1 MAP-1).png"), fig_n_bunch)
    save(joinpath(path_outputs, "3.Biomass_dry_fruit_per_bunch.png"), fig_biomass_dry_fruit)

    return (; fig_phyllochron, fig_n_bunch, fig_biomass_dry_fruit,)
end