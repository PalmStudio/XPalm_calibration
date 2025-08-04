function evaluate(df_plant, df_female, df_leaf, path_outputs)
    #plant scale
    fig_phyllochron = evaluate_phyllochron(df_plant)
    fig_n_bunch = evaluate_bunch_number(df_plant)
    fig_leaf_area_17 = evaluate_leaf_area(df_leaf)
    fig_FFB = evaluate_FFB(df_plant)


    #female scale
    fig_biomass_dry_fruit = evaluate_biomass_dry_fruit(df_female)

    mkpath(path_outputs)
    save(joinpath(path_outputs, "1.leaf_emitted_since_first_observation.png"), fig_phyllochron)
    save(joinpath(path_outputs, "2.total_n_bunches_harvested (plant-1 MAP-1).png"), fig_n_bunch)
    save(joinpath(path_outputs, "3.Biomass_dry_fruit_per_bunch.png"), fig_biomass_dry_fruit)
    save(joinpath(path_outputs, "4.Leaf_area_17.png"), fig_leaf_area_17)
    save(joinpath(path_outputs, "5.FFB_(plant -1 MAP -1).png"), fig_FFB)


    return (; fig_phyllochron, fig_n_bunch, fig_biomass_dry_fruit, fig_leaf_area_17, fig_FFB, fig_FFB_cum)
end