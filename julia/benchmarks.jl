using Images
using BenchmarkTools
using ProgressMeter

run_complement(img) = complement.(img)

setup_mean(img) = repeat(img, ntuple(_->1, ndims(img))..., 5)
function run_mean(imgr)
    return mean(imgr; dims=ndims(imgr))
end

run_gradient(img) = imgradients(img, KernelFactors.sobel)

run_blur(img) = imfilter(img, KernelFactors.gaussian(ntuple(_->5, ndims(img)), ntuple(_->21, ndims(img))))
run_blur_iir(img) = imfilter(img, KernelFactors.IIRGaussian(ntuple(_->5, ndims(img)))) # a bit faster

run_histeq(img) = adjust_histogram(img, Equalization(nbins = 256, minval = 0, maxval = 1))

function time_generics(workdir)
    tasks = Dict(task=>Dict{String,Float64}() for task in ["complement", "mean", "gradient", "blur", "histeq"])
    @showprogress "Timing generic operations: " for fn in readdir(workdir)
        img = load(joinpath(workdir, fn))
        tasks["complement"][fn] = @belapsed run_complement($img) samples=16 evals=1
        tasks["mean"][fn] = @belapsed run_mean(imgr) samples=16 evals=1 setup=(imgr = setup_mean($img))
        tasks["gradient"][fn] = @belapsed run_gradient($img) samples=16 evals=1
        tasks["blur"][fn] = @belapsed run_blur($img) samples=16 evals=1
        tasks["histeq"][fn] = @belapsed run_histeq($img) samples=16 evals=1
    end
    return tasks
end

# tdata = time_generics("/tmp/imgs")
