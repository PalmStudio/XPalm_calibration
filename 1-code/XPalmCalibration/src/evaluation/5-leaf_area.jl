function evaluate_leaf_area(df_leaf)
    fig_dynamic = evaluate_generic_dynamic(df_leaf, "Leaf_area_17"; ylabel="Leaf area in rank 17 (m² plant⁻¹ MAP⁻¹)", xlabel="Month after planting")
    fig_scatter = evaluate_generic_scatter(df_leaf, "Leaf_area_17"; ylabel="Simulation", xlabel="Observations", title="Leaf area (m² plant⁻¹ MAP⁻¹)")
    stats = evaluate_statistics(df_leaf, "Leaf_area_17")
    return (; dynamic=fig_dynamic, scatter=fig_scatter, statistics=stats)
end