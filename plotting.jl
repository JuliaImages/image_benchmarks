using CSV
using DataFrames
using Colors
using PyPlot

const rexeltype = r"N0f8|N0f16|Float32"
const idxeltype = Dict("N0f8"=>1, "N0f16"=>2, "Float32"=>3)
const eltypeidx = Dict(v=>k for (k, v) in idxeltype)
const rexsize = r"_(\d+)$"

randomtag(fn) = (occursin(r"rgb", fn), idxeltype[match(rexeltype, fn).match], parse(Int, only(match(rexsize, fn).captures)))
randomlabel(tag) = (tag[1] ? "RGB" : "Gray") * "{" * eltypeidx[tag[2]] * "}, $(tag[3])"


hexhash(c) = "#"*hex(c)

function taskplots(jobtag::Function, jobname::Function, filelabel::Pair...; colordict=nothing, tasknames=nothing, pervoxel::Bool=true)
    # Read all the data
    benchdata = Dict{String,GroupedDataFrame{DataFrame}}()
    for (file, label) in filelabel
        benchdata[label] = groupby(DataFrame(CSV.File(file; delim=',')), "Benchmark")
    end
    # Ensure all inputs have the same tasks
    ks = keys(first(benchdata).second)
    knames = Set(only(Tuple(k)) for k in ks)
    for (_, df) in benchdata
        dfknames = Set(only(Tuple(k)) for k in keys(df))
        # kdf ⊆ ks && ks ⊆ kdf || error("disjoint tasks")
        dfknames == knames || error("disjoint tasks")
    end
    # Determine the plotting order
    if tasknames === nothing
        tasknames = sort(collect(knames))
    end
    # Assign colors to each suite
    if colordict === nothing
        colordict = Dict(zip(keys(benchdata), hexhash.(distinguishable_colors(length(benchdata), [colorant"white"]; dropseed=true))))
    end
    ncols = floor(Int, sqrt(length(tasknames)))
    nrows = ceil(Int, length(tasknames)/ncols)
    fig, axes = plt.subplots(nrows=nrows, ncols=ncols, gridspec_kw=Dict("bottom"=>0.2))
    for i = length(tasknames)+1:length(axes)
        axes[i].set_axis_off()  # close()
    end
    legend_labels, hlines = String[], []
    for (axidx, ax, k) in zip(CartesianIndices(axes), axes, tasknames)
        xlbls = nothing
        for (label, data) in benchdata
            data = sort(data[(Benchmark=k,)], "File"; by=jobtag)
            if xlbls === nothing
                xlbls = jobname.(jobtag.(data."File"))
            end
            y = data."Time(s)"
            if pervoxel
                nvox = map(data."File") do fn
                    jobtag(fn)[end]^2
                end
                y ./= nvox
            end
            hline = ax.plot(y; color=colordict[label], marker="x")
            if length(legend_labels) < length(filelabel)
                push!(legend_labels, label)
                push!(hlines, first(hline))
            end
        end
        if axidx[1] == size(axes, 1) || LinearIndices(axes)[axidx] == length(tasknames)
            ax.set_xticks(0:length(xlbls)-1)
            ax.set_xticklabels(xlbls; rotation=90)
            ax.set_xlabel("Jobs")
        else
            ax.set_xticks([])
        end
        ax.set_yscale("log")
        if axidx[2] == 1
            ax.set_ylabel("Time (s)")
        end
        ax.set_title(k)
    end
    fig.legend(hlines, legend_labels)
    return fig
end

# taskplots(randomtag, randomlabel, "julia/julia_generics.csv" => "Julia",
#                                   "python-skimage/python_generics.csv" => "python-skimage",
#                                   "matlab/matlab_generics.csv" => "Matlab",
#                                   "opencv/opencv_generics.csv" => "OpenCV",
# )

function specialplots(filelabel::Pair...; colordict=nothing)
    # Read all the data
    benchdata = Dict{String,DataFrame}()
    for (file, label) in filelabel
        benchdata[label] = DataFrame(CSV.File(file; delim=','))
    end
    # Ensure all inputs have the same tasks
    tasknames = sort(first(benchdata).second."Benchmark")
    all(df -> Set(df."Benchmark") == Set(tasknames), values(benchdata))
    # Assign colors to each suite
    if colordict === nothing
        colordict = Dict(zip(keys(benchdata), hexhash.(distinguishable_colors(length(benchdata), [colorant"white"]; dropseed=true))))
    end
    fig, ax = plt.subplots()
    x = 1:length(tasknames)
    w = 1/(2*length(benchdata))
    for (i, (label, df)) in enumerate(benchdata)
        p = Int.(indexin(df."Benchmark", tasknames))
        dfs = df[invperm(p),:]
        display(dfs)
        ax.bar(x .+ (i-1)*w .- w/2, dfs."Time(s)", w; label=label, color=colordict[label])
    end
    ax.set_xticks(x)
    repnames = map(tasknames) do tn
        foldl((str, rep) -> replace(str, rep), ["components" => "label_components", "dblcone" => "distance_transform", "spiral" => "flood"]; init=tn)
    end
    ax.set_xticklabels(repnames; rotation=90)
    ax.set_yscale("log")
    ax.set_ylabel("Time (s)")
    fig.legend()
    fig.tight_layout()
    return fig
end

# specialplots("julia/julia_special.csv" => "Julia",
#              "python-skimage/python_special.csv" => "python-skimage",
#              "matlab/matlab_special.csv" => "Matlab",
#              #= "opencv/opencv_special.csv" => "OpenCV", =#
# )
