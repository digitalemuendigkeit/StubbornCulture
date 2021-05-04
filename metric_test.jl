using DelimitedFiles
using Arrow
using DataFrames
using Distances
using Query
using PyPlot
using Clustering
using Glob

if !("clustering_matrices" in readdir("data"))
    mkdir(joinpath("data", "clustering_matrices"))
end
begin
    cd(joinpath("data", "simulation_records"))
    filenames = readdir(glob"config_*")
    cd(joinpath("..", ".."))
end

for f in filenames
    data = DataFrame(Arrow.Table(joinpath("data", "simulation_records", f)))
    M = zeros(34, 34)
    
    for rep in 1:100
        cultures = data |> @filter(_.replicate == rep) |> DataFrame
        select!(cultures, :id, :culture)

        for i in 1:34
            for j in 1:34
                M[i, j] = M[i, j] + hamming(cultures[i, :culture], cultures[j, :culture])
            end
        end
    end
    
    M = M ./ 100
    clus = hclust(M)
    M = M[clus.order, clus.order]
    df = DataFrame(ClusID1 = Int[], ClusID2 = Int[], Similarity = Float64[])
    for i in 1:34
        for j in 1:34
            push!(df, (i, j, M[i, j]))
        end
    end
    order_df_1 = DataFrame(ClusID1 = 1:34, RealID1 = clus.order)
    order_df_2 =  DataFrame(ClusID2 = 1:34, RealID2 = clus.order)

    df = innerjoin(df, order_df_1, on = :ClusID1)
    df = innerjoin(df, order_df_2, on = :ClusID2)
    
    Arrow.write(joinpath("data", "clustering_matrices", f), df)
end