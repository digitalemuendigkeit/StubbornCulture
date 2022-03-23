using Graphs
using Graphs.LinAlg
using Random
using DataFrames
using Arrow

# TODO: add seeding everywhere

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

# construct update matrix for the karate network
karate = Graphs.smallgraph(:karate)
karate_adj = Float64.(Matrix(adjacency_matrix(karate)))
for i in 1:34
    karate_adj[i, :] = karate_adj[i, :] ./ sum(karate_adj[i, :]) 
end

# run 100 replicates
df_list = DataFrame[]
for rep in 1:100
    opinions = rand!(zeros(34)) .* 2 .-1
    opinions[1] = -1.
    opinions[34] = 1.
    outcomes = classical_model(karate_adj, opinions, 100)
    outcomes[!, :replicate] .= rep
    push!(df_list, deepcopy(outcomes))
end
classical_model_outcomes = vcat(df_list..., cols = :union)


# if !("classical_model" in readdir("data"))
#     mkdir(joinpath("data", "classical_model"))
# end
# Arrow.write(joinpath("data", "classical_model", "classical_model.arrow"), classical_model_outcomes)


# I converted the adjacency matrix of the karate network to a right stochastic matrix by deviding each entry by its rowsum.
# The model converges very close to 0 in all replicates, the network structure does not seem to play a big role.


# This model was proposed as a model of consensus finding among experts (De Groot 1974, Lehrer 1975)
