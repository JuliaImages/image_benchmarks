# Installing Julia

Download Julia from https://julialang.org/downloads/.

# Running the Julia benchmarks

When you run code in this folder, you should use the `Project.toml` file that has been created.
The easiest way to do that is to launch Julia from a shell, starting in this folder, with `julia --project`.
The [main readme](../README.md) gives an alternative if you launch Julia via your operating system's GUI.

Once you have Julia running with the active project set here, do the following:

```
julia> include("benchmarks.jl")
time_special (generic function with 1 method)

julia> tg = time_generics("/tmp/imgbench");
Timing generic operations: 100%|████████████████████████████████████████████████████████████████████████████████████████████████████████████████████| Time: 0:03:21

julia> include("write_benchmarks.jl")
write_benchmarks (generic function with 3 methods)

julia> write_benchmarks("julia_generics.csv", tg)

julia> ts = time_special("/tmp/imgbench_special");
Timing special operations: 100%|████████████████████████████████████████████████████████████████████████████████████████████████████████████████████| Time: 0:00:40

julia> write_benchmarks("julia_special.csv", ts)
```

The progress bar will keep you up-to-date about how far the suite has gotten. (Each task is run multiple times, so it can take many minutes.)
