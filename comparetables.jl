using CSV
using DataFrames

if !isdefined(@__MODULE__, :imagelt)
    include("filenaming.jl")
end

function compare_table(fn1, fn2, renamecols)
    df1 = DataFrame(CSV.File(fn1))
    df2 = DataFrame(CSV.File(fn2))
    return innerjoin(df1, df2; on=["Benchmark", "File"], renamecols)
end
