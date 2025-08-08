function evaluate(df_plant, df_female, df_leaf, path_outputs)
    #plant scale
    fig_phyllochron_dynamic, fig_phyllochron_scatter, statistics_phyllochron = evaluate_phyllochron(df_plant)
    fig_ffb_dynamic, fig_ffb_scatter, statistics_ffb = evaluate_FFB(df_plant)
    fig_n_bunch_dynamic, fig_n_bunch_scatter, statistics_n_bunch = evaluate_bunch_number(df_plant)
    fig_leaf_area_17_dynamic, fig_leaf_area_17_scatter, statistics_leaf_area_17 = evaluate_leaf_area(df_leaf)

    #female scale
    fig_bunch_dry_biomass_dynamic, fig_bunch_dry_biomass_scatter, statistics_bunch_dry_biomass = evaluate_bunch_dry_biomass(df_female) #from female but we sum it so its the total from all bunches in one tree
    fig_avg_n_fruit_per_bunch_dynamic, fig_avg_n_fruit_per_bunch_scatter, statistics_avg_n_fruit_per_bunch = evaluate_avg_n_fruit_per_bunch(df_female)
    fig_fruit_dry_mass_per_bunch_dynamic, fig_fruit_dry_mass_per_bunch_scatter, statistics_fruit_dry_mass_per_bunch = evaluate_fruit_dry_mass_per_bunch(df_female)
    fig_fruit_fresh_mass_per_bunch_dynamic, fig_fruit_fresh_mass_per_bunch_scatter, statistics_fruit_fresh_mass_per_bunch = evaluate_fruit_fresh_mass_per_bunch(df_female)
    fig_bunch_dry_mass_per_bunch_dynamic, fig_bunch_dry_mass_per_bunch_scatter, statistics_bunch_dry_mass_per_bunch = evaluate_bunch_dry_mass_per_bunch(df_female)
    fig_bunch_fresh_mass_per_bunch_dynamic, fig_bunch_fresh_mass_per_bunch_scatter, statistics_bunch_fresh_mass_per_bunch = evaluate_bunch_fresh_mass_per_bunch(df_female)
    fig_stalk_dry_biomass_per_bunch_dynamic, fig_stalk_dry_biomass_per_bunch_scatter, statistics_stalk_dry_biomass_per_bunch = evaluate_stalk_dry_biomass_per_bunch(df_female)
    fig_stalk_fresh_biomass_per_bunch_dynamic, fig_stalk_fresh_biomass_per_bunch_scatter, statistics_stalk_fresh_biomass_per_bunch = evaluate_stalk_fresh_biomass_per_bunch(df_female)


    mkpath(path_outputs)
    save(joinpath(path_outputs, "1.leaf_emitted_since_first_observation.png"), fig_phyllochron_dynamic)
    save(joinpath(path_outputs, "1.leaf_emitted_since_first_observation_scatter.png"), fig_phyllochron_scatter)
    CSV.write(joinpath(path_outputs, "1.statistics_phyllochron.csv"), statistics_phyllochron)

    save(joinpath(path_outputs, "2.1.FFB_(kg plant⁻¹ MAP⁻¹)_dynamic.png"), fig_ffb_dynamic)
    save(joinpath(path_outputs, "2.2.FFB_(kg plant⁻¹ MAP⁻¹)_scatter.png"), fig_ffb_scatter)
    CSV.write(joinpath(path_outputs, "2.statistics_FFB.csv"), statistics_ffb)

    save(joinpath(path_outputs, "3.bunch_dry_biomass_(kg plant⁻¹ MAP⁻¹)_dynamic.png"), fig_bunch_dry_biomass_dynamic)
    save(joinpath(path_outputs, "3.bunch_dry_biomass_(kg plant⁻¹ MAP⁻¹)_scatter.png"), fig_bunch_dry_biomass_scatter)
    CSV.write(joinpath(path_outputs, "3.statistics_bunch_dry_biomass.csv"), statistics_bunch_dry_biomass)

    save(joinpath(path_outputs, "4.total_n_bunches_harvested (plant⁻¹ MAP⁻¹)_dynamic.png"), fig_n_bunch_dynamic)
    save(joinpath(path_outputs, "4.total_n_bunches_harvested (plant⁻¹ MAP⁻¹)_scatter.png"), fig_n_bunch_scatter)
    CSV.write(joinpath(path_outputs, "4.statistics_total_n_bunches_harvested.csv"), statistics_n_bunch)


    save(joinpath(path_outputs, "5.Leaf_area_17_dynamic (m2 plant⁻¹ MAP⁻¹).png"), fig_leaf_area_17_dynamic)
    save(joinpath(path_outputs, "5.Leaf_area_17_scatter (m2 plant⁻¹ MAP⁻¹).png"), fig_leaf_area_17_scatter)
    CSV.write(joinpath(path_outputs, "5.statistics_Leaf_area_17.csv"), statistics_leaf_area_17)

    save(joinpath(path_outputs, "6.avg_n_fruit_per_bunch(bunch⁻¹ MAP⁻¹)_dynamic.png"), fig_avg_n_fruit_per_bunch_dynamic)
    save(joinpath(path_outputs, "6.avg_n_fruit_per_bunch(bunch⁻¹ MAP⁻¹)_scatter.png"), fig_avg_n_fruit_per_bunch_scatter)
    CSV.write(joinpath(path_outputs, "6.statistics_avg_n_fruit_per_bunch.csv"), statistics_avg_n_fruit_per_bunch)

    save(joinpath(path_outputs, "7.Fruit_dry_mass_per_bunch(kg bunch⁻¹ MAP⁻¹)_dynamic.png"), fig_fruit_dry_mass_per_bunch_dynamic)
    save(joinpath(path_outputs, "7.Fruit_dry_mass_per_bunch(kg bunch⁻¹ MAP⁻¹)_scatter.png"), fig_fruit_dry_mass_per_bunch_scatter)
    CSV.write(joinpath(path_outputs, "7.statistics_fruit_dry_mass_per_bunch.csv"), statistics_fruit_dry_mass_per_bunch)


    save(joinpath(path_outputs, "8.Fruit_fresh_mass_per_bunch(kg bunch⁻¹ MAP⁻¹)_dynamic.png"), fig_fruit_fresh_mass_per_bunch_dynamic)
    save(joinpath(path_outputs, "8.Fruit_fresh_mass_per_bunch(kg bunch⁻¹ MAP⁻¹)_scatter.png"), fig_fruit_fresh_mass_per_bunch_scatter)
    CSV.write(joinpath(path_outputs, "8.Statistics_fruit_fresh_mass_per_bunch.csv"), statistics_fruit_fresh_mass_per_bunch)


    save(joinpath(path_outputs, "9.bunch_dry_mass_per_bunch(kg bunch⁻¹ MAP⁻¹)_dynamic.png"), fig_bunch_dry_mass_per_bunch_dynamic)
    save(joinpath(path_outputs, "9.bunch_dry_mass_per_bunch(kg bunch⁻¹ MAP⁻¹)_scatter.png"), fig_bunch_dry_mass_per_bunch_scatter)
    CSV.write(joinpath(path_outputs, "9.Statistics_bunch_dry_mass_per_bunch.csv"), statistics_bunch_dry_mass_per_bunch)

    save(joinpath(path_outputs, "10.bunch_fresh_mass_per_bunch (kg bunch-1 MAP -1)_dynamic.png"), fig_bunch_fresh_mass_per_bunch_dynamic)
    save(joinpath(path_outputs, "10.bunch_fresh_mass_per_bunch (kg bunch-1 MAP -1)_scatter.png"), fig_bunch_fresh_mass_per_bunch_scatter)
    CSV.write(joinpath(path_outputs, "10.Statistics_bunch_fresh_mass_per_bunch.csv"), statistics_bunch_fresh_mass_per_bunch)



    save(joinpath(path_outputs, "11.stalk_dry_biomass_per_bunch (kg bunch⁻¹ MAP⁻¹)_dynamic.png"), fig_stalk_dry_biomass_per_bunch_dynamic)
    save(joinpath(path_outputs, "11.stalk_dry_biomass_per_bunch (kg bunch⁻¹ MAP⁻¹)_scatter.png"), fig_stalk_dry_biomass_per_bunch_scatter)
    CSV.write(joinpath(path_outputs, "11.Statistics_stalk_dry_biomass_per_bunch.csv"), statistics_stalk_dry_biomass_per_bunch)



    save(joinpath(path_outputs, "12.stalk_fresh_biomass_per_bunch (kg bunch⁻¹ MAP⁻¹)_dynamic.png"), fig_stalk_fresh_biomass_per_bunch_dynamic)
    save(joinpath(path_outputs, "12.stalk_fresh_biomass_per_bunch (kg bunch⁻¹ MAP⁻¹)_scatter.png"), fig_stalk_fresh_biomass_per_bunch_scatter)
    CSV.write(joinpath(path_outputs, "12.Statistics_stalk_fresh_biomass_per_bunch.csv"), statistics_stalk_fresh_biomass_per_bunch)


    return (;
        phyllochron=(; dynamic=fig_phyllochron_dynamic, scatter=fig_phyllochron_scatter, statistics=statistics_phyllochron),
        ffb=(; dynamic=fig_ffb_dynamic, scatter=fig_ffb_scatter, statistics=statistics_ffb),
        n_bunch=(; dynamic=fig_n_bunch_dynamic, scatter=fig_n_bunch_scatter, statistics=statistics_n_bunch),
        Leaf_area_17=(; dynamic=fig_leaf_area_17_dynamic, scatter=fig_leaf_area_17_scatter, statistics=statistics_leaf_area_17),
        bunch_dry_biomass=(; dynamic=fig_bunch_dry_biomass_dynamic, scatter=fig_bunch_dry_biomass_scatter, statistics=statistics_bunch_dry_biomass),
        avg_n_fruit_per_bunch_dynamic=(; dynamic=fig_avg_n_fruit_per_bunch_dynamic, scatter=fig_avg_n_fruit_per_bunch_scatter, statistics=statistics_avg_n_fruit_per_bunch),
        fruit_dry_mass_per_bunch_dynamic=(; dynamic=fig_fruit_dry_mass_per_bunch_dynamic, scatter=fig_fruit_dry_mass_per_bunch_scatter, statistics_fruit_dry_mass_per_bunch_dynamic),
        fruit_fresh_mass_per_bunch_dynamic=(; dynamic=fig_fruit_fresh_mass_per_bunch_dynamic, scatter=fig_fruit_fresh_mass_per_bunch_scatter, statistics=statistics_fruit_fresh_mass_per_bunch),
        bunch_dry_mass_per_bunch_dynamic=(; dynamic=fig_bunch_dry_mass_per_bunch_dynamic, scatter=fig_bunch_dry_mass_per_bunch_scatter, statistics=statistics_bunch_dry_mass_per_bunch),
        bunch_fresh_mass_per_bunch_dynamic=(; dynamic=fig_bunch_fresh_mass_per_bunch_dynamic, scatter=fig_bunch_fresh_mass_per_bunch_scatter, statistics=statistics_bunch_fresh_mass_per_bunch),
        stalk_dry_biomass_per_bunch_dynamic=(; dynamic=fig_stalk_dry_biomass_per_bunch_dynamic, scatter=fig_stalk_dry_biomass_per_bunch_scatter, statistics=statistics_stalk_dry_biomass_per_bunch),
        stalk_fresh_biomass_per_bunch_dynamic=(; dynamic=fig_stalk_fresh_biomass_per_bunch_dynamic, scatter=fig_stalk_fresh_biomass_per_bunch_scatter, statistics=statistics_stalk_fresh_biomass_per_bunch)
    )
end