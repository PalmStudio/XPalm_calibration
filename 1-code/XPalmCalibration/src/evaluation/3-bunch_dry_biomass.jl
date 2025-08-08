function evaluate_bunch_dry_biomass(df_plant)
    fig_dynamic = evaluate_generic_dynamic(df_plant, "bunch_dry_biomass"; ylabel="Bunch_dry_biomass (kg plant⁻¹ MAP⁻¹)", xlabel="Month after planting")
    fig_scatter = evaluate_generic_scatter(df_plant, "bunch_dry_biomass"; ylabel="Simulation", xlabel="Observations", title="Total bunch dry mass (kg plant⁻¹ MAP⁻¹)")
    stats = evaluate_statistics(df_plant, "bunch_dry_biomass")
    return (; dynamic=fig_dynamic, scatter=fig_scatter, statistics=stats)
end