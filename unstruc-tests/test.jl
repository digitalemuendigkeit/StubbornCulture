# TODO: include other script to have functions available



# NEXT STEPS

# use the model with 3 cultural dimensions
# choose two agents at random and simulate the outcomes repeatedly
# compute the probability for a schism

space = Agents.GraphSpace(LightGraphs.smallgraph(:karate))
df_list = DataFrame[]
@time for i in 1:33
    for j in (i + 1):34
        model = create_model(space, 3, 2, Dict(0 => [i], 1 => [j]))
        adata, _ = run!(
            model, agent_step!, 500, 
            adata = [:stubborn, :culture, :changed_culture], 
            replicates = 100, obtainer = copy, when = [500]
        )
        adata[!, "culture"] = [join(c) for c in adata[!, "culture"]]
        adata[!, "leader1"] .= i
        adata[!, "leader2"] .= j
        select!(adata, Not([:step, :changed_culture]))
        push!(df_list, deepcopy(adata))
        print(".")
    end
end
all_combs = vcat(df_list..., cols = :union)
Arrow.write(joinpath("data", "all_combs.arrow"), all_combs)




karate = LightGraphs.smallgraph(:karate)

using GraphPlot

layout=(args...)->spring_layout(args...; C=20)
gplot(karate, layout=layout)
