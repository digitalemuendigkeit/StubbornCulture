module OpinionDynamics

using Graphs
using Plots
using GraphRecipes
using DataFrames
using Random

include("classical_model.jl")
# include("axelrod.jl")

export ClassicalModel
export create_model
export run!
export rand_weight_matrix

# export AxelrodModel

# TODO: dispatch multiple methods for each create_model, create_agents etc.

end  # end module
