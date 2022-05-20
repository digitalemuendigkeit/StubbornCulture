mutable struct ClassicalModel
    agents::Array{Float64}
    weights::Matrix{Float64}
end

function create_model(n_agents; weights = Nothing)
    agents = create_agents(n_agents)
    if weights == Nothing
        weights = rand_weight_matrix(n_agents)
    end
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

# graph to weight matrix?

function run!(model, n_steps)
    current_state = DataFrame(
        id = 1:length(model.agents),
        step = 0,
        opinion = model.agents
    )
    data = DataFrame[]
    push!(data, deepcopy(current_state))
    for i in 1:n_steps
        model.agents = model.weights * model.agents
        current_state[!, :step] .= i
        current_state[!, :opinion] = deepcopy(model.agents)
        push!(data, deepcopy(current_state))
    end
    data = reduce(vcat, data)
    return data
end
