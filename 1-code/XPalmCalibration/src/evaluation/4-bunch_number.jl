function evaluate_bunch_number(df_plant)
    fig_dynamic = evaluate_generic_dynamic(df_plant, "total_n_bunches_harvested"; ylabel="Total number of bunches harvested (plant⁻¹ MAP⁻¹)", xlabel="Month after planting")
    fig_scatter = evaluate_generic_scatter(df_plant, "total_n_bunches_harvested"; ylabel="Simulation", xlabel="Observations", title="Total number of bunches (plant⁻¹ MAP⁻¹)")
    stats = evaluate_statistics(df_plant, "total_n_bunches_harvested")
    return (; dynamic=fig_dynamic, scatter=fig_scatter, statistics=stats)
end