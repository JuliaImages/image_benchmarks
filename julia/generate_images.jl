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

function generate_random(workdir::AbstractString, ext=".png";
                         sizes = multsizes((32, 2, 2048), (32, 2, 2048)),
                         eltypes = (Gray{N0f8}, Gray{N0f16}, Gray{Float32}, RGB{N0f8}, RGB{N0f16}, RGB{Float32},))
    for T in eltypes, sz in sizes
        img = rand(T, sz)
        Tstr = (T <: Gray ? "gray_" : "rgb_")*string(eltype(T))
        szstr = join(sz, '_')
        save(joinpath(workdir, "random_$(Tstr)_$szstr$ext"), img)
    end
end

