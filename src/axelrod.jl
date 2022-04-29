using Graphs
using Plots
using GraphRecipes
using DataFrames
using Random

mutable struct AxelrodAgent
    id::Int
    culture::AbstractArray
end

mutable struct AxelrodModel
    agents::Array{AxelrodAgent}
    space::Graphs.AbstractGraph
end

function create_agents(sqrt_n; n_culture_dims=5)
    agent_set = AxelrodAgent[]
    for i in 1:(sqrt_n^2)  # make sure agent count is feasible for grid
        push!(agent_set, AxelrodAgent(i, rand(0:9, n_culture_dims)))
    end
    return agent_set
end

function similarity(agent1, agent2)
    return (
        sum(agent1.culture .== agent2.culture)
        / length(agent1.culture)
    )
end

function create_model(sqrt_n_agents; periodic=false, n_culture_dims=5)
    agents = create_agents(sqrt_n_agents, n_culture_dims=n_culture_dims)
    space = Graphs.grid(
        [Int(sqrt_n_agents), Int(sqrt_n_agents)],
        periodic=periodic
    )
    return AxelrodModel(agents, space)
end

function choose_neighbor(model, agent_id)
    neighbor_ids = neighbors(model.space, agent_id)
    return rand(neighbor_ids)
end

function run!(model, n_steps)
    data = DataFrame[]
    for i in 1:n_steps
        updtd_agents = AxelrodAgent[]
        for a in model.agents
            b_id = choose_neighbor(model, a.id)
            updtd_a = deepcopy(a)
            updtd_b = deepcopy(model.agents[b_id])
            if similarity(updtd_a, updtd_b) < rand()
                idx_arr = findall(
                    ==(0),
                    updtd_a.culture .== updtd_b.culture
                )
                dim_to_change = rand(idx_arr)
                updtd_a.culture[dim_to_change] = updtd_b.culture[dim_to_change]
            end
            push!(updtd_agents, updtd_a)
        end
        push!(data, DataFrame(deepcopy(updtd_agents)))
        model.agents = updtd_agents
    end
    data = vcat(data...)
    return data
end

# Plot graph
# graphplot(space, curves=false)

