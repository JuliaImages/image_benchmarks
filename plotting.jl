using CSV
using DataFrames
using Colors
using PyPlot

const rexeltype = r"N0f8|N0f16|Float32"
const idxeltype = Dict("N0f8"=>1, "N0f16"=>2, "Float32"=>3)
const eltypeidx = Dict(v=>k for (k, v) in idxeltype)
const rexsize = r"_(\d+)$"
const special_replacements = ["components" => "label_components", "dblcone" => "distance_transform", "spiral" => "flood"]

randomtag(fn) = (occursin(r"rgb", fn), idxeltype[match(rexeltype, fn).match], parse(Int, only(match(rexsize, fn).captures)))
randomlabel(tag) = (tag[1] ? "RGB" : "Gray") * "{" * eltypeidx[tag[2]] * "}, $(tag[3])"

function imagelt(image1, image2)
    image1 ∈ ("2d", "3d") && image2 ∈ ("2d", "3d") && return image1 < image2
    @show image1 image2

    getcolor(str) = match(r"(Gray|RGB)", str).captures[1]::AbstractString
    geteltype(str) = idxeltype[match(r"(N0f8|N0f16|Float32)", str).captures[1]]
    getsz(str) = parse(Int, match(r", (\d)+", str).captures[1])

    col1, col2 = getcolor(image1), getcolor(image2)
    col1 != col2 && return col1 < col2
    et1, et2 = geteltype(image1), geteltype(image2)
    et1 != et2 && return et1 < et2
    return getsz(image1) < getsz(image2)
end

hexhash(c) = "#"*hex(c)
const language_colors = (cols = hexhash.(distinguishable_colors(4, [colorant"white", colorant"black"]; dropseed=true));
                         Dict("python-skimage"=>cols[1], "Matlab"=>cols[2], "OpenCV"=>cols[3], "Julia"=>cols[4]))

function taskplots(jobtag::Function, jobname::Function, filelabel::Pair...; colordict=language_colors, tasknames=nothing, pervoxel::Bool=true)
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

function specialplots(filelabel::Pair...; colordict=language_colors)
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
        foldl((str, rep) -> replace(str, rep), special_replacements; init=tn)
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

function combine_all(prs...; szs=(r"64_64", r"2048_2048"), eltypes=(r"gray_N0f8", r"gray_Float32", r"rgb_N0f8", r"rgb_Float32"))
    df = DataFrame("Framework"=>String[], "Operation"=>String[], "Image"=>String[], "Time"=>Float64[])
    for (file, framework) in prs
        for row in CSV.Rows(file)
            if length(row) == 3  # one of the generics
                any(occursin(row.File), szs) || continue
                any(occursin(row.File), eltypes) || continue
                tag = randomtag(row.File)
                t = getproperty(row, Symbol("Time(s)"))
                push!(df, (framework, row.Benchmark, randomlabel(tag), parse(Float64, t)))
            else  # one of the special
                imagetag = occursin("3d", row.Benchmark) ? "3d" : "2d"
                optag = foldl((str, rep) -> replace(str, rep), special_replacements; init=row.Benchmark[1:end-2])
                t = getproperty(row, Symbol("Time(s)"))
                push!(df, (framework, optag, imagetag, parse(Float64, t)))
            end
        end
    end
    return df
end

# df = combine_all("julia/julia_generics.csv" => "Julia",
#                  "python-skimage/python_generics.csv" => "python-skimage",
#                  "matlab/matlab_generics.csv" => "Matlab",
#                  "opencv/opencv_generics.csv" => "OpenCV",
#                  "julia/julia_special.csv" => "Julia",
#                  "python-skimage/python_special.csv" => "python-skimage",
#                  "matlab/matlab_special.csv" => "Matlab")

function ratio_df(df; operation_order=["complement", "mean", "histeq", "blur", "gradient", "label_components", "flood", "distance_transform"])
    jdata = filter(:Framework=>isequal("Julia"), df)
    jgroups = groupby(jdata, :Operation)
    rdf = DataFrame("Framework"=>String[], "Operation"=>String[], "Image"=>String[], "Ratio"=>Float64[])
    for f in ("python-skimage", "Matlab", "OpenCV")
        fdata = filter(:Framework=>isequal(f), df)
        fgroups = groupby(fdata, :Operation)
        for op in operation_order
            k = (Operation=op,)
            jref = sort(jgroups[k], :Image; lt=imagelt)
            try
                fval = sort(fgroups[k], :Image; lt=imagelt)
                for (jrow, frow) in zip(eachrow(jref), eachrow(fval))
                    @assert jrow.Image == frow.Image
                    push!(rdf, [f, op, frow.Image, frow.Time / jrow.Time])
                end
            catch
                for jrow in eachrow(jref)
                    push!(rdf, [f, op, jrow.Image, NaN])
                end
            end
        end
    end
    return rdf
end

function plot_ratio(rdf; colordict=language_colors)
    frameworks = unique(rdf.Framework)
    operations = unique(rdf.Operation)
    n = Int(nrow(rdf)/length(frameworks))  # deliberately errors if not an even divisor
    x = 1:n+length(operations)-1
    xlabels = String[]
    opgaps = Int[]
    gdf = groupby(rdf, :Framework)
    fig, axouter = plt.subplots(figsize=(7.5,4), subplot_kw=Dict("position" => [0.1, 0.05, 0.9, 0.95]))
    insetgap = 0.4
    ax = axouter.inset_axes([0, insetgap, 1, 1-insetgap])
    for k in keys(gdf)
        g = gdf[k]
        col = colordict[k.Framework]
        oldop = ""
        y = Float64[]
        for (i, (op, t)) in enumerate(zip(g.Operation, g.Ratio))
            if op != oldop && i != 1
                push!(y, NaN)
                if length(xlabels) < n && i != 1
                    # push!(xlabels, "")
                    push!(opgaps, length(y))
                end
            end
            oldop = op
            push!(y, t)
            if length(xlabels) < n
                push!(xlabels, g.Image[i])
            end
        end

        ax.plot(x, y, color=col, label=k.Framework, marker="x")
    end
    ax.plot(x, fill(1, length(x)), "k--", label=nothing)
    ax.set_xticks(setdiff(x, opgaps))
    ax.set_xticklabels(xlabels; rotation=90, fontsize=6)
    ax.set_yscale(:log)
    ax.set_ylim((1/3000, 3000))
    ax.set_yticks([1/1000, 1/100, 1/10, 1, 10, 100, 1000])
    ax.set_ylabel("Time relative to Julia")
    ax.legend(loc="lower left", fontsize=8)
    pushfirst!(opgaps, 0)
    push!(opgaps, length(x)+1)
    xc = (opgaps[1:end-1] .+ opgaps[2:end])./2
    axouter.set_xlim(ax.get_xlim())
    axouter.set_xticks(xc)
    axouter.set_xticklabels(operations; rotation=90, fontsize=9)
    for obj in axouter.get_xticklines()
        obj.set_visible(false)
    end
    axouter.get_yaxis().set_visible(false)
    axouter.set_frame_on(false)
    # for spkey in axouter.spines
    #     axouter.spines[spkey].set_visible(false)
    # end
    # for sp in ("left", "bottom", "right", "top")
    #     axouter.spines[sp].set_visible(false)
    # end
    fig.tight_layout()
    return fig
end
