function evaluate_bunch_fresh_mass_per_bunch(df_female)
    fig_dynamic = evaluate_generic_dynamic(df_female, "bunch_fresh_mass_per_bunch"; ylabel="bunch_fresh_mass_per_bunch (bunch⁻¹ MAP⁻¹)", xlabel="Month after planting")
    fig_scatter = evaluate_generic_scatter(df_female, "bunch_fresh_mass_per_bunch"; ylabel="Simulation", xlabel="Observations", title="Bunch Fresh Biomass (kg bunch⁻¹ MAP⁻¹)")
    stats = evaluate_statistics(df_female, "bunch_fresh_mass_per_bunch")
    return (; dynamic=fig_dynamic, scatter=fig_scatter, statistics=stats)
end