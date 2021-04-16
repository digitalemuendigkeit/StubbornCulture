using DataFrames
using Arrow
using Pipe
using Query

if !("simulation_outcomes" in readdir("data"))
    mkdir(joinpath("data", "simulation_outcomes"))
end

filenames = readdir(joinpath("data", "simulation_records"))

df_list = DataFrame[]
for f in filenames
    df = DataFrames.DataFrame(Arrow.Table(joinpath("data", "simulation_records", f)))
    maxstep = maximum(df.step)
    maxrep = maximum(df.replicate)

    outcome = df |> @filter(_.step == maxstep) |> DataFrames.DataFrame
    unique_cultures = sort(unique(outcome.culture))
    new_colnames = vcat(("id" => :id), [c => Symbol("culture" * c[1]) for c in unique_cultures])

    outcome_sum = groupby(outcome, [:id, :culture])
    outcome_sum = combine(outcome_sum, nrow)
    outcome_sum = unstack(outcome_sum, :id, :culture, :nrow)  # TODO: insert culture dimensions here (as second id column)
    outcome_sum = coalesce.(outcome_sum, 0)
    select!(outcome_sum, new_colnames...)
    outcome_sum[!, :tendency] = (outcome_sum[!, 2] .- outcome_sum[!, 3]) ./ maxrep
    outcome_sum[!, :config] .= replace(f, r".arrow" => s"")
    push!(df_list, deepcopy(outcome_sum))
    Arrow.write(joinpath("data", "simulation_outcomes", "outcome_" * f), outcome_sum)
end

full_df = vcat(df_list..., cols=:union)
Arrow.write(joinpath("data", "simulation_outcomes", "outcomes_full.arrow"), full_df)
