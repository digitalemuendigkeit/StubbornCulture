using Graphs
using Plots
using GraphRecipes
using DataFrames
using Random
using Agents

@agent CultureDisseminationAgent GridAgent{2} begin
    culture::Array{Int64}
end

mutable struct CultureDisseminationModel
    agents::Array{CultureDisseminationAgent}
    space::Agents.GridSpace
end

space = GridSpace((10, 10), periodic = false, metric = :euclidean)
model = AgentBasedModel(CultureDisseminationAgent, space)

# populate! function ->
for (i, (x, y)) in enumerate(Iterators.product(1:10, 1:10))
    add_agent_pos!(CultureDisseminationAgent(i, (x, y), rand(1:5, 5)), model)
end

function agent_step!(agent, model)
    neigh_id = rand(collect(nearby_ids(agent, model, 1)))
    neigh = model.agents[neigh_id]
    if !(similarity(agent, neigh) == 1) & (similarity(agent, neigh) < rand())
        idx_arr = findall(
            ==(0),
            agent.culture .== neigh.culture
        )
        dim_to_change = rand(idx_arr)
        agent.culture[dim_to_change] = neigh.culture[dim_to_change]
    end
    return agent
end

function similarity(agent1::CultureDisseminationAgent, agent2::CultureDisseminationAgent)
    return (
        sum(agent1.culture .== agent2.culture)
        / length(agent1.culture)
    )
end

function run!(model, n_steps)
    adata = DataFrame[]
    for i in 1:n_steps
        step!(model, agent_step!, 1)
        adata_step = DataFrame(values(model.agents))
        push!(adata, deepcopy(adata_step))
    end
end

# function create_agents(grid_dims::Tuple{Int, Int}; n_culture_dims=5)
#     agent_set = AxelrodAgent[]
#     for i in 1:reduce(*, grid_dims)  # make sure agent count is feasible for grid
#         push!(agent_set, AxelrodAgent(i, rand(0:9, n_culture_dims)))
#     end
#     return agent_set
# end

# function create_model(grid_dims::Tuple{Int, Int}; periodic=false, n_culture_dims=5)
#     agents = create_agents(grid_dims, n_culture_dims=n_culture_dims)
#     space = Graphs.grid(
#         [Int(grid_dims[1]), Int(grid_dims[2])],
#         periodic=periodic
#     )
#     return AxelrodModel(agents, space)
# end

# function choose_neighbor(model, agent_id)
#     neighbor_ids = neighbors(model.space, agent_id)
#     return rand(neighbor_ids)
# end

# function run!(model, n_steps)
#     data = DataFrame[]
#     for i in 1:n_steps
#         updtd_agents = AxelrodAgent[]
#         for a in model.agents
#             b_id = choose_neighbor(model, a.id)
#             updtd_a = deepcopy(a)
#             updtd_b = deepcopy(model.agents[b_id])
#             if similarity(updtd_a, updtd_b) < rand()
#                 idx_arr = findall(
#                     ==(0),
#                     updtd_a.culture .== updtd_b.culture
#                 )
#                 dim_to_change = rand(idx_arr)
#                 updtd_a.culture[dim_to_change] = updtd_b.culture[dim_to_change]
#             end
#             push!(updtd_agents, updtd_a)
#         end
#         push!(data, DataFrame(deepcopy(updtd_agents)))
#         model.agents = updtd_agents
#     end
#     data = vcat(data...)
#     return data
# end

# # Plot graph
# # graphplot(space, curves=false)
