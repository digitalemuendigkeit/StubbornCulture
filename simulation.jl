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

mutable struct Config 
    space::Agents.GraphSpace
    culture_dims::Int
    trait_dims::Int
    stubborn_positions::Dict
    model_steps::Int
    replicates::Int
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

function run_config(cfg::Config, agent_step::Function)
    adata_list = DataFrame[]
    for i in 1:cfg.replicates
        model = create_model(cfg.space, cfg.culture_dims, cfg.trait_dims, cfg.stubborn_positions)
        adata, _ = run!(model, agent_step, cfg.model_steps, 
                        adata = [:stubborn, :culture, :changed_culture],  
                        obtainer = copy)
        adata[!, "replicate"] .= i
        push!(adata_list, deepcopy(adata))
    end
    adata = vcat(adata_list..., cols = :union)
    adata[!, "culture"] = [join(c) for c in adata[!, "culture"]]
    return adata
end


# CONVERGENCE WITH DIFFERENT NUMBERS OF CULTURAL DIMENSIONS
if !("simulation_records" in readdir("data"))
    mkdir(joinpath("data", "simulation_records"))
end
space = Agents.GraphSpace(LightGraphs.smallgraph(:karate))
cfg_list = [Config(space, i, 2, Dict(0 => [34], 1 => [1]), 1000, 100) for i in 2:10]
for cfg in cfg_list
    adata = run_config(cfg, agent_step!)
    Arrow.write(
        joinpath("data", "simulation_records", "config_" * lpad(string(cfg.culture_dims), 2, "0") * ".arrow"), 
        adata
    )
end
