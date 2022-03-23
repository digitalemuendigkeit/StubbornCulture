using LightGraphs
using LightGraphs.LinAlg
using Random
using DataFrames
using Arrow
using LinearAlgebra

# TODO: add seeding everywhere

function friedkin_johnson(x_0, A, G, iterations)
    opinion_states = DataFrame[]
    x = x_0
    for i in 0:iterations
        opinion_df = DataFrame(id = 1:34, opinion = x, step = i)
        push!(opinion_states, deepcopy(opinion_df))
        x = G * x_0 + (Diagonal(ones(34)) - G) * A * x
    end
    opinion_states = vcat(opinion_states..., cols = :union)
end


# initial opinions and the susceptibility matrix
G = Diagonal(rand!(zeros(34)))
G[1, 1] = 1.  # opinion leader 1
G[34, 34] = 1.  # opinion leader 2

# construct update matrix for the karate network
karate = LightGraphs.smallgraph(:karate)
A = Float64.(Matrix(adjacency_matrix(karate)))
for i in 1:34
    A[i, :] = A[i, :] ./ sum(A[i, :]) 
end

# run 100 replicates
df_list = DataFrame[]
for rep in 1:100
    x_0 = rand!(zeros(34)) .* 2 .- 1
    x_0[1] = -1.
    x_0[34] = 1.
    outcomes = friedkin_johnson(x_0, A, G, 500)
    outcomes[!, :replicate] .= rep
    push!(df_list, deepcopy(outcomes))
end
friedkin_johnson_outcomes = vcat(df_list..., cols = :union)


if !("friedkin_johnson" in readdir("data"))
    mkdir(joinpath("data", "friedkin_johnson"))
end
Arrow.write(joinpath("data", "friedkin_johnson", "friedkin_johnson.arrow"), friedkin_johnson_outcomes)


# The Friedkin-Johnson model factors in "stubbornness" (given by the matrix G)