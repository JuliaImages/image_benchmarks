# image_benchmarks

This repository contains a set of benchmarks implemented in different image processing suites.
This is currently in fairly early stages and not yet ready for promotion.
It is, however, open to enhancements and extensions.

Suites with mostly-complete support:

- JuliaImages
- Python's [scikit-image](https://scikit-image.org/)
- Matlab and its [image processing toolbox](https://www.mathworks.com/products/image.html)
- [OpenCV](https://opencv.org/) (partial)

Wanted/TODO:

- [Fiji/ImageJ2/ImgLib2](https://imagej.net/software/fiji/)
- [ITK](https://itk.org/)

Currently there are two categories of benchmarks:

- the "generic" benchmarks do not require a carefully-crafted image,
  and the performance of the associated benchmarks should not depend
  on specific image content
- the "specialized" benchmarks for which the algorithm execution time
  may be dependent on image content (sometimes strongly so)

## Creating the test images

You can create these images using the Julia code (if needed, install Julia from https://julialang.org/downloads/).
These instructions were tested on Linux, but with small modifications they should work for any operating system.
Navigate to the `julia/` subdirectory, then launch Julia:

```sh
image_benchmarks/julia$ julia --project
```

or launch Julia via your GUI, and then navigate within Julia to this directory and "activate" the project:

```julia
julia> cd(raw"C:\path\to\this\repository\julia")   # "raw" makes the \ non-escaping

julia> using Pkg

julia> Pkg.activate(".")                           # use the `julia/` folder's Project.toml
```

and then execute the following at the Julia prompt:

```julia
julia> include("generate_images.jl")
generate_special (generic function with 2 methods)

julia> generate_random("/tmp/imgbench")

julia> generate_special("/tmp/imgbench_special")
```

The two folder names supplied to the `generate_*` functions are just a suggestion, you can store the images wherever you want.

## Running the benchmarks

Each suite has a separate README file that describes how to run the benchmarks.

A few oddities have been observed in the
[Python benchmark timing](https://stackoverflow.com/questions/69164027/unreliable-results-from-timeit-cache-issue),
but we believe that these have been largely resolved.

## Plotting the results

Navigate to the top-level directory of this repository, and then launch Julia:

```sh
image_benchmarks$ julia --project
```

```julia
julia> include("plotting.jl")
plot_ratio (generic function with 1 method)

julia> taskplots(randomtag, randomlabel, "julia/julia_generics.csv" => "Julia",
                                         "python-skimage/python_generics.csv" => "python-skimage",
                                         "matlab/matlab_generics.csv" => "Matlab",
                                         "opencv/opencv_generics.csv" => "OpenCV",
       )
Figure(PyObject <Figure size 640x480 with 6 Axes>)

julia> df = combine_all("julia/julia_generics.csv" => "Julia",
                        "python-skimage/python_generics.csv" => "python-skimage",
                        "matlab/matlab_generics.csv" => "Matlab",
                        "opencv/opencv_generics.csv" => "OpenCV",
                        "julia/julia_special.csv" => "Julia",
                        "python-skimage/python_special.csv" => "python-skimage",
                        "matlab/matlab_special.csv" => "Matlab");   # makes a DataFrame

julia> plot_ratio(ratio_df(df))
Figure(PyObject <Figure size 750x400 with 1 Axes>)
```
