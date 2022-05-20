using Pkg
Pkg.activate(".")

include("src/OpinionDynamics.jl")
using Main.OpinionDynamics

agents = rand(100)
weights = rand_weight_matrix(100)
model = ClassicalModel(agents, weights)
data = run!(model, 100)

