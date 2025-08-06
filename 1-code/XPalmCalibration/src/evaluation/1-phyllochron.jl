function evaluate_phyllochron(df_plant)
    fig_dynamic = evaluate_generic_dynamic(df_plant, "cumulated_n_leaf_emitted"; ylabel="Number of leaves emitted since first observation")
    fig_scatter = evaluate_generic_scatter(df_plant, "cumulated_n_leaf_emitted"; ylabel="Simulation", xlabel="Observations", title="Leaves emitted")
    stats = evaluate_statistics(df_plant, "cumulated_n_leaf_emitted")
    return (; dynamic=fig_dynamic, scatter=fig_scatter, statistics=stats)
end
