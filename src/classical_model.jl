using DataFrames
using Random

mutable struct ClassicalModel
    agents::AbstractArray
    weights::Matrix{Float64}
end

function create_model(n_agents)
    agents = create_agents(n_agents)
    weights = rand_weight_matrix(n_agents)
    return ClassicalModel(agents, weights)
end

function create_agents(n_agents)
    return rand(n_agents)
end

function rand_weight_matrix(n_agents)
    m = rand(Float64, (n_agents, n_agents))
    for i in 1:n_agents  # turn into stochastic matrix
        m[i, :] = m[i, :] ./ sum(m[i, :])
    end
    return m
end

function run!(model, n_steps)
    data = DataFrame(
        id = 1:length(model.agents),
        opinion = deepcopy(model.agents)
    )
    for i in n_steps
        model.agents = model.weights * model.agents
        data = vcat(
            data,
            DataFrame(
                id = 1:length(model.agents),
                opinion = deepcopy(model.agents)
            )
        )
    end
    return data
end
