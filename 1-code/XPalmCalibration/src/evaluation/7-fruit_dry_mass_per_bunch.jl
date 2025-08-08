function evaluate_fruit_dry_mass_per_bunch(df_female)
    fig_dynamic = evaluate_generic_dynamic(df_female, "fruit_dry_mass_per_bunch"; ylabel="Biomass_dry_fruit (kg bunch⁻¹ MAP⁻¹)", xlabel="Month after planting")
    fig_scatter = evaluate_generic_scatter(df_female, "fruit_dry_mass_per_bunch"; ylabel="Simulation", xlabel="Observations", title="Biomass dry fruit (kg bunch⁻¹ MAP⁻¹)")
    stats = evaluate_statistics(df_female, "fruit_dry_mass_per_bunch")
    return (; dynamic=fig_dynamic, scatter=fig_scatter, statistics=stats)
end