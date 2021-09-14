# image_benchmarks

This repository contains a set of benchmarks implemented in different image processing suites:

- JuliaImages
- Python's [scikit-image](https://scikit-image.org/)
- Matlab and its [image processing toolbox](https://www.mathworks.com/products/image.html)
- [OpenCV](https://opencv.org/)

Wanted: [Fiji/ImageJ2/ImgLib2](https://imagej.net/software/fiji/)

Currently there are two categories of benchmarks:

- the "generic" benchmarks do not require a carefully-crafted image,
  and the performance of the associated benchmarks should not depend
  on specific image content
- the "specialized" benchmarks for which the algorithm execution time
  may be dependent on image content (sometimes strongly so)

This is currently in fairly early stages and not yet ready for promotion.
It is, however, open to enhancements and extensions.

Currently, there are some questions about the
[Python benchmark timing](https://stackoverflow.com/questions/69164027/unreliable-results-from-timeit-cache-issue).
