const rexeltype = r"N0f8|N0f16|Float32"
const idxeltype = Dict("N0f8"=>1, "N0f16"=>2, "Float32"=>3)
const eltypeidx = Dict(v=>k for (k, v) in idxeltype)
const rexsize = r"_(\d+)$"
const special_replacements = ["components" => "label_components", "dblcone" => "distance_transform", "spiral" => "flood"]

randomtag(fn) = (occursin(r"rgb", fn), idxeltype[match(rexeltype, fn).match], parse(Int, only(match(rexsize, fn).captures)))
randomlabel(tag) = (tag[1] ? "RGB" : "Gray") * "{" * eltypeidx[tag[2]] * "}, $(tag[3])"

function imagelt(image1, image2)
    image1 ∈ ("2d", "3d") && image2 ∈ ("2d", "3d") && return image1 < image2

    getcolor(str) = match(r"(Gray|RGB)"i, str).captures[1]::AbstractString
    geteltype(str) = idxeltype[match(r"(N0f8|N0f16|Float32)"i, str).captures[1]]
    function getsz(str)
        m =  match(r", (\d)+", str)
        if m === nothing
            m = match(r"_(\d+)_", str)
        end
        return parse(Int,m.captures[1])
    end

    col1, col2 = getcolor(image1), getcolor(image2)
    col1 != col2 && return col1 < col2
    et1, et2 = geteltype(image1), geteltype(image2)
    et1 != et2 && return et1 < et2
    return getsz(image1) < getsz(image2)
end
