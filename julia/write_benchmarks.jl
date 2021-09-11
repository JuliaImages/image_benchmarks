function write_benchmarks(io::IO, bench::AbstractDict{String,<:AbstractDict})
    println(io, "Benchmark,File,Time(s)")
    for (b, d) in bench
        for (f, t) in d
            println(io, b, ',', f, ',', t)
        end
    end
end
function write_benchmarks(filename::AbstractString, bench)
    open(filename, "w") do io
        write_benchmarks(io, bench)
    end
end
