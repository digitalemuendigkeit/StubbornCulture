using Graphs
using Plots
using GraphRecipes
using DataFrames
using Random

# TODO:
# * make n_dims a parameter

N_AGENTS = 100

mutable struct AxelrodAgent
    id
    culture
end

mutable struct AxelrodModel
    agents
    space
end

# Plot graph
# graphplot(space, curves=false)

function create_agents(n)
    agent_set = AxelrodAgent[]
    for i in 1:n
        push!(agent_set, AxelrodAgent(i, rand(0:9, 5)))
    end
    return agent_set
end

function similarity(agent1, agent2)
    return (
        sum(agent1.culture .== agent2.culture)
        / length(agent1.culture)
    )
end

function create_model(n_agents)
    agents = create_agents(n_agents)
    space = Graphs.grid(
        [Int(sqrt(n_agents)), Int(sqrt(n_agents))],
        periodic=false
    )
    return(AxelrodModel(agents, space))
end

function choose_neighbor(model, agent_id)
    neighbor_ids = neighbors(model.space, agent_id)
    return rand(neighbor_ids)
end

function run!(model, n_steps)
    data = DataFrame[]
    for i in 1:n_steps
        updated_agents = AxelrodAgent[]
        for a in model.agents
            neigh_id = choose_neighbor(model, a.id)
            updated_a = deepcopy(a)
            updated_neigh = deepcopy(model.agents[neigh_id])
            if similarity(updated_a, updated_neigh) < rand()
                # TODO: add axelrod step
                println("update culture")
            else
                println("don't update culture")
            end
            push!(updated_agents, updated_a)
        end
        push!(data, DataFrame(deepcopy(updated_agents)))
        model.agents = updated_agents
    end
    data = vcat(data...)
    return data
end
