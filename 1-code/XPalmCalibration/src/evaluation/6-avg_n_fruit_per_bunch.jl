function evaluate_avg_n_fruit_per_bunch(df_female)
    fig_dynamic = evaluate_generic_dynamic(df_female, "avg_n_fruit_per_bunch"; ylabel="avg_n_fruit_per_bunch (bunch⁻¹ MAP⁻¹)", xlabel="Month after planting")
    fig_scatter = evaluate_generic_scatter(df_female, "avg_n_fruit_per_bunch"; ylabel="Simulation", xlabel="Observations", title="Avg number of fruit (bunch⁻¹ MAP⁻¹)")
    stats = evaluate_statistics(df_female, "avg_n_fruit_per_bunch")
    return (; dynamic=fig_dynamic, scatter=fig_scatter, statistics=stats)
end