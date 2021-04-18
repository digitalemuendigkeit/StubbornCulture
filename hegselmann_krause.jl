using LightGraphs
using Random
using DataFrames
using Arrow
using Agents
using Distributions

function hegselmann_krause(x_0, rel, ϵ, iterations)
    n_agents = nv(rel)
    x = x_0
    df_list = DataFrame[]
    for i in 0:iterations
        df = DataFrame(id = 1:n_agents, opinion = x, step = i, epsilon = ϵ)
        push!(df_list, deepcopy(df))
        A = zeros(n_agents, n_agents)
        for v in 1:n_agents
            v_set = sort!(push!(copy(neighbors(rel, v)), v))
            epsilon_filter = [abs(x[n] - x[v]) <= ϵ for n in v_set]
            v_set_filtered = v_set[epsilon_filter]
            for i in 1:n_agents
                if i in v_set_filtered
                    A[v, i] = 1.
                end
            end
            if sum(A[v, :]) != 0
                A[v, :] = A[v, :] ./ sum(A[v, :]) 
            end
        end
        x = A * x
    end
    outcome = vcat(df_list..., cols = :union)
    return outcome    
end

# define the agent relations
rel = LightGraphs.smallgraph(:karate)

# define the distribution for the initial opinion profile
D = Uniform(-1, 1)

# run 100 replicates for different ϵ values
df_list = DataFrame[]
for ϵ in 0.1:0.1:1.0
    for rep in 1:100
        x_0 = rand(D, nv(rel))
        x_0[1] = -1.
        x_0[34] = 1.
        outcome = hegselmann_krause(x_0, rel, ϵ, 50)
        outcome[!, :replicate] .= rep
        push!(df_list, deepcopy(outcome))
    end
end
hegselmann_krause_outcomes = vcat(df_list..., cols = :union)
if !("hegselmann_krause" in readdir("data"))
    mkdir(joinpath("data", "hegselmann_krause"))
end
Arrow.write(joinpath("data", "hegselmann_krause", "hegselmann_krause.arrow"), hegselmann_krause_outcomes)
