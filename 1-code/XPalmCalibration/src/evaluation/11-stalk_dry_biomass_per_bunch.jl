function evaluate_stalk_dry_biomass_per_bunch(df_female)
    fig_dynamic = evaluate_generic_dynamic(df_female, "stalk_dry_biomass_per_bunch"; ylabel="stalk_dry_biomass (kg bunch⁻¹ MAP⁻¹)", xlabel="Month after planting")
    fig_scatter = evaluate_generic_scatter(df_female, "stalk_dry_biomass_per_bunch"; ylabel="Simulation", xlabel="Observations", title="Stalk dry biomass (kg bunch⁻¹ MAP⁻¹)")
    stats = evaluate_statistics(df_female, "stalk_dry_biomass_per_bunch")
    return (; dynamic=fig_dynamic, scatter=fig_scatter, statistics=stats)
end