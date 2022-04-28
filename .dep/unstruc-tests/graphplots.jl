using GraphRecipes
using Plots
using Arrow
using DataFrames
using ColorSchemes
using LightGraphs
using GraphPlot
using Cairo
using Compose

# read data
df = DataFrame(Arrow.Table(joinpath("data", "simulation_outcomes", "outcome_config_02.arrow")))

# normalize tendendies
df.tendency = df.tendency .+ 1
df.tendency = df.tendency ./ 2

# create karate network
k = LightGraphs.smallgraph(:karate)

# plot specifics
cs = [RGB(get(ColorSchemes.RdBu_10, df.tendency[i])) for i in 1:size(df, 1)]
layout = (args...) -> spring_layout(args...; C=4)
nodesize = [LightGraphs.outdegree(k, v) for v in LightGraphs.vertices(k)]
nodelabel = 1:nv(k)

# draw plot
draw(PDF("karate.pdf", 20cm, 20cm), 
     gplot(k, nodefillc = cs, layout = layout, nodelabel = nodelabel, EDGELINEWIDTH = 0.08, NODESIZE = 0.05))

