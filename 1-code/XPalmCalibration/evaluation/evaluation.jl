function evaluate(df_plant, df_female, df_leaf, path_outputs)
    #plant scale
    fig_phyllochron = evaluate_phyllochron(df_plant)
    fig_n_bunch = evaluate_bunch_number(df_plant)
    fig_leaf_area_17 = evaluate_leaf_area(df_leaf)
    fig_FFB = evaluate_FFB(df_plant)


    #female scale
    fig_biomass_dry_fruit = evaluate_biomass_dry_fruit(df_female)
    fig_avg_n_fruit_per_bunch = evaluate_avg_n_fruit_per_bunch(df_female)
    fig_biomass_fresh_fruit_per_bunch = evaluate_biomass_fresh_fruit_per_bunch(df_female)
    fig_bunch_dry_biomass = evaluate_bunch_dry_biomass(df_female)
    fig_bunch_dry_mass_per_bunch = evaluate_bunch_dry_mass_per_bunch(df_female)

    mkpath(path_outputs)
    save(joinpath(path_outputs, "1.leaf_emitted_since_first_observation.png"), fig_phyllochron)
    save(joinpath(path_outputs, "2.total_n_bunches_harvested (plant-1 MAP-1).png"), fig_n_bunch)
    save(joinpath(path_outputs, "3.Biomass_dry_fruit_per_bunch.png"), fig_biomass_dry_fruit)
    save(joinpath(path_outputs, "4.Leaf_area_17.png"), fig_leaf_area_17)
    save(joinpath(path_outputs, "5.FFB_(plant -1 MAP -1).png"), fig_FFB)
    save(joinpath(path_outputs, "6.avg_n_fruit_per_bunch(bunch -1 MAP -1).png"), fig_avg_n_fruit_per_bunch)
    save(joinpath(path_outputs, "7.biomass_fresh_fruit_per_bunch.png"), fig_biomass_fresh_fruit_per_bunch)
    save(joinpath(path_outputs, "8.bunch_dry_biomass.png"), fig_bunch_dry_biomass)
    save(joinpath(path_outputs, "9.bunch_dry_mass_per_bunch.png"), fig_bunch_dry_mass_per_bunch)

    return (; fig_phyllochron, fig_n_bunch, fig_biomass_dry_fruit, fig_leaf_area_17, fig_FFB, fig_avg_n_fruit_per_bunch, fig_biomass_fresh_fruit_per_bunch,
        fig_bunch_dry_biomass, fig_bunch_dry_mass_per_bunch)
end