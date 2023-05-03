using ImageCorners

# corner related algorithms
run_corners_harris(img) = ImageCorners.imcorner(img; method = ImageCorners.harris)
run_corners_shitomasi(img) = ImageCorners.imcorner(img; method = ImageCorners.shi_tomasi)
run_corners_kr(img) = ImageCorners.imcorner(img; method = ImageCorners.kitchen_rosenfeld)
run_corners_fastcorners(img) = ImageCorners.imcorner(img; method = ImageCorners.fastcorners)