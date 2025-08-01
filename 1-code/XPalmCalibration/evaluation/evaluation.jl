function evaluate(df_plant, path_outputs)
    f_phyllochron = evaluate_phyllochron(df_plant)
    fig_n_bunch = evaluate_bunch_number(df_plant)

    mkpath(path_outputs)
    save(joinpath(path_outputs, "1.leaf_emitted.png"), f_phyllochron)
    save(joinpath(path_outputs, "2.total_n_bunches_harvested (plant-1 MAP-1).png"), fig_n_bunch)

    return (; f_phyllochron)
end