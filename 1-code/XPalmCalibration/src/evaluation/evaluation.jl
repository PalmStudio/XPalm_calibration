function evaluate(df_plant, df_female, df_leaf, path_outputs)
    #plant scale
    fig_phyllochron_dynamic, fig_phyllochron_scatter, statistics_phyllochron = evaluate_phyllochron(df_plant)
    fig_ffb_dynamic, fig_ffb_scatter, statistics_ffb = evaluate_FFB(df_plant)
    fig_n_bunch = evaluate_bunch_number(df_plant)
    fig_leaf_area_17 = evaluate_leaf_area(df_leaf)

    #female scale
    fig_avg_n_fruit_per_bunch = evaluate_avg_n_fruit_per_bunch(df_female)
    fig_biomass_dry_fruit_per_bunch = evaluate_biomass_dry_fruit_per_bunch(df_female)
    fig_biomass_fresh_fruit_per_bunch = evaluate_biomass_fresh_fruit_per_bunch(df_female)
    fig_bunch_dry_biomass = evaluate_bunch_dry_biomass(df_female)
    fig_bunch_dry_mass_per_bunch = evaluate_bunch_dry_mass_per_bunch(df_female)
    fig_n_fruit = evaluate_n_fruit(df_female)
    fig_bunch_fresh_mass_per_bunch = evaluate_bunch_fresh_mass_per_bunch(df_female)
    fig_stalk_dry_biomass_per_bunch = evaluate_stalk_dry_biomass_per_bunch(df_female)
    fig_stalk_fresh_biomass_per_bunch = evaluate_stalk_fresh_biomass_per_bunch(df_female)


    mkpath(path_outputs)
    save(joinpath(path_outputs, "1.leaf_emitted_since_first_observation.png"), fig_phyllochron_dynamic)
    save(joinpath(path_outputs, "1.leaf_emitted_since_first_observation_scatter.png"), fig_phyllochron_scatter)
    CSV.write(joinpath(path_outputs, "statistics_phyllochron.csv"), statistics_phyllochron)
    save(joinpath(path_outputs, "2.total_n_bunches_harvested (plant-1 MAP-1).png"), fig_n_bunch)
    save(joinpath(path_outputs, "3.Biomass_dry_fruit_per_bunch.png"), fig_biomass_dry_fruit_per_bunch)
    save(joinpath(path_outputs, "4.Leaf_area_17.png"), fig_leaf_area_17)
    save(joinpath(path_outputs, "5.1.FFB_(plant -1 MAP -1)_dynamic.png"), fig_ffb_dynamic)
    save(joinpath(path_outputs, "5.2.FFB_(plant -1 MAP -1)_scatter.png"), fig_ffb_scatter)
    CSV.write(joinpath(path_outputs, "statistics_FFB.csv"), statistics_ffb)
    save(joinpath(path_outputs, "6.avg_n_fruit_per_bunch(bunch -1 MAP -1).png"), fig_avg_n_fruit_per_bunch)
    save(joinpath(path_outputs, "7.biomass_fresh_fruit_per_bunch.png"), fig_biomass_fresh_fruit_per_bunch)
    save(joinpath(path_outputs, "8.bunch_dry_biomass.png"), fig_bunch_dry_biomass)
    save(joinpath(path_outputs, "9.bunch_dry_mass_per_bunch.png"), fig_bunch_dry_mass_per_bunch)
    save(joinpath(path_outputs, "10.total_n_fruit_harvested (plant-1 MAP -1).png"), fig_n_fruit)
    save(joinpath(path_outputs, "11.bunch_fresh_mass_per_bunch (bunch-1 MAP -1).png"), fig_bunch_fresh_mass_per_bunch)
    save(joinpath(path_outputs, "12.stalk_dry_biomass_per_bunch (bunch-1 MAP -1).png"), fig_stalk_dry_biomass_per_bunch)
    save(joinpath(path_outputs, "13.stalk_fresh_biomass_per_bunch (bunch-1 MAP -1).png"), fig_stalk_fresh_biomass_per_bunch)


    return (;
        phyllochron=(; dynamic=fig_phyllochron_dynamic, scatter=fig_phyllochron_scatter, statistics=statistics_phyllochron),
        fig_n_bunch, fig_biomass_dry_fruit_per_bunch, fig_leaf_area_17,
        ffb=(; dynamic=fig_ffb_dynamic, scatter=fig_ffb_scatter, statistics=statistics_ffb),
        fig_avg_n_fruit_per_bunch, fig_biomass_fresh_fruit_per_bunch, fig_bunch_dry_biomass, fig_bunch_dry_mass_per_bunch, fig_n_fruit, fig_bunch_fresh_mass_per_bunch, fig_stalk_dry_biomass_per_bunch, fig_stalk_fresh_biomass_per_bunch
    )
end