"""
    evaluate_FFB(df_plant)

Evaluates the Fresh Fruit Bunch (FFB) data from the plant DataFrame `df_plant`.
Returns a tuple of figures: one for the dynamic evaluation and one for the scatter plot comparison with observations.
"""
function evaluate_FFB(df_plant)
    fig_dynamic = evaluate_generic_dynamic(df_plant, "bunch_fresh_biomass"; ylabel="FFB (plant⁻¹ MAP⁻¹)", xlabel="Month after planting")
    fig_scatter = evaluate_generic_scatter(df_plant, "bunch_fresh_biomass"; ylabel="Simulation", xlabel="Observations", title="FFB (Bunch Fresh Biomass, kg plant⁻¹ MAP⁻¹)")
    stats = evaluate_statistics(df_plant, "bunch_fresh_biomass")
    return (; dynamic=fig_dynamic, scatter=fig_scatter, statistics=stats)
end