using Images
using ImageSegmentation
using BenchmarkTools
using ProgressMeter

run_complement(img) = complement.(img)

setup_mean(img) = repeat(img, ntuple(_->1, ndims(img))..., 5)
function run_mean(imgr)
    return mean(imgr; dims=ndims(imgr))
end

run_gradient(img) = imgradients(img, KernelFactors.sobel)

run_blur(img) = imfilter(img, KernelFactors.gaussian(ntuple(_->5.0f0, ndims(img)), ntuple(_->21, ndims(img))))
run_blur_iir(img) = imfilter(img, KernelFactors.IIRGaussian(ntuple(_->5, ndims(img)))) # a bit faster

run_histeq(img) = adjust_histogram(img, Equalization(nbins = 256, minval = 0, maxval = 1))

function time_generics(workdir)
    tdata = Dict(task=>Dict{String,Float64}() for task in ["complement", "mean", "gradient", "blur", "histeq"])
    time_generics!(tdata, workdir, keys(tdata))
end

function time_generics!(tdata, workdir, taskitems)
    @showprogress "Timing generic operations: " for fn in readdir(workdir)
        img = load(joinpath(workdir, fn))
        fn, _ = splitext(fn)
        "complement" ∈ taskitems && (tdata["complement"][fn] = @belapsed run_complement($img) samples=16 evals=1)
        "mean" ∈ taskitems       && (tdata["mean"][fn] = @belapsed run_mean(imgr) samples=16 evals=1 setup=(imgr = setup_mean($img)))
        "gradient" ∈ taskitems   && (tdata["gradient"][fn] = @belapsed run_gradient($img) samples=16 evals=1)
        "blur" ∈ taskitems       && (tdata["blur"][fn] = @belapsed run_blur($img) samples=16 evals=1)
        "histeq" ∈ taskitems     && (tdata["histeq"][fn] = @belapsed run_histeq($img) samples=16 evals=1)
    end
    return tdata
end

# tdata = time_generics("/tmp/imgs")

run_label(img) = label_components(img, trues(ntuple(_->3, ndims(img))))

run_disttform(img) = distance_transform(feature_transform(img))

function run_flood(img)
    middle = map(axes(img)) do ax
        (first(ax) + last(ax)) ÷ 2
    end
    flood(>=(0.5), img, CartesianIndex(middle))
end

function time_special(workdir)
    imgs = ["components2d" => run_label, "components3d" => run_label,
            "dblcone2d" => run_disttform, "dblcone3d" => run_disttform,
            "spiral2d" => run_flood, "spiral3d" => run_flood]
    fls = readdir(workdir)
    tdata = Dict{String,Float64}()
    @showprogress "Timing special operations: " for (name, f) in imgs
        idx = findfirst(str->startswith(str, name), fls)
        img = load(joinpath(workdir, fls[idx]))
        if f === run_disttform
            img = convert(Array{Bool}, img)
        end
        tdata[name] = @belapsed $f($img) evals=1
    end
    return tdata
end

# tdata = time_special("/tmp/imgspecial")
