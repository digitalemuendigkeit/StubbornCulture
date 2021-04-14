using DataFrames
using Arrow
using Pipe
using Query

if !("simulation_outcomes" in readdir("data"))
    mkdir(joinpath("data", "simulation_outcomes"))
end

filenames = readdir(joinpath("data", "simulation_records"))

for f in filenames
    df = DataFrames.DataFrame(Arrow.Table(joinpath("data", "simulation_records", f)))
    maxstep = maximum(df.step)

    outcome = df |> @filter(_.step == maxstep) |> DataFrames.DataFrame
    unique_cultures = sort(unique(outcome.culture))
    new_colnames = [c => Symbol("culture" * c) for c in unique_cultures]

    outcome_sum = groupby(outcome, [:id, :culture])
    outcome_sum = combine(outcome_sum, nrow)
    outcome_sum = unstack(outcome_sum, :id, :culture, :nrow)
    outcome_sum = coalesce.(outcome_sum, 0)
    select!(outcome_sum, new_colnames...)
    outcome_sum[!, :tendency] = (outcome_sum[!, 1] .- outcome_sum[!, 2]) / 100
    Arrow.write(joinpath("data", "simulation_outcomes", "outcome_" * f), outcome_sum)
end
