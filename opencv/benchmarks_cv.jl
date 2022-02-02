using OpenCV
using BenchmarkTools
using ProgressMeter

using OpenCV: Mat

# Stuff to add to OpenCV:
Base.materialize!(dest::OpenCV.Mat, src::Broadcast.Broadcasted{Style,Axes,typeof(+),Tuple{<:OpenCV.Mat,<:OpenCV.Mat}}) where {Style,Axes} =
    OpenCV.add(src.args..., dest)

run_complement(img::OpenCV.Mat{T}) where T<:Integer = OpenCV.bitwise_not(img)
# run_complement(img::OpenCV.Mat{T}) where T<:AbstractFloat = 1 .- img

# Not quite equivalent to Julia & Python as it takes a tuple-of-images as input
function run_mean(imgr)
    n = length(imgr)
    n < 2 && return first(imgr)
    img = OpenCV.addWeighted(imgr[1], 1/n, imgr[2], 1/n, 0.0; dtype=Cint(OpenCV.CV_64F))
    for j = 3:n
        OpenCV.addWeighted(img, 1.0, imgr[j], 1/n, 0.0, img, Cint(OpenCV.CV_64F))
    end
    return img
end

run_gradient(img) = (OpenCV.Sobel(img, Cint(OpenCV.CV_64F), Cint(0), Cint(1)), OpenCV.Sobel(img, Cint(OpenCV.CV_64F), Cint(1), Cint(0)))

run_blur(img) = OpenCV.GaussianBlur(img, OpenCV.Size{Int32}(21, 21), 5.0)

function run_histeq(img::OpenCV.Mat)
    if size(img, 1) == 1
        return OpenCV.equalizeHist(img)
    end
    ym = OpenCV.cvtColor(img, OpenCV.COLOR_BGR2LAB)
    vm = OpenCV.split(ym)
    OpenCV.equalizeHist(first(vm), first(vm))
    ym = OpenCV.merge(vm)
    return OpenCV.cvtColor(ym, OpenCV.COLOR_LAB2BGR)
end

const tasknames = ["complement", "mean", "gradient", "blur", "histeq"]
function time_generics(workdir)
    tasks = Dict(task=>Dict{String,Float64}() for task in tasknames)
    @showprogress "Timing generic operations: " for fn in readdir(workdir)
        img = OpenCV.imread(joinpath(workdir, fn), OpenCV.IMREAD_UNCHANGED)
        fn, _ = splitext(fn)
        if isempty(img)
            for tn in tasknames
                tasks[tn][fn] = NaN
            end
            continue
        end
        tasks["complement"][fn] = try
            @belapsed run_complement($img) samples=16 evals=1
        catch
            NaN
        end
        tasks["mean"][fn] = @belapsed run_mean(imgr) samples=16 evals=1 setup=(imgr = ($img, $img, $img, $img, $img))
        tasks["gradient"][fn] = @belapsed run_gradient($img) samples=16 evals=1
        tasks["blur"][fn] = @belapsed run_blur($img) samples=16 evals=1
        tasks["histeq"][fn] = try
            @belapsed run_histeq($img) samples=16 evals=1
        catch
            NaN
        end
    end
    return tasks
end

# tdata = time_generics("/tmp/imgs")

# For things that OpenCV just can't do
return_err(img) = error("not supported")

run_label(img) = OpenCV.connectedComponents(img; connectivity=Cint(8))

run_disttform(img) = OpenCV.distanceTransform(img, OpenCV.DIST_L2, OpenCV.DIST_MASK_3)

function run_flood(img)
    middle = map(Base.tail(axes(img))) do ax
        (first(ax) + last(ax)) ÷ 2
    end
    val = img[:, middle...]
    @show val
    loDiff = eltype(img).(val .- half(img))
    upDiff = white(img) .- val
    masksz = ntuple(d -> d == 1 ? size(img, 1) : size(img, d) + 2, ndims(img))
    mask = falses(masksz)
    newval = (fill(white(img), size(img, 1))...,)
    @show loDiff upDiff newval middle
    OpenCV.floodFill(img, Mat(UInt8.(mask)), OpenCV.Point{Cint}(reverse(middle)...), newval, (loDiff...,), (upDiff...,), Cint(4) | OpenCV.FLOODFILL_MASK_ONLY)
end

white(img::Mat{T}) where T<:Integer = typemax(T)
white(img::Mat{T}) where T<:AbstractFloat = oneunit(T)
half(img::Mat{T}) where T<:Integer = white(img) ÷ 2
half(img::Mat{T}) where T<:AbstractFloat = white(img) / 2

function time_special(workdir)
    imgs = ["components2d" => run_label, "components3d" => return_err,
            "dblcone2d" => run_disttform, "dblcone3d" => return_err,
            "spiral2d" => run_flood, "spiral3d" => return_err]
    fls = readdir(workdir)
    tdata = Dict{String,Float64}()
    @showprogress "Timing special operations: " for (name, f) in imgs
        @show name
        idx = findfirst(str->startswith(str, name), fls)
        img = OpenCV.imread(joinpath(workdir, fls[idx]), OpenCV.IMREAD_UNCHANGED)
        if f === run_label
            img = Mat(UInt8.(img .> 0))
        end
        tdata[name] = try @belapsed $f($img) evals=1 catch NaN end
    end
    return tdata
end

# tdata = time_special("/tmp/imgspecial")
