function evaluate_cumulated_FFB(df_plant)
    fig_dynamic = evaluate_generic_dynamic(df_plant, "cumulated_FFB"; ylabel="cumulated FFB (kg plant⁻¹ MAP⁻¹)", xlabel="Month after planting")
    fig_scatter = evaluate_generic_scatter(df_plant, "cumulated_FFB"; ylabel="Simulation", xlabel="Observations", title="Cumulated FFB MAP 50 - 100 (kg plant⁻¹ MAP⁻¹)")
    stats = evaluate_statistics(df_plant, "cumulated_FFB")
    return (; dynamic=fig_dynamic, scatter=fig_scatter, statistics=stats)
end