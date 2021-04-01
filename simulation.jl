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

function init_random_agent(id, pos)
    culture = rand(0:9, 5)
    return AxelrodAgent(id, pos, false, culture, false)
end

function to_stubborn!(positions::Array{Int}, model::Agents.AgentBasedModel, value::Int64=0)
    for pos in positions
        stubborn_agent = model.agents[pos]
        stubborn_agent.stubborn = true
        stubborn_agent.culture = fill(value, 5)
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
        add_agent!(init_random_agent(i, i), i, model)
    end
    return model
end

space = Agents.GraphSpace(LightGraphs.smallgraph(:karate))
model = Agents.AgentBasedModel(AxelrodAgent, space)
populate!(model)
to_stubborn!([1], model)
adata, _ = run!(model, agent_step!, 500, adata = [:stubborn, :culture, :changed_culture], replicates = 3, obtainer = copy)
adata[!, "culture"] = [join(c) for c in adata[!, "culture"]]
Arrow.write(joinpath("data", "data.arrow"), adata)
# DataFrame(Arrow.Table("data"))