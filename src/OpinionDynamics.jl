module OpinionDynamics


function classical_model(stochastic_matrix, initial_opinions, iterations)
    opinion_states = DataFrame[]
    opinions = initial_opinions
    for i in 0:iterations
        opinion_df = DataFrame(id = 1:34, opinion = opinions, step = i)
        push!(opinion_states, deepcopy(opinion_df))
        opinions = karate_adj * opinions
    end
    opinion_states = vcat(opinion_states..., cols = :union)
    return opinion_states
end



end  # end module
