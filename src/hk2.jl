using Agents
using Distributions
using LightGraphs
using DataFrames

mutable struct HKAgent <: AbstractAgent
    id::Int
    pos::Int
    stubborn::Bool
    opinion::Float64
    updated_opinion::Float64
    confidence::Float64
end

function init_random_agent(id, pos, confidence)
    opinion = rand(Uniform(-1, 1))
    agent = HKAgent(id, pos, false, opinion, opinion, confidence)
    return agent
end

function populate!(model::AgentBasedModel, confidence)
    for i in 1:nv(model.space.graph)
        add_agent!(init_random_agent(i, i, confidence), i, model)
    end
    return model
end

function to_stubborn!(pos, model, value=1)
    stubborn_agent = model.agents[pos]
    stubborn_agent.stubborn = true
    stubborn_agent.opinion = value
    stubborn_agent.updated_opinion = value
    return stubborn_agent
end

function is_in_bounded_confidence(agent, interaction_partner)
    return abs(agent.opinion - interaction_partner.opinion) <= agent.confidence
end

function agent_step!(agent::HKAgent, model::AgentBasedModel)
    if !agent.stubborn
        agent_neighbors = node_neighbors(agent, model)
        neighbor_opinions = Float64[]
        for id in agent_neighbors
            interaction_partner = model.agents[id]
            if is_in_bounded_confidence(agent, interaction_partner)
                push!(neighbor_opinions, interaction_partner.opinion)
            end             
        end
        agent.updated_opinion = length(neighbor_opinions) > 0 ? mean(neighbor_opinions) : agent.opinion
    end
    return agent
end

function model_step!(model)
    for id in keys(model.agents)
        model.agents[id].opinion = model.agents[id].updated_opinion
    end
    return model
end

function create_model(space, confidence_level, stubborn_positions::Dict)
    model = Agents.AgentBasedModel(HKAgent, space)
    populate!(model, confidence_level)
    for k in keys(stubborn_positions)
        to_stubborn!(k, model, stubborn_positions[k])
    end
    return model
end



space = Agents.GraphSpace(LightGraphs.smallgraph(:karate))
model = create_model(space, 0.4, Dict(1 => 1., 34 => -1.))

adata, _ = run!(model, agent_step!, model_step!, 200, obtainer = copy, adata = [:stubborn, :opinion, :confidence])
last(adata, 34)