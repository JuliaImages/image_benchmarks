import skimage
from skimage import io
from skimage import filters
from skimage import exposure
from skimage import measure
from skimage import segmentation
import scipy.ndimage.morphology
import numpy as np
import timeit
import os
from tqdm import tqdm

import corners 

nrep = 16

def run_complement(img):
    skimage.util.invert(img)

def setup_mean(img):
    return np.repeat(img.reshape((1, *img.shape)), 5, axis=0)
def run_mean(imgr):
    return np.mean(imgr, axis=0)

def run_gradient(img):
    return (skimage.filters.sobel(img, axis=0), skimage.filters.sobel(img, axis=1))

def run_blur(img):
    return skimage.filters.gaussian(img, 5, truncate=2)  # channel_axis=img.ndim-1)

def run_histeq(img):
    if img.shape[-1] == 3:   # not-very-robust signal of a color image
        imgyiq = skimage.color.rgb2yiq(img)
        # 2 spatial dimensions only, FIXME?
        imgyiq[:,:,0] = skimage.exposure.equalize_hist(imgyiq[:,:,0], nbins = 256)
        return skimage.color.yiq2rgb(imgyiq)
    else:
        return skimage.exposure.equalize_hist(img, nbins = 256)

def time_generics(workdir):
    tdata = {task:{} for task in ["complement", "mean", "gradient", "blur", "histeq", "corners_harris", "corners_shi_tomasi", "corners_kitchen_rosenfeld", "corners_fastcorners"]}
    return time_generics_(tdata, workdir, tdata.keys())

def time_generics_(tdata, workdir, taskitems):
    for fn in tqdm(os.listdir(workdir), desc="Timing generic operations: "):
        img = io.imread(os.path.join(workdir, fn))
        fn, _ = os.path.splitext(fn)
        if "complement" in taskitems:
            n = 100
            tdata["complement"][fn] = min(timeit.repeat(f'run_complement(img)', number=n, repeat=nrep, globals={"img": img, "run_complement":run_complement}))/n
        if "mean" in taskitems:
            n = 100
            tdata["mean"][fn] = min(timeit.repeat(f'run_mean(imgr)', f'imgr = setup_mean(img)', number=n, repeat=nrep, globals={"img": img, "setup_mean":setup_mean, "run_mean":run_mean}))/n
        if "gradient" in taskitems:
            n = 10
            tdata["gradient"][fn] = min(timeit.repeat(f'run_gradient(img)', number=n, repeat=nrep, globals={"img": img, "run_gradient":run_gradient}))/n
        if "blur" in taskitems:
            n = 10
            tdata["blur"][fn] = min(timeit.repeat(f'run_blur(img)', number=n, repeat=nrep, globals={"img": img, "run_blur":run_blur}))/n
        if "histeq" in taskitems:
            n = 10
            tdata["histeq"][fn] = min(timeit.repeat(f'run_histeq(img)', number=n, repeat=nrep, globals={"img": img, "run_histeq":run_histeq}))/n
        if "corners_harris" in taskitems:
            n = 10
            tdata["corners_harris"][fn] = min(timeit.repeat(f'run_imcorner_harris(img)', number=n, repeat=nrep, globals={"img": img, "run_imcorner_harris":corners.run_imcorner_harris}))/n
        if "corners_shi_tomasi" in taskitems:
            n = 10
            tdata["corners_shi_tomasi"][fn] = min(timeit.repeat(f'run_imcorner_shi_tomasi(img)', number=n, repeat=nrep, globals={"img": img, "run_imcorner_shi_tomasi":corners.run_imcorner_shi_tomasi}))/n
        if "corners_kitchen_rosenfeld" in taskitems:
            n = 10
            tdata["corners_kitchen_rosenfeld"][fn] = min(timeit.repeat(f'run_imcorner_kr(img)', number=n, repeat=nrep, globals={"img": img, "run_imcorner_kr":corners.run_imcorner_kr}))/n
        if "corners_fastcorners" in taskitems:
            n = 10
            tdata["corners_fastcorners"][fn] = min(timeit.repeat(f'run_imcorner_fastcorners(img)', number=n, repeat=nrep, globals={"img": img, "run_imcorner_fastcorners":corners.run_imcorner_fastcorners}))/n 
    return tdata

# tdata = time_generics("/tmp/imgs")

def run_label(img):
    return measure.label(img)
def closure_label(img):
    def inner():
        run_label(img)
    return inner

def run_disttform(img):
    return scipy.ndimage.morphology.distance_transform_edt(img, return_indices=True)
def closure_disttform(img):
    def inner():
        run_disttform(img)
    return inner

def run_flood(img):
    def div2(x):
        return x // 2
    middle = tuple(map(div2, img.shape))
    return segmentation.flood(img, middle, connectivity=1, tolerance=0.5*255)
def closure_flood(img):
    def inner():
        run_flood(img)
    return inner

def time_special(workdir, ext=".tif"):
    tdata = {}
    for f in ("components2d", "components3d"):
        img = io.imread(os.path.join(workdir, f + ext))
        tmr = timeit.Timer(closure_label(img))
        n, t = tmr.autorange()
        tdata[f] = t/n
    for f in ("dblcone2d", "dblcone3d"):
        img = io.imread(os.path.join(workdir, f + ext))
        tmr = timeit.Timer(closure_disttform(img))
        n, t = tmr.autorange()
        tdata[f] = t/n
    for f in ("spiral2d", "spiral3d"):
        img = io.imread(os.path.join(workdir, f + ext))
        tmr = timeit.Timer(closure_flood(img))
        n, t = tmr.autorange()
        tdata[f] = t/n

    return tdata
