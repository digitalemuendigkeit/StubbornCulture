using Agents
using StatsBase
using DataFrames
using Arrow
using Random
using LightGraphs

mutable struct AxelrodAgent <: Agents.AbstractAgent
    id::Int
    pos::Int
    stubborn::Bool
    culture::AbstractArray
    changed_culture::Bool
end

function init_random_agent(id, pos, model::Agents.AgentBasedModel)
    culture = rand(0:(model.trait_dims - 1), model.culture_dims)
    return AxelrodAgent(id, pos, false, culture, false)
end

function to_stubborn!(positions::Array{Int}, model::Agents.AgentBasedModel, value::Int64=0)
    dims = model.culture_dims
    for pos in positions
        stubborn_agent = model.agents[pos]
        stubborn_agent.stubborn = true
        stubborn_agent.culture = fill(value, dims)
    end
    return model
end

function to_stubborn!(positions::Dict, model::Agents.AgentBasedModel)
    for key in keys(positions)
        to_stubborn!(positions[key], model, key)
    end
    return model
end

function agent_step!(agent::Agents.AbstractAgent, model::Agents.AgentBasedModel)
    neighbors = Agents.node_neighbors(agent, model)
    interaction_partner_pos = StatsBase.sample(neighbors)
    interaction_partner = first(collect(Agents.agents_in_position(interaction_partner_pos, model)))
    similarity = StatsBase.mean(agent.culture .== interaction_partner.culture)
    if !(similarity == 1.0) & !agent.stubborn & (rand() <= similarity)
        assimilate!(agent, interaction_partner)
        agent.changed_culture = true
    else
        agent.changed_culture = false
    end
    return agent
end

function assimilate!(agent::Agents.AbstractAgent, interaction_partner::Agents.AbstractAgent)
    random_attr = rand(collect(1:length(agent.culture))[(agent.culture .!== interaction_partner.culture)])
    agent.culture[random_attr] = interaction_partner.culture[random_attr]
    return agent
end

function populate!(model::Agents.AgentBasedModel)
    for i in 1:nv(model.space.graph)
        add_agent!(init_random_agent(i, i, model), i, model)
    end
    return model
end

function create_model(space::Agents.GraphSpace, culture_dims::Int, trait_dims::Int, stubborn_positions::Union{Dict, Array{Int}}) 
    properties = Dict(
        :culture_dims => culture_dims,
        :trait_dims => trait_dims
    )
    model = Agents.AgentBasedModel(AxelrodAgent, space, properties = properties)
    populate!(model)
    to_stubborn!(stubborn_positions, model)
    return model
end



# CONVERGENCE WITH TWO CULTURAL DIMENSIONS
space = Agents.GraphSpace(LightGraphs.smallgraph(:karate))
model1 = create_model(space, 2, 2, Dict(0 => [34], 1 => [1]))
adata1, _ = run!(model1, agent_step!, 500, adata = [:stubborn, :culture, :changed_culture], replicates = 100, obtainer = copy)
adata1[!, "culture"] = [join(c) for c in adata1[!, "culture"]]
Arrow.write(joinpath("data", "convergence1.arrow"), adata1)

# CONVERGENCE WITH THREE CULTURAL DIMENSIONS
space = Agents.GraphSpace(LightGraphs.smallgraph(:karate))
model2 = create_model(space, 3, 2, Dict(0 => [34], 1 => [1]))
adata2, _ = run!(model2, agent_step!, 500, adata = [:stubborn, :culture, :changed_culture], replicates = 100, obtainer = copy)
adata2[!, "culture"] = [join(c) for c in adata2[!, "culture"]]
Arrow.write(joinpath("data", "convergence2.arrow"), adata2)

# CONVERGENCE WITH FOUR CULTURAL DIMENSIONS
space = Agents.GraphSpace(LightGraphs.smallgraph(:karate))
model3 = create_model(space, 4, 2, Dict(0 => [34], 1 => [1]))
adata3, _ = run!(model3, agent_step!, 500, adata = [:stubborn, :culture, :changed_culture], replicates = 100, obtainer = copy)
adata3[!, "culture"] = [join(c) for c in adata3[!, "culture"]]
Arrow.write(joinpath("data", "convergence3.arrow"), adata3)

# CONVERGENCE WITH FIVE CULTURAL DIMENSIONS
space = Agents.GraphSpace(LightGraphs.smallgraph(:karate))
model4 = create_model(space, 5, 2, Dict(0 => [34], 1 => [1]))
adata4, _ = run!(model4, agent_step!, 500, adata = [:stubborn, :culture, :changed_culture], replicates = 100, obtainer = copy)
adata4[!, "culture"] = [join(c) for c in adata4[!, "culture"]]
Arrow.write(joinpath("data", "convergence4.arrow"), adata4)



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