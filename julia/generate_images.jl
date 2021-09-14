using FileIO, ImageCore

function multsizes(dimspecs...)
    szs = Dims{length(dimspecs)}[]
    sz = map(first, dimspecs)
    mult = map(s->s[2], dimspecs)
    stop = map(last, dimspecs)
    while true
        push!(szs, sz)
        sz = sz .* mult
        any(sz .> stop) && break
    end
    return szs
end

function generate_random(workdir::AbstractString, ext=".tif"; # ext=Dict(RGB=>".ppm", Gray=>".pgm");
                         sizes = multsizes((32, 2, 2048), (32, 2, 2048)),
                         eltypes = (Gray{N0f8}, Gray{N0f16}, Gray{Float32}, RGB{N0f8}, RGB{N0f16}, RGB{Float32},))
    if !isdir(workdir)
        mkpath(workdir)
    end
    for T in eltypes, sz in sizes
        Tstr = (T <: Gray ? "gray_" : "rgb_")*string(eltype(T))
        if isa(ext, AbstractDict)
            thisext = ext[T <: Gray ? Gray : RGB]
        else
            thisext = ext
        end
        if eltype(T) <: AbstractFloat && thisext ∈ (".pbm", ".pgm", ".ppm")
            @warn "extension $thisext does not support floating point, skipping"
            continue
        end
        szstr = join(sz, '_')
        img = rand(T, sz)
        save(joinpath(workdir, "random_$(Tstr)_$szstr$thisext"), img)
    end
end

generate_bool(sz) = rand(Bool, sz)

function generate_dblcone(sz)
    img = trues(sz)
    middle = map(axes(img)) do ax
        (first(ax) + last(ax)) ÷ 2
    end
    jmiddle = CartesianIndex(Base.tail(middle))
    jsz = Base.tail(size(img))
    for j in CartesianIndices(Base.tail(axes(img)))
        for i in axes(img, 1)
            img[i, j] = abs2((i - middle[1])/size(img, 1)) < sum(abs2, Tuple(j - jmiddle)./jsz)
        end
    end
    return img
end

function generate_spiral(sz)
    img = zeros(Gray{N0f8}, sz)
    middle = map(axes(img)) do ax
        (first(ax) + last(ax)) ÷ 2
    end
    corner = Tuple(first(CartesianIndices(img)))
    orthog = (last(axes(img, 1)), Base.tail(corner)...)
    I1 = CartesianIndex(ntuple(_->1, ndims(img)))
    Iend = last(CartesianIndices(img))
    # Archimedian spiral
    for θ in LinRange(0, 6π, 6*maximum(size(img)))
        r = 0.95*θ/(6π)
        yn, xn = r*cos(θ), r*sin(θ)
        c = CartesianIndex(round.(Int, middle .+ yn .* (corner .- middle) .+ xn .* (orthog .- middle)))
        I = max(CartesianIndex(corner), c-I1):min(Iend, c+I1)
        isempty(I) && break
        imgtmp = 0.5 .+ 0.5 .* rand(size(I)...)
        img[I] = imgtmp
    end
    return img
end

function generate_special(workdir::AbstractString, ext=".tif")
    if !isdir(workdir)
        mkpath(workdir)
    end
    save(joinpath(workdir, "components2d"*ext), generate_bool((2048, 2048)))
    save(joinpath(workdir, "components3d"*ext), generate_bool((512, 512, 50)))
    save(joinpath(workdir, "dblcone2d"*ext), generate_dblcone((2048, 2048)))
    save(joinpath(workdir, "dblcone3d"*ext), generate_dblcone((512, 512, 50)))
    save(joinpath(workdir, "spiral2d"*ext), generate_spiral((2048, 2048)))
    save(joinpath(workdir, "spiral3d"*ext), generate_spiral((2048, 2048, 50)))
end